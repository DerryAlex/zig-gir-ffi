#include "emit.h"
#include "fmt.h"
#include "gir-zig.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

static inline int is_basic_type(GITypeTag type)
{
	return type < GI_TYPE_TAG_UTF8 || type == GI_TYPE_TAG_UNICHAR;
}

static inline int maybe_allocate_on_stack(GITypeInfo *type_info)
{
	if (g_type_info_is_pointer(type_info)) return 0;
	GITypeTag type = g_type_info_get_tag(type_info);
	if (type < GI_TYPE_TAG_UTF8) return 1;
	if (type == GI_TYPE_TAG_ARRAY)
	{
		GIArrayType array_type = g_type_info_get_array_type(type_info);
		if (array_type != GI_ARRAY_TYPE_C) return 1;
		else
		{
			if (g_type_info_get_array_fixed_size(type_info) != -1) return 1;
		}
	}
	if (type == GI_TYPE_TAG_INTERFACE)
	{
		GIBaseInfo *interface = g_type_info_get_interface(type_info);
		GIInfoType info_type = g_base_info_get_type(interface);
		if (info_type == GI_INFO_TYPE_STRUCT || info_type == GI_INFO_TYPE_UNION || info_type == GI_INFO_TYPE_BOXED || info_type == GI_INFO_TYPE_ENUM || info_type == GI_INFO_TYPE_FLAGS) return 1;
	}
	if (type > GI_TYPE_TAG_INTERFACE) return 1;
	return 0;
}

static inline int is_fixed_size_array(GITypeInfo *type_info)
{
	GITypeTag type = g_type_info_get_tag(type_info);
	if (type == GI_TYPE_TAG_ARRAY)
	{
		GIArrayType array_type = g_type_info_get_array_type(type_info);
		if (array_type == GI_ARRAY_TYPE_C)
		{
			if (g_type_info_get_array_fixed_size(type_info) != -1) return 1;
		}
	}
	return 0;
}

static inline int is_struct_union(GITypeInfo *type_info)
{
	if (g_type_info_is_pointer(type_info)) return 0;
	GITypeTag type = g_type_info_get_tag(type_info);
	if (type == GI_TYPE_TAG_INTERFACE)
	{
		GIBaseInfo *interface = g_type_info_get_interface(type_info);
		GIInfoType info_type = g_base_info_get_type(interface);
		if (info_type == GI_INFO_TYPE_STRUCT || info_type == GI_INFO_TYPE_UNION || info_type == GI_INFO_TYPE_BOXED) return 1;
	}
	return 0;
}

static inline int is_gtk_widget(GITypeInfo *type_info)
{
	GITypeTag type = g_type_info_get_tag(type_info);
	if (type == GI_TYPE_TAG_INTERFACE)
	{
		GIBaseInfo *interface = g_type_info_get_interface(type_info);
		const char *namespace = g_base_info_get_namespace(interface);
		const char *name = g_base_info_get_name(interface);
		if (strcmp(namespace, "Gtk") == 0 && strcmp(name, "Widget") == 0) return 1;
	}
	return 0;
}

static inline int is_instance(GITypeInfo *type_info)
{
	GITypeTag type = g_type_info_get_tag(type_info);
	if (type == GI_TYPE_TAG_INTERFACE)
	{
		GIBaseInfo *interface = g_type_info_get_interface(type_info);
		GIInfoType info_type = g_base_info_get_type(interface);
		g_base_info_unref(interface);
		if (info_type == GI_INFO_TYPE_OBJECT || info_type == GI_INFO_TYPE_INTERFACE) return 1;
	}
	return 0;
}

static inline int is_callback(GITypeInfo *type_info)
{
	GITypeTag type = g_type_info_get_tag(type_info);
	if (type == GI_TYPE_TAG_INTERFACE)
	{
		GIBaseInfo *interface = g_type_info_get_interface(type_info);
		GIInfoType info_type = g_base_info_get_type(interface);
		if (info_type == GI_INFO_TYPE_CALLBACK) return 1;
		g_base_info_unref(interface);
	}
	return 0;
}

static inline int patch_return_nullable(GITypeInfo *type_info)
{
	GITypeTag type = g_type_info_get_tag(type_info);
	if (type == GI_TYPE_TAG_GLIST || type == GI_TYPE_TAG_GSLIST || type == GI_TYPE_TAG_GHASH) return 1;
	return 0;
}

void emit_c_function(GIBaseInfo *info, const char *name, const char *container_name, int is_deprecated, int is_container_struct)
{
	printf("extern fn ");
	emit_function_symbol(info);
	printf("(");
	int is_method = g_callable_info_is_method(info);
	if (is_method)
	{
		if (is_container_struct) printf("*");
		printf("%s", container_name);
	}
	int n = g_callable_info_get_n_args(info);
	for (int i = 0; i < n; i++)
	{
		if (is_method || i > 0) printf(", ");
		GIArgInfo *arg_info = g_callable_info_get_arg(info, i);
		GIDirection direction = g_arg_info_get_direction(arg_info);
		GITypeInfo *type_info = g_arg_info_get_type(arg_info);
		emit_type(type_info, g_arg_info_is_optional(arg_info) || g_arg_info_may_be_null(arg_info), 0, direction == GI_DIRECTION_OUT || direction == GI_DIRECTION_INOUT, 1);
		g_base_info_unref(type_info);
		g_base_info_unref(arg_info);
	}
	if (g_callable_info_can_throw_gerror(info))
	{
		if (is_method || n > 0) printf(", ");
		printf("*?*core.Error");
	}
	printf(") ");
	int return_nullable = g_callable_info_may_return_null(info);
	GITypeInfo *return_type_info = g_callable_info_get_return_type(info);
	if (is_gtk_widget(return_type_info) && strncmp(name, "new", 3) == 0) printf("%s", container_name);
	else emit_type(return_type_info, return_nullable || patch_return_nullable(return_type_info), 0, 0, 1);
	g_base_info_unref(return_type_info);
	printf(";\n");
}

// toplevel
void emit_function(GIBaseInfo *info, const char *name, const char *container_name, int is_deprecated, int is_container_struct, GIStructInfo *virt_class)
{
	if (is_deprecated && !config_enable_deprecated) return;
	emit_function_wrapper(info, name, container_name, is_deprecated, is_container_struct, virt_class);
}

// toplevel
void emit_callback(GIBaseInfo *info, const char *name, int is_deprecated, int type_only)
{
	if (is_deprecated && !config_enable_deprecated) return;
	if (!type_only)
	{
		if (is_deprecated) printf("/// (deprecated)\n");
		printf("/// %s\n", name);
		emit_function_comment(info);
	}
	if (!type_only) printf("pub const %s = *const fn(", name);
	else printf("*const fn(");
	int n = g_callable_info_get_n_args(info);
	for (int i = 0; i < n; i++)
	{
		if (i > 0) printf(", ");
		GIArgInfo *arg_info = g_callable_info_get_arg(info, i);
		GIDirection direction = g_arg_info_get_direction(arg_info);
		GITypeInfo *type_info = g_arg_info_get_type(arg_info);
		emit_type(type_info, g_arg_info_is_optional(arg_info) || g_arg_info_may_be_null(arg_info), 0, direction == GI_DIRECTION_OUT || direction == GI_DIRECTION_INOUT, 1);
		g_base_info_unref(type_info);
		g_base_info_unref(arg_info);
	}
	printf(") callconv(.C) ");
	int return_nullable = g_callable_info_may_return_null(info);
	GITypeInfo *return_type_info = g_callable_info_get_return_type(info);
	emit_type(return_type_info, return_nullable, 0, 0, 1);
	g_base_info_unref(return_type_info);
	if (!type_only) printf(";\n");
}

// toplevel
void emit_struct(GIBaseInfo *info, const char *name, int is_deprecated)
{
	if (is_deprecated && !config_enable_deprecated) return;
	// unsigned long size = g_struct_info_get_size(info);
	// unsigned long align = g_struct_info_get_alignment(info);
	if (is_deprecated) printf("/// (deprecated)\n");
	int n = g_struct_info_get_n_fields(info);
	if (n == 0) printf("pub const %s = opaque {\n", name);
	else
	{
		printf("pub const %s = extern struct {\n", name);
		for (int i = 0; i < n; i++)
		{
			GIFieldInfo *field_info = g_struct_info_get_field(info, i);
			emit_field(field_info, i == 0);
		}
	}
	n = g_struct_info_get_n_methods(info);
	for (int i = 0; i < n; i++)
	{
		printf("\n");
		GIFunctionInfo *method = g_struct_info_get_method(info, i);
		const char *method_name = g_base_info_get_name(method);
		emit_function(method, method_name, name, g_base_info_is_deprecated(method), 1, NULL);
		g_base_info_unref(method);
	}
	emit_registered_type(info, 0);
	printf("};\n");
}

// toplevel
void emit_enum(GIBaseInfo *info, const char *name, int is_flags, int is_deprecated)
{
	if (is_deprecated && !config_enable_deprecated) return;
	if (is_deprecated) printf("/// (deprecated)\n");
	GITypeTag storage = g_enum_info_get_storage_type(info);
	const char *storage_type = "";
	switch (storage) {
		case GI_TYPE_TAG_INT8:
			storage_type = "(i8)";
			break;
		case GI_TYPE_TAG_UINT8:
			storage_type = "(u8)";
			break;
		case GI_TYPE_TAG_INT16:
			storage_type = "(i16)";
			break;
		case GI_TYPE_TAG_UINT16:
			storage_type = "(u16)";
			break;
		case GI_TYPE_TAG_INT32:
			storage_type = "(i32)";
			break;
		case GI_TYPE_TAG_UINT32:
			storage_type = "(u32)";
			break;
		case GI_TYPE_TAG_INT64:
			storage_type = "(i64)";
			break;
		case GI_TYPE_TAG_UINT64:
			storage_type = "(u64)";
			break;
		default:
			fprintf(stderr, "Unsupported enum storage type %s\n", g_type_tag_to_string(storage));
			break;
	}
	printf("pub const %s = enum%s {\n", name, storage_type);
	long last_value = -1;
	int n = g_enum_info_get_n_values(info);
	for (int i = 0; i < n; i++)
	{
		GIValueInfo *value_info = g_enum_info_get_value(info, i);
		long value = g_value_info_get_value(value_info);
		if (i > 0 && value == last_value)
		{
			g_base_info_unref(value_info);
			continue;
		}
		last_value = value;
		const char *value_name = g_base_info_get_name(value_info);
		char *ziggy_value_name = snake_to_title(value_name);
		if (!isupper(ziggy_value_name[0]))
		{
			int len = strlen(ziggy_value_name);
			char *tmp = (char *)malloc((2 + len + 1 + 1) * sizeof(char));
			assert(tmp != NULL);
			memcpy(tmp, "@\"", 2);
			memcpy(tmp + 2, ziggy_value_name, len);
			memcpy(tmp + 2 + len, "\"", 1);
			tmp[2 + len + 1] = 0;
			free(ziggy_value_name);
			ziggy_value_name = tmp;
		}
		if (!is_flags) printf("    %s = %ld,\n", ziggy_value_name, value);
		else printf("    %s = %s0x%lx,\n", ziggy_value_name, value >= 0 ? "" : "~", value >= 0 ? value : ~value);
		free(ziggy_value_name);
		g_base_info_unref(value_info);
	}
	if (is_flags) printf("    _,\n");
	n = g_enum_info_get_n_methods(info);
	for (int i = 0; i < n; i++)
	{
		GIFunctionInfo *method = g_enum_info_get_method(info, i);
		const char *method_name = g_base_info_get_name(method);
		emit_function(method, method_name, name, g_base_info_is_deprecated(method) || is_deprecated, 0, NULL);
		g_base_info_unref(method);
	}
	emit_registered_type(info, 0);
	printf("};\n");
}

