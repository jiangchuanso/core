#pragma once

#ifdef _WIN32
#define LINGUASPARK_API __declspec(dllexport)
#else
#define LINGUASPARK_API __attribute__((visibility("default")))
#endif

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct TranslatorWrapper TranslatorWrapper;

LINGUASPARK_API TranslatorWrapper *bergamot_create(size_t numWorkers);
LINGUASPARK_API void bergamot_destroy(TranslatorWrapper *translator);
LINGUASPARK_API void
bergamot_load_model_from_config(TranslatorWrapper *translator,
                                const char *languagePair, const char *config);
LINGUASPARK_API bool bergamot_is_supported(TranslatorWrapper *translator,
                                           const char *from, const char *to);
LINGUASPARK_API const char *bergamot_translate(TranslatorWrapper *translator,
                                               const char *from, const char *to,
                                               const char *input);
LINGUASPARK_API void bergamot_free_translation(const char *translation);

#ifdef __cplusplus
}
#endif
