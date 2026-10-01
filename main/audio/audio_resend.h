#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <string.h>

// A 512-packet window covers about four seconds at 44.1 kHz / 352 samples.
// The sender normally transmits about two seconds before playout, so a lost
// packet must remain eligible for retransmission past the old 64-packet
// (0.51-second) window. Each request is still capped at 64 packets.
#define AUDIO_RESEND_WINDOW_WORDS 8
#define AUDIO_RESEND_WINDOW_BITS  (AUDIO_RESEND_WINDOW_WORDS * 64)
#define AUDIO_RESEND_MAX_REQUEST 64

typedef struct {
  uint64_t missing[AUDIO_RESEND_WINDOW_WORDS];
  uint16_t first_seq;
  uint16_t retry_after_seq;
} audio_resend_window_t;

static inline void audio_resend_window_clear(audio_resend_window_t *window) {
  memset(window, 0, sizeof(*window));
}

static inline bool audio_resend_window_empty(const audio_resend_window_t *window) {
  for (unsigned i = 0; i < AUDIO_RESEND_WINDOW_WORDS; ++i) {
    if (window->missing[i] != 0) {
      return false;
    }
  }
  return true;
}

static inline bool audio_resend_window_has(const audio_resend_window_t *window,
                                            unsigned offset) {
  return (window->missing[offset / 64] & (1ULL << (offset % 64))) != 0;
}

// Returns true if an older unresolved range had to be abandoned.
static inline bool audio_resend_window_track(audio_resend_window_t *window,
                                              uint16_t first_seq,
                                              uint16_t count) {
  if (count == 0 || count > AUDIO_RESEND_MAX_REQUEST) {
    return false;
  }
  bool had_missing = !audio_resend_window_empty(window);
  uint16_t offset = (uint16_t)(first_seq - window->first_seq);
  bool abandoned = had_missing &&
                   (offset >= AUDIO_RESEND_WINDOW_BITS ||
                    (unsigned)offset + count > AUDIO_RESEND_WINDOW_BITS);
  if (!had_missing || abandoned) {
    audio_resend_window_clear(window);
    window->first_seq = first_seq;
    window->retry_after_seq = first_seq;
    offset = 0;
  }
  for (unsigned i = 0; i < count; ++i) {
    unsigned bit = (unsigned)offset + i;
    window->missing[bit / 64] |= 1ULL << (bit % 64);
  }
  return abandoned;
}

static inline bool audio_resend_window_mark(audio_resend_window_t *window,
                                             uint16_t seq) {
  unsigned offset = (uint16_t)(seq - window->first_seq);
  if (offset >= AUDIO_RESEND_WINDOW_BITS ||
      !audio_resend_window_has(window, offset)) {
    return false;
  }
  window->missing[offset / 64] &= ~(1ULL << (offset % 64));
  if (audio_resend_window_empty(window)) {
    audio_resend_window_clear(window);
    return true;
  }

  // Slide past resolved sequence numbers. Shift whole words at once so a
  // far-ahead retransmit cannot cost hundreds of per-bit shifts in the UDP
  // receiver task.
  unsigned skip = 0;
  while (!audio_resend_window_has(window, skip)) {
    ++skip;
  }
  if (skip != 0) {
    unsigned words = skip / 64;
    unsigned bits = skip % 64;
    for (unsigned i = 0; i < AUDIO_RESEND_WINDOW_WORDS; ++i) {
      unsigned src = i + words;
      uint64_t value = src < AUDIO_RESEND_WINDOW_WORDS
                           ? window->missing[src] >> bits
                           : 0;
      if (bits != 0 && src + 1 < AUDIO_RESEND_WINDOW_WORDS) {
        value |= window->missing[src + 1] << (64 - bits);
      }
      window->missing[i] = value;
    }
    window->first_seq = (uint16_t)(window->first_seq + skip);
  }
  return true;
}

// Rotate retries across independent missing ranges, including sequence wrap.
static inline bool audio_resend_window_next_range(
    const audio_resend_window_t *window, uint16_t *first, uint16_t *count) {
  if (!first || !count || audio_resend_window_empty(window)) {
    return false;
  }
  unsigned start = (uint16_t)(window->retry_after_seq - window->first_seq);
  if (start >= AUDIO_RESEND_WINDOW_BITS) {
    start = 0;
  }
  unsigned bit = start;
  while (bit < AUDIO_RESEND_WINDOW_BITS &&
         !audio_resend_window_has(window, bit)) {
    ++bit;
  }
  if (bit == AUDIO_RESEND_WINDOW_BITS) {
    bit = 0;
    while (!audio_resend_window_has(window, bit)) {
      ++bit;
    }
  }
  unsigned end = bit;
  while (end < AUDIO_RESEND_WINDOW_BITS &&
         end - bit < AUDIO_RESEND_MAX_REQUEST &&
         audio_resend_window_has(window, end)) {
    ++end;
  }
  *first = (uint16_t)(window->first_seq + bit);
  *count = (uint16_t)(end - bit);
  return true;
}