static void emit_interface_mark(GIBaseInfo *info)
{
	int n = g_object_info_get_n_interfaces(info);
	for (int i = 0; i < n; i++)
	{
		GIInterfaceInfo *interface_info = g_object_info_get_interface(info, i);
		const char *namespace = g_base_info_get_namespace(interface_info);
		const char *interface_name = g_base_info_get_name(interface_info);
		printf("    trait%s%s: void = {},\n", namespace, interface_name);
		g_base_info_unref(interface_info);
	}
}

static void emit_ancestor_mark(GIBaseInfo *info)
{
	if (!(GI_IS_OBJECT_INFO(info))) return;
	GIObjectInfo *parent = g_object_info_get_parent(info);
	if (parent != NULL)
	{
		emit_ancestor_mark(parent);
		g_base_info_unref(parent);
	}
	const char *namespace = g_base_info_get_namespace(info);
	const char *name = g_base_info_get_name(info);
	printf("    trait%s%s: void = {},\n", namespace, name);
}

// toplevel
void emit_object(GIBaseInfo *info, const char *name, int is_deprecated)
{
	if (is_deprecated && !config_enable_deprecated) return;
	int n = g_object_info_get_n_fields(info);
	if (n == 0) printf("pub const %sImpl = opaque {};\n", name);
	else
	{
		printf("pub const %sImpl = extern struct {\n", name);
		for (int i = 0; i < n; i++)
		{
			GIFieldInfo *field_info = g_object_info_get_field(info, i);
			emit_field(field_info, i == 0);
		}
		printf("};\n");
	}
	emit_nullable(name);
	if (is_deprecated) printf("/// (deprecated)\n");
	printf("pub const %s = packed struct {\n", name);
	printf("    instance: *%sImpl,\n", name);
	emit_interface_mark(info);
	emit_ancestor_mark(info);
	GIObjectInfo *parent = g_object_info_get_parent(info);
	if (parent != NULL)
	{
		const char *parent_name = g_base_info_get_name(parent);
		const char *parent_namespace = g_base_info_get_namespace(parent);
		printf("\n");
		printf("    pub const Parent = %s.%s;\n", parent_namespace, parent_name);
		g_base_info_unref(parent);
	}
	n = g_object_info_get_n_constants(info);
	for (int i = 0; i < n; i++)
	{
		printf("\n");
		GIConstantInfo *constant_info = g_object_info_get_constant(info, i);
		const char *constant_name = g_base_info_get_name(constant_info);
		int is_deprecated_constant = g_base_info_is_deprecated(constant_info);
		emit_constant(constant_info, constant_name, is_deprecated_constant);
		g_base_info_unref(constant_info);
	}
	n = g_object_info_get_n_methods(info);
	for (int i = 0; i < n; i++)
	{
		printf("\n");
		GIFunctionInfo *method = g_object_info_get_method(info, i);
		const char *method_name = g_base_info_get_name(method);
		emit_function(method, method_name, name, g_base_info_is_deprecated(method), 0, NULL);
		g_base_info_unref(method);
	}
	n = g_object_info_get_n_signals(info);
	for (int i = 0; i < n; i++)
	{
		printf("\n");
		GISignalInfo *signal_info = g_object_info_get_signal(info, i);
		emit_signal(signal_info, name);
		g_base_info_unref(signal_info);
	}
	n = g_object_info_get_n_properties(info);
	for (int i = 0; i < n; i++)
	{
		printf("\n");
		GIPropertyInfo *property_info = g_object_info_get_property(info, i);
		emit_property(property_info, name);
		g_base_info_unref(property_info);
	}
	n = g_object_info_get_n_vfuncs(info);
	for (int i = 0; i < n; i++)
	{
		printf("\n");
		GIVFuncInfo *vfunc_info = g_object_info_get_vfunc(info, i);
		GIStructInfo *class_info = g_object_info_get_class_struct(info);
		emit_vfunc(vfunc_info, name, class_info);
		g_base_info_unref(vfunc_info);
		g_base_info_unref(class_info);
	}
	/* emit helper function */
	printf("\n");
	printf("    pub fn CallMethod(comptime method: []const u8) ?type {\n");
	n = g_object_info_get_n_methods(info);
	for (int i = 0; i < n; i++)
	{
		GIFunctionInfo *method = g_object_info_get_method(info, i);
		if (!g_callable_info_is_method(method))
		{
			g_base_info_unref(method);
			continue;
		}
		const char *method_name = g_base_info_get_name(method);
		char *ziggy_name = snake_to_camel(method_name);
		if (strcmp(ziggy_name, "break") == 0 || strcmp(ziggy_name, "continue") == 0 || strcmp(ziggy_name, "error") == 0 || strcmp(ziggy_name, "export") == 0 || strcmp(ziggy_name, "union") == 0) printf("        if (std.mem.eql(method, \"%s\")) return core.fnReturnType(@This().@\"%s\");", ziggy_name, ziggy_name);
		else if (strcmp(ziggy_name, "self") == 0) printf("        if (std.mem.eql(u8, method, \"self\")) return core.FnReturnType(@TypeOf(@This().getSelf));\n");
		else printf("        if (std.mem.eql(u8, method, \"%s\")) return core.FnReturnType(@TypeOf(@This().%s));\n", ziggy_name, ziggy_name);
		free(ziggy_name);
		g_base_info_unref(method);
	}
	n = g_object_info_get_n_signals(info);
	for (int i = 0; i < n; i++)
	{
		GISignalInfo *signal = g_object_info_get_signal(info, i);
		const char *signal_name = g_base_info_get_name(signal);
		char *ziggy_signal_name = snake_to_title(signal_name);
		printf("        if (std.mem.eql(u8, method, \"signal%s\")) return core.FnReturnType(@TypeOf(@This().signal%s));\n", ziggy_signal_name, ziggy_signal_name);
		free(ziggy_signal_name);
		g_base_info_unref(signal);
	}
	n = g_object_info_get_n_properties(info);
	for (int i = 0; i < n; i++)
	{
		GIPropertyInfo *property = g_object_info_get_property(info, i);
		const char *property_name = g_base_info_get_name(property);
		char *ziggy_property_name = snake_to_title(property_name);
		printf("        if (std.mem.eql(u8, method, \"property%s\")) return core.FnReturnType(@TypeOf(@This().property%s));\n", ziggy_property_name, ziggy_property_name);
		free(ziggy_property_name);
		g_base_info_unref(property);
	}
	n = g_object_info_get_n_vfuncs(info);
	for (int i = 0; i < n; i++)
	{
		GIVFuncInfo *vfunc = g_object_info_get_vfunc(info, i);
		const char *vfunc_name = g_base_info_get_name(vfunc);
		char *ziggy_vfunc_name = snake_to_camel(vfunc_name);
		printf("        if (std.mem.eql(u8, method, \"%sV\")) return core.FnReturnType(@TypeOf(@This().%sV));\n", ziggy_vfunc_name, ziggy_vfunc_name);
		free(ziggy_vfunc_name);
		g_base_info_unref(vfunc);
	}
	n = g_object_info_get_n_interfaces(info);
	for (int i = 0; i < n; i++)
	{
		GIInterfaceInfo *interface = g_object_info_get_interface(info, i);
		const char *interface_name = g_base_info_get_name(interface);
		const char *interface_namespace = g_base_info_get_namespace(interface);
		printf("        if (%s.%s.CallMethod(method)) |some| return some;\n", interface_namespace, interface_name);
		g_base_info_unref(interface);
	}
	parent = g_object_info_get_parent(info);
	if (parent != NULL)
	{
		printf("        if (Parent.CallMethod(method)) |some| return some;\n");
		g_base_info_unref(parent);
	}
	printf("        return null;\n");
	printf("    }\n");

	printf("\n");
	printf("    pub fn callMethod(self: %s, comptime method: []const u8, args: anytype) gen_return_type: {\n", name);
	printf("        if (CallMethod(method)) |some| {\n");
	printf("            break :gen_return_type some;\n");
	printf("        }\n");
	printf("        else {\n");
	printf("            @compileError(std.fmt.comptimePrint(\"No such method {s}\", .{method}));\n");
	printf("        }\n");
	printf("    } {\n");
	printf("        if (false) {\n");
	printf("            return {};\n");
	printf("        }\n");
	n = g_object_info_get_n_methods(info);
	for (int i = 0; i < n; i++)
	{
		GIFunctionInfo *method = g_object_info_get_method(info, i);
		if (!g_callable_info_is_method(method))
		{
			g_base_info_unref(method);
			continue;
		}
		const char *method_name = g_base_info_get_name(method);
		char *ziggy_name = snake_to_camel(method_name);
		printf("        else if (comptime std.mem.eql(u8, method, \"%s\")) {\n", ziggy_name);
		if (strcmp(ziggy_name, "break") == 0 || strcmp(ziggy_name, "continue") == 0 || strcmp(ziggy_name, "error") == 0 || strcmp(ziggy_name, "export") == 0 || strcmp(ziggy_name, "union") == 0) printf("             return @call(.auto, @This().@\"%s\", .{self} ++ args);\n", ziggy_name);
		else if (strcmp(ziggy_name, "self") == 0) printf("            return @call(.auto, @This().getSelf, .{self} ++ args);\n");
		else printf("            return @call(.auto, @This().%s, .{self} ++ args);\n", ziggy_name);
		printf("        }\n");
		free(ziggy_name);
		g_base_info_unref(method);
	}
	n = g_object_info_get_n_signals(info);
	for (int i = 0; i < n; i++)
	{
		GISignalInfo *signal = g_object_info_get_signal(info, i);
		const char *signal_name = g_base_info_get_name(signal);
		char *ziggy_signal_name = snake_to_title(signal_name);
		printf("        else if (comptime std.mem.eql(u8, method, \"signal%s\")) {\n", ziggy_signal_name);
		printf("            return @call(.auto, @This().signal%s, .{self} ++ args);\n", ziggy_signal_name);
		printf("        }\n");
		free(ziggy_signal_name);
		g_base_info_unref(signal);
	}
	n = g_object_info_get_n_properties(info);
	for (int i = 0; i < n; i++)
	{
		GIPropertyInfo *property = g_object_info_get_property(info, i);
		const char *property_name = g_base_info_get_name(property);
		char *ziggy_property_name = snake_to_title(property_name);
		printf("        else if (comptime std.mem.eql(u8, method, \"property%s\")) {\n", ziggy_property_name);
		printf("            return @call(.auto, @This().property%s, .{self} ++ args);\n", ziggy_property_name);
		printf("        }\n");
		free(ziggy_property_name);
		g_base_info_unref(property);
	}
	n = g_object_info_get_n_vfuncs(info);
	for (int i = 0; i < n; i++)
	{
		GIVFuncInfo *vfunc = g_object_info_get_vfunc(info, i);
		const char *vfunc_name = g_base_info_get_name(vfunc);
		char *ziggy_vfunc_name = snake_to_camel(vfunc_name);
		printf("        else if (comptime std.mem.eql(u8, method, \"%sV\")) {\n", ziggy_vfunc_name);
		printf("            return @call(.auto, @This().%sV, .{self} ++ args);\n", ziggy_vfunc_name);
		printf("        }\n");
		free(ziggy_vfunc_name);
		g_base_info_unref(vfunc);
	}
	n = g_object_info_get_n_interfaces(info);
	for (int i = 0; i < n; i++)
	{
		GIInterfaceInfo *interface = g_object_info_get_interface(info, i);
		const char *interface_name = g_base_info_get_name(interface);
		const char *interface_namespace = g_base_info_get_namespace(interface);
		printf("        else if (%s.%s.CallMethod(method)) |_| {\n", interface_namespace, interface_name);
		printf("            return self.into(%s.%s).callMethod(method, args);\n", interface_namespace, interface_name);
		printf("        }\n");
		g_base_info_unref(interface);
	}
	parent = g_object_info_get_parent(info);
	if (parent != NULL)
	{
		printf("        else if (Parent.CallMethod(method)) |_| {\n");
		printf("            return self.into(Parent).callMethod(method, args);\n");
		printf("        }\n");
		g_base_info_unref(parent);
	}
	printf("        else {\n");
	printf("            @compileError(\"No such method\");\n");
	printf("        }\n");
	printf("    }\n");

	printf("\n");
	emit_registered_type(info, 1);

	printf("\n");
	printf("    pub fn isAImpl(comptime T: type) bool {\n");
	printf("        return meta.trait.hasField(\"trait%s%s\")(T);\n", g_base_info_get_namespace(info), name);
	printf("    }\n");

	printf("\n");
	emit_into(name);

	printf("};\n");
}

