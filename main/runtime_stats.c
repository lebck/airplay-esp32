#include "runtime_stats.h"

#include "esp_heap_caps.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#if CONFIG_FREERTOS_GENERATE_RUN_TIME_STATS
#if !CONFIG_FREERTOS_RUN_TIME_STATS_USING_ESP_TIMER
#error "CPU utilization monitoring requires the ESP timer runtime clock"
#endif
static portMUX_TYPE s_lock = portMUX_INITIALIZER_UNLOCKED;
static float s_cpu[portNUM_PROCESSORS];
static int64_t s_sample_time;
static int64_t s_interval_us;

static void monitor_task(void *arg) {
  (void)arg;
  configRUN_TIME_COUNTER_TYPE previous_idle[portNUM_PROCESSORS] = {0};
  int64_t previous_time = 0;
  while (1) {
    configRUN_TIME_COUNTER_TYPE idle[portNUM_PROCESSORS];
    for (int core = 0; core < portNUM_PROCESSORS; ++core) {
      TaskStatus_t status;
      // Skip stack scanning and task-state lookup: only the counter is needed.
      vTaskGetInfo(xTaskGetIdleTaskHandleForCore(core), &status, pdFALSE,
                   eRunning);
      idle[core] = status.ulRunTimeCounter;
    }
    int64_t now = esp_timer_get_time();
    if (previous_time != 0) {
      int64_t interval = now - previous_time;
      float cpu[portNUM_PROCESSORS];
      for (int core = 0; core < portNUM_PROCESSORS; ++core) {
        double idle_fraction =
            (double)(idle[core] - previous_idle[core]) / (double)interval;
        // Counters are updated at context switches, so small boundary errors
        // are possible. Report bounded, interval-based percentages.
        cpu[core] = 100.0 * (1.0 - idle_fraction);
        if (cpu[core] < 0) {
          cpu[core] = 0;
        }
        if (cpu[core] > 100) {
          cpu[core] = 100;
        }
      }
      portENTER_CRITICAL(&s_lock);
      for (int core = 0; core < portNUM_PROCESSORS; ++core) {
        s_cpu[core] = cpu[core];
      }
      s_sample_time = now;
      s_interval_us = interval;
      portEXIT_CRITICAL(&s_lock);
      for (int core = 0; core < portNUM_PROCESSORS; ++core) {
        ESP_LOGI("runtime", "CPU%d=%.1f%% (last %.1fs)", core,
                 (double)cpu[core], (double)interval / 1000000.0);
      }
      ESP_LOGI("runtime", "free RAM: internal=%u PSRAM=%u bytes",
               (unsigned)heap_caps_get_free_size(MALLOC_CAP_INTERNAL),
               (unsigned)heap_caps_get_free_size(MALLOC_CAP_SPIRAM));
    }
    for (int core = 0; core < portNUM_PROCESSORS; ++core) {
      previous_idle[core] = idle[core];
    }
    previous_time = now;
    vTaskDelay(pdMS_TO_TICKS(5000));
  }
}
#endif

void runtime_stats_start(void) {
#if CONFIG_FREERTOS_GENERATE_RUN_TIME_STATS
  if (xTaskCreate(monitor_task, "runtime", 3072, NULL, 1, NULL) != pdPASS) {
    ESP_LOGE("runtime", "Could not start CPU monitor");
  }
#endif
}

void runtime_stats_add_json(cJSON *info) {
#if CONFIG_FREERTOS_GENERATE_RUN_TIME_STATS
  float cpu[portNUM_PROCESSORS];
  int64_t sample_time, interval;
  portENTER_CRITICAL(&s_lock);
  for (int core = 0; core < portNUM_PROCESSORS; ++core) {
    cpu[core] = s_cpu[core];
  }
  sample_time = s_sample_time;
  interval = s_interval_us;
  portEXIT_CRITICAL(&s_lock);
  cJSON_AddBoolToObject(info, "cpu_stats_ready", sample_time != 0);
  if (sample_time != 0) {
    cJSON *cores = cJSON_AddArrayToObject(info, "cpu_usage_percent");
    for (int core = 0; core < portNUM_PROCESSORS; ++core) {
      cJSON_AddItemToArray(cores, cJSON_CreateNumber(cpu[core]));
    }
    cJSON_AddNumberToObject(info, "cpu_sample_interval_ms", interval / 1000);
    cJSON_AddNumberToObject(info, "cpu_sample_age_ms",
                            (esp_timer_get_time() - sample_time) / 1000);
  }
#else
  cJSON_AddBoolToObject(info, "cpu_stats_ready", false);
#endif
  cJSON_AddNumberToObject(info, "free_internal_heap",
                          heap_caps_get_free_size(MALLOC_CAP_INTERNAL));
  cJSON_AddNumberToObject(info, "free_psram",
                          heap_caps_get_free_size(MALLOC_CAP_SPIRAM));
}
