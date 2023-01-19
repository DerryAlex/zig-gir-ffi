#include "gir-zig.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int config_enable_deprecated = 0;
int config_enable_uppercase_constant = 1;
GIRepository *repository = NULL;

int main(int argc, char *argv[])
{
	repository = g_irepository_get_default();
	GError *error = NULL;
	g_irepository_require(repository, "Gtk", NULL, 0, &error);
	if (error)
	{
		g_error("ERROR: %s\n", error->message);
		return 1;
	}
	char **namespaces = g_irepository_get_loaded_namespaces(repository);
	for (int namespace_idx = 0; namespaces[namespace_idx]; namespace_idx++)
	{
		int len = strlen(namespaces[namespace_idx]);
		char *filename = (char *)malloc((7 + len + 4 + 1) * sizeof(char));
		if (filename == NULL)
		{
			fprintf(stderr, "alloc filename failed\n");
			return 1;
		}
		memcpy(filename, "output/", 7);
		memcpy(filename + 7, namespaces[namespace_idx], len);
		memcpy(filename + 7 + len, ".zig", 4);
		filename[7 + len + 4] = 0;
		if (freopen(filename, "w", stdout) == NULL)
		{
			fprintf(stderr, "open %s failed\n", filename);
			return 1;
		}
		free(filename);
		printf("const %s = @This();\n\n", namespaces[namespace_idx]);
		char **dependencies = g_irepository_get_dependencies(repository, namespaces[namespace_idx]);
		for (int i = 0; dependencies[i]; i++)
		{
			char *dependency = strdup(dependencies[i]);
			int sep = 0;
			for (sep = 0; dependency[sep] && dependency[sep] != '-'; sep++);
			dependency[sep] = 0;
			printf("pub const %s = @import(\"%s.zig\");\n", dependency, dependency);
			if (strcmp(dependency, "Gtk") == 0) printf("pub const template = @import(\"template.zig\");\n");
			free(dependency);
		}
		printf("pub const core = @import(\"core.zig\");\n");
		if (strcmp(namespaces[namespace_idx], "Gtk") == 0) printf("pub const template = @import(\"template.zig\");\n");
		printf("const std = @import(\"std\");\n");
		printf("const meta = std.meta;\n");
		printf("const assert = std.debug.assert;\n");
		printf("const Allocator = std.mem.Allocator;\n");
		int n = g_irepository_get_n_infos(repository, namespaces[namespace_idx]);
		for (int i = 0; i < n; i++)
		{
			GIBaseInfo *info = g_irepository_get_info(repository, namespaces[namespace_idx], i);
			int is_deprecated = g_base_info_is_deprecated(info);
			if (is_deprecated && !config_enable_deprecated) continue;
			GIInfoType type = g_base_info_get_type(info);
			const char *name = g_base_info_get_name(info);
			switch (type)
			{
				case GI_INFO_TYPE_FUNCTION:
					emit_function(info, name, "", is_deprecated, 0, NULL);
					break;
				case GI_INFO_TYPE_CALLBACK:
					emit_callback(info, name, is_deprecated, 0);
					break;
				case GI_INFO_TYPE_STRUCT:
					emit_struct(info, name, is_deprecated);
					break;
				case GI_INFO_TYPE_BOXED:
					if (GI_IS_STRUCT_INFO(info)) emit_struct(info, name, is_deprecated);
					else emit_union(info, name, is_deprecated);
					break;
				case GI_INFO_TYPE_ENUM:
					emit_enum(info, name, 0, is_deprecated);
					break;
				case GI_INFO_TYPE_FLAGS:
					emit_enum(info, name, 1, is_deprecated);
					break;
				case GI_INFO_TYPE_OBJECT:
					emit_object(info, name, is_deprecated);
					break;
				case GI_INFO_TYPE_INTERFACE:
					emit_interface(info, name, is_deprecated);
					break;
				case GI_INFO_TYPE_CONSTANT:
					emit_constant(info, name, is_deprecated);
					break;
				case GI_INFO_TYPE_UNION:
					emit_union(info, name, is_deprecated);
					break;
				case GI_INFO_TYPE_INVALID:
				case GI_INFO_TYPE_INVALID_0:
				case GI_INFO_TYPE_UNRESOLVED:
				case GI_INFO_TYPE_VALUE:
				case GI_INFO_TYPE_SIGNAL:
				case GI_INFO_TYPE_VFUNC:
				case GI_INFO_TYPE_PROPERTY:
				case GI_INFO_TYPE_FIELD:
				case GI_INFO_TYPE_ARG:
				case GI_INFO_TYPE_TYPE:
				default:
					fprintf(stderr, "Unsupported type %s\n", g_info_type_to_string(type));
					break;
			}
			g_base_info_unref(info);
		}
		fflush(stdout);
		fclose(stdout);
	}
	return 0;
}