// top level
void emit_interface(GIBaseInfo *info, const char *name, int is_deprecated)
{
	if (is_deprecated && !config_enable_deprecated) return;
	GIStructInfo *iface_struct_info = g_interface_info_get_iface_struct(info);
	if (iface_struct_info) {
		printf("pub const %sImpl = %s;\n", name, g_base_info_get_name(iface_struct_info));
		g_base_info_unref(iface_struct_info);
	}
	else {
		printf("pub const %sImpl = opaque {};\n", name);
	}
	emit_nullable(name);
	if (is_deprecated) printf("/// (deprecated)\n");
	printf("pub const %s = packed struct{\n", name);
	printf("    instance: *%sImpl,\n", name);
	int n = g_interface_info_get_n_prerequisites(info);
	for (int i = 0; i < n; i++)
	{
		GIBaseInfo *req = g_interface_info_get_prerequisite(info, i);
		const char *namespace = g_base_info_get_namespace(req);
		const char *name = g_base_info_get_name(req);
		printf("    trait%s%s: void = {},\n", namespace, name);
		g_base_info_unref(req);
	}
	printf("    trait%s%s: void = {},\n", g_base_info_get_namespace(info), name);
	n = g_interface_info_get_n_constants(info);
	for (int i = 0; i < n; i++)
	{
		printf("\n");
		GIConstantInfo *constant_info = g_interface_info_get_constant(info, i);
		const char *constant_name = g_base_info_get_name(constant_info);
		int is_deprecated_constant = g_base_info_is_deprecated(constant_info);
		emit_constant(constant_info, constant_name, is_deprecated_constant);
		g_base_info_unref(constant_info);
	}
	n = g_interface_info_get_n_methods(info);
	for (int i = 0; i < n; i++)
	{
		printf("\n");
		GIFunctionInfo *method = g_interface_info_get_method(info, i);
		const char *method_name = g_base_info_get_name(method);
		emit_function(method, method_name, name, g_base_info_is_deprecated(method), 0, NULL);
		g_base_info_unref(method);
	}
	n = g_interface_info_get_n_signals(info);
	for (int i = 0; i < n; i++)
	{
		printf("\n");
		GISignalInfo *signal_info = g_interface_info_get_signal(info, i);
		emit_signal(signal_info, name);
		g_base_info_unref(signal_info);
	}
	n = g_interface_info_get_n_properties(info);
	for (int i = 0; i < n; i++)
	{
		printf("\n");
		GIPropertyInfo *property_info = g_interface_info_get_property(info, i);
		emit_property(property_info, name);
		g_base_info_unref(property_info);
	}
	n = g_interface_info_get_n_vfuncs(info);
	for (int i = 0; i < n; i++)
	{
		printf("\n");
		GIVFuncInfo *vfunc_info = g_interface_info_get_vfunc(info, i);
		GIStructInfo *class_info = g_interface_info_get_iface_struct(info);
		emit_vfunc(vfunc_info, name, class_info);
		g_base_info_unref(vfunc_info);
		g_base_info_unref(class_info);
	}
	
	printf("\n");
	printf("    pub fn CallMethod(comptime method: []const u8) ?type {\n");
	printf("        core.maybeUnused(method);\n");
	n = g_interface_info_get_n_methods(info);
	for (int i = 0; i < n; i++)
	{
		GIFunctionInfo *method = g_interface_info_get_method(info, i);
		if (!g_callable_info_is_method(method))
		{
			g_base_info_unref(method);
			continue;
		}
		const char *method_name = g_base_info_get_name(method);
		char *ziggy_name = snake_to_camel(method_name);
		if (strcmp(ziggy_name, "break") == 0 || strcmp(ziggy_name, "continue") == 0 || strcmp(ziggy_name, "error") == 0 || strcmp(ziggy_name, "export") == 0 || strcmp(ziggy_name, "union") == 0) printf("        if (std.mem.eql(method, \"%s\")) return core.fnReturnType(@This().@\"%s\");", ziggy_name, ziggy_name);
		else if (strcmp(ziggy_name, "self") == 0) printf("        if (std.mem.eql(u8, method, \"self\")) return core.FnReturnType(@TypeOf(@This().getSelf));\n");
		else printf("        if (std.mem.eql(u8, method, \"%s\")) return core.FnReturnType(@TypeOf(@This().%s));\n", ziggy_name, ziggy_name);
		free(ziggy_name);
		g_base_info_unref(method);
	}
	n = g_interface_info_get_n_signals(info);
	for (int i = 0; i < n; i++)
	{
		GISignalInfo *signal = g_interface_info_get_signal(info, i);
		const char *signal_name = g_base_info_get_name(signal);
		char *ziggy_signal_name = snake_to_title(signal_name);
		printf("        if (std.mem.eql(u8, method, \"signal%s\")) return core.FnReturnType(@TypeOf(@This().signal%s));\n", ziggy_signal_name, ziggy_signal_name);
		free(ziggy_signal_name);
		g_base_info_unref(signal);
	}
	n = g_interface_info_get_n_properties(info);
	for (int i = 0; i < n; i++)
	{
		GIPropertyInfo *property = g_interface_info_get_property(info, i);
		const char *property_name = g_base_info_get_name(property);
		char *ziggy_property_name = snake_to_title(property_name);
		printf("        if (std.mem.eql(u8, method, \"property%s\")) return core.FnReturnType(@TypeOf(@This().property%s));\n", ziggy_property_name, ziggy_property_name);
		free(ziggy_property_name);
		g_base_info_unref(property);
	}
	n = g_interface_info_get_n_vfuncs(info);
	for (int i = 0; i < n; i++)
	{
		GIVFuncInfo *vfunc = g_interface_info_get_vfunc(info, i);
		const char *vfunc_name = g_base_info_get_name(vfunc);
		char *ziggy_vfunc_name = snake_to_camel(vfunc_name);
		printf("        if (std.mem.eql(u8, method, \"%sV\")) return core.FnReturnType(@TypeOf(@This().%sV));\n", ziggy_vfunc_name, ziggy_vfunc_name);
		free(ziggy_vfunc_name);
		g_base_info_unref(vfunc);
	}
	printf("        return null;\n");
	printf("    }\n");

	printf("\n");
	printf("    pub fn callMethod(self: %s, comptime method: []const u8, args: anytype) gen_return_type: {\n", name);
	printf("        if (CallMethod(method)) |some| {\n");
	printf("            break :gen_return_type some;\n");
	printf("        }\n");
	printf("        else {\n");
	printf("            @compileError(std.fmt.comptimePrint(\"No such method {s}\", .{method}));\n");
	printf("        }\n");
	printf("    } {\n");
	printf("        core.maybeUnused(self);\n");
	printf("        core.maybeUnused(method);\n");
	printf("        core.maybeUnused(args);\n");
	printf("        if (false) {\n");
	printf("            return {};\n");
	printf("        }\n");
	n = g_interface_info_get_n_methods(info);
	for (int i = 0; i < n; i++)
	{
		GIFunctionInfo *method = g_interface_info_get_method(info, i);
		if (!g_callable_info_is_method(method))
		{
			g_base_info_unref(method);
			continue;
		}
		const char *method_name = g_base_info_get_name(method);
		char *ziggy_name = snake_to_camel(method_name);
		printf("        else if (comptime std.mem.eql(u8, method, \"%s\")) {\n", ziggy_name);
		if (strcmp(ziggy_name, "break") == 0 || strcmp(ziggy_name, "continue") == 0 || strcmp(ziggy_name, "error") == 0 || strcmp(ziggy_name, "export") == 0 || strcmp(ziggy_name, "union") == 0) printf("             return @call(.auto, @This().@\"%s\", .{self} ++ args);\n", ziggy_name);
		else if (strcmp(ziggy_name, "self") == 0) printf("            return @call(.auto, @This().getSelf, .{self} ++ args);\n");
		else printf("            return @call(.auto, @This().%s, .{self} ++ args);\n", ziggy_name);
		printf("        }\n");
		free(ziggy_name);
		g_base_info_unref(method);
	}
	n = g_interface_info_get_n_signals(info);
	for (int i = 0; i < n; i++)
	{
		GISignalInfo *signal = g_interface_info_get_signal(info, i);
		const char *signal_name = g_base_info_get_name(signal);
		char *ziggy_signal_name = snake_to_title(signal_name);
		printf("        else if (comptime std.mem.eql(u8, method, \"signal%s\")) {\n", ziggy_signal_name);
		printf("            return @call(.auto, @This().signal%s, .{self} ++ args);\n", ziggy_signal_name);
		printf("        }\n");
		free(ziggy_signal_name);
		g_base_info_unref(signal);
	}
	n = g_interface_info_get_n_properties(info);
	for (int i = 0; i < n; i++)
	{
		GIPropertyInfo *property = g_interface_info_get_property(info, i);
		const char *property_name = g_base_info_get_name(property);
		char *ziggy_property_name = snake_to_title(property_name);
		printf("        else if (comptime std.mem.eql(u8, method, \"property%s\")) {\n", ziggy_property_name);
		printf("            return @call(.auto, @This().property%s, .{self} ++ args);\n", ziggy_property_name);
		printf("        }\n");
		free(ziggy_property_name);
		g_base_info_unref(property);
	}
	n = g_interface_info_get_n_vfuncs(info);
	for (int i = 0; i < n; i++)
	{
		GIVFuncInfo *vfunc = g_interface_info_get_vfunc(info, i);
		const char *vfunc_name = g_base_info_get_name(vfunc);
		char *ziggy_vfunc_name = snake_to_camel(vfunc_name);
		printf("        else if (comptime std.mem.eql(u8, method, \"%sV\")) {\n", ziggy_vfunc_name);
		printf("            return @call(.auto, @This().%sV, .{self} ++ args);\n", ziggy_vfunc_name);
		printf("        }\n");
		free(ziggy_vfunc_name);
		g_base_info_unref(vfunc);
	}
	printf("        else {\n");
	printf("            @compileError(\"No such method\");\n");
	printf("        }\n");
	printf("    }\n");

	printf("\n");
	emit_registered_type(info, 1);

	printf("\n");
	printf("    pub fn isAImpl(comptime T: type) bool {\n");
	printf("        return meta.trait.hasField(\"trait%s%s\")(T);\n", g_base_info_get_namespace(info), name);
	printf("    }\n");

	printf("\n");
	emit_into(name);

	printf("};\n");
}

