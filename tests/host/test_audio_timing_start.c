#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "audio_timing.h"
#include "audio_output.h"
#include "ntp_clock.h"
#include "ptp_clock.h"

static int64_t now_us = 1000000;
static uint32_t queued[32];
static int queued_count;
static audio_frame_header_t taken;

int64_t esp_timer_get_time(void) { return now_us; }
bool ptp_clock_is_locked(void) { return true; }
int64_t ptp_clock_get_offset_ns(void) { return 0; }
void ptp_clock_get_stats(ptp_stats_t *stats) { memset(stats, 0, sizeof(*stats)); }
bool ntp_clock_is_locked(void) { return false; }
int64_t ntp_clock_get_offset_ns(void) { return 0; }
bool audio_output_get_pipeline_us(int64_t *time_us, uint32_t *pipeline_us) {
  *time_us = now_us;
  *pipeline_us = 0;
  return true;
}
uint32_t audio_output_get_hardware_latency_us(void) { return 0; }
uint32_t audio_output_get_underruns(void) { return 0; }
bool audio_stream_uses_buffer(audio_stream_type_t type) {
  return type == AUDIO_STREAM_BUFFERED;
}
int audio_buffer_get_frame_count(audio_buffer_t *buffer) {
  (void)buffer;
  return queued_count;
}
bool audio_buffer_take(audio_buffer_t *buffer, void **item, size_t *size,
                       TickType_t ticks) {
  (void)buffer;
  (void)ticks;
  if (!queued_count) return false;
  taken.rtp_timestamp = queued[0];
  taken.samples_per_channel = 352;
  taken.channels = 2;
  memmove(queued, queued + 1, (size_t)--queued_count * sizeof(*queued));
  static struct { audio_frame_header_t hdr; int16_t pcm[352 * 2]; } frame;
  frame.hdr = taken;
  *item = &frame;
  *size = sizeof(frame);
  return true;
}
void audio_buffer_return(audio_buffer_t *buffer, void *item) {
  (void)buffer;
  (void)item;
}
bool audio_buffer_bulk_start_rtp(audio_buffer_t *buffer, uint32_t *rtp) {
  (void)buffer;
  if (!queued_count) return false;
  uint32_t start = queued[queued_count - 1];
  for (int i = queued_count - 1; i > 0; --i) {
    if (queued[i - 1] + 352 != start) break;
    start = queued[i - 1];
  }
  *rtp = start;
  return true;
}
bool audio_buffer_peek_newest_rtp(audio_buffer_t *buffer, uint32_t *rtp) {
  (void)buffer;
  if (!queued_count) return false;
  *rtp = queued[queued_count - 1];
  return true;
}
void audio_buffer_flush(audio_buffer_t *buffer) { (void)buffer; queued_count = 0; }

int main(void) {
  audio_timing_t timing;
  audio_stream_t stream = {0};
  audio_buffer_t buffer = {0};
  audio_stats_t stats = {0};
  int16_t out[353 * 2] = {0};
  stream.type = AUDIO_STREAM_REALTIME;
  stream.format.sample_rate = 44100;
  stream.format.channels = 2;
  stream.format.frame_size = 352;
  audio_timing_init(&timing, sizeof(audio_frame_header_t) + 352 * 2 * 2);
  timing.quick_start = true;
  audio_timing_set_anchor(&timing, &stream.format, 0, 3000000000ULL, 0);

  queued[queued_count++] = 0;
  queued[queued_count++] = 352;
  assert(audio_timing_read(&timing, &buffer, &stream, &stats, out, 353) == 352);
  assert(timing.pending_valid);

  // A later contiguous run appears while the first frame waits for its
  // scheduled time.  A gap in the ahead-of-playback data must not evict it.
  for (int i = 0; i < 12; ++i) queued[queued_count++] = 10000 + i * 352;
  now_us = 2995000; // target 3 s minus 5 ms pipeline allowance
  size_t played = audio_timing_read(&timing, &buffer, &stream, &stats, out, 353);
  assert(played == 352);
  assert(timing.playout_started);
  assert(!timing.pending_valid);

  // A retransmit for the already-played first frame may arrive while that
  // frame waits pending. It must not be emitted a second time.
  memmove(queued + 1, queued, (size_t)queued_count * sizeof(*queued));
  queued[0] = 0;
  queued_count++;
  now_us = 3003000;
  assert(audio_timing_read(&timing, &buffer, &stream, &stats, out, 353) == 352);
  assert(timing.expected_rtp == 704);
  free(timing.pending_frame);

  // A genuinely separated old island is still discarded before startup.
  now_us = 1000000;
  queued_count = 0;
  audio_timing_init(&timing, sizeof(audio_frame_header_t) + 352 * 2 * 2);
  timing.quick_start = true;
  audio_timing_set_anchor(&timing, &stream.format, 0, 3000000000ULL, 0);
  queued[queued_count++] = 0;
  for (int i = 0; i < 12; ++i) queued[queued_count++] = 10000 + i * 352;
  assert(audio_timing_read(&timing, &buffer, &stream, &stats, out, 353) == 352);
  assert(timing.pending_valid);
  assert(((audio_frame_header_t *)timing.pending_frame)->rtp_timestamp == 10000);
  free(timing.pending_frame);
  puts("startup timing and stale-island checks passed");
  return 0;
}
