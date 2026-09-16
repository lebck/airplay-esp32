#pragma once
#include <stdbool.h>
typedef enum {
  AUDIO_STREAM_NONE = 0,
  AUDIO_STREAM_REALTIME = 96,
  AUDIO_STREAM_BUFFERED = 103
} audio_stream_type_t;
// Only needed by unrelated SETUP builders in the same translation unit.
static inline bool audio_stream_uses_buffer(audio_stream_type_t type) {
  return type == AUDIO_STREAM_BUFFERED;
}