// toplevel
void emit_constant(GIBaseInfo *info, const char *name, int is_deprecated)
{
	if (is_deprecated && !config_enable_deprecated) return;
	if (is_deprecated) printf("/// (deprecated)\n");
	GITypeInfo *type_info = g_constant_info_get_type(info);
	GITypeTag type = g_type_info_get_tag(type_info);
	GIArgument value;
	g_constant_info_get_value(info, &value);
	char *ziggy_name = config_enable_uppercase_constant ? strdup(name) : SNAKE_to_snake(name);
	switch (type)
	{
		case GI_TYPE_TAG_BOOLEAN:
			printf("pub const %s = %s;\n", ziggy_name, value.v_boolean ? "true" : "false");
			break;
		case GI_TYPE_TAG_INT8:
			printf("pub const %s = %hhd;\n", ziggy_name, value.v_int8);
			break;
		case GI_TYPE_TAG_UINT8:
			printf("pub const %s = %hhu;\n", ziggy_name, value.v_uint8);
			break;
		case GI_TYPE_TAG_INT16:
			printf("pub const %s = %hd;\n", ziggy_name, value.v_int16);
			break;
		case GI_TYPE_TAG_UINT16:
			printf("pub const %s = %hu;\n", ziggy_name, value.v_uint16);
			break;
		case GI_TYPE_TAG_INT32:
			printf("pub const %s = %d;\n", ziggy_name, value.v_int32);
			break;
		case GI_TYPE_TAG_UINT32:
			printf("pub const %s = %u;\n", ziggy_name, value.v_uint32);
			break;
		case GI_TYPE_TAG_INT64:
			printf("pub const %s = %ld;\n", ziggy_name, value.v_int64);
			break;
		case GI_TYPE_TAG_UINT64:
			printf("pub const %s = %lu;\n", ziggy_name, value.v_uint64);
			break;
		case GI_TYPE_TAG_FLOAT:
			printf("pub const %s = %f;\n", ziggy_name, value.v_float);
			break;
		case GI_TYPE_TAG_DOUBLE:
			printf("pub const %s = %lf;\n", ziggy_name, value.v_double);
			break;
		case GI_TYPE_TAG_UTF8:
			printf("pub const %s = \"%s\";\n", ziggy_name, (char *)value.v_pointer);
			break;
		default:
			// printf("pub const %s = core.Unsupported;\n", ziggy_name);
			fprintf(stderr, "Unsupported constant type %s [%s]\n", g_type_tag_to_string(type), ziggy_name);
			break;
	}
	free(ziggy_name);
	g_base_info_unref(type_info);
}

void emit_union(GIBaseInfo *info, const char *name, int is_deprecated)
{
	if (is_deprecated && !config_enable_deprecated) return;
	if (is_deprecated) printf("/// (deprecated)\n");
	int n = g_union_info_get_n_fields(info);
	if (n == 0) printf("pub const %s = opaque {\n", name);
	else
	{
		printf("pub const %s = extern union {\n", name);
		for (int i = 0; i < n; i++)
		{
			GIFieldInfo *field_info = g_union_info_get_field(info, i);
			emit_field(field_info, 0);
		}
	}
	n = g_union_info_get_n_methods(info);
	for (int i = 0; i < n; i++)
	{
		printf("\n");
		GIFunctionInfo *method = g_union_info_get_method(info, i);
		const char *method_name = g_base_info_get_name(method);
		emit_function(method, method_name, name, g_base_info_is_deprecated(method), 1, NULL);
		g_base_info_unref(method);
	}
	emit_registered_type(info, 0);
	printf("};\n");
}

void emit_type(GIBaseInfo *type_info, int optional, int is_slice, int is_out, int prefer_c)
{
	int pointer = g_type_info_is_pointer(type_info) || is_out;
	GITypeTag type = g_type_info_get_tag(type_info);
	switch (type)
	{
		case GI_TYPE_TAG_VOID:
			if (optional) printf("?");
			if (g_type_info_is_pointer(type_info) && is_out) printf("*");
			if (pointer) printf("*anyopaque");
			else printf("void");
			break;
		case GI_TYPE_TAG_BOOLEAN:
			if (optional) printf("?");
			if (pointer) printf("*");
			printf("core.Boolean");
			break;
		case GI_TYPE_TAG_INT8:
			if (optional) printf("?");
			if (pointer) printf("*");
			printf("i8");
			break;
		case GI_TYPE_TAG_UINT8:
			if (optional) printf("?");
			if (pointer) printf("*");
			printf("u8");
			break;
		case GI_TYPE_TAG_INT16:
			if (optional) printf("?");
			if (pointer) printf("*");
			printf("i16");
			break;
		case GI_TYPE_TAG_UINT16:
			if (optional) printf("?");
			if (pointer) printf("*");
			printf("u16");
			break;
		case GI_TYPE_TAG_INT32:
			if (optional) printf("?");
			if (pointer) printf("*");
			printf("i32");
			break;
		case GI_TYPE_TAG_UINT32:
			if (optional) printf("?");
			if (pointer) printf("*");
			printf("u32");
			break;
		case GI_TYPE_TAG_INT64:
			if (optional) printf("?");
			if (pointer) printf("*");
			printf("i64");
			break;
		case GI_TYPE_TAG_UINT64:
			if (optional) printf("?");
			if (pointer) printf("*");
			printf("u64");
			break;
		case GI_TYPE_TAG_FLOAT:
			if (optional) printf("?");
			if (pointer) printf("*");
			printf("f32");
			break;
		case GI_TYPE_TAG_DOUBLE:
			if (optional) printf("?");
			if (pointer) printf("*");
			printf("f64");
			break;
		case GI_TYPE_TAG_GTYPE:
			printf("core.GType");
			break;
		case GI_TYPE_TAG_UTF8:
		case GI_TYPE_TAG_FILENAME:
			if (optional) printf("?");
			if (g_type_info_is_pointer(type_info) && is_out) printf("*");
			printf("[*:0]const u8");
			break;
		case GI_TYPE_TAG_ARRAY:
			GIArrayType array_type = g_type_info_get_array_type(type_info);
			switch (array_type)
			{
				case GI_ARRAY_TYPE_ARRAY:
					if (optional) printf("?");
					if (pointer) printf("*");
					printf("core.Array");
					break;
				case GI_ARRAY_TYPE_PTR_ARRAY:
					if (optional) printf("?");
					if (pointer) printf("*");
					printf("core.PtrArray");
					break;
				case GI_ARRAY_TYPE_BYTE_ARRAY:
					if (optional) printf("?");
					if (pointer) printf("*");
					printf("core.ByteArray");
					break;
				default:
					/* C array */
					if (optional) printf("?");
					if (is_out) printf("*");
					if (is_slice) printf("[]");
					GITypeInfo *array_info = g_type_info_get_param_type(type_info, 0);
					int array_length = g_type_info_get_array_length(type_info);
					if (!is_slice && array_length != -1) printf("[*]");
					int array_fixed_size = g_type_info_get_array_fixed_size(type_info);
					if (!is_slice && array_fixed_size != -1) printf("%s[%d]", prefer_c ? "*" : "", array_fixed_size); /* PREFER_C */
					int zero_terminated = g_type_info_is_zero_terminated(type_info);
					if (!is_slice && zero_terminated)
					{
						if (!g_type_info_is_pointer(array_info) && is_basic_type(g_type_info_get_tag(array_info))) printf("[*:0]");
						else printf("[*:null]");
					}
					if (!is_slice && array_length == -1 && array_fixed_size == -1 && !zero_terminated) printf("[*]");
					GITypeTag elem_type = g_type_info_get_tag(array_info);
					emit_type(array_info, zero_terminated && (!is_basic_type(elem_type) || g_type_info_is_pointer(array_info)), 0, 0, 0);
					g_base_info_unref(array_info);
					break;
			}
			break;
		case GI_TYPE_TAG_INTERFACE:
			GIBaseInfo *interface = g_type_info_get_interface(type_info);
			const char *namespace = g_base_info_get_namespace(interface);
			const char *name = g_base_info_get_name(interface);
			GIInfoType info_type = g_base_info_get_type(interface);
			switch (info_type)
			{
				case GI_INFO_TYPE_OBJECT:
				case GI_INFO_TYPE_INTERFACE:
					printf("%s.%s", namespace, name);
					if (optional) printf("Nullable");
					break;
				case GI_INFO_TYPE_CALLBACK:
					if (optional) printf("?");
					if (isupper(name[0])) printf("%s.%s", namespace, name);
					else emit_callback(interface, name, 0, 1);
					break;
				case GI_INFO_TYPE_STRUCT:
				case GI_INFO_TYPE_UNION:
				case GI_INFO_TYPE_BOXED:
				case GI_INFO_TYPE_ENUM:
				case GI_INFO_TYPE_FLAGS:
					if (optional) printf("?");
					if (pointer) printf("*");
					printf("%s.%s", namespace, name);
					break;
				default:
					printf("core.Unsupported");
					fprintf(stderr, "Unsupported interface type %s\n", g_info_type_to_string(info_type));
					break;
			}
			g_base_info_unref(interface);
			break;
		case GI_TYPE_TAG_GLIST:
			if (optional) printf("?");
			if (pointer) printf("*");
			printf("core.List");
			break;
		case GI_TYPE_TAG_GSLIST:
			if (optional) printf("?");
			if (pointer) printf("*");
			printf("core.SList");
			break;
		case GI_TYPE_TAG_GHASH:
			if (optional) printf("?");
			if (pointer) printf("*");
			printf("core.HashTable");
			break;
		case GI_TYPE_TAG_ERROR:
			if (optional) printf("?");
			if (pointer) printf("*");
			printf("core.Error");
			break;
		case GI_TYPE_TAG_UNICHAR:
			if (optional) printf("?");
			if (pointer) printf("*");
			printf("core.Unichar");
			break;
		default:
			printf("core.Unsupported");
			fprintf(stderr, "Unsupported type %s\n", g_type_tag_to_string(type));
			break;
	}
}

