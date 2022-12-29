#ifndef __GIR_ZIG_FMT_H__
#define __GIR_ZIG_FMT_H__

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

char *snake_to_SNAKE(const char *src);
char *SNAKE_to_snake(const char *src);

char *title_to_snake(const char *src);
char *snake_to_camel(const char *src);
char *snake_to_title(const char *src);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __GIR_ZIG_FMT_H__ */