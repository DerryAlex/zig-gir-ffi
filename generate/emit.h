#ifndef __GIR_ZIG_EMIT_H__
#define __GIR_ZIG_EMIT_H__

#include <girepository.h>

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

// toplevels
void emit_function(GIBaseInfo *info, const char *name, const char *container_name, int is_deprecated, int is_container_struct, GIStructInfo *virt_class);
void emit_callback(GIBaseInfo *info, const char *name, int is_deprecated, int type_only);
void emit_struct(GIBaseInfo *info, const char *name, int is_deprecated);
void emit_enum(GIBaseInfo *info, const char *name, int is_flags, int is_deprecated);
void emit_object(GIBaseInfo *info, const char *name, int is_deprecated);
void emit_interface(GIBaseInfo *info, const char *name, int is_deprecated);
void emit_constant(GIBaseInfo *info, const char *name, int is_deprecated);
void emit_union(GIBaseInfo *info, const char *name, int is_deprecated);

// internals
void emit_type(GIBaseInfo *type_info, int optional, int is_slice, int is_out, int prefer_c);
void emit_function_comment(GIBaseInfo *info);
void emit_function_symbol(GIBaseInfo *info);
void emit_function_wrapper(GIBaseInfo *info, const char *name, const char *container_name, int is_deprecated, int is_container_struct, GIStructInfo *virt_class);
void emit_field_begin();
void emit_field_end();
void emit_field(GIFieldInfo *field_info, int first_field);
void emit_signal(GISignalInfo *info, const char *container_name);
void emit_property(GIPropertyInfo *info, const char *container_name);
void emit_registered_type(GIRegisteredTypeInfo *info, int is_instance);
void emit_nullable(const char *name);
void emit_into(const char *name);
void emit_value_get(const char *value_name, GITypeInfo *type_info);
void emit_value_set(const char *value_name, GITypeInfo *type_info, const char *value);
void emit_vfunc(GIVFuncInfo *info, const char *container_name, GIStructInfo *class_info);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __GIR_ZIG_EMIT_H__ */