void emit_function_comment(GIBaseInfo *info)
{
	int is_method = g_callable_info_is_method(info);
	if (is_method)
	{
		printf("/// @self: ");
		GITransfer transfer = g_callable_info_get_instance_ownership_transfer(info);
		switch (transfer)
		{
			case GI_TRANSFER_CONTAINER:
				printf("(transfer container) ");
				break;
			case GI_TRANSFER_EVERYTHING:
				printf("(transfer full) ");
				break;
			default:
				/* (transfer none) */
				break;
		}
		printf("Self\n");
	}
	int n = g_callable_info_get_n_args(info);
	for (int i = 0; i < n; i++)
	{
		GIArgInfo *arg_info = g_callable_info_get_arg(info, i);
		const char *arg_name = g_base_info_get_name(arg_info);
		printf("/// @%s: ", arg_name);
		GIDirection direction = g_arg_info_get_direction(arg_info);
		switch (direction)
		{
			case GI_DIRECTION_OUT:
				printf("(out) ");
				break;
			case GI_DIRECTION_INOUT:
				printf("(inout) ");
				break;
			default:
				/* (in) */
				break;
		}
		GITransfer ownership = g_arg_info_get_ownership_transfer(arg_info);
		switch (ownership)
		{
			case GI_TRANSFER_CONTAINER:
				printf("(transfer container) ");
				break;
			case GI_TRANSFER_EVERYTHING:
				printf("(transfer full) ");
				break;
			default:
				/* (transfer none) */
				break;
		}
		int arg_optional = 0;
		if (direction == GI_DIRECTION_OUT)
		{
			int optional = g_arg_info_is_optional(arg_info);
			if (optional) printf("(optional) ");
			// if (optional) arg_optional = 1;
		}
		int nullable = g_arg_info_may_be_null(arg_info);
		if (nullable) printf("(nullable) ");
		if (nullable) arg_optional = 1;
		if (direction == GI_DIRECTION_OUT)
		{
			int caller_allocates = g_arg_info_is_caller_allocates(arg_info);
			if (caller_allocates) printf("(caller-allocates) ");
			else printf("(callee-allocates) ");
		}
		GIScopeType scope = g_arg_info_get_scope(arg_info);
		switch (scope)
		{
			case GI_SCOPE_TYPE_CALL:
				printf("(scope call) ");
				break;
			case GI_SCOPE_TYPE_ASYNC:
				printf("(scope async) ");
				break;
			case GI_SCOPE_TYPE_NOTIFIED:
				printf("(scope notified) ");
				break;
			case GI_SCOPE_TYPE_FOREVER:
				printf("(scope forever) ");
				break;
			default:
				/* not callback */
				break;
		}
		GITypeInfo *type_info = g_arg_info_get_type(arg_info);
		emit_type(type_info, arg_optional, 0, 0, 0);
		printf("\n");
		g_base_info_unref(type_info);
		g_base_info_unref(arg_info);
	}
	if (g_callable_info_can_throw_gerror(info)) printf("/// @error: core.Error\n");
	printf("/// Return: ");
	GITransfer return_ownership = g_callable_info_get_caller_owns(info);
	switch (return_ownership)
	{
		case GI_TRANSFER_CONTAINER:
			printf("(transfer container) ");
			break;
		case GI_TRANSFER_EVERYTHING:
			printf("(transfer full) ");
			break;
		default:
			/* (transfer none) */
			break;
	}
	GITypeInfo *return_type_info = g_callable_info_get_return_type(info);
	int return_nullable = g_callable_info_may_return_null(info) || patch_return_nullable(return_type_info);
	if (return_nullable) printf("(nullable) ");
	emit_type(return_type_info, return_nullable, 0, 0, 0);
	g_base_info_unref(return_type_info);
	printf("\n");
}

void emit_function_symbol(GIBaseInfo *info)
{
	const char *symbol = g_function_info_get_symbol(info);
	printf("%s", symbol);
}

