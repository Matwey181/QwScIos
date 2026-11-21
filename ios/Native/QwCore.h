#pragma once
#ifdef __cplusplus
extern "C" {
#endif
// Returns an owned UTF-8 string; release it with qw_free.
char* qw_run(const char* operation, int count, const char* const* arguments);
void qw_free(char* result);
#ifdef __cplusplus
}
#endif
