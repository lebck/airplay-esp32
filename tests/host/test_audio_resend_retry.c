#include <assert.h>
#include <stdint.h>
#include <stdio.h>

#include "audio_resend.h"

int main(void) {
  audio_resend_window_t window;
  uint16_t first = 0;
  uint16_t count = 0;

  audio_resend_window_clear(&window);
  audio_resend_window_track(&window, 65534, 1);
  audio_resend_window_track(&window, 2, 1);
  assert(audio_resend_window_next_range(&window, &first, &count));
  assert(first == 65534 && count == 1);
  window.retry_after_seq = (uint16_t)(first + count);
  assert(audio_resend_window_next_range(&window, &first, &count));
  assert(first == 2 && count == 1);
  window.retry_after_seq = (uint16_t)(first + count);
  assert(audio_resend_window_next_range(&window, &first, &count));
  assert(first == 65534 && count == 1);
  audio_resend_window_clear(&window);
  audio_resend_window_track(&window, 101, 2);
  assert(audio_resend_window_next_range(&window, &first, &count));
  assert(first == 101 && count == 2);
  audio_resend_window_clear(&window);
  assert(!audio_resend_window_next_range(&window, &first, &count));

  // The sender transmits roughly two seconds ahead: a missing frame must
  // remain recoverable after more than 64 newer packets have arrived.
  audio_resend_window_track(&window, 1000, 1);
  audio_resend_window_track(&window, 1200, 1);
  assert(audio_resend_window_mark(&window, 1000));
  assert(audio_resend_window_mark(&window, 1200));
  assert(audio_resend_window_empty(&window));

  audio_resend_window_track(&window, 1000, 1);
  audio_resend_window_track(&window, 1511, 1);
  assert(audio_resend_window_mark(&window, 1000));
  assert(window.first_seq == 1511);
  assert(audio_resend_window_mark(&window, 1511));
  assert(audio_resend_window_empty(&window));

  audio_resend_window_track(&window, 2000, 1);
  assert(audio_resend_window_track(&window, 2512, 1));
  assert(!audio_resend_window_mark(&window, 2000));
  assert(audio_resend_window_mark(&window, 2512));

  puts("resend window and rotating retries passed");
  return 0;
}