void emit_function_wrapper(GIBaseInfo *info, const char *name, const char *container_name, int is_deprecated, int is_container_struct, GIStructInfo *virt_class)
{
	const int PARAM_IN = 1;
	const int PARAM_OUT = 2;
	const int PARAM_INOUT = 3;
	if (is_deprecated && !config_enable_deprecated) return;
	if (is_deprecated) printf("/// (deprecated)\n");
	int is_vfunc = (virt_class != NULL);
	char *ziggy_name = snake_to_camel(name);
	emit_function_comment(info);
	/* collect parameter infomation */
	int n = g_callable_info_get_n_args(info);
	int param_dir[n];
	for (int i = 0; i < n; i++) param_dir[i] = PARAM_IN;
	int param_caller_allocate[n];
	for (int i = 0; i < n; i++) param_caller_allocate[i] = 0;
	int param_optional[n];
	for (int i = 0; i < n; i++) param_optional[i] = 0;
	int param_nullable[n];
	for (int i = 0; i < n; i++) param_nullable[i] = 0;
	int param_is_slice_ptr[n];
	for (int i = 0; i < n; i++) param_is_slice_ptr[i] = 0;
	int param_slice_len_ptr_pos[n];
	for (int i = 0; i < n; i++) param_slice_len_ptr_pos[i] = -1;
	int param_slice_len_eq[n];
	for (int i = 0; i < n; i++) param_slice_len_eq[i] = -1;
	int param_instance[n];
	for (int i = 0; i < n; i++) param_instance[i] = 0;
	for (int i = 0; i < n; i++)
	{
		GIArgInfo *arg_info = g_callable_info_get_arg(info, i);
		GIDirection direction = g_arg_info_get_direction(arg_info);
		if (direction == GI_DIRECTION_OUT)
		{
			param_dir[i] = PARAM_OUT;
			if (g_arg_info_is_caller_allocates(arg_info)) param_caller_allocate[i] = 1;
			if (g_arg_info_is_optional(arg_info)) param_optional[i] = 1;
		}
		if (direction == GI_DIRECTION_INOUT)
		{
			param_dir[i] = PARAM_INOUT;
		}
		if (g_arg_info_may_be_null(arg_info)) param_nullable[i] = 1;
		GITypeInfo *type_info = g_arg_info_get_type(arg_info);
		GITypeTag type = g_type_info_get_tag(type_info);
		if (type == GI_TYPE_TAG_ARRAY)
		{
			GIArrayType array_type = g_type_info_get_array_type(type_info);
			if (array_type == GI_ARRAY_TYPE_C)
			{
				int array_length = g_type_info_get_array_length(type_info);
				if (array_length != -1)
				{
					param_is_slice_ptr[i] = 1;
					param_slice_len_eq[i] = param_slice_len_ptr_pos[array_length];
					param_slice_len_ptr_pos[array_length] = i;
				}
			}
		}
		param_instance[i] = is_instance(type_info);

		/* override */
		if (param_dir[i] == PARAM_OUT && !param_caller_allocate[i]) param_optional[i] = 0;
		/* override */
		if (param_caller_allocate[i] && maybe_allocate_on_stack(type_info))
		{
			param_caller_allocate[i] = 0;
			param_optional[i] = 0;
		}

		g_base_info_unref(type_info);
		g_base_info_unref(arg_info);
	}
	/* output prototype */
	if (is_vfunc) printf("pub fn %sV(", ziggy_name);
	else if (strcmp(ziggy_name, "break") == 0 || strcmp(ziggy_name, "continue") == 0 || strcmp(ziggy_name, "error") == 0 || strcmp(ziggy_name, "export") == 0 || strcmp(ziggy_name, "union") == 0) printf("pub fn @\"%s\"(", ziggy_name);
	else if (strcmp(ziggy_name, "self") == 0) printf("pub fn getSelf(");
	else printf("pub fn %s(", ziggy_name);
	int first_input_param = 1;
	int is_method = g_callable_info_is_method(info);
	if (is_method)
	{
		printf("self: %s%s", is_container_struct ? "*" : "", container_name);
		first_input_param = 0;
	}
	if (is_vfunc)
	{
		if (!first_input_param) printf(", ");
		printf("g_type: core.GType");
		first_input_param = 0;
	}
	for (int i = 0; i < n; i++)
	{
		if ((param_dir[i] & PARAM_IN) || param_caller_allocate[i])
		{
			if (param_slice_len_ptr_pos[i] != -1) continue;
			if (!first_input_param) printf(", ");
			first_input_param = 0;
			GIArgInfo *arg_info = g_callable_info_get_arg(info, i);
			const char *arg_name = g_base_info_get_name(arg_info);
			printf("arg_%s: ", arg_name);
			GITypeInfo *type_info = g_arg_info_get_type(arg_info);
			emit_type(type_info, param_nullable[i] || param_optional[i], param_is_slice_ptr[i], 0, 0);
			g_base_info_unref(type_info);
			g_base_info_unref(arg_info);
		}
	}
	printf(") ");
	int throw = g_callable_info_can_throw_gerror(info);
	int skip_return = g_callable_info_skip_return(info);
	GITypeInfo *return_type_info = g_callable_info_get_return_type(info);
	GITypeTag return_type = g_type_info_get_tag(return_type_info);
	if (!g_type_info_is_pointer(return_type_info) && return_type == GI_TYPE_TAG_VOID) skip_return = 1;
	/* override */
	if (throw && return_type == GI_TYPE_TAG_BOOLEAN) skip_return = 1;
	int return_instance = is_instance(return_type_info);
	int multiple_return = 0;
	if (!skip_return) multiple_return++;
	for (int i = 0; i < n; i++)
	{
		if (param_slice_len_ptr_pos[i] != -1) continue;
		if (param_dir[i] != PARAM_IN) multiple_return++;
	}
	int boolean_error = 0;
	/* override */
	if (!skip_return && return_type == GI_TYPE_TAG_BOOLEAN && multiple_return > 1)
	{
		boolean_error = 1;
		multiple_return--;
	}
	int return_nullable = g_callable_info_may_return_null(info);
	if (throw || boolean_error)
	{
		printf("core.Result(");
	}
	if (multiple_return == 0) printf("void");
	else
	{
		if (multiple_return > 1) printf("struct {\n");
		if (!skip_return && !boolean_error)
		{
			if (multiple_return > 1) printf("    ret: ");
			if (is_gtk_widget(return_type_info) && strncmp(name, "new", 3) == 0) printf("%s", container_name);
			else emit_type(return_type_info, return_nullable || patch_return_nullable(return_type_info), 0, 0, 0);
			if (multiple_return > 1) printf(",\n");
		}
		for (int i = 0; i < n; i++)
		{
			if (param_slice_len_ptr_pos[i] != -1) continue;
			if (param_dir[i] == PARAM_IN) continue;
			GIArgInfo *arg_info = g_callable_info_get_arg(info, i);
			const char *arg_name = g_base_info_get_name(arg_info);
			GITypeInfo *type_info = g_arg_info_get_type(arg_info);
			if (multiple_return > 1) printf("    %s: ", arg_name);
			emit_type(type_info, param_nullable[i] || param_optional[i], param_is_slice_ptr[i], 0, 0);
			if (multiple_return > 1) printf(",\n");
			g_base_info_unref(type_info);
			g_base_info_unref(arg_info);
		}
		if (multiple_return > 1) printf("}");
	}
	if (throw || boolean_error)
	{
		printf(", %s)", boolean_error ? "void" : "*core.Error");
	}
	printf(" {\n");
	/* prepare output parameter */
	for (int i = 0; i < n; i++)
	{
		if (param_slice_len_ptr_pos[i] != -1)
		{
			GIArgInfo *arg_info = g_callable_info_get_arg(info, i);
			const char *arg_name = g_base_info_get_name(arg_info);
			int ptr_pos = param_slice_len_ptr_pos[i];
			GIArgInfo *ptr_info = g_callable_info_get_arg(info, ptr_pos);
			const char *ptr_name = g_base_info_get_name(ptr_info);
			if ((param_dir[ptr_pos] & PARAM_IN) || param_caller_allocate[ptr_pos])
			{
				printf("    var %s: ", arg_name);
				GITypeInfo *type_info = g_arg_info_get_type(arg_info);
				emit_type(type_info, 0, 0, 0, 0);
				printf(" = @intCast(");
				emit_type(type_info, 0, 0, 0, 0);
				printf(", ");
				if (param_nullable[ptr_pos] || param_optional[ptr_pos]) printf("if (arg_%s) |some| some.len else 0", ptr_name);
				else printf("arg_%s.len", ptr_name);
				printf(");\n");
			}
			else
			{
				/* callee-allocated non-optional output parameter */
				printf("    var %s: ", arg_name);
				GITypeInfo *type_info = g_arg_info_get_type(arg_info);
				emit_type(type_info, 0, 0, 0, 0);
				printf(" = 0;\n");
				g_base_info_unref(type_info);
			}
			g_base_info_unref(ptr_info);
			g_base_info_unref(arg_info);
		}
		else if (param_is_slice_ptr[i])
		{
			GIArgInfo *arg_info = g_callable_info_get_arg(info, i);
			const char *arg_name = g_base_info_get_name(arg_info);
			if ((param_dir[i] & PARAM_IN) || param_caller_allocate[i])
			{
				if (param_nullable[i] || param_optional[i]) printf("    var %s = if (arg_%s) |some| some.ptr else undefined;\n", arg_name, arg_name);
				else printf("    var %s = arg_%s.ptr;\n", arg_name, arg_name);
			}
			else
			{
				printf("    var %s: ", arg_name);
				GITypeInfo *type_info = g_arg_info_get_type(arg_info);
				emit_type(type_info, 0, 0, 0, 0);
				printf(" = undefined;\n");
				g_base_info_unref(type_info);
			}
			g_base_info_unref(arg_info);
		}
		else if ((param_dir[i] & PARAM_IN) || param_caller_allocate[i])
		{
			if (param_dir[i] == PARAM_IN) continue;
			GIArgInfo *arg_info = g_callable_info_get_arg(info, i);
			const char *arg_name = g_base_info_get_name(arg_info);
			printf("    var %s_mut = arg_%s", arg_name, arg_name);
			if (param_optional[i] && !param_instance[i]) printf(" orelse undefined");
			printf(";\n");
			g_base_info_unref(arg_info);
		}
		else
		{
			GIArgInfo *arg_info = g_callable_info_get_arg(info, i);
			const char *arg_name = g_base_info_get_name(arg_info);
			printf("    var %s_mut: ", arg_name);
			GITypeInfo *type_info = g_arg_info_get_type(arg_info);
			emit_type(type_info, 0, 0, 0, 0);
			printf(" = undefined;\n");
			g_base_info_unref(type_info);
			g_base_info_unref(arg_info);
		}
	}
	if (throw) printf("    var err: ?*core.Error = null;\n");
	/* sanity check */
	for (int i = 0; i < n; i++)
	{
		if (param_slice_len_eq[i] != -1)
		{
			GIArgInfo *arg1_info = g_callable_info_get_arg(info, i);
			GIArgInfo *arg2_info = g_callable_info_get_arg(info, param_slice_len_eq[i]);
			const char *arg1_name = g_base_info_get_name(arg1_info);
			const char *arg2_name = g_base_info_get_name(arg2_info);
			if ((param_dir[i] & PARAM_IN) && (param_dir[param_slice_len_eq[i]] & PARAM_IN)) printf("    assert(arg_%s.len == arg_%s.len);\n", arg1_name, arg2_name);
			g_base_info_unref(arg1_info);
			g_base_info_unref(arg2_info);
		}
	}
	/* call C API */
	if (is_vfunc)
	{
		printf("    const class = core.alignedPtrCast(*%s.%s, core.typeClassPeek(g_type));\n", g_base_info_get_namespace(virt_class), g_base_info_get_name(virt_class));
		printf("    const %s_fn = class.%s.?;\n", name, name);
	}

	if (skip_return) printf("    _ = ");
	else printf("    var ret = ");

	if (is_vfunc) printf("%s_fn(", name);
	else
	{
		printf("struct {\n");
		printf("pub ");
		emit_c_function(info, name, container_name, is_deprecated, is_container_struct);
		printf("}.");
		emit_function_symbol(info);
		printf("(");
	}
	int first_call_param = 1;
	if (is_method)
	{
		printf("self");
		first_call_param = 0;
	}
	for (int i = 0; i < n; i++)
	{
		GIArgInfo *arg_info = g_callable_info_get_arg(info, i);
		const char *arg_name = g_base_info_get_name(arg_info);
		if (!first_call_param) printf(", ");
		first_call_param = 0;
		if (param_optional[i] && param_caller_allocate[i] && param_slice_len_ptr_pos[i] == -1 && !param_instance[i]) printf("if (arg_%s) |_|", arg_name);
		if (param_dir[i] == PARAM_IN && param_nullable[i] && !param_is_slice_ptr[i] && !param_instance[i]) printf("if (arg_%s) |some| ", arg_name);
		GITypeInfo *type_info = g_arg_info_get_type(arg_info);
		if ((param_dir[i] != PARAM_IN && !param_caller_allocate[i]) || is_fixed_size_array(type_info)) printf("&");
		if (param_slice_len_ptr_pos[i] != -1 || param_is_slice_ptr[i]) printf("%s", arg_name);
		else if (param_dir[i] == PARAM_IN)
		{
			if (param_nullable[i] && !param_instance[i]) printf("some");
			else printf("arg_%s", arg_name);
		}
		else printf("%s_mut", arg_name);
		if (param_optional[i] && param_caller_allocate[i] && param_slice_len_ptr_pos[i] == -1 && !param_instance[i]) printf(" else null");
		if (param_dir[i] == PARAM_IN && param_nullable[i] && !param_is_slice_ptr[i] && !param_instance[i]) printf(" else null");
		g_base_info_unref(type_info);
		g_base_info_unref(arg_info);
	}
	if (throw)
	{
		if (!first_call_param) printf(", ");
		printf("&err");
	}
	printf(");\n");
	/* generate output */
	if (throw)
	{
		printf("    if (err) |some| return .{ .Err = some };\n");
		printf("    return .{ .Ok = ");
	}
	else if (boolean_error)
	{
		printf("    if (!ret.toBool()) return .{ .Err = {}};\n");
		printf("    return .{. Ok = ");
	}
	else
	{
		printf("    return ");
	}
	if (multiple_return == 0) printf("{}");
	else
	{
		if (multiple_return > 1) printf(".{ ");
		int first_output_param = 1;
		if (!skip_return && !boolean_error)
		{
			if (multiple_return > 1) printf(".ret = ");
			if (return_nullable && !return_instance) printf("if (ret) |some| some else null");
			else printf("ret");
			first_output_param = 0;
		}
		for (int i = 0; i < n; i++)
		{
			if (param_slice_len_ptr_pos[i] != -1) continue;
			if (param_dir[i] == PARAM_IN) continue;
			if (!first_output_param) printf(", ");
			first_output_param = 0;
			GIArgInfo *arg_info = g_callable_info_get_arg(info, i);
			const char *arg_name = g_base_info_get_name(arg_info);
			if (multiple_return > 1) printf(".%s = ", arg_name);
			if (param_optional[i] && param_caller_allocate[i] && !param_instance[i]) printf("if (arg_%s) |_| ", arg_name);
			GITypeInfo *type_info = g_arg_info_get_type(arg_info);
			printf("%s", arg_name);
			if (param_is_slice_ptr[i])
			{
				int len_pos = g_type_info_get_array_length(type_info);
				GIArgInfo *len_info = g_callable_info_get_arg(info, len_pos);
				const char *len_name = g_base_info_get_name(len_info);
				printf("[0 .. @intCast(usize, %s)]", len_name);
				g_base_info_unref(len_info);
			}
			else printf("_mut");
			if (param_optional[i] && param_caller_allocate[i] && !param_instance[i]) printf(" else null");
			g_base_info_unref(type_info);
			g_base_info_unref(arg_info);
		}
		if (multiple_return > 1) printf(" }");
	}
	if (throw)
	{
		printf(" }");
	}
	else if (boolean_error)
	{
		printf(" }");
	}
	printf(";\n");
	printf("}\n");
	g_base_info_unref(return_type_info);
	free(ziggy_name);
}

