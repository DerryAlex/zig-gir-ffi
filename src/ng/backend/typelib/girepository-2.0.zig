const gi_repository = @This();
const gi = @import("../../gi.zig");
pub const core = @import("core_min.zig");
const std = @import("std");
/// Class [ArgInfo](https://docs.gtk.org/girepository/class.ArgInfo.html)
pub const ArgInfo = extern struct {
    parent: BaseInfoStack,
    padding: [6]?*anyopaque,
    pub const Parent = BaseInfo;
    /// method [get_closure_index](https://docs.gtk.org/girepository/method.ArgInfo.get_closure_index.html)
    pub fn getClosureIndex(self: *ArgInfo) ?u32 {
        var out_closure_index_out: u32 = undefined;
        const _out_closure_index = &out_closure_index_out;
        const cFn = @extern(*const fn (*ArgInfo, ?*u32) callconv(.c) bool, .{ .name = "gi_arg_info_get_closure_index" });
        const ret = cFn(self, _out_closure_index);
        if (!ret) return null;
        return out_closure_index_out;
    }
    /// method [get_destroy_index](https://docs.gtk.org/girepository/method.ArgInfo.get_destroy_index.html)
    pub fn getDestroyIndex(self: *ArgInfo) ?u32 {
        var out_destroy_index_out: u32 = undefined;
        const _out_destroy_index = &out_destroy_index_out;
        const cFn = @extern(*const fn (*ArgInfo, ?*u32) callconv(.c) bool, .{ .name = "gi_arg_info_get_destroy_index" });
        const ret = cFn(self, _out_destroy_index);
        if (!ret) return null;
        return out_destroy_index_out;
    }
    /// method [get_direction](https://docs.gtk.org/girepository/method.ArgInfo.get_direction.html)
    pub fn getDirection(self: *ArgInfo) Direction {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) Direction, .{ .name = "gi_arg_info_get_direction" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_ownership_transfer](https://docs.gtk.org/girepository/method.ArgInfo.get_ownership_transfer.html)
    pub fn getOwnershipTransfer(self: *ArgInfo) Transfer {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) Transfer, .{ .name = "gi_arg_info_get_ownership_transfer" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_scope](https://docs.gtk.org/girepository/method.ArgInfo.get_scope.html)
    pub fn getScope(self: *ArgInfo) ScopeType {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) ScopeType, .{ .name = "gi_arg_info_get_scope" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_type_info](https://docs.gtk.org/girepository/method.ArgInfo.get_type_info.html)
    pub fn getTypeInfo(self: *ArgInfo) *TypeInfo {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) *TypeInfo, .{ .name = "gi_arg_info_get_type_info" });
        const ret = cFn(self);
        return ret;
    }
    /// method [is_caller_allocates](https://docs.gtk.org/girepository/method.ArgInfo.is_caller_allocates.html)
    pub fn isCallerAllocates(self: *ArgInfo) bool {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) bool, .{ .name = "gi_arg_info_is_caller_allocates" });
        const ret = cFn(self);
        return ret;
    }
    /// method [is_optional](https://docs.gtk.org/girepository/method.ArgInfo.is_optional.html)
    pub fn isOptional(self: *ArgInfo) bool {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) bool, .{ .name = "gi_arg_info_is_optional" });
        const ret = cFn(self);
        return ret;
    }
    /// method [is_return_value](https://docs.gtk.org/girepository/method.ArgInfo.is_return_value.html)
    pub fn isReturnValue(self: *ArgInfo) bool {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) bool, .{ .name = "gi_arg_info_is_return_value" });
        const ret = cFn(self);
        return ret;
    }
    /// method [is_skip](https://docs.gtk.org/girepository/method.ArgInfo.is_skip.html)
    pub fn isSkip(self: *ArgInfo) bool {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) bool, .{ .name = "gi_arg_info_is_skip" });
        const ret = cFn(self);
        return ret;
    }
    /// method [load_type_info](https://docs.gtk.org/girepository/method.ArgInfo.load_type_info.html)
    pub fn loadTypeInfo(self: *ArgInfo, _type: *TypeInfo) void {
        const cFn = @extern(*const fn (*ArgInfo, *TypeInfo) callconv(.c) void, .{ .name = "gi_arg_info_load_type_info" });
        const ret = cFn(self, _type);
        return ret;
    }
    /// method [may_be_null](https://docs.gtk.org/girepository/method.ArgInfo.may_be_null.html)
    pub fn mayBeNull(self: *ArgInfo) bool {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) bool, .{ .name = "gi_arg_info_may_be_null" });
        const ret = cFn(self);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_arg_info_get_type" });
        return cFn();
    }
};
/// Union [Argument](https://docs.gtk.org/girepository/union.Argument.html)
pub const Argument = gi.Argument;
/// Enum [ArrayType](https://docs.gtk.org/girepository/enum.ArrayType.html)
pub const ArrayType = gi.ArrayType;
/// Struct [AttributeIter](https://docs.gtk.org/girepository/struct.AttributeIter.html)
pub const AttributeIter = extern struct {
    data: ?*anyopaque,
    _dummy: [4]?*anyopaque,
};
/// Class [BaseInfo](https://docs.gtk.org/girepository/class.BaseInfo.html)
pub const BaseInfo = opaque {
    pub const Class = BaseInfoClass;
    /// method [clear](https://docs.gtk.org/girepository/method.BaseInfo.clear.html)
    pub fn clear(self: *BaseInfo) void {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.c) void, .{ .name = "gi_base_info_clear" });
        const ret = cFn(self);
        return ret;
    }
    /// method [equal](https://docs.gtk.org/girepository/method.BaseInfo.equal.html)
    pub fn equal(self: *BaseInfo, _info2: *BaseInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo, *BaseInfo) callconv(.c) bool, .{ .name = "gi_base_info_equal" });
        const ret = cFn(self, _info2);
        return ret;
    }
    /// method [get_attribute](https://docs.gtk.org/girepository/method.BaseInfo.get_attribute.html)
    pub fn getAttribute(self: *BaseInfo, _name: [*:0]const u8) ?[*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo, [*:0]const u8) callconv(.c) ?[*:0]u8, .{ .name = "gi_base_info_get_attribute" });
        const ret = cFn(self, _name);
        return ret;
    }
    /// method [get_container](https://docs.gtk.org/girepository/method.BaseInfo.get_container.html)
    pub fn getContainer(self: *BaseInfo) ?*BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.c) ?*BaseInfo, .{ .name = "gi_base_info_get_container" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_name](https://docs.gtk.org/girepository/method.BaseInfo.get_name.html)
    pub fn getName(self: *BaseInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_base_info_get_name" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_namespace](https://docs.gtk.org/girepository/method.BaseInfo.get_namespace.html)
    pub fn getNamespace(self: *BaseInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_base_info_get_namespace" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_typelib](https://docs.gtk.org/girepository/method.BaseInfo.get_typelib.html)
    pub fn getTypelib(self: *BaseInfo) *Typelib {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.c) *Typelib, .{ .name = "gi_base_info_get_typelib" });
        const ret = cFn(self);
        return ret;
    }
    /// method [is_deprecated](https://docs.gtk.org/girepository/method.BaseInfo.is_deprecated.html)
    pub fn isDeprecated(self: *BaseInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.c) bool, .{ .name = "gi_base_info_is_deprecated" });
        const ret = cFn(self);
        return ret;
    }
    /// method [iterate_attributes](https://docs.gtk.org/girepository/method.BaseInfo.iterate_attributes.html)
    pub fn iterateAttributes(self: *BaseInfo, _iterator: *AttributeIter) struct {
        ret: bool,
        name: [*:0]u8,
        value: [*:0]u8,
    } {
        var name_out: [*:0]u8 = undefined;
        const _name = &name_out;
        var value_out: [*:0]u8 = undefined;
        const _value = &value_out;
        const cFn = @extern(*const fn (*BaseInfo, *AttributeIter, *[*:0]u8, *[*:0]u8) callconv(.c) bool, .{ .name = "gi_base_info_iterate_attributes" });
        const ret = cFn(self, _iterator, _name, _value);
        return .{ .ret = ret, .name = name_out, .value = value_out };
    }
    /// method [ref](https://docs.gtk.org/girepository/method.BaseInfo.ref.html)
    pub fn ref(self: *BaseInfo) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.c) *BaseInfo, .{ .name = "gi_base_info_ref" });
        const ret = cFn(self);
        return ret;
    }
    /// method [unref](https://docs.gtk.org/girepository/method.BaseInfo.unref.html)
    pub fn unref(self: *BaseInfo) void {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.c) void, .{ .name = "gi_base_info_unref" });
        const ret = cFn(self);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_base_info_get_type" });
        return cFn();
    }
};
pub const BaseInfoClass = opaque {};
/// Struct [BaseInfoStack](https://docs.gtk.org/girepository/struct.BaseInfoStack.html)
pub const BaseInfoStack = extern struct {
    parent_instance: core.TypeInstance,
    dummy0: i32,
    dummy1: [3]?*anyopaque,
    dummy2: [2]u32,
    dummy3: [6]?*anyopaque,
};
/// Class [CallableInfo](https://docs.gtk.org/girepository/class.CallableInfo.html)
pub const CallableInfo = opaque {
    pub const Parent = BaseInfo;
    /// method [can_throw_gerror](https://docs.gtk.org/girepository/method.CallableInfo.can_throw_gerror.html)
    pub fn canThrowGerror(self: *CallableInfo) bool {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) bool, .{ .name = "gi_callable_info_can_throw_gerror" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_arg](https://docs.gtk.org/girepository/method.CallableInfo.get_arg.html)
    pub fn getArg(self: *CallableInfo, _n: u32) *ArgInfo {
        const cFn = @extern(*const fn (*CallableInfo, u32) callconv(.c) *ArgInfo, .{ .name = "gi_callable_info_get_arg" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_caller_owns](https://docs.gtk.org/girepository/method.CallableInfo.get_caller_owns.html)
    pub fn getCallerOwns(self: *CallableInfo) Transfer {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) Transfer, .{ .name = "gi_callable_info_get_caller_owns" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_instance_ownership_transfer](https://docs.gtk.org/girepository/method.CallableInfo.get_instance_ownership_transfer.html)
    pub fn getInstanceOwnershipTransfer(self: *CallableInfo) Transfer {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) Transfer, .{ .name = "gi_callable_info_get_instance_ownership_transfer" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_n_args](https://docs.gtk.org/girepository/method.CallableInfo.get_n_args.html)
    pub fn getNArgs(self: *CallableInfo) u32 {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) u32, .{ .name = "gi_callable_info_get_n_args" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_return_attribute](https://docs.gtk.org/girepository/method.CallableInfo.get_return_attribute.html)
    pub fn getReturnAttribute(self: *CallableInfo, _name: [*:0]const u8) ?[*:0]u8 {
        const cFn = @extern(*const fn (*CallableInfo, [*:0]const u8) callconv(.c) ?[*:0]u8, .{ .name = "gi_callable_info_get_return_attribute" });
        const ret = cFn(self, _name);
        return ret;
    }
    /// method [get_return_type](https://docs.gtk.org/girepository/method.CallableInfo.get_return_type.html)
    pub fn getReturnType(self: *CallableInfo) *TypeInfo {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) *TypeInfo, .{ .name = "gi_callable_info_get_return_type" });
        const ret = cFn(self);
        return ret;
    }
    /// method [invoke](https://docs.gtk.org/girepository/method.CallableInfo.invoke.html)
    pub fn invoke(self: *CallableInfo, _function: ?*anyopaque, _in_argss: []Argument, _out_argss: []Argument, _return_value: *Argument, _error: *?*core.Error) error{GError}!bool {
        const _in_args = _in_argss.ptr;
        const _n_in_args: u64 = @intCast(_in_argss.len);
        const _out_args = _out_argss.ptr;
        const _n_out_args: u64 = @intCast(_out_argss.len);
        const cFn = @extern(*const fn (*CallableInfo, ?*anyopaque, [*]Argument, u64, [*]Argument, u64, *Argument, *?*core.Error) callconv(.c) bool, .{ .name = "gi_callable_info_invoke" });
        const ret = cFn(self, @ptrCast(_function), _in_args, _n_in_args, _out_args, _n_out_args, _return_value, _error);
        if (_error.* != null) return error.GError;
        return ret;
    }
    /// method [is_method](https://docs.gtk.org/girepository/method.CallableInfo.is_method.html)
    pub fn isMethod(self: *CallableInfo) bool {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) bool, .{ .name = "gi_callable_info_is_method" });
        const ret = cFn(self);
        return ret;
    }
    /// method [iterate_return_attributes](https://docs.gtk.org/girepository/method.CallableInfo.iterate_return_attributes.html)
    pub fn iterateReturnAttributes(self: *CallableInfo, _iterator: *AttributeIter) struct {
        ret: bool,
        name: [*:0]u8,
        value: [*:0]u8,
    } {
        var name_out: [*:0]u8 = undefined;
        const _name = &name_out;
        var value_out: [*:0]u8 = undefined;
        const _value = &value_out;
        const cFn = @extern(*const fn (*CallableInfo, *AttributeIter, *[*:0]u8, *[*:0]u8) callconv(.c) bool, .{ .name = "gi_callable_info_iterate_return_attributes" });
        const ret = cFn(self, _iterator, _name, _value);
        return .{ .ret = ret, .name = name_out, .value = value_out };
    }
    /// method [load_arg](https://docs.gtk.org/girepository/method.CallableInfo.load_arg.html)
    pub fn loadArg(self: *CallableInfo, _n: u32, _arg: *ArgInfo) void {
        const cFn = @extern(*const fn (*CallableInfo, u32, *ArgInfo) callconv(.c) void, .{ .name = "gi_callable_info_load_arg" });
        const ret = cFn(self, _n, _arg);
        return ret;
    }
    /// method [load_return_type](https://docs.gtk.org/girepository/method.CallableInfo.load_return_type.html)
    pub fn loadReturnType(self: *CallableInfo, _type: *TypeInfo) void {
        const cFn = @extern(*const fn (*CallableInfo, *TypeInfo) callconv(.c) void, .{ .name = "gi_callable_info_load_return_type" });
        const ret = cFn(self, _type);
        return ret;
    }
    /// method [may_return_null](https://docs.gtk.org/girepository/method.CallableInfo.may_return_null.html)
    pub fn mayReturnNull(self: *CallableInfo) bool {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) bool, .{ .name = "gi_callable_info_may_return_null" });
        const ret = cFn(self);
        return ret;
    }
    /// method [skip_return](https://docs.gtk.org/girepository/method.CallableInfo.skip_return.html)
    pub fn skipReturn(self: *CallableInfo) bool {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) bool, .{ .name = "gi_callable_info_skip_return" });
        const ret = cFn(self);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_callable_info_get_type" });
        return cFn();
    }
};
/// Class [CallbackInfo](https://docs.gtk.org/girepository/class.CallbackInfo.html)
pub const CallbackInfo = opaque {
    pub const Parent = CallableInfo;
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_callback_info_get_type" });
        return cFn();
    }
};
/// Class [ConstantInfo](https://docs.gtk.org/girepository/class.ConstantInfo.html)
pub const ConstantInfo = opaque {
    pub const Parent = BaseInfo;
    /// method [get_type_info](https://docs.gtk.org/girepository/method.ConstantInfo.get_type_info.html)
    pub fn getTypeInfo(self: *ConstantInfo) *TypeInfo {
        const cFn = @extern(*const fn (*ConstantInfo) callconv(.c) *TypeInfo, .{ .name = "gi_constant_info_get_type_info" });
        const ret = cFn(self);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;

    pub fn freeValue(self: *ConstantInfo, value: *Argument) void {
        const cFn = @extern(*const fn (*BaseInfo, *Argument) callconv(.c) void, .{ .name = "gi_constant_info_free_value" });
        _ = cFn(self.into(BaseInfo), value);
    }

    pub fn getValue(self: *ConstantInfo, value: *Argument) c_int {
        const cFn = @extern(*const fn (*BaseInfo, *Argument) callconv(.c) c_int, .{ .name = "gi_constant_info_get_value" });
        const ret = cFn(self.into(BaseInfo), value);
        return ret;
    }

    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_constant_info_get_type" });
        return cFn();
    }
};
/// Enum [Direction](https://docs.gtk.org/girepository/enum.Direction.html)
pub const Direction = gi.Direction;
/// Class [EnumInfo](https://docs.gtk.org/girepository/class.EnumInfo.html)
pub const EnumInfo = opaque {
    pub const Parent = RegisteredTypeInfo;
    /// method [get_error_domain](https://docs.gtk.org/girepository/method.EnumInfo.get_error_domain.html)
    pub fn getErrorDomain(self: *EnumInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*EnumInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_enum_info_get_error_domain" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_method](https://docs.gtk.org/girepository/method.EnumInfo.get_method.html)
    pub fn getMethod(self: *EnumInfo, _n: u32) *FunctionInfo {
        const cFn = @extern(*const fn (*EnumInfo, u32) callconv(.c) *FunctionInfo, .{ .name = "gi_enum_info_get_method" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_n_methods](https://docs.gtk.org/girepository/method.EnumInfo.get_n_methods.html)
    pub fn getNMethods(self: *EnumInfo) u32 {
        const cFn = @extern(*const fn (*EnumInfo) callconv(.c) u32, .{ .name = "gi_enum_info_get_n_methods" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_n_values](https://docs.gtk.org/girepository/method.EnumInfo.get_n_values.html)
    pub fn getNValues(self: *EnumInfo) u32 {
        const cFn = @extern(*const fn (*EnumInfo) callconv(.c) u32, .{ .name = "gi_enum_info_get_n_values" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_storage_type](https://docs.gtk.org/girepository/method.EnumInfo.get_storage_type.html)
    pub fn getStorageType(self: *EnumInfo) TypeTag {
        const cFn = @extern(*const fn (*EnumInfo) callconv(.c) TypeTag, .{ .name = "gi_enum_info_get_storage_type" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_value](https://docs.gtk.org/girepository/method.EnumInfo.get_value.html)
    pub fn getValue(self: *EnumInfo, _n: u32) *ValueInfo {
        const cFn = @extern(*const fn (*EnumInfo, u32) callconv(.c) *ValueInfo, .{ .name = "gi_enum_info_get_value" });
        const ret = cFn(self, _n);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_enum_info_get_type" });
        return cFn();
    }
};
/// Class [FieldInfo](https://docs.gtk.org/girepository/class.FieldInfo.html)
pub const FieldInfo = opaque {
    pub const Parent = BaseInfo;
    /// method [get_flags](https://docs.gtk.org/girepository/method.FieldInfo.get_flags.html)
    pub fn getFlags(self: *FieldInfo) FieldInfoFlags {
        const cFn = @extern(*const fn (*FieldInfo) callconv(.c) FieldInfoFlags, .{ .name = "gi_field_info_get_flags" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_offset](https://docs.gtk.org/girepository/method.FieldInfo.get_offset.html)
    pub fn getOffset(self: *FieldInfo) u64 {
        const cFn = @extern(*const fn (*FieldInfo) callconv(.c) u64, .{ .name = "gi_field_info_get_offset" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_size](https://docs.gtk.org/girepository/method.FieldInfo.get_size.html)
    pub fn getSize(self: *FieldInfo) u64 {
        const cFn = @extern(*const fn (*FieldInfo) callconv(.c) u64, .{ .name = "gi_field_info_get_size" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_type_info](https://docs.gtk.org/girepository/method.FieldInfo.get_type_info.html)
    pub fn getTypeInfo(self: *FieldInfo) *TypeInfo {
        const cFn = @extern(*const fn (*FieldInfo) callconv(.c) *TypeInfo, .{ .name = "gi_field_info_get_type_info" });
        const ret = cFn(self);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_field_info_get_type" });
        return cFn();
    }
};
/// Flags [FieldInfoFlags](https://docs.gtk.org/girepository/flags.FieldInfoFlags.html)
pub const FieldInfoFlags = packed struct(u32) {
    readable: bool = false,
    writable: bool = false,
    _: u30 = 0,
};
/// Class [FlagsInfo](https://docs.gtk.org/girepository/class.FlagsInfo.html)
pub const FlagsInfo = opaque {
    pub const Parent = EnumInfo;
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_flags_info_get_type" });
        return cFn();
    }
};
/// Class [FunctionInfo](https://docs.gtk.org/girepository/class.FunctionInfo.html)
pub const FunctionInfo = opaque {
    pub const Parent = CallableInfo;
    /// method [get_flags](https://docs.gtk.org/girepository/method.FunctionInfo.get_flags.html)
    pub fn getFlags(self: *FunctionInfo) FunctionInfoFlags {
        const cFn = @extern(*const fn (*FunctionInfo) callconv(.c) FunctionInfoFlags, .{ .name = "gi_function_info_get_flags" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_property](https://docs.gtk.org/girepository/method.FunctionInfo.get_property.html)
    pub fn getProperty(self: *FunctionInfo) ?*PropertyInfo {
        const cFn = @extern(*const fn (*FunctionInfo) callconv(.c) ?*PropertyInfo, .{ .name = "gi_function_info_get_property" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_symbol](https://docs.gtk.org/girepository/method.FunctionInfo.get_symbol.html)
    pub fn getSymbol(self: *FunctionInfo) [*:0]u8 {
        const cFn = @extern(*const fn (*FunctionInfo) callconv(.c) [*:0]u8, .{ .name = "gi_function_info_get_symbol" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_vfunc](https://docs.gtk.org/girepository/method.FunctionInfo.get_vfunc.html)
    pub fn getVfunc(self: *FunctionInfo) ?*VFuncInfo {
        const cFn = @extern(*const fn (*FunctionInfo) callconv(.c) ?*VFuncInfo, .{ .name = "gi_function_info_get_vfunc" });
        const ret = cFn(self);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_function_info_get_type" });
        return cFn();
    }
};
/// Flags [FunctionInfoFlags](https://docs.gtk.org/girepository/flags.FunctionInfoFlags.html)
pub const FunctionInfoFlags = gi.FunctionFlags;
/// Class [InterfaceInfo](https://docs.gtk.org/girepository/class.InterfaceInfo.html)
pub const InterfaceInfo = opaque {
    pub const Parent = RegisteredTypeInfo;
    /// method [find_method](https://docs.gtk.org/girepository/method.InterfaceInfo.find_method.html)
    pub fn findMethod(self: *InterfaceInfo, _name: [*:0]const u8) ?*FunctionInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, [*:0]const u8) callconv(.c) ?*FunctionInfo, .{ .name = "gi_interface_info_find_method" });
        const ret = cFn(self, _name);
        return ret;
    }
    /// method [find_signal](https://docs.gtk.org/girepository/method.InterfaceInfo.find_signal.html)
    pub fn findSignal(self: *InterfaceInfo, _name: [*:0]const u8) ?*SignalInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, [*:0]const u8) callconv(.c) ?*SignalInfo, .{ .name = "gi_interface_info_find_signal" });
        const ret = cFn(self, _name);
        return ret;
    }
    /// method [find_vfunc](https://docs.gtk.org/girepository/method.InterfaceInfo.find_vfunc.html)
    pub fn findVfunc(self: *InterfaceInfo, _name: [*:0]const u8) ?*VFuncInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, [*:0]const u8) callconv(.c) ?*VFuncInfo, .{ .name = "gi_interface_info_find_vfunc" });
        const ret = cFn(self, _name);
        return ret;
    }
    /// method [get_constant](https://docs.gtk.org/girepository/method.InterfaceInfo.get_constant.html)
    pub fn getConstant(self: *InterfaceInfo, _n: u32) *ConstantInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, u32) callconv(.c) *ConstantInfo, .{ .name = "gi_interface_info_get_constant" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_iface_struct](https://docs.gtk.org/girepository/method.InterfaceInfo.get_iface_struct.html)
    pub fn getIfaceStruct(self: *InterfaceInfo) ?*StructInfo {
        const cFn = @extern(*const fn (*InterfaceInfo) callconv(.c) ?*StructInfo, .{ .name = "gi_interface_info_get_iface_struct" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_method](https://docs.gtk.org/girepository/method.InterfaceInfo.get_method.html)
    pub fn getMethod(self: *InterfaceInfo, _n: u32) *FunctionInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, u32) callconv(.c) *FunctionInfo, .{ .name = "gi_interface_info_get_method" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_n_constants](https://docs.gtk.org/girepository/method.InterfaceInfo.get_n_constants.html)
    pub fn getNConstants(self: *InterfaceInfo) u32 {
        const cFn = @extern(*const fn (*InterfaceInfo) callconv(.c) u32, .{ .name = "gi_interface_info_get_n_constants" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_n_methods](https://docs.gtk.org/girepository/method.InterfaceInfo.get_n_methods.html)
    pub fn getNMethods(self: *InterfaceInfo) u32 {
        const cFn = @extern(*const fn (*InterfaceInfo) callconv(.c) u32, .{ .name = "gi_interface_info_get_n_methods" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_n_prerequisites](https://docs.gtk.org/girepository/method.InterfaceInfo.get_n_prerequisites.html)
    pub fn getNPrerequisites(self: *InterfaceInfo) u32 {
        const cFn = @extern(*const fn (*InterfaceInfo) callconv(.c) u32, .{ .name = "gi_interface_info_get_n_prerequisites" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_n_properties](https://docs.gtk.org/girepository/method.InterfaceInfo.get_n_properties.html)
    pub fn getNProperties(self: *InterfaceInfo) u32 {
        const cFn = @extern(*const fn (*InterfaceInfo) callconv(.c) u32, .{ .name = "gi_interface_info_get_n_properties" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_n_signals](https://docs.gtk.org/girepository/method.InterfaceInfo.get_n_signals.html)
    pub fn getNSignals(self: *InterfaceInfo) u32 {
        const cFn = @extern(*const fn (*InterfaceInfo) callconv(.c) u32, .{ .name = "gi_interface_info_get_n_signals" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_n_vfuncs](https://docs.gtk.org/girepository/method.InterfaceInfo.get_n_vfuncs.html)
    pub fn getNVfuncs(self: *InterfaceInfo) u32 {
        const cFn = @extern(*const fn (*InterfaceInfo) callconv(.c) u32, .{ .name = "gi_interface_info_get_n_vfuncs" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_prerequisite](https://docs.gtk.org/girepository/method.InterfaceInfo.get_prerequisite.html)
    pub fn getPrerequisite(self: *InterfaceInfo, _n: u32) *BaseInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, u32) callconv(.c) *BaseInfo, .{ .name = "gi_interface_info_get_prerequisite" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_property](https://docs.gtk.org/girepository/method.InterfaceInfo.get_property.html)
    pub fn getProperty(self: *InterfaceInfo, _n: u32) *PropertyInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, u32) callconv(.c) *PropertyInfo, .{ .name = "gi_interface_info_get_property" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_signal](https://docs.gtk.org/girepository/method.InterfaceInfo.get_signal.html)
    pub fn getSignal(self: *InterfaceInfo, _n: u32) *SignalInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, u32) callconv(.c) *SignalInfo, .{ .name = "gi_interface_info_get_signal" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_vfunc](https://docs.gtk.org/girepository/method.InterfaceInfo.get_vfunc.html)
    pub fn getVfunc(self: *InterfaceInfo, _n: u32) *VFuncInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, u32) callconv(.c) *VFuncInfo, .{ .name = "gi_interface_info_get_vfunc" });
        const ret = cFn(self, _n);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_interface_info_get_type" });
        return cFn();
    }
};
/// Error [InvokeError](https://docs.gtk.org/girepository/error.InvokeError.html)
pub const InvokeError = enum(u32) {
    failed = 0,
    symbol_not_found = 1,
    argument_mismatch = 2,
};
/// Class [ObjectInfo](https://docs.gtk.org/girepository/class.ObjectInfo.html)
pub const ObjectInfo = opaque {
    pub const Parent = RegisteredTypeInfo;
    /// method [find_method](https://docs.gtk.org/girepository/method.ObjectInfo.find_method.html)
    pub fn findMethod(self: *ObjectInfo, _name: [*:0]const u8) ?*FunctionInfo {
        const cFn = @extern(*const fn (*ObjectInfo, [*:0]const u8) callconv(.c) ?*FunctionInfo, .{ .name = "gi_object_info_find_method" });
        const ret = cFn(self, _name);
        return ret;
    }
    /// method [find_method_using_interfaces](https://docs.gtk.org/girepository/method.ObjectInfo.find_method_using_interfaces.html)
    pub fn findMethodUsingInterfaces(self: *ObjectInfo, _name: [*:0]const u8) struct {
        ret: ?*FunctionInfo,
        declarer: ?*BaseInfo,
    } {
        var declarer_out: ?*BaseInfo = undefined;
        const _declarer = &declarer_out;
        const cFn = @extern(*const fn (*ObjectInfo, [*:0]const u8, ?*?*BaseInfo) callconv(.c) ?*FunctionInfo, .{ .name = "gi_object_info_find_method_using_interfaces" });
        const ret = cFn(self, _name, _declarer);
        return .{ .ret = ret, .declarer = declarer_out };
    }
    /// method [find_signal](https://docs.gtk.org/girepository/method.ObjectInfo.find_signal.html)
    pub fn findSignal(self: *ObjectInfo, _name: [*:0]const u8) ?*SignalInfo {
        const cFn = @extern(*const fn (*ObjectInfo, [*:0]const u8) callconv(.c) ?*SignalInfo, .{ .name = "gi_object_info_find_signal" });
        const ret = cFn(self, _name);
        return ret;
    }
    /// method [find_vfunc](https://docs.gtk.org/girepository/method.ObjectInfo.find_vfunc.html)
    pub fn findVfunc(self: *ObjectInfo, _name: [*:0]const u8) ?*VFuncInfo {
        const cFn = @extern(*const fn (*ObjectInfo, [*:0]const u8) callconv(.c) ?*VFuncInfo, .{ .name = "gi_object_info_find_vfunc" });
        const ret = cFn(self, _name);
        return ret;
    }
    /// method [find_vfunc_using_interfaces](https://docs.gtk.org/girepository/method.ObjectInfo.find_vfunc_using_interfaces.html)
    pub fn findVfuncUsingInterfaces(self: *ObjectInfo, _name: [*:0]const u8) struct {
        ret: ?*VFuncInfo,
        declarer: ?*BaseInfo,
    } {
        var declarer_out: ?*BaseInfo = undefined;
        const _declarer = &declarer_out;
        const cFn = @extern(*const fn (*ObjectInfo, [*:0]const u8, ?*?*BaseInfo) callconv(.c) ?*VFuncInfo, .{ .name = "gi_object_info_find_vfunc_using_interfaces" });
        const ret = cFn(self, _name, _declarer);
        return .{ .ret = ret, .declarer = declarer_out };
    }
    /// method [get_abstract](https://docs.gtk.org/girepository/method.ObjectInfo.get_abstract.html)
    pub fn getAbstract(self: *ObjectInfo) bool {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) bool, .{ .name = "gi_object_info_get_abstract" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_class_struct](https://docs.gtk.org/girepository/method.ObjectInfo.get_class_struct.html)
    pub fn getClassStruct(self: *ObjectInfo) ?*StructInfo {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) ?*StructInfo, .{ .name = "gi_object_info_get_class_struct" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_constant](https://docs.gtk.org/girepository/method.ObjectInfo.get_constant.html)
    pub fn getConstant(self: *ObjectInfo, _n: u32) *ConstantInfo {
        const cFn = @extern(*const fn (*ObjectInfo, u32) callconv(.c) *ConstantInfo, .{ .name = "gi_object_info_get_constant" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_field](https://docs.gtk.org/girepository/method.ObjectInfo.get_field.html)
    pub fn getField(self: *ObjectInfo, _n: u32) *FieldInfo {
        const cFn = @extern(*const fn (*ObjectInfo, u32) callconv(.c) *FieldInfo, .{ .name = "gi_object_info_get_field" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_final](https://docs.gtk.org/girepository/method.ObjectInfo.get_final.html)
    pub fn getFinal(self: *ObjectInfo) bool {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) bool, .{ .name = "gi_object_info_get_final" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_fundamental](https://docs.gtk.org/girepository/method.ObjectInfo.get_fundamental.html)
    pub fn getFundamental(self: *ObjectInfo) bool {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) bool, .{ .name = "gi_object_info_get_fundamental" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_get_value_function_name](https://docs.gtk.org/girepository/method.ObjectInfo.get_get_value_function_name.html)
    pub fn getGetValueFunctionName(self: *ObjectInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_object_info_get_get_value_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_interface](https://docs.gtk.org/girepository/method.ObjectInfo.get_interface.html)
    pub fn getInterface(self: *ObjectInfo, _n: u32) *InterfaceInfo {
        const cFn = @extern(*const fn (*ObjectInfo, u32) callconv(.c) *InterfaceInfo, .{ .name = "gi_object_info_get_interface" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_method](https://docs.gtk.org/girepository/method.ObjectInfo.get_method.html)
    pub fn getMethod(self: *ObjectInfo, _n: u32) *FunctionInfo {
        const cFn = @extern(*const fn (*ObjectInfo, u32) callconv(.c) *FunctionInfo, .{ .name = "gi_object_info_get_method" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_n_constants](https://docs.gtk.org/girepository/method.ObjectInfo.get_n_constants.html)
    pub fn getNConstants(self: *ObjectInfo) u32 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) u32, .{ .name = "gi_object_info_get_n_constants" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_n_fields](https://docs.gtk.org/girepository/method.ObjectInfo.get_n_fields.html)
    pub fn getNFields(self: *ObjectInfo) u32 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) u32, .{ .name = "gi_object_info_get_n_fields" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_n_interfaces](https://docs.gtk.org/girepository/method.ObjectInfo.get_n_interfaces.html)
    pub fn getNInterfaces(self: *ObjectInfo) u32 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) u32, .{ .name = "gi_object_info_get_n_interfaces" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_n_methods](https://docs.gtk.org/girepository/method.ObjectInfo.get_n_methods.html)
    pub fn getNMethods(self: *ObjectInfo) u32 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) u32, .{ .name = "gi_object_info_get_n_methods" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_n_properties](https://docs.gtk.org/girepository/method.ObjectInfo.get_n_properties.html)
    pub fn getNProperties(self: *ObjectInfo) u32 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) u32, .{ .name = "gi_object_info_get_n_properties" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_n_signals](https://docs.gtk.org/girepository/method.ObjectInfo.get_n_signals.html)
    pub fn getNSignals(self: *ObjectInfo) u32 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) u32, .{ .name = "gi_object_info_get_n_signals" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_n_vfuncs](https://docs.gtk.org/girepository/method.ObjectInfo.get_n_vfuncs.html)
    pub fn getNVfuncs(self: *ObjectInfo) u32 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) u32, .{ .name = "gi_object_info_get_n_vfuncs" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_parent](https://docs.gtk.org/girepository/method.ObjectInfo.get_parent.html)
    pub fn getParent(self: *ObjectInfo) ?*ObjectInfo {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) ?*ObjectInfo, .{ .name = "gi_object_info_get_parent" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_property](https://docs.gtk.org/girepository/method.ObjectInfo.get_property.html)
    pub fn getProperty(self: *ObjectInfo, _n: u32) *PropertyInfo {
        const cFn = @extern(*const fn (*ObjectInfo, u32) callconv(.c) *PropertyInfo, .{ .name = "gi_object_info_get_property" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_ref_function_name](https://docs.gtk.org/girepository/method.ObjectInfo.get_ref_function_name.html)
    pub fn getRefFunctionName(self: *ObjectInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_object_info_get_ref_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_set_value_function_name](https://docs.gtk.org/girepository/method.ObjectInfo.get_set_value_function_name.html)
    pub fn getSetValueFunctionName(self: *ObjectInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_object_info_get_set_value_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_signal](https://docs.gtk.org/girepository/method.ObjectInfo.get_signal.html)
    pub fn getSignal(self: *ObjectInfo, _n: u32) *SignalInfo {
        const cFn = @extern(*const fn (*ObjectInfo, u32) callconv(.c) *SignalInfo, .{ .name = "gi_object_info_get_signal" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_type_init_function_name](https://docs.gtk.org/girepository/method.ObjectInfo.get_type_init_function_name.html)
    pub fn getTypeInitFunctionName(self: *ObjectInfo) [*:0]u8 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) [*:0]u8, .{ .name = "gi_object_info_get_type_init_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_type_name](https://docs.gtk.org/girepository/method.ObjectInfo.get_type_name.html)
    pub fn getTypeName(self: *ObjectInfo) [*:0]u8 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) [*:0]u8, .{ .name = "gi_object_info_get_type_name" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_unref_function_name](https://docs.gtk.org/girepository/method.ObjectInfo.get_unref_function_name.html)
    pub fn getUnrefFunctionName(self: *ObjectInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_object_info_get_unref_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_vfunc](https://docs.gtk.org/girepository/method.ObjectInfo.get_vfunc.html)
    pub fn getVfunc(self: *ObjectInfo, _n: u32) *VFuncInfo {
        const cFn = @extern(*const fn (*ObjectInfo, u32) callconv(.c) *VFuncInfo, .{ .name = "gi_object_info_get_vfunc" });
        const ret = cFn(self, _n);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_object_info_get_type" });
        return cFn();
    }
};
/// Class [PropertyInfo](https://docs.gtk.org/girepository/class.PropertyInfo.html)
pub const PropertyInfo = opaque {
    pub const Parent = BaseInfo;
    /// method [get_flags](https://docs.gtk.org/girepository/method.PropertyInfo.get_flags.html)
    pub fn getFlags(self: *PropertyInfo) core.ParamFlags {
        const cFn = @extern(*const fn (*PropertyInfo) callconv(.c) core.ParamFlags, .{ .name = "gi_property_info_get_flags" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_getter](https://docs.gtk.org/girepository/method.PropertyInfo.get_getter.html)
    pub fn getGetter(self: *PropertyInfo) ?*FunctionInfo {
        const cFn = @extern(*const fn (*PropertyInfo) callconv(.c) ?*FunctionInfo, .{ .name = "gi_property_info_get_getter" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_ownership_transfer](https://docs.gtk.org/girepository/method.PropertyInfo.get_ownership_transfer.html)
    pub fn getOwnershipTransfer(self: *PropertyInfo) Transfer {
        const cFn = @extern(*const fn (*PropertyInfo) callconv(.c) Transfer, .{ .name = "gi_property_info_get_ownership_transfer" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_setter](https://docs.gtk.org/girepository/method.PropertyInfo.get_setter.html)
    pub fn getSetter(self: *PropertyInfo) ?*FunctionInfo {
        const cFn = @extern(*const fn (*PropertyInfo) callconv(.c) ?*FunctionInfo, .{ .name = "gi_property_info_get_setter" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_type_info](https://docs.gtk.org/girepository/method.PropertyInfo.get_type_info.html)
    pub fn getTypeInfo(self: *PropertyInfo) *TypeInfo {
        const cFn = @extern(*const fn (*PropertyInfo) callconv(.c) *TypeInfo, .{ .name = "gi_property_info_get_type_info" });
        const ret = cFn(self);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_property_info_get_type" });
        return cFn();
    }
};
/// Class [RegisteredTypeInfo](https://docs.gtk.org/girepository/class.RegisteredTypeInfo.html)
pub const RegisteredTypeInfo = opaque {
    pub const Parent = BaseInfo;
    /// method [get_g_type](https://docs.gtk.org/girepository/method.RegisteredTypeInfo.get_g_type.html)
    pub fn getGType(self: *RegisteredTypeInfo) core.Type {
        const cFn = @extern(*const fn (*RegisteredTypeInfo) callconv(.c) core.Type, .{ .name = "gi_registered_type_info_get_g_type" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_type_init_function_name](https://docs.gtk.org/girepository/method.RegisteredTypeInfo.get_type_init_function_name.html)
    pub fn getTypeInitFunctionName(self: *RegisteredTypeInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*RegisteredTypeInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_registered_type_info_get_type_init_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_type_name](https://docs.gtk.org/girepository/method.RegisteredTypeInfo.get_type_name.html)
    pub fn getTypeName(self: *RegisteredTypeInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*RegisteredTypeInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_registered_type_info_get_type_name" });
        const ret = cFn(self);
        return ret;
    }
    /// method [is_boxed](https://docs.gtk.org/girepository/method.RegisteredTypeInfo.is_boxed.html)
    pub fn isBoxed(self: *RegisteredTypeInfo) bool {
        const cFn = @extern(*const fn (*RegisteredTypeInfo) callconv(.c) bool, .{ .name = "gi_registered_type_info_is_boxed" });
        const ret = cFn(self);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_registered_type_info_get_type" });
        return cFn();
    }
};
/// Class [Repository](https://docs.gtk.org/girepository/class.Repository.html)
pub const Repository = opaque {
    pub const Parent = core.Object;
    pub const Class = RepositoryClass;
    /// ctor [new](https://docs.gtk.org/girepository/ctor.Repository.new.html)
    pub fn new() *Repository {
        const cFn = @extern(*const fn () callconv(.c) *Repository, .{ .name = "gi_repository_new" });
        const ret = cFn();
        return ret;
    }
    /// type func [dump](https://docs.gtk.org/girepository/type_func.Repository.dump.html)
    pub fn dump(_input_filename: [*:0]const u8, _output_filename: [*:0]const u8, _error: *?*core.Error) error{GError}!bool {
        const cFn = @extern(*const fn ([*:0]const u8, [*:0]const u8, *?*core.Error) callconv(.c) bool, .{ .name = "gi_repository_dump" });
        const ret = cFn(_input_filename, _output_filename, _error);
        if (_error.* != null) return error.GError;
        return ret;
    }
    /// type func [error_quark](https://docs.gtk.org/girepository/type_func.Repository.error_quark.html)
    pub fn errorQuark() u32 {
        const cFn = @extern(*const fn () callconv(.c) u32, .{ .name = "gi_repository_error_quark" });
        const ret = cFn();
        return ret;
    }
    /// type func [get_option_group](https://docs.gtk.org/girepository/type_func.Repository.get_option_group.html)
    pub fn getOptionGroup() *core.OptionGroup {
        const cFn = @extern(*const fn () callconv(.c) *core.OptionGroup, .{ .name = "gi_repository_get_option_group" });
        const ret = cFn();
        return ret;
    }
    /// method [enumerate_versions](https://docs.gtk.org/girepository/method.Repository.enumerate_versions.html)
    pub fn enumerateVersions(self: *Repository, _namespace_: [*:0]const u8) struct {
        ret: [*][*:0]const u8,
        n_versions_out: u64,
    } {
        var n_versions_out_out: u64 = undefined;
        const _n_versions_out = &n_versions_out_out;
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, ?*u64) callconv(.c) [*][*:0]const u8, .{ .name = "gi_repository_enumerate_versions" });
        const ret = cFn(self, _namespace_, _n_versions_out);
        return .{ .ret = ret, .n_versions_out = n_versions_out_out };
    }
    /// method [find_by_error_domain](https://docs.gtk.org/girepository/method.Repository.find_by_error_domain.html)
    pub fn findByErrorDomain(self: *Repository, _domain: u32) ?*EnumInfo {
        const cFn = @extern(*const fn (*Repository, u32) callconv(.c) ?*EnumInfo, .{ .name = "gi_repository_find_by_error_domain" });
        const ret = cFn(self, _domain);
        return ret;
    }
    /// method [find_by_gtype](https://docs.gtk.org/girepository/method.Repository.find_by_gtype.html)
    pub fn findByGtype(self: *Repository, _gtype: core.Type) ?*BaseInfo {
        const cFn = @extern(*const fn (*Repository, core.Type) callconv(.c) ?*BaseInfo, .{ .name = "gi_repository_find_by_gtype" });
        const ret = cFn(self, _gtype);
        return ret;
    }
    /// method [find_by_name](https://docs.gtk.org/girepository/method.Repository.find_by_name.html)
    pub fn findByName(self: *Repository, _namespace_: [*:0]const u8, _name: [*:0]const u8) ?*BaseInfo {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, [*:0]const u8) callconv(.c) ?*BaseInfo, .{ .name = "gi_repository_find_by_name" });
        const ret = cFn(self, _namespace_, _name);
        return ret;
    }
    /// method [get_c_prefix](https://docs.gtk.org/girepository/method.Repository.get_c_prefix.html)
    pub fn getCPrefix(self: *Repository, _namespace_: [*:0]const u8) ?[*:0]u8 {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.c) ?[*:0]u8, .{ .name = "gi_repository_get_c_prefix" });
        const ret = cFn(self, _namespace_);
        return ret;
    }
    /// method [get_dependencies](https://docs.gtk.org/girepository/method.Repository.get_dependencies.html)
    pub fn getDependencies(self: *Repository, _namespace_: [*:0]const u8) struct {
        ret: [*][*:0]const u8,
        n_dependencies_out: u64,
    } {
        var n_dependencies_out_out: u64 = undefined;
        const _n_dependencies_out = &n_dependencies_out_out;
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, ?*u64) callconv(.c) [*][*:0]const u8, .{ .name = "gi_repository_get_dependencies" });
        const ret = cFn(self, _namespace_, _n_dependencies_out);
        return .{ .ret = ret, .n_dependencies_out = n_dependencies_out_out };
    }
    /// method [get_immediate_dependencies](https://docs.gtk.org/girepository/method.Repository.get_immediate_dependencies.html)
    pub fn getImmediateDependencies(self: *Repository, _namespace_: [*:0]const u8) struct {
        ret: [*][*:0]const u8,
        n_dependencies_out: u64,
    } {
        var n_dependencies_out_out: u64 = undefined;
        const _n_dependencies_out = &n_dependencies_out_out;
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, ?*u64) callconv(.c) [*][*:0]const u8, .{ .name = "gi_repository_get_immediate_dependencies" });
        const ret = cFn(self, _namespace_, _n_dependencies_out);
        return .{ .ret = ret, .n_dependencies_out = n_dependencies_out_out };
    }
    /// method [get_info](https://docs.gtk.org/girepository/method.Repository.get_info.html)
    pub fn getInfo(self: *Repository, _namespace_: [*:0]const u8, _idx: u32) *BaseInfo {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, u32) callconv(.c) *BaseInfo, .{ .name = "gi_repository_get_info" });
        const ret = cFn(self, _namespace_, _idx);
        return ret;
    }
    /// method [get_library_path](https://docs.gtk.org/girepository/method.Repository.get_library_path.html)
    pub fn getLibraryPath(self: *Repository) struct {
        ret: [*][*:0]const u8,
        n_paths_out: u64,
    } {
        var n_paths_out_out: u64 = undefined;
        const _n_paths_out = &n_paths_out_out;
        const cFn = @extern(*const fn (*Repository, ?*u64) callconv(.c) [*][*:0]const u8, .{ .name = "gi_repository_get_library_path" });
        const ret = cFn(self, _n_paths_out);
        return .{ .ret = ret, .n_paths_out = n_paths_out_out };
    }
    /// method [get_loaded_namespaces](https://docs.gtk.org/girepository/method.Repository.get_loaded_namespaces.html)
    pub fn getLoadedNamespaces(self: *Repository) struct {
        ret: [*][*:0]const u8,
        n_namespaces_out: u64,
    } {
        var n_namespaces_out_out: u64 = undefined;
        const _n_namespaces_out = &n_namespaces_out_out;
        const cFn = @extern(*const fn (*Repository, ?*u64) callconv(.c) [*][*:0]const u8, .{ .name = "gi_repository_get_loaded_namespaces" });
        const ret = cFn(self, _n_namespaces_out);
        return .{ .ret = ret, .n_namespaces_out = n_namespaces_out_out };
    }
    /// method [get_n_infos](https://docs.gtk.org/girepository/method.Repository.get_n_infos.html)
    pub fn getNInfos(self: *Repository, _namespace_: [*:0]const u8) u32 {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.c) u32, .{ .name = "gi_repository_get_n_infos" });
        const ret = cFn(self, _namespace_);
        return ret;
    }
    /// method [get_object_gtype_interfaces](https://docs.gtk.org/girepository/method.Repository.get_object_gtype_interfaces.html)
    pub fn getObjectGtypeInterfaces(self: *Repository, _gtype: core.Type) struct {
        ret: void,
        interfaces_out: []*InterfaceInfo,
    } {
        var n_interfaces_out_out: u64 = undefined;
        const _n_interfaces_out = &n_interfaces_out_out;
        var interfaces_out_out: [*]*InterfaceInfo = undefined;
        const _interfaces_out = &interfaces_out_out;
        const cFn = @extern(*const fn (*Repository, core.Type, *u64, *[*]*InterfaceInfo) callconv(.c) void, .{ .name = "gi_repository_get_object_gtype_interfaces" });
        const ret = cFn(self, _gtype, _n_interfaces_out, _interfaces_out);
        return .{ .ret = ret, .interfaces_out = interfaces_out_out[0..@intCast(n_interfaces_out_out)] };
    }
    /// method [get_search_path](https://docs.gtk.org/girepository/method.Repository.get_search_path.html)
    pub fn getSearchPath(self: *Repository) struct {
        ret: [*][*:0]const u8,
        n_paths_out: u64,
    } {
        var n_paths_out_out: u64 = undefined;
        const _n_paths_out = &n_paths_out_out;
        const cFn = @extern(*const fn (*Repository, ?*u64) callconv(.c) [*][*:0]const u8, .{ .name = "gi_repository_get_search_path" });
        const ret = cFn(self, _n_paths_out);
        return .{ .ret = ret, .n_paths_out = n_paths_out_out };
    }
    /// method [get_shared_libraries](https://docs.gtk.org/girepository/method.Repository.get_shared_libraries.html)
    pub fn getSharedLibraries(self: *Repository, _namespace_: [*:0]const u8) struct {
        ret: ?[*][*:0]const u8,
        out_n_elements: u64,
    } {
        var out_n_elements_out: u64 = undefined;
        const _out_n_elements = &out_n_elements_out;
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, ?*u64) callconv(.c) ?[*][*:0]const u8, .{ .name = "gi_repository_get_shared_libraries" });
        const ret = cFn(self, _namespace_, _out_n_elements);
        return .{ .ret = ret, .out_n_elements = out_n_elements_out };
    }
    /// method [get_typelib_path](https://docs.gtk.org/girepository/method.Repository.get_typelib_path.html)
    pub fn getTypelibPath(self: *Repository, _namespace_: [*:0]const u8) ?[*:0]u8 {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.c) ?[*:0]u8, .{ .name = "gi_repository_get_typelib_path" });
        const ret = cFn(self, _namespace_);
        return ret;
    }
    /// method [get_version](https://docs.gtk.org/girepository/method.Repository.get_version.html)
    pub fn getVersion(self: *Repository, _namespace_: [*:0]const u8) [*:0]u8 {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.c) [*:0]u8, .{ .name = "gi_repository_get_version" });
        const ret = cFn(self, _namespace_);
        return ret;
    }
    /// method [is_registered](https://docs.gtk.org/girepository/method.Repository.is_registered.html)
    pub fn isRegistered(self: *Repository, _namespace_: [*:0]const u8, _version: ?[*:0]const u8) bool {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, ?[*:0]const u8) callconv(.c) bool, .{ .name = "gi_repository_is_registered" });
        const ret = cFn(self, _namespace_, _version);
        return ret;
    }
    /// method [load_typelib](https://docs.gtk.org/girepository/method.Repository.load_typelib.html)
    pub fn loadTypelib(self: *Repository, _typelib: *Typelib, _flags: RepositoryLoadFlags, _error: *?*core.Error) error{GError}![*:0]u8 {
        const cFn = @extern(*const fn (*Repository, *Typelib, RepositoryLoadFlags, *?*core.Error) callconv(.c) [*:0]u8, .{ .name = "gi_repository_load_typelib" });
        const ret = cFn(self, _typelib, _flags, _error);
        if (_error.* != null) return error.GError;
        return ret;
    }
    /// method [prepend_library_path](https://docs.gtk.org/girepository/method.Repository.prepend_library_path.html)
    pub fn prependLibraryPath(self: *Repository, _directory: [*:0]const u8) void {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.c) void, .{ .name = "gi_repository_prepend_library_path" });
        const ret = cFn(self, _directory);
        return ret;
    }
    /// method [prepend_search_path](https://docs.gtk.org/girepository/method.Repository.prepend_search_path.html)
    pub fn prependSearchPath(self: *Repository, _directory: [*:0]const u8) void {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.c) void, .{ .name = "gi_repository_prepend_search_path" });
        const ret = cFn(self, _directory);
        return ret;
    }
    /// method [require](https://docs.gtk.org/girepository/method.Repository.require.html)
    pub fn require(self: *Repository, _namespace_: [*:0]const u8, _version: ?[*:0]const u8, _flags: RepositoryLoadFlags, _error: *?*core.Error) error{GError}!*Typelib {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, ?[*:0]const u8, RepositoryLoadFlags, *?*core.Error) callconv(.c) *Typelib, .{ .name = "gi_repository_require" });
        const ret = cFn(self, _namespace_, _version, _flags, _error);
        if (_error.* != null) return error.GError;
        return ret;
    }
    /// method [require_private](https://docs.gtk.org/girepository/method.Repository.require_private.html)
    pub fn requirePrivate(self: *Repository, _typelib_dir: [*:0]const u8, _namespace_: [*:0]const u8, _version: ?[*:0]const u8, _flags: RepositoryLoadFlags, _error: *?*core.Error) error{GError}!*Typelib {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, [*:0]const u8, ?[*:0]const u8, RepositoryLoadFlags, *?*core.Error) callconv(.c) *Typelib, .{ .name = "gi_repository_require_private" });
        const ret = cFn(self, _typelib_dir, _namespace_, _version, _flags, _error);
        if (_error.* != null) return error.GError;
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_repository_get_type" });
        return cFn();
    }
};
pub const RepositoryClass = extern struct {
    parent_class: core.ObjectClass,
};
/// Error [RepositoryError](https://docs.gtk.org/girepository/error.RepositoryError.html)
pub const RepositoryError = enum(u32) {
    typelib_not_found = 0,
    namespace_mismatch = 1,
    namespace_version_conflict = 2,
    library_not_found = 3,
};
/// Flags [RepositoryLoadFlags](https://docs.gtk.org/girepository/flags.RepositoryLoadFlags.html)
pub const RepositoryLoadFlags = packed struct(u32) {
    lazy: bool = false,
    _: u31 = 0,
};
/// Enum [ScopeType](https://docs.gtk.org/girepository/enum.ScopeType.html)
pub const ScopeType = gi.ScopeType;
/// Class [SignalInfo](https://docs.gtk.org/girepository/class.SignalInfo.html)
pub const SignalInfo = opaque {
    pub const Parent = CallableInfo;
    /// method [get_class_closure](https://docs.gtk.org/girepository/method.SignalInfo.get_class_closure.html)
    pub fn getClassClosure(self: *SignalInfo) ?*VFuncInfo {
        const cFn = @extern(*const fn (*SignalInfo) callconv(.c) ?*VFuncInfo, .{ .name = "gi_signal_info_get_class_closure" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_flags](https://docs.gtk.org/girepository/method.SignalInfo.get_flags.html)
    pub fn getFlags(self: *SignalInfo) core.SignalFlags {
        const cFn = @extern(*const fn (*SignalInfo) callconv(.c) core.SignalFlags, .{ .name = "gi_signal_info_get_flags" });
        const ret = cFn(self);
        return ret;
    }
    /// method [true_stops_emit](https://docs.gtk.org/girepository/method.SignalInfo.true_stops_emit.html)
    pub fn trueStopsEmit(self: *SignalInfo) bool {
        const cFn = @extern(*const fn (*SignalInfo) callconv(.c) bool, .{ .name = "gi_signal_info_true_stops_emit" });
        const ret = cFn(self);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_signal_info_get_type" });
        return cFn();
    }
};
/// Class [StructInfo](https://docs.gtk.org/girepository/class.StructInfo.html)
pub const StructInfo = opaque {
    pub const Parent = RegisteredTypeInfo;
    /// method [find_field](https://docs.gtk.org/girepository/method.StructInfo.find_field.html)
    pub fn findField(self: *StructInfo, _name: [*:0]const u8) ?*FieldInfo {
        const cFn = @extern(*const fn (*StructInfo, [*:0]const u8) callconv(.c) ?*FieldInfo, .{ .name = "gi_struct_info_find_field" });
        const ret = cFn(self, _name);
        return ret;
    }
    /// method [find_method](https://docs.gtk.org/girepository/method.StructInfo.find_method.html)
    pub fn findMethod(self: *StructInfo, _name: [*:0]const u8) ?*FunctionInfo {
        const cFn = @extern(*const fn (*StructInfo, [*:0]const u8) callconv(.c) ?*FunctionInfo, .{ .name = "gi_struct_info_find_method" });
        const ret = cFn(self, _name);
        return ret;
    }
    /// method [get_alignment](https://docs.gtk.org/girepository/method.StructInfo.get_alignment.html)
    pub fn getAlignment(self: *StructInfo) u64 {
        const cFn = @extern(*const fn (*StructInfo) callconv(.c) u64, .{ .name = "gi_struct_info_get_alignment" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_copy_function_name](https://docs.gtk.org/girepository/method.StructInfo.get_copy_function_name.html)
    pub fn getCopyFunctionName(self: *StructInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*StructInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_struct_info_get_copy_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_field](https://docs.gtk.org/girepository/method.StructInfo.get_field.html)
    pub fn getField(self: *StructInfo, _n: u32) *FieldInfo {
        const cFn = @extern(*const fn (*StructInfo, u32) callconv(.c) *FieldInfo, .{ .name = "gi_struct_info_get_field" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_free_function_name](https://docs.gtk.org/girepository/method.StructInfo.get_free_function_name.html)
    pub fn getFreeFunctionName(self: *StructInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*StructInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_struct_info_get_free_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_method](https://docs.gtk.org/girepository/method.StructInfo.get_method.html)
    pub fn getMethod(self: *StructInfo, _n: u32) *FunctionInfo {
        const cFn = @extern(*const fn (*StructInfo, u32) callconv(.c) *FunctionInfo, .{ .name = "gi_struct_info_get_method" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_n_fields](https://docs.gtk.org/girepository/method.StructInfo.get_n_fields.html)
    pub fn getNFields(self: *StructInfo) u32 {
        const cFn = @extern(*const fn (*StructInfo) callconv(.c) u32, .{ .name = "gi_struct_info_get_n_fields" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_n_methods](https://docs.gtk.org/girepository/method.StructInfo.get_n_methods.html)
    pub fn getNMethods(self: *StructInfo) u32 {
        const cFn = @extern(*const fn (*StructInfo) callconv(.c) u32, .{ .name = "gi_struct_info_get_n_methods" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_size](https://docs.gtk.org/girepository/method.StructInfo.get_size.html)
    pub fn getSize(self: *StructInfo) u64 {
        const cFn = @extern(*const fn (*StructInfo) callconv(.c) u64, .{ .name = "gi_struct_info_get_size" });
        const ret = cFn(self);
        return ret;
    }
    /// method [is_foreign](https://docs.gtk.org/girepository/method.StructInfo.is_foreign.html)
    pub fn isForeign(self: *StructInfo) bool {
        const cFn = @extern(*const fn (*StructInfo) callconv(.c) bool, .{ .name = "gi_struct_info_is_foreign" });
        const ret = cFn(self);
        return ret;
    }
    /// method [is_gtype_struct](https://docs.gtk.org/girepository/method.StructInfo.is_gtype_struct.html)
    pub fn isGtypeStruct(self: *StructInfo) bool {
        const cFn = @extern(*const fn (*StructInfo) callconv(.c) bool, .{ .name = "gi_struct_info_is_gtype_struct" });
        const ret = cFn(self);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_struct_info_get_type" });
        return cFn();
    }
};
/// const [TYPE_TAG_N_TYPES](https://docs.gtk.org/girepository/const.TYPE_TAG_N_TYPES.html)
pub const TYPE_TAG_N_TYPES = 22;
/// Enum [Transfer](https://docs.gtk.org/girepository/enum.Transfer.html)
pub const Transfer = gi.Transfer;
/// Class [TypeInfo](https://docs.gtk.org/girepository/class.TypeInfo.html)
pub const TypeInfo = extern struct {
    parent: BaseInfoStack,
    padding: [6]?*anyopaque,
    pub const Parent = BaseInfo;
    /// method [argument_from_hash_pointer](https://docs.gtk.org/girepository/method.TypeInfo.argument_from_hash_pointer.html)
    pub fn argumentFromHashPointer(self: *TypeInfo, _hash_pointer: ?*anyopaque, _arg: *Argument) void {
        const cFn = @extern(*const fn (*TypeInfo, ?*anyopaque, *Argument) callconv(.c) void, .{ .name = "gi_type_info_argument_from_hash_pointer" });
        const ret = cFn(self, @ptrCast(_hash_pointer), _arg);
        return ret;
    }
    /// method [get_array_fixed_size](https://docs.gtk.org/girepository/method.TypeInfo.get_array_fixed_size.html)
    pub fn getArrayFixedSize(self: *TypeInfo) ?u64 {
        var out_size_out: u64 = undefined;
        const _out_size = &out_size_out;
        const cFn = @extern(*const fn (*TypeInfo, ?*u64) callconv(.c) bool, .{ .name = "gi_type_info_get_array_fixed_size" });
        const ret = cFn(self, _out_size);
        if (!ret) return null;
        return out_size_out;
    }
    /// method [get_array_length_index](https://docs.gtk.org/girepository/method.TypeInfo.get_array_length_index.html)
    pub fn getArrayLengthIndex(self: *TypeInfo) ?u32 {
        var out_length_index_out: u32 = undefined;
        const _out_length_index = &out_length_index_out;
        const cFn = @extern(*const fn (*TypeInfo, ?*u32) callconv(.c) bool, .{ .name = "gi_type_info_get_array_length_index" });
        const ret = cFn(self, _out_length_index);
        if (!ret) return null;
        return out_length_index_out;
    }
    /// method [get_array_type](https://docs.gtk.org/girepository/method.TypeInfo.get_array_type.html)
    pub fn getArrayType(self: *TypeInfo) ArrayType {
        const cFn = @extern(*const fn (*TypeInfo) callconv(.c) ArrayType, .{ .name = "gi_type_info_get_array_type" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_interface](https://docs.gtk.org/girepository/method.TypeInfo.get_interface.html)
    pub fn getInterface(self: *TypeInfo) ?*BaseInfo {
        const cFn = @extern(*const fn (*TypeInfo) callconv(.c) ?*BaseInfo, .{ .name = "gi_type_info_get_interface" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_param_type](https://docs.gtk.org/girepository/method.TypeInfo.get_param_type.html)
    pub fn getParamType(self: *TypeInfo, _n: u32) ?*TypeInfo {
        const cFn = @extern(*const fn (*TypeInfo, u32) callconv(.c) ?*TypeInfo, .{ .name = "gi_type_info_get_param_type" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_storage_type](https://docs.gtk.org/girepository/method.TypeInfo.get_storage_type.html)
    pub fn getStorageType(self: *TypeInfo) TypeTag {
        const cFn = @extern(*const fn (*TypeInfo) callconv(.c) TypeTag, .{ .name = "gi_type_info_get_storage_type" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_tag](https://docs.gtk.org/girepository/method.TypeInfo.get_tag.html)
    pub fn getTag(self: *TypeInfo) TypeTag {
        const cFn = @extern(*const fn (*TypeInfo) callconv(.c) TypeTag, .{ .name = "gi_type_info_get_tag" });
        const ret = cFn(self);
        return ret;
    }
    /// method [hash_pointer_from_argument](https://docs.gtk.org/girepository/method.TypeInfo.hash_pointer_from_argument.html)
    pub fn hashPointerFromArgument(self: *TypeInfo, _arg: *Argument) ?*anyopaque {
        const cFn = @extern(*const fn (*TypeInfo, *Argument) callconv(.c) ?*anyopaque, .{ .name = "gi_type_info_hash_pointer_from_argument" });
        const ret = cFn(self, _arg);
        return ret;
    }
    /// method [is_pointer](https://docs.gtk.org/girepository/method.TypeInfo.is_pointer.html)
    pub fn isPointer(self: *TypeInfo) bool {
        const cFn = @extern(*const fn (*TypeInfo) callconv(.c) bool, .{ .name = "gi_type_info_is_pointer" });
        const ret = cFn(self);
        return ret;
    }
    /// method [is_zero_terminated](https://docs.gtk.org/girepository/method.TypeInfo.is_zero_terminated.html)
    pub fn isZeroTerminated(self: *TypeInfo) bool {
        const cFn = @extern(*const fn (*TypeInfo) callconv(.c) bool, .{ .name = "gi_type_info_is_zero_terminated" });
        const ret = cFn(self);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_type_info_get_type" });
        return cFn();
    }
};
/// Enum [TypeTag](https://docs.gtk.org/girepository/enum.TypeTag.html)
pub const TypeTag = gi.TypeTag;
/// Struct [Typelib](https://docs.gtk.org/girepository/struct.Typelib.html)
pub const Typelib = opaque {
    /// ctor [new_from_bytes](https://docs.gtk.org/girepository/ctor.Typelib.new_from_bytes.html)
    pub fn newFromBytes(_bytes: *core.Bytes, _error: *?*core.Error) error{GError}!*Typelib {
        const cFn = @extern(*const fn (*core.Bytes, *?*core.Error) callconv(.c) *Typelib, .{ .name = "gi_typelib_new_from_bytes" });
        const ret = cFn(_bytes, _error);
        if (_error.* != null) return error.GError;
        return ret;
    }
    /// method [get_namespace](https://docs.gtk.org/girepository/method.Typelib.get_namespace.html)
    pub fn getNamespace(self: *Typelib) [*:0]u8 {
        const cFn = @extern(*const fn (*Typelib) callconv(.c) [*:0]u8, .{ .name = "gi_typelib_get_namespace" });
        const ret = cFn(self);
        return ret;
    }
    /// method [ref](https://docs.gtk.org/girepository/method.Typelib.ref.html)
    pub fn ref(self: *Typelib) *Typelib {
        const cFn = @extern(*const fn (*Typelib) callconv(.c) *Typelib, .{ .name = "gi_typelib_ref" });
        const ret = cFn(self);
        return ret;
    }
    /// method [symbol](https://docs.gtk.org/girepository/method.Typelib.symbol.html)
    pub fn symbol(self: *Typelib, _symbol_name: [*:0]const u8) struct {
        ret: bool,
        symbol: ?*anyopaque,
    } {
        var symbol_out: ?*anyopaque = undefined;
        const _symbol = &symbol_out;
        const cFn = @extern(*const fn (*Typelib, [*:0]const u8, *anyopaque) callconv(.c) bool, .{ .name = "gi_typelib_symbol" });
        const ret = cFn(self, _symbol_name, @ptrCast(_symbol));
        return .{ .ret = ret, .symbol = symbol_out };
    }
    /// method [unref](https://docs.gtk.org/girepository/method.Typelib.unref.html)
    pub fn unref(self: *Typelib) void {
        const cFn = @extern(*const fn (*Typelib) callconv(.c) void, .{ .name = "gi_typelib_unref" });
        const ret = cFn(self);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_typelib_get_type" });
        return cFn();
    }
};
/// Class [UnionInfo](https://docs.gtk.org/girepository/class.UnionInfo.html)
pub const UnionInfo = opaque {
    pub const Parent = RegisteredTypeInfo;
    /// method [find_method](https://docs.gtk.org/girepository/method.UnionInfo.find_method.html)
    pub fn findMethod(self: *UnionInfo, _name: [*:0]const u8) ?*FunctionInfo {
        const cFn = @extern(*const fn (*UnionInfo, [*:0]const u8) callconv(.c) ?*FunctionInfo, .{ .name = "gi_union_info_find_method" });
        const ret = cFn(self, _name);
        return ret;
    }
    /// method [get_alignment](https://docs.gtk.org/girepository/method.UnionInfo.get_alignment.html)
    pub fn getAlignment(self: *UnionInfo) u64 {
        const cFn = @extern(*const fn (*UnionInfo) callconv(.c) u64, .{ .name = "gi_union_info_get_alignment" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_copy_function_name](https://docs.gtk.org/girepository/method.UnionInfo.get_copy_function_name.html)
    pub fn getCopyFunctionName(self: *UnionInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*UnionInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_union_info_get_copy_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_discriminator](https://docs.gtk.org/girepository/method.UnionInfo.get_discriminator.html)
    pub fn getDiscriminator(self: *UnionInfo, _n: u64) ?*ConstantInfo {
        const cFn = @extern(*const fn (*UnionInfo, u64) callconv(.c) ?*ConstantInfo, .{ .name = "gi_union_info_get_discriminator" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_discriminator_offset](https://docs.gtk.org/girepository/method.UnionInfo.get_discriminator_offset.html)
    pub fn getDiscriminatorOffset(self: *UnionInfo) ?u64 {
        var out_offset_out: u64 = undefined;
        const _out_offset = &out_offset_out;
        const cFn = @extern(*const fn (*UnionInfo, ?*u64) callconv(.c) bool, .{ .name = "gi_union_info_get_discriminator_offset" });
        const ret = cFn(self, _out_offset);
        if (!ret) return null;
        return out_offset_out;
    }
    /// method [get_discriminator_type](https://docs.gtk.org/girepository/method.UnionInfo.get_discriminator_type.html)
    pub fn getDiscriminatorType(self: *UnionInfo) ?*TypeInfo {
        const cFn = @extern(*const fn (*UnionInfo) callconv(.c) ?*TypeInfo, .{ .name = "gi_union_info_get_discriminator_type" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_field](https://docs.gtk.org/girepository/method.UnionInfo.get_field.html)
    pub fn getField(self: *UnionInfo, _n: u32) *FieldInfo {
        const cFn = @extern(*const fn (*UnionInfo, u32) callconv(.c) *FieldInfo, .{ .name = "gi_union_info_get_field" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_free_function_name](https://docs.gtk.org/girepository/method.UnionInfo.get_free_function_name.html)
    pub fn getFreeFunctionName(self: *UnionInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*UnionInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_union_info_get_free_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_method](https://docs.gtk.org/girepository/method.UnionInfo.get_method.html)
    pub fn getMethod(self: *UnionInfo, _n: u32) *FunctionInfo {
        const cFn = @extern(*const fn (*UnionInfo, u32) callconv(.c) *FunctionInfo, .{ .name = "gi_union_info_get_method" });
        const ret = cFn(self, _n);
        return ret;
    }
    /// method [get_n_fields](https://docs.gtk.org/girepository/method.UnionInfo.get_n_fields.html)
    pub fn getNFields(self: *UnionInfo) u32 {
        const cFn = @extern(*const fn (*UnionInfo) callconv(.c) u32, .{ .name = "gi_union_info_get_n_fields" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_n_methods](https://docs.gtk.org/girepository/method.UnionInfo.get_n_methods.html)
    pub fn getNMethods(self: *UnionInfo) u32 {
        const cFn = @extern(*const fn (*UnionInfo) callconv(.c) u32, .{ .name = "gi_union_info_get_n_methods" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_size](https://docs.gtk.org/girepository/method.UnionInfo.get_size.html)
    pub fn getSize(self: *UnionInfo) u64 {
        const cFn = @extern(*const fn (*UnionInfo) callconv(.c) u64, .{ .name = "gi_union_info_get_size" });
        const ret = cFn(self);
        return ret;
    }
    /// method [is_discriminated](https://docs.gtk.org/girepository/method.UnionInfo.is_discriminated.html)
    pub fn isDiscriminated(self: *UnionInfo) bool {
        const cFn = @extern(*const fn (*UnionInfo) callconv(.c) bool, .{ .name = "gi_union_info_is_discriminated" });
        const ret = cFn(self);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_union_info_get_type" });
        return cFn();
    }
};
/// Class [UnresolvedInfo](https://docs.gtk.org/girepository/class.UnresolvedInfo.html)
pub const UnresolvedInfo = opaque {
    pub const Parent = BaseInfo;
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_unresolved_info_get_type" });
        return cFn();
    }
};
/// Class [VFuncInfo](https://docs.gtk.org/girepository/class.VFuncInfo.html)
pub const VFuncInfo = opaque {
    pub const Parent = CallableInfo;
    /// method [get_address](https://docs.gtk.org/girepository/method.VFuncInfo.get_address.html)
    pub fn getAddress(self: *VFuncInfo, _implementor_gtype: core.Type, _error: *?*core.Error) error{GError}!?*anyopaque {
        const cFn = @extern(*const fn (*VFuncInfo, core.Type, *?*core.Error) callconv(.c) ?*anyopaque, .{ .name = "gi_vfunc_info_get_address" });
        const ret = cFn(self, _implementor_gtype, _error);
        if (_error.* != null) return error.GError;
        return ret;
    }
    /// method [get_flags](https://docs.gtk.org/girepository/method.VFuncInfo.get_flags.html)
    pub fn getFlags(self: *VFuncInfo) VFuncInfoFlags {
        const cFn = @extern(*const fn (*VFuncInfo) callconv(.c) VFuncInfoFlags, .{ .name = "gi_vfunc_info_get_flags" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_invoker](https://docs.gtk.org/girepository/method.VFuncInfo.get_invoker.html)
    pub fn getInvoker(self: *VFuncInfo) ?*FunctionInfo {
        const cFn = @extern(*const fn (*VFuncInfo) callconv(.c) ?*FunctionInfo, .{ .name = "gi_vfunc_info_get_invoker" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_offset](https://docs.gtk.org/girepository/method.VFuncInfo.get_offset.html)
    pub fn getOffset(self: *VFuncInfo) u64 {
        const cFn = @extern(*const fn (*VFuncInfo) callconv(.c) u64, .{ .name = "gi_vfunc_info_get_offset" });
        const ret = cFn(self);
        return ret;
    }
    /// method [get_signal](https://docs.gtk.org/girepository/method.VFuncInfo.get_signal.html)
    pub fn getSignal(self: *VFuncInfo) ?*SignalInfo {
        const cFn = @extern(*const fn (*VFuncInfo) callconv(.c) ?*SignalInfo, .{ .name = "gi_vfunc_info_get_signal" });
        const ret = cFn(self);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_vfunc_info_get_type" });
        return cFn();
    }
};
/// Flags [VFuncInfoFlags](https://docs.gtk.org/girepository/flags.VFuncInfoFlags.html)
pub const VFuncInfoFlags = packed struct(u32) {
    chain_up: bool = false,
    override: bool = false,
    not_override: bool = false,
    _: u29 = 0,
};
/// Class [ValueInfo](https://docs.gtk.org/girepository/class.ValueInfo.html)
pub const ValueInfo = opaque {
    pub const Parent = BaseInfo;
    /// method [get_value](https://docs.gtk.org/girepository/method.ValueInfo.get_value.html)
    pub fn getValue(self: *ValueInfo) i64 {
        const cFn = @extern(*const fn (*ValueInfo) callconv(.c) i64, .{ .name = "gi_value_info_get_value" });
        const ret = cFn(self);
        return ret;
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_value_info_get_type" });
        return cFn();
    }
};
/// func [invoke_error_quark](https://docs.gtk.org/girepository/func.invoke_error_quark.html)
pub fn invokeErrorQuark() u32 {
    const cFn = @extern(*const fn () callconv(.c) u32, .{ .name = "gi_invoke_error_quark" });
    const ret = cFn();
    return ret;
}
/// func [type_tag_argument_from_hash_pointer](https://docs.gtk.org/girepository/func.type_tag_argument_from_hash_pointer.html)
pub fn typeTagArgumentFromHashPointer(_storage_type: TypeTag, _hash_pointer: ?*anyopaque, _arg: *Argument) void {
    const cFn = @extern(*const fn (TypeTag, ?*anyopaque, *Argument) callconv(.c) void, .{ .name = "gi_type_tag_argument_from_hash_pointer" });
    const ret = cFn(_storage_type, @ptrCast(_hash_pointer), _arg);
    return ret;
}
/// func [type_tag_hash_pointer_from_argument](https://docs.gtk.org/girepository/func.type_tag_hash_pointer_from_argument.html)
pub fn typeTagHashPointerFromArgument(_storage_type: TypeTag, _arg: *Argument) ?*anyopaque {
    const cFn = @extern(*const fn (TypeTag, *Argument) callconv(.c) ?*anyopaque, .{ .name = "gi_type_tag_hash_pointer_from_argument" });
    const ret = cFn(_storage_type, _arg);
    return ret;
}
/// func [type_tag_to_string](https://docs.gtk.org/girepository/func.type_tag_to_string.html)
pub fn typeTagToString(_type: TypeTag) [*:0]u8 {
    const cFn = @extern(*const fn (TypeTag) callconv(.c) [*:0]u8, .{ .name = "gi_type_tag_to_string" });
    const ret = cFn(_type);
    return ret;
}
