#pragma once

#include "cJSON.h"

void runtime_stats_start(void);
void runtime_stats_add_json(cJSON *info);