void emit_field(GIFieldInfo *field_info, int first_field)
{
	GITypeInfo *field_type_info = g_field_info_get_type(field_info);
	const char *field_name = g_base_info_get_name(field_info);
	// printf("\n");
	if (strcmp(field_name, "error") == 0 || strcmp(field_name, "var") == 0) printf("    @\"%s\": ", field_name);
	else printf("    %s: ", field_name);
	emit_type(field_type_info, g_type_info_is_pointer(field_type_info) || is_callback(field_type_info), 0, 0, 0);
	if (first_field && is_instance(field_type_info) && !g_type_info_is_pointer(field_type_info)) printf(".cType()");
	printf(",\n");
	g_base_info_unref(field_type_info);
	g_base_info_unref(field_info);
}

void emit_signal(GISignalInfo *info, const char *container_name)
{
	GSignalFlags flags = g_signal_info_get_flags(info);
	if ((flags & G_SIGNAL_DEPRECATED) && !config_enable_deprecated) return;
	const char *signal_name = g_base_info_get_name(info);
	char *ziggy_signal_name = snake_to_title(signal_name); /* '-' is handled correctly */
	printf("const SignalProxy%s = struct {\n", ziggy_signal_name);
	printf("    object: %s,\n", container_name);
	printf("\n");
	printf("    /// @handler: fn(%s", container_name);
	int n = g_callable_info_get_n_args(info);
	for (int i = 0; i < n; i++)
	{
		printf(", ");
		GIArgInfo *arg_info = g_callable_info_get_arg(info, i);
		GIDirection direction = g_arg_info_get_direction(arg_info);
		GITypeInfo *type_info = g_arg_info_get_type(arg_info);
		if (is_struct_union(type_info)) printf("*");
		emit_type(type_info, g_arg_info_is_optional(arg_info) || g_arg_info_may_be_null(arg_info), 0, direction == GI_DIRECTION_OUT || direction == GI_DIRECTION_INOUT, 1);
		g_base_info_unref(type_info);
		g_base_info_unref(arg_info);
	}
	printf(", args...) ");
	int return_nullable = g_callable_info_may_return_null(info);
	GITypeInfo *return_type_info = g_callable_info_get_return_type(info);
	emit_type(return_type_info, return_nullable, 0, 0, 1);
	printf("\n");
	printf("    pub fn connect(self: SignalProxy%s, comptime handler: anytype, args: anytype, comptime flags: core.ConnectFlagsZ) usize {\n", ziggy_signal_name);
	printf("        return core.connectZ(self.object.into(core.Object), \"%s\", handler, args, flags, &[_]type{ ", signal_name);
	emit_type(return_type_info, return_nullable, 0, 0, 1);
	printf(", %s", container_name);
	n = g_callable_info_get_n_args(info);
	for (int i = 0; i < n; i++)
	{
		printf(", ");
		GIArgInfo *arg_info = g_callable_info_get_arg(info, i);
		GIDirection direction = g_arg_info_get_direction(arg_info);
		GITypeInfo *type_info = g_arg_info_get_type(arg_info);
		if (is_struct_union(type_info)) printf("*"); /* no pointer annotation for struct */
		emit_type(type_info, g_arg_info_is_optional(arg_info) || g_arg_info_may_be_null(arg_info), 0, direction == GI_DIRECTION_OUT || direction == GI_DIRECTION_INOUT, 1);
		g_base_info_unref(type_info);
		g_base_info_unref(arg_info);
	}
	printf(" });\n");
	printf("    }\n");
	printf("};\n");
	printf("\n");
	printf("pub fn signal%s(self: %s) SignalProxy%s {\n", ziggy_signal_name, container_name, ziggy_signal_name);
	printf("    return .{ .object = self };\n");
	printf("}\n");
	g_base_info_unref(return_type_info);
	free(ziggy_signal_name);
}

void emit_property(GIPropertyInfo *info, const char *container_name)
{
	GParamFlags flags = g_property_info_get_flags(info);
	const char *property_name = g_base_info_get_name(info);
	char *ziggy_property_name = snake_to_title(property_name);
	GITypeInfo *type_info = g_property_info_get_type(info);
	printf("const PropertyProxy%s = struct {\n", ziggy_property_name);
	printf("    object: %s,\n", container_name);
	printf("\n");
	printf("    pub fn connectNotify(self: PropertyProxy%s, comptime handler: anytype, args: anytype, comptime flags: core.ConnectFlagsZ) usize {\n", ziggy_property_name);
	printf("        return core.connectZ(self.object.into(core.Object), \"notify::%s\", handler, args, flags, &[_]type{ void, %s, core.ParamSpec });\n", property_name, container_name);
	printf("    }\n");
	GIFunctionInfo *getter = g_property_info_get_getter(info);
	if (getter != NULL)
	{
		printf("\n");
		printf("    extern fn ");
		emit_function_symbol(getter);
		printf("(%s) ", container_name);
		emit_type(type_info, 0, 0, 0, 1);
		printf(";\n");
		printf("    pub fn get(self: PropertyProxy%s) ", ziggy_property_name);
		emit_type(type_info, 0, 0, 0, 1);
		printf(" {\n");
		printf("        return ");
		emit_function_symbol(getter);
		printf("(self.object);\n");
		printf("    }\n");
		g_base_info_unref(getter);
	}
	else if (flags & G_PARAM_READABLE)
	{
		printf("\n");
		printf("    pub fn get(self: PropertyProxy%s) ", ziggy_property_name);
		emit_type(type_info, 0, 0, 0, 1);
		printf(" {\n");
		printf("        var property_value = std.mem.zeroes(core.Value);\n");
		printf("        defer property_value.unset();\n");
		emit_value_set("property_value", type_info, NULL);
		printf("        self.callMethod(\"getProperty\", .{ \"%s\", &property_value });\n", property_name);
		printf("        return ");
		emit_value_get("property_value", type_info);
		printf(";\n");
		printf("    }\n");
	}
	GIFunctionInfo *setter = g_property_info_get_setter(info);
	if (setter != NULL)
	{
		printf("\n");
		printf("    extern fn ");
		emit_function_symbol(setter);
		printf("(%s, ", container_name);
		emit_type(type_info, 0, 0, 0, 1);
		printf(") void;\n");
		printf("    pub fn set(self: PropertyProxy%s, value: ", ziggy_property_name);
		emit_type(type_info, 0, 0, 0, 1);
		printf(") void {\n");
		printf("        ");
		emit_function_symbol(setter);
		printf("(self.object, value);\n");
		printf("    }\n");
		g_base_info_unref(setter);
	}
	else if ((flags & G_PARAM_WRITABLE) && !(flags & G_PARAM_CONSTRUCT_ONLY))
	{
		printf("\n");
		printf("    pub fn set(self: PropertyProxy%s, value: ", ziggy_property_name);
		emit_type(type_info, 0, 0, 0, 1);
		printf(") void {\n");
		printf("        var property_value = std.mem.zeroes(core.Value);\n");
		printf("        defer property_value.unset();\n");
		emit_value_set("property_value", type_info, "value");
		printf("        self.callMethod(\"setProperty\", .{ \"%s\", &property_value });\n", property_name);
		printf("    }\n");
	}
	printf("};\n");
	printf("\n");
	printf("pub fn property%s(self: %s) PropertyProxy%s {\n", ziggy_property_name, container_name, ziggy_property_name);
	printf("    return .{ .object = self };\n");
	printf("}\n");
	g_base_info_unref(type_info);
	free(ziggy_property_name);
}

void emit_registered_type(GIRegisteredTypeInfo *info, int is_instance)
{
	if (is_instance)
	{
		const char *name = g_base_info_get_name(info);
		printf("\n");
		printf("    pub fn cType() type {\n");
		printf("        return %sImpl;\n", name);
		printf("    }\n");
	}

	unsigned long id = g_registered_type_info_get_g_type(info);
	if (id == G_TYPE_NONE) return;
	printf("\n");
	printf("    pub fn gType() core.GType {\n");
	printf("        return struct {\n");
	printf("            pub extern fn %s() core.GType;\n", g_registered_type_info_get_type_init(info));
	printf("        }.%s();\n", g_registered_type_info_get_type_init(info));
	printf("    }\n");
}

void emit_nullable(const char *name)
{
	printf("pub const %sNullable = packed struct {\n", name);
	printf("    ptr: ?*%sImpl,\n", name);
	printf("\n");
	printf("    pub fn expect(self: %sNullable, message: []const u8) %s {\n", name, name);
	printf("        if (self.ptr) |some| { return %s{ .instance = some }; } else @panic(message);\n", name);
	printf("    }\n");
	printf("\n");
	printf("    pub fn wrap(self: %sNullable) ?%s {\n", name, name);
	printf("        return if (self.ptr) |some| %s{ .instance = some } else null;\n", name);
	printf("    }\n");
	printf("};\n");
}

void emit_into(const char *name)
{
	printf("    pub fn into(self: %s, comptime T: type) T {\n", name);
	printf("        return core.upCast(T, self);\n");
	printf("    }\n");
	printf("\n");
	printf("    pub fn tryInto(self: %s, comptime T: type) ?T {\n", name);
	printf("        return core.downCast(T, self);\n");
	printf("    }\n");
	printf("\n");
	printf("    pub fn asSome(self: %s) %sNullable {\n", name, name);
	printf("        return .{ .ptr = self.instance };\n");
	printf("    }\n");
}

