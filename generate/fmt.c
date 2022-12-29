#include "fmt.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

char *snake_to_SNAKE(const char *src)
{
	int src_len = strlen(src);
	int dst_len = src_len;
	char *dst = (char *)malloc((dst_len + 1) * sizeof(char));
	assert(dst != NULL);
	for (int src_idx = 0, dst_idx = 0; src_idx < src_len; src_idx++)
	{
		dst[dst_idx] = toupper(src[src_idx]);
		dst_idx++;
	}
	dst[dst_len] = 0;
	return dst;
}

char *SNAKE_to_snake(const char *src)
{
	int src_len = strlen(src);
	int dst_len = src_len;
	char *dst = (char *)malloc((dst_len + 1) * sizeof(char));
	assert(dst != NULL);
	for (int src_idx = 0, dst_idx = 0; src_idx < src_len; src_idx++)
	{
		dst[dst_idx] = tolower(src[src_idx]);
		dst_idx++;
	}
	dst[dst_len] = 0;
	return dst;
}

char *title_to_snake(const char *src)
{
	int src_len = 0;
	int dst_len = 0;
	for (src_len = 0; src[src_len]; src_len++)
	{
		dst_len++;
		if (src_len > 0 && isupper(src[src_len])) dst_len++;
	}
	char *dst = (char *)malloc((dst_len + 1) * sizeof(char));
	assert(dst != NULL);
	for (int src_idx = 0, dst_idx = 0; src_idx < src_len; src_idx++)
	{
		if (isupper(src[src_idx]))
		{
			if (src_idx > 0)
			{
				dst[dst_idx] = '_';
				dst_idx++;
			}
			dst[dst_idx] = tolower(src[src_idx]);
			dst_idx++;
		}
		else
		{
			dst[dst_idx] = src[src_idx];
			dst_idx++;
		}
	}
	dst[dst_len] = 0;
	return dst;
}

char *snake_to_camel(const char *src)
{
	int src_len = 0;
	int dst_len = 0;
	for (src_len = 0; src[src_len]; src_len++)
	{
		if (src[src_len] != '_' && src[src_len] != '-') dst_len++; /* handle '-' for signal name */
	}
	char *dst = (char *)malloc((dst_len + 1) * sizeof(char));
	assert(dst != NULL);
	int flag = 0;
	for (int src_idx = 0, dst_idx = 0; src_idx < src_len; src_idx++)
	{
		if (src[src_idx] == '_' || src[src_idx] == '-')
		{
			flag = 1;
		}
		else
		{
			dst[dst_idx] = flag ? toupper(src[src_idx]) : src[src_idx];
			dst_idx++;
			flag = 0;
		}
	}
	dst[dst_len] = 0;
	return dst;
}

char *snake_to_title(const char *src)
{
	int src_len = 0;
	int dst_len = 0;
	for (src_len = 0; src[src_len]; src_len++)
	{
		if (src[src_len] != '_' && src[src_len] != '-') dst_len++; /* handle '-' for signal name */
	}
	char *dst = (char *)malloc((dst_len + 1) * sizeof(char));
	assert(dst != NULL);
	int flag = 1;
	for (int src_idx = 0, dst_idx = 0; src_idx < src_len; src_idx++)
	{
		if (src[src_idx] == '_' || src[src_idx] == '-')
		{
			flag = 1;
		}
		else
		{
			dst[dst_idx] = flag ? toupper(src[src_idx]) : src[src_idx];
			dst_idx++;
			flag = 0;
		}
	}
	dst[dst_len] = 0;
	return dst;
}