void emit_value_get(const char *value_name, GITypeInfo *type_info)
{
	// TODO: support glib.variant
	GITypeTag type = g_type_info_get_tag(type_info);
	switch (type)
	{
		case GI_TYPE_TAG_VOID:
			assert(g_type_info_is_pointer(type_info));
			printf("%s.getPointer()", value_name);
			break;
		case GI_TYPE_TAG_BOOLEAN:
			printf("%s.getBoolean()", value_name);
			break;
		case GI_TYPE_TAG_INT8:
			printf("%s.getSchar()", value_name);
			break;
		case GI_TYPE_TAG_UINT8:
			printf("%s.getUchar()", value_name);
			break;
		case GI_TYPE_TAG_INT16:
			printf("@intCast(i16, %s.getInt())", value_name);
			break;
		case GI_TYPE_TAG_UINT16:
			printf("@intCast(u16, %s.getUInt())", value_name);
			break;
		case GI_TYPE_TAG_INT32:
			printf("if (%s.g_type == .Int) @intCast(i32, %s.getInt()) else @intCast(i32, %s.getLong())", value_name, value_name, value_name);
			break;
		case GI_TYPE_TAG_UINT32:
			printf("if (%s.g_type == .Uint) @intCast(u32, %s.getUint()) else @intCast(u32, %s.getUlong())", value_name, value_name, value_name);
			break;
		case GI_TYPE_TAG_INT64:
			printf("if (%s.g_type == .Int64) %s.getInt64() else @intCast(i64, %s.getLong())", value_name, value_name, value_name);
			break;
		case GI_TYPE_TAG_UINT64:
			printf("if (%s.g_type == .UInt64) %s.getUint64() else @intCast(u64, %s.getUlong())", value_name, value_name, value_name);
			break;
		case GI_TYPE_TAG_FLOAT:
			printf("%s.getFloat()", value_name);
			break;
		case GI_TYPE_TAG_DOUBLE:
			printf("%s.getDouble()", value_name);
			break;
		case GI_TYPE_TAG_GTYPE:
			printf("%s.getGtype()", value_name);
			break;
		case GI_TYPE_TAG_UTF8:
		case GI_TYPE_TAG_FILENAME:
			printf("%s.getString()", value_name);
			break;
		case GI_TYPE_TAG_ARRAY:
			GIArrayType array_type = g_type_info_get_array_type(type_info);
			switch (array_type)
			{
				case GI_ARRAY_TYPE_ARRAY:
					printf("core.alignedPtrCast(*core.Array, %s.getBoxed())\n", value_name);
					break;
				case GI_ARRAY_TYPE_PTR_ARRAY:
					printf("core.alignedPtrCast(*core.PtrArray, %s.getBoxed())\n", value_name);
					break;
				case GI_ARRAY_TYPE_BYTE_ARRAY:
					printf("core.alignedPtrCast(*core.ByteArray, %s.getBoxed())\n", value_name);
					break;
				default:
					/* C array */
					printf("core.alignedPtrCast(");
					emit_type(type_info, 0, 0, 0, 1);
					printf(", %s.getPointer())", value_name);
					break;
			}
			break;
		case GI_TYPE_TAG_INTERFACE:
			GIBaseInfo *interface = g_type_info_get_interface(type_info);
			GIInfoType info_type = g_base_info_get_type(interface);
			switch (info_type)
			{
				case GI_INFO_TYPE_OBJECT:
				case GI_INFO_TYPE_INTERFACE:
					printf("%s.getObject().tryInto(", value_name);
					emit_type(type_info, 0, 0, 0, 1);
					printf(").?");
					break;
				case GI_INFO_TYPE_STRUCT:
				case GI_INFO_TYPE_UNION:
				case GI_INFO_TYPE_BOXED:
					printf("core.alignedPtrCast(*");
					emit_type(type_info, 0, 0, 0, 1);
					printf(", %s.getBoxed())", value_name);
					break;
				case GI_INFO_TYPE_ENUM:
					printf("@intToEnum(");
					emit_type(type_info, 0, 0, 0, 1);
					printf(", %s.getEnum())", value_name);
					break;
				case GI_INFO_TYPE_FLAGS:
					printf("@intToEnum(");
					emit_type(type_info, 0, 0, 0, 1);
					printf(", %s.getFlags())", value_name);
					break;
				case GI_INFO_TYPE_CALLBACK:
				default:
					printf("core.Unsupported");
					fprintf(stderr, "Unsupported (value) interface type %s\n", g_info_type_to_string(info_type));
					break;
			}
			g_base_info_unref(interface);
			break;
		case GI_TYPE_TAG_GLIST:
		case GI_TYPE_TAG_GSLIST:
		case GI_TYPE_TAG_GHASH:
		case GI_TYPE_TAG_ERROR:
		case GI_TYPE_TAG_UNICHAR:
		default:
			printf("core.Unsupported");
			fprintf(stderr, "Unsupported (value) type %s\n", g_type_tag_to_string(type));
			break;
	}
}

void emit_value_set(const char *value_name, GITypeInfo *type_info, const char *value)
{
	GITypeTag type = g_type_info_get_tag(type_info);
	switch (type)
	{
		case GI_TYPE_TAG_VOID:
			assert(g_type_info_is_pointer(type_info));
			printf("_ = %s.init(.Pointer);\n", value_name);
			if (value != NULL) printf("%s.setPointer(%s);\n", value_name, value);
			break;
		case GI_TYPE_TAG_BOOLEAN:
			printf("_ = %s.init(.Boolean);\n", value_name);
			if (value != NULL) printf("%s.setBoolean(%s);\n", value_name, value);
			break;
		case GI_TYPE_TAG_INT8:
			printf("_ = %s.init(.Char);\n", value_name);
			if (value != NULL) printf("%s.setSchar(%s);\n", value_name, value);
			break;
		case GI_TYPE_TAG_UINT8:
			printf("_ = %s.init(.Uchar);\n", value_name);
			if (value != NULL) printf("%s.setUchar(%s);\n", value_name, value);
			break;
		case GI_TYPE_TAG_INT16:
			printf("_ = %s.init(.Int);\n", value_name);
			if (value != NULL) printf("%s.setInt(%s);\n", value_name, value);
			break;
		case GI_TYPE_TAG_UINT16:
			printf("_ = %s.init(.Uint);\n", value_name);
			if (value != NULL) printf("%s.setUInt(%s);\n", value_name, value);
			break;
		case GI_TYPE_TAG_INT32:
			if (sizeof(int) == 4)
			{
				printf("_ = %s.init(.Int);\n", value_name);
				if (value != NULL) printf("%s.setInt(%s);\n", value_name, value);
			}
			else
			{
				printf("_ = %s.init(.Long);\n", value_name);
				if (value != NULL) printf("%s.setLong(%s);\n", value_name, value);
			}
			break;
		case GI_TYPE_TAG_UINT32:
			if (sizeof(int) == 4)
			{
				printf("_ = %s.init(.Uint);\n", value_name);
				if (value != NULL) printf("%s.setUint(%s);\n", value_name, value);
			}
			else
			{
				printf("_ = %s.init(.Ulong);\n", value_name);
				if (value != NULL) printf("%s.setUlong(%s);\n", value_name, value);
			}
			break;
		case GI_TYPE_TAG_INT64:
			printf("_ = %s.init(.Int64);\n", value_name);
			if (value != NULL) printf("%s.setInt64(%s);\n", value_name, value);
			break;
		case GI_TYPE_TAG_UINT64:
			printf("_ = %s.init(.Uint64);\n", value_name);
			if (value != NULL) printf("%s.setUint64(%s);\n", value_name, value);
			break;
		case GI_TYPE_TAG_FLOAT:
			printf("_ = %s.init(.Float);\n", value_name);
			if (value != NULL) printf("%s.setFloat(%s);\n", value_name, value);
			break;
		case GI_TYPE_TAG_DOUBLE:
			printf("_ = %s.init(.Double);\n", value_name);
			if (value != NULL) printf("%s.setDouble(%s);\n", value_name, value);
			break;
		case GI_TYPE_TAG_GTYPE:
			printf("_ = %s.init(core.gtypeGetType());\n", value_name);
			if (value != NULL) printf("%s.setGtype(%s);\n", value_name, value);
			break;
		case GI_TYPE_TAG_UTF8:
		case GI_TYPE_TAG_FILENAME:
			printf("_ = %s.init(.String);\n", value_name);
			if (value != NULL) printf("%s.setString(%s);\n", value_name, value);
			break;
		case GI_TYPE_TAG_ARRAY:
			GIArrayType array_type = g_type_info_get_array_type(type_info);
			switch (array_type)
			{
				case GI_ARRAY_TYPE_ARRAY:
				case GI_ARRAY_TYPE_PTR_ARRAY:
				case GI_ARRAY_TYPE_BYTE_ARRAY:
					printf("_ = %s.init(.Boxed);\n", value_name);
					if (value != NULL) printf("%s.setBoxed(%s);\n\n", value_name, value);
					break;
				default:
					/* C array */
					printf("_ = %s.init(.Pointer);\n", value_name);
					if (value != NULL) printf("%s.setObject(%s);\n", value_name, value);
					break;
			}
			break;
		case GI_TYPE_TAG_INTERFACE:
			GIBaseInfo *interface = g_type_info_get_interface(type_info);
			GIInfoType info_type = g_base_info_get_type(interface);
			switch (info_type)
			{
				case GI_INFO_TYPE_OBJECT:
				case GI_INFO_TYPE_INTERFACE:
					printf("_ = %s.init(.Object);", value_name);
					if (value != NULL) printf("%s.setObject(%s.into(core.Object));\n", value_name, value);
					break;
				case GI_INFO_TYPE_STRUCT:
				case GI_INFO_TYPE_UNION:
				case GI_INFO_TYPE_BOXED:
					printf("_ = %s.init(.Boxed);\n", value_name);
					if (value != NULL) printf("%s.setBoxed(%s);\n", value_name, value);
					break;
				case GI_INFO_TYPE_ENUM:
					printf("_ = %s.init(.Enum);\n", value_name);
					if (value != NULL) printf("%s.setEnum(@enumToInt(%s));\n", value_name, value);
					break;
				case GI_INFO_TYPE_FLAGS:
					printf("_ = %s.init(.Flags);\n", value_name);
					if (value != NULL) printf("%s.setFlags(@enumToInt(%s));\n", value_name, value);
					break;
				case GI_INFO_TYPE_CALLBACK:
				default:
					printf("_ = core.Unsupported;\n");
					fprintf(stderr, "Unsupported (value) interface type %s\n", g_info_type_to_string(info_type));
					break;
			}
			g_base_info_unref(interface);
			break;
		case GI_TYPE_TAG_GLIST:
		case GI_TYPE_TAG_GSLIST:
		case GI_TYPE_TAG_GHASH:
		case GI_TYPE_TAG_ERROR:
		case GI_TYPE_TAG_UNICHAR:
		default:
			printf("_ = core.Unsupported;\n");
			fprintf(stderr, "Unsupported (value) type %s\n", g_type_tag_to_string(type));
			break;
	}
}

void emit_vfunc(GIVFuncInfo *info, const char *container_name, GIStructInfo *class_info)
{
	const char *vfunc_name = g_base_info_get_name(info);
	emit_function(info, vfunc_name, container_name, g_base_info_is_deprecated(info), 0, class_info);
}