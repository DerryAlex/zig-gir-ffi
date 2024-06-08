pub const core = @import("core_min.zig");
const std = @import("std");
const assert = std.debug.assert;
const ext = @import("gi-ext.zig");

pub const Argument = extern union {
    v_boolean: bool,
    v_int8: i8,
    v_uint8: u8,
    v_int16: i16,
    v_uint16: u16,
    v_int32: i32,
    v_uint32: u32,
    v_int64: i64,
    v_uint64: u64,
    v_float: f32,
    v_double: f64,
    v_short: i16,
    v_ushort: u16,
    v_int: i32,
    v_uint: u32,
    v_long: i64,
    v_ulong: u64,
    v_ssize: i64,
    v_size: u64,
    v_string: ?[*:0]const u8,
    v_pointer: ?*anyopaque,
};
pub const ArrayType = enum(u32) {
    c = 0,
    array = 1,
    ptr_array = 2,
    byte_array = 3,
};
pub const AttributeIter = extern struct {
    data: ?*anyopaque,
    data2: ?*anyopaque,
    data3: ?*anyopaque,
    data4: ?*anyopaque,
};
pub const BaseInfo = extern struct {
    dummy1: i32,
    dummy2: i32,
    dummy3: ?*anyopaque,
    dummy4: ?*anyopaque,
    dummy5: ?*anyopaque,
    dummy6: u32,
    dummy7: u32,
    padding: [4]?*anyopaque,

    pub fn equal(self: *BaseInfo, _info2: *BaseInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo, *BaseInfo) callconv(.C) bool, .{ .name = "g_base_info_equal" });
        const ret = cFn(self, _info2);
        return ret;
    }

    pub fn getAttribute(self: *BaseInfo, _name: [*:0]const u8) [*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo, [*:0]const u8) callconv(.C) [*:0]u8, .{ .name = "g_base_info_get_attribute" });
        const ret = cFn(self, _name);
        return ret;
    }

    pub fn getContainer(self: *BaseInfo) ?*BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) ?*BaseInfo, .{ .name = "g_base_info_get_container" });
        const ret = cFn(self);
        return ret;
    }

    pub fn getName(self: *BaseInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) ?[*:0]u8, .{ .name = "g_base_info_get_name" });
        const ret = cFn(self);
        return ret;
    }

    pub fn getNamespace(self: *BaseInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) ?[*:0]u8, .{ .name = "g_base_info_get_namespace" });
        const ret = cFn(self);
        return ret;
    }

    pub fn getType(self: *BaseInfo) InfoType {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) InfoType, .{ .name = "g_base_info_get_type" });
        const ret = cFn(self);
        return ret;
    }

    pub fn getTypelib(self: *BaseInfo) *Typelib {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) *Typelib, .{ .name = "g_base_info_get_typelib" });
        const ret = cFn(self);
        return ret;
    }

    pub fn isDeprecated(self: *BaseInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_base_info_is_deprecated" });
        const ret = cFn(self);
        return ret;
    }

    pub fn iterateAttributes(self: *BaseInfo, _iterator: *AttributeIter) error{BooleanError}!struct {
        name: [*:0]u8,
        value: [*:0]u8,
    } {
        var name_out: [*:0]u8 = undefined;
        const _name = &name_out;
        var value_out: [*:0]u8 = undefined;
        const _value = &value_out;
        const cFn = @extern(*const fn (*BaseInfo, *AttributeIter, *[*:0]u8, *[*:0]u8) callconv(.C) bool, .{ .name = "g_base_info_iterate_attributes" });
        const ret = cFn(self, _iterator, _name, _value);
        if (ret) return error.BooleanError;
        return .{ .name = name_out, .value = value_out };
    }
    pub usingnamespace core.Extend(@This());
};
pub const Direction = enum(u32) {
    in = 0,
    out = 1,
    inout = 2,
};
pub const FieldInfoFlags = packed struct(u32) {
    readable: bool = false,
    writable: bool = false,
    _: u30 = 0,
    pub const readable: @This() = @bitCast(1);
    pub const writable: @This() = @bitCast(2);
};
pub const FunctionInfoFlags = packed struct(u32) {
    is_method: bool = false,
    is_constructor: bool = false,
    is_getter: bool = false,
    is_setter: bool = false,
    wraps_vfunc: bool = false,
    throws: bool = false,
    _: u26 = 0,
};
pub const InfoType = enum(u32) {
    invalid = 0,
    function = 1,
    callback = 2,
    @"struct" = 3,
    boxed = 4,
    @"enum" = 5,
    flags = 6,
    object = 7,
    interface = 8,
    constant = 9,
    invalid_0 = 10,
    @"union" = 11,
    value = 12,
    signal = 13,
    vfunc = 14,
    property = 15,
    field = 16,
    arg = 17,
    type = 18,
    unresolved = 19,

    pub fn toString(_type: InfoType) [*:0]u8 {
        const cFn = @extern(*const fn (InfoType) callconv(.C) [*:0]u8, .{ .name = "g_info_type_to_string" });
        const ret = cFn(_type);
        return ret;
    }
};
pub const Repository = extern struct {
    parent: core.Object,
    priv: ?*RepositoryPrivate,
    pub const Parent = core.Object;
    pub fn dump(_arg: [*:0]const u8) error{GError}!bool {
        var _error: ?*core.Error = null;
        const cFn = @extern(*const fn ([*:0]const u8, *?*core.Error) callconv(.C) bool, .{ .name = "g_irepository_dump" });
        const ret = cFn(_arg, &_error);
        if (_error) |some| {
            core.setError(some);
            return error.GError;
        }
        return ret;
    }

    pub fn errorQuark() u32 {
        const cFn = @extern(*const fn () callconv(.C) u32, .{ .name = "g_irepository_error_quark" });
        const ret = cFn();
        return ret;
    }

    pub fn getDefault() *Repository {
        const cFn = @extern(*const fn () callconv(.C) *Repository, .{ .name = "g_irepository_get_default" });
        const ret = cFn();
        return ret;
    }

    pub fn getOptionGroup() *core.OptionGroup {
        const cFn = @extern(*const fn () callconv(.C) *core.OptionGroup, .{ .name = "g_irepository_get_option_group" });
        const ret = cFn();
        return ret;
    }

    pub fn getSearchPath() ?*core.SList {
        const cFn = @extern(*const fn () callconv(.C) ?*core.SList, .{ .name = "g_irepository_get_search_path" });
        const ret = cFn();
        return ret;
    }

    pub fn prependLibraryPath(_directory: [*:0]const u8) void {
        const cFn = @extern(*const fn ([*:0]const u8) callconv(.C) void, .{ .name = "g_irepository_prepend_library_path" });
        const ret = cFn(_directory);
        return ret;
    }

    pub fn prependSearchPath(_directory: [*:0]const u8) void {
        const cFn = @extern(*const fn ([*:0]const u8) callconv(.C) void, .{ .name = "g_irepository_prepend_search_path" });
        const ret = cFn(_directory);
        return ret;
    }

    pub fn enumerateVersions(self: *Repository, _namespace_: [*:0]const u8) ?*core.List {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.C) ?*core.List, .{ .name = "g_irepository_enumerate_versions" });
        const ret = cFn(self, _namespace_);
        return ret;
    }

    pub fn findByErrorDomain(self: *Repository, _domain: u32) *BaseInfo {
        const cFn = @extern(*const fn (*Repository, u32) callconv(.C) *BaseInfo, .{ .name = "g_irepository_find_by_error_domain" });
        const ret = cFn(self, _domain);
        return ret;
    }

    pub fn findByGtype(self: *Repository, _gtype: core.Type) *BaseInfo {
        const cFn = @extern(*const fn (*Repository, core.Type) callconv(.C) *BaseInfo, .{ .name = "g_irepository_find_by_gtype" });
        const ret = cFn(self, _gtype);
        return ret;
    }

    pub fn findByName(self: *Repository, _namespace_: [*:0]const u8, _name: [*:0]const u8) *BaseInfo {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, [*:0]const u8) callconv(.C) *BaseInfo, .{ .name = "g_irepository_find_by_name" });
        const ret = cFn(self, _namespace_, _name);
        return ret;
    }

    pub fn getCPrefix(self: *Repository, _namespace_: [*:0]const u8) [*:0]u8 {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.C) [*:0]u8, .{ .name = "g_irepository_get_c_prefix" });
        const ret = cFn(self, _namespace_);
        return ret;
    }

    pub fn getDependencies(self: *Repository, _namespace_: [*:0]const u8) [*:null]?[*:0]const u8 {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.C) [*:null]?[*:0]const u8, .{ .name = "g_irepository_get_dependencies" });
        const ret = cFn(self, _namespace_);
        return ret;
    }

    pub fn getImmediateDependencies(self: *Repository, _namespace_: [*:0]const u8) [*:null]?[*:0]const u8 {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.C) [*:null]?[*:0]const u8, .{ .name = "g_irepository_get_immediate_dependencies" });
        const ret = cFn(self, _namespace_);
        return ret;
    }

    pub fn getInfo(self: *Repository, _namespace_: [*:0]const u8, _index: i32) *BaseInfo {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, i32) callconv(.C) *BaseInfo, .{ .name = "g_irepository_get_info" });
        const ret = cFn(self, _namespace_, _index);
        return ret;
    }

    pub fn getLoadedNamespaces(self: *Repository) [*:null]?[*:0]const u8 {
        const cFn = @extern(*const fn (*Repository) callconv(.C) [*:null]?[*:0]const u8, .{ .name = "g_irepository_get_loaded_namespaces" });
        const ret = cFn(self);
        return ret;
    }

    pub fn getNInfos(self: *Repository, _namespace_: [*:0]const u8) i32 {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.C) i32, .{ .name = "g_irepository_get_n_infos" });
        const ret = cFn(self, _namespace_);
        return ret;
    }

    pub fn getObjectGtypeInterfaces(self: *Repository, _gtype: core.Type) struct {
        ret: void,
        interfaces_out: []*BaseInfo,
    } {
        var n_interfaces_out_out: u32 = undefined;
        const _n_interfaces_out = &n_interfaces_out_out;
        var interfaces_out_out: [*]*BaseInfo = undefined;
        const _interfaces_out = &interfaces_out_out;
        const cFn = @extern(*const fn (*Repository, core.Type, *u32, *[*]*BaseInfo) callconv(.C) void, .{ .name = "g_irepository_get_object_gtype_interfaces" });
        const ret = cFn(self, _gtype, _n_interfaces_out, _interfaces_out);
        return .{ .ret = ret, .interfaces_out = interfaces_out_out[0..@intCast(n_interfaces_out_out)] };
    }

    pub fn getSharedLibrary(self: *Repository, _namespace_: [*:0]const u8) ?[*:0]u8 {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.C) ?[*:0]u8, .{ .name = "g_irepository_get_shared_library" });
        const ret = cFn(self, _namespace_);
        return ret;
    }

    pub fn getTypelibPath(self: *Repository, _namespace_: [*:0]const u8) [*:0]u8 {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.C) [*:0]u8, .{ .name = "g_irepository_get_typelib_path" });
        const ret = cFn(self, _namespace_);
        return ret;
    }

    pub fn getVersion(self: *Repository, _namespace_: [*:0]const u8) [*:0]u8 {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.C) [*:0]u8, .{ .name = "g_irepository_get_version" });
        const ret = cFn(self, _namespace_);
        return ret;
    }

    pub fn isRegistered(self: *Repository, _namespace_: [*:0]const u8, _version: ?[*:0]const u8) bool {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, ?[*:0]const u8) callconv(.C) bool, .{ .name = "g_irepository_is_registered" });
        const ret = cFn(self, _namespace_, _version);
        return ret;
    }

    pub fn loadTypelib(self: *Repository, _typelib: *Typelib, _flags: RepositoryLoadFlags) error{GError}![*:0]u8 {
        var _error: ?*core.Error = null;
        const cFn = @extern(*const fn (*Repository, *Typelib, RepositoryLoadFlags, *?*core.Error) callconv(.C) [*:0]u8, .{ .name = "g_irepository_load_typelib" });
        const ret = cFn(self, _typelib, _flags, &_error);
        if (_error) |some| {
            core.setError(some);
            return error.GError;
        }
        return ret;
    }

    pub fn require(self: *Repository, _namespace_: [*:0]const u8, _version: ?[*:0]const u8, _flags: RepositoryLoadFlags) error{GError}!*Typelib {
        var _error: ?*core.Error = null;
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, ?[*:0]const u8, RepositoryLoadFlags, *?*core.Error) callconv(.C) *Typelib, .{ .name = "g_irepository_require" });
        const ret = cFn(self, _namespace_, _version, _flags, &_error);
        if (_error) |some| {
            core.setError(some);
            return error.GError;
        }
        return ret;
    }

    pub fn requirePrivate(self: *Repository, _typelib_dir: [*:0]const u8, _namespace_: [*:0]const u8, _version: ?[*:0]const u8, _flags: RepositoryLoadFlags) error{GError}!*Typelib {
        var _error: ?*core.Error = null;
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, [*:0]const u8, ?[*:0]const u8, RepositoryLoadFlags, *?*core.Error) callconv(.C) *Typelib, .{ .name = "g_irepository_require_private" });
        const ret = cFn(self, _typelib_dir, _namespace_, _version, _flags, &_error);
        if (_error) |some| {
            core.setError(some);
            return error.GError;
        }
        return ret;
    }
    pub usingnamespace core.Extend(@This());
};
pub const RepositoryError = enum(u32) {
    typelib_not_found = 0,
    namespace_mismatch = 1,
    namespace_version_conflict = 2,
    library_not_found = 3,
};
pub const RepositoryLoadFlags = packed struct(u32) {
    irepository_load_flag_lazy: bool = false,
    _: u31 = 0,
    pub const irepository_load_flag_lazy: @This() = @bitCast(1);
};
pub const RepositoryPrivate = opaque {};
pub const ScopeType = enum(u32) {
    invalid = 0,
    call = 1,
    @"async" = 2,
    notified = 3,
    forever = 4,
};
pub const Transfer = enum(u32) {
    nothing = 0,
    container = 1,
    everything = 2,
};
pub const TypeTag = enum(u32) {
    void = 0,
    boolean = 1,
    int8 = 2,
    uint8 = 3,
    int16 = 4,
    uint16 = 5,
    int32 = 6,
    uint32 = 7,
    int64 = 8,
    uint64 = 9,
    float = 10,
    double = 11,
    gtype = 12,
    utf8 = 13,
    filename = 14,
    array = 15,
    interface = 16,
    glist = 17,
    gslist = 18,
    ghash = 19,
    @"error" = 20,
    unichar = 21,

    pub fn argumentFromHashPointer(_storage_type: TypeTag, _hash_pointer: ?*anyopaque, _arg: *Argument) void {
        const cFn = @extern(*const fn (TypeTag, ?*anyopaque, *Argument) callconv(.C) void, .{ .name = "gi_type_tag_argument_from_hash_pointer" });
        const ret = cFn(_storage_type, _hash_pointer, _arg);
        return ret;
    }

    pub fn hashPointerFromArgument(_storage_type: TypeTag, _arg: *Argument) ?*anyopaque {
        const cFn = @extern(*const fn (TypeTag, *Argument) callconv(.C) ?*anyopaque, .{ .name = "gi_type_tag_hash_pointer_from_argument" });
        const ret = cFn(_storage_type, _arg);
        return ret;
    }

    pub fn toString(_type: TypeTag) [*:0]u8 {
        const cFn = @extern(*const fn (TypeTag) callconv(.C) [*:0]u8, .{ .name = "g_type_tag_to_string" });
        const ret = cFn(_type);
        return ret;
    }
};
pub const Typelib = opaque {
    pub fn free(self: *Typelib) void {
        const cFn = @extern(*const fn (*Typelib) callconv(.C) void, .{ .name = "g_typelib_free" });
        const ret = cFn(self);
        return ret;
    }

    pub fn getNamespace(self: *Typelib) [*:0]u8 {
        const cFn = @extern(*const fn (*Typelib) callconv(.C) [*:0]u8, .{ .name = "g_typelib_get_namespace" });
        const ret = cFn(self);
        return ret;
    }

    pub fn symbol(self: *Typelib, _symbol_name: [*:0]const u8, _symbol: ?*anyopaque) bool {
        const cFn = @extern(*const fn (*Typelib, [*:0]const u8, ?*anyopaque) callconv(.C) bool, .{ .name = "g_typelib_symbol" });
        const ret = cFn(self, _symbol_name, _symbol);
        return ret;
    }
};
pub const UnresolvedInfo = opaque {};
pub const VFuncInfoFlags = packed struct(u32) {
    must_chain_up: bool = false,
    must_override: bool = false,
    must_not_override: bool = false,
    throws: bool = false,
    _: u28 = 0,
};
pub const ArgInfo = extern struct {
    parent: BaseInfo,
    pub const Parent = BaseInfo;
    pub fn getClosure(self: *ArgInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_arg_info_get_closure" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getDestroy(self: *ArgInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_arg_info_get_destroy" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getDirection(self: *ArgInfo) Direction {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) Direction, .{ .name = "g_arg_info_get_direction" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getOwnershipTransfer(self: *ArgInfo) Transfer {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) Transfer, .{ .name = "g_arg_info_get_ownership_transfer" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getScope(self: *ArgInfo) ScopeType {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) ScopeType, .{ .name = "g_arg_info_get_scope" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getType(self: *ArgInfo) *TypeInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) *BaseInfo, .{ .name = "g_arg_info_get_type" });
        const ret = cFn(self.into(BaseInfo)).tryInto(TypeInfo).?;
        return ret;
    }

    pub fn isCallerAllocates(self: *ArgInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_arg_info_is_caller_allocates" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn isOptional(self: *ArgInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_arg_info_is_optional" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn isReturnValue(self: *ArgInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_arg_info_is_return_value" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn isSkip(self: *ArgInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_arg_info_is_skip" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn loadType(self: *ArgInfo, _type: *BaseInfo) void {
        const cFn = @extern(*const fn (*BaseInfo, *BaseInfo) callconv(.C) void, .{ .name = "g_arg_info_load_type" });
        const ret = cFn(self.into(BaseInfo), _type);
        return ret;
    }

    pub fn mayBeNull(self: *ArgInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_arg_info_may_be_null" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.ArgInfoExt;
};
pub const CallableInfo = extern struct {
    parent: BaseInfo,
    pub const Parent = BaseInfo;
    pub fn canThrowGerror(self: *CallableInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_callable_info_can_throw_gerror" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getArg(self: *CallableInfo, _n: i32) *ArgInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_callable_info_get_arg" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(ArgInfo).?;
        return ret;
    }

    pub fn getCallerOwns(self: *CallableInfo) Transfer {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) Transfer, .{ .name = "g_callable_info_get_caller_owns" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getInstanceOwnershipTransfer(self: *CallableInfo) Transfer {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) Transfer, .{ .name = "g_callable_info_get_instance_ownership_transfer" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getNArgs(self: *CallableInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_callable_info_get_n_args" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getReturnAttribute(self: *CallableInfo, _name: [*:0]const u8) [*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo, [*:0]const u8) callconv(.C) [*:0]u8, .{ .name = "g_callable_info_get_return_attribute" });
        const ret = cFn(self.into(BaseInfo), _name);
        return ret;
    }

    pub fn getReturnType(self: *CallableInfo) *TypeInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) *BaseInfo, .{ .name = "g_callable_info_get_return_type" });
        const ret = cFn(self.into(BaseInfo)).tryInto(TypeInfo).?;
        return ret;
    }

    pub fn invoke(self: *CallableInfo, _function: ?*anyopaque, _in_argss: []Argument, _out_argss: []Argument, _return_value: *Argument, _is_method: bool, _throws: bool) error{GError}!bool {
        var _error: ?*core.Error = null;
        const _in_args = _in_argss.ptr;
        const _n_in_args: i32 = @intCast(_in_argss.len);
        const _out_args = _out_argss.ptr;
        const _n_out_args: i32 = @intCast(_out_argss.len);
        const cFn = @extern(*const fn (*BaseInfo, ?*anyopaque, [*]Argument, i32, [*]Argument, i32, *Argument, bool, bool, *?*core.Error) callconv(.C) bool, .{ .name = "g_callable_info_invoke" });
        const ret = cFn(self.into(BaseInfo), _function, _in_args, _n_in_args, _out_args, _n_out_args, _return_value, _is_method, _throws, &_error);
        if (_error) |some| {
            core.setError(some);
            return error.GError;
        }
        return ret;
    }

    pub fn isMethod(self: *CallableInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_callable_info_is_method" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn iterateReturnAttributes(self: *CallableInfo, _iterator: *AttributeIter) error{BooleanError}!struct {
        name: [*:0]u8,
        value: [*:0]u8,
    } {
        var name_out: [*:0]u8 = undefined;
        const _name = &name_out;
        var value_out: [*:0]u8 = undefined;
        const _value = &value_out;
        const cFn = @extern(*const fn (*BaseInfo, *AttributeIter, *[*:0]u8, *[*:0]u8) callconv(.C) bool, .{ .name = "g_callable_info_iterate_return_attributes" });
        const ret = cFn(self.into(BaseInfo), _iterator, _name, _value);
        if (ret) return error.BooleanError;
        return .{ .name = name_out, .value = value_out };
    }

    pub fn loadArg(self: *CallableInfo, _n: i32, _arg: *BaseInfo) void {
        const cFn = @extern(*const fn (*BaseInfo, i32, *BaseInfo) callconv(.C) void, .{ .name = "g_callable_info_load_arg" });
        const ret = cFn(self.into(BaseInfo), _n, _arg);
        return ret;
    }

    pub fn loadReturnType(self: *CallableInfo, _type: *BaseInfo) void {
        const cFn = @extern(*const fn (*BaseInfo, *BaseInfo) callconv(.C) void, .{ .name = "g_callable_info_load_return_type" });
        const ret = cFn(self.into(BaseInfo), _type);
        return ret;
    }

    pub fn mayReturnNull(self: *CallableInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_callable_info_may_return_null" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn skipReturn(self: *CallableInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_callable_info_skip_return" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.CallableInfoExt;
};
pub const CallbackInfo = extern struct {
    parent: CallableInfo,
    pub const Parent = CallableInfo;
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.CallbackInfoExt;
};
pub const ConstantInfo = extern struct {
    parent: BaseInfo,
    pub const Parent = BaseInfo;
    pub fn getType(self: *ConstantInfo) *TypeInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) *BaseInfo, .{ .name = "g_constant_info_get_type" });
        const ret = cFn(self.into(BaseInfo)).tryInto(TypeInfo).?;
        return ret;
    }
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.ConstantInfoExt;
};
pub const EnumInfo = extern struct {
    parent: RegisteredTypeInfo,
    pub const Parent = RegisteredTypeInfo;
    pub fn getErrorDomain(self: *EnumInfo) [*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) [*:0]u8, .{ .name = "g_enum_info_get_error_domain" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getMethod(self: *EnumInfo, _n: i32) *FunctionInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_enum_info_get_method" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(FunctionInfo).?;
        return ret;
    }

    pub fn getNMethods(self: *EnumInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_enum_info_get_n_methods" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getNValues(self: *EnumInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_enum_info_get_n_values" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getStorageType(self: *EnumInfo) TypeTag {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) TypeTag, .{ .name = "g_enum_info_get_storage_type" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getValue(self: *EnumInfo, _n: i32) *ValueInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_enum_info_get_value" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(ValueInfo).?;
        return ret;
    }
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.EnumInfoExt;
};
pub const FlagsInfo = extern struct {
    parent: EnumInfo,
    pub const Parent = EnumInfo;
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.FlagsInfoExt;
};
pub const FieldInfo = extern struct {
    parent: BaseInfo,
    pub const Parent = BaseInfo;
    pub fn getFlags(self: *FieldInfo) FieldInfoFlags {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) FieldInfoFlags, .{ .name = "g_field_info_get_flags" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getOffset(self: *FieldInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_field_info_get_offset" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getSize(self: *FieldInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_field_info_get_size" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getType(self: *FieldInfo) *TypeInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) *BaseInfo, .{ .name = "g_field_info_get_type" });
        const ret = cFn(self.into(BaseInfo)).tryInto(TypeInfo).?;
        return ret;
    }
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.FieldInfoExt;
};
pub const FunctionInfo = extern struct {
    parent: CallableInfo,
    pub const Parent = CallableInfo;
    pub fn getFlags(self: *FunctionInfo) FunctionInfoFlags {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) FunctionInfoFlags, .{ .name = "g_function_info_get_flags" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getProperty(self: *FunctionInfo) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) *BaseInfo, .{ .name = "g_function_info_get_property" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getSymbol(self: *FunctionInfo) [*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) [*:0]u8, .{ .name = "g_function_info_get_symbol" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getVfunc(self: *FunctionInfo) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) *BaseInfo, .{ .name = "g_function_info_get_vfunc" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.FunctionInfoExt;
};
pub const InterfaceInfo = extern struct {
    parent: RegisteredTypeInfo,
    pub const Parent = RegisteredTypeInfo;
    pub fn findMethod(self: *InterfaceInfo, _name: [*:0]const u8) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo, [*:0]const u8) callconv(.C) *BaseInfo, .{ .name = "g_interface_info_find_method" });
        const ret = cFn(self.into(BaseInfo), _name);
        return ret;
    }

    pub fn findSignal(self: *InterfaceInfo, _name: [*:0]const u8) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo, [*:0]const u8) callconv(.C) *BaseInfo, .{ .name = "g_interface_info_find_signal" });
        const ret = cFn(self.into(BaseInfo), _name);
        return ret;
    }

    pub fn findVfunc(self: *InterfaceInfo, _name: [*:0]const u8) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo, [*:0]const u8) callconv(.C) *BaseInfo, .{ .name = "g_interface_info_find_vfunc" });
        const ret = cFn(self.into(BaseInfo), _name);
        return ret;
    }

    pub fn getConstant(self: *InterfaceInfo, _n: i32) *ConstantInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_interface_info_get_constant" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(ConstantInfo).?;
        return ret;
    }

    pub fn getIfaceStruct(self: *InterfaceInfo) *StructInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) *BaseInfo, .{ .name = "g_interface_info_get_iface_struct" });
        const ret = cFn(self.into(BaseInfo)).tryInto(StructInfo).?;
        return ret;
    }

    pub fn getMethod(self: *InterfaceInfo, _n: i32) *FunctionInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_interface_info_get_method" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(FunctionInfo).?;
        return ret;
    }

    pub fn getNConstants(self: *InterfaceInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_interface_info_get_n_constants" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getNMethods(self: *InterfaceInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_interface_info_get_n_methods" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getNPrerequisites(self: *InterfaceInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_interface_info_get_n_prerequisites" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getNProperties(self: *InterfaceInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_interface_info_get_n_properties" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getNSignals(self: *InterfaceInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_interface_info_get_n_signals" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getNVfuncs(self: *InterfaceInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_interface_info_get_n_vfuncs" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getPrerequisite(self: *InterfaceInfo, _n: i32) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_interface_info_get_prerequisite" });
        const ret = cFn(self.into(BaseInfo), _n);
        return ret;
    }

    pub fn getProperty(self: *InterfaceInfo, _n: i32) *PropertyInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_interface_info_get_property" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(PropertyInfo).?;
        return ret;
    }

    pub fn getSignal(self: *InterfaceInfo, _n: i32) *SignalInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_interface_info_get_signal" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(SignalInfo).?;
        return ret;
    }

    pub fn getVfunc(self: *InterfaceInfo, _n: i32) *VFuncInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_interface_info_get_vfunc" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(VFuncInfo).?;
        return ret;
    }
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.InterfaceInfoExt;
};
pub const InvokeError = enum(u32) {
    failed = 0,
    symbol_not_found = 1,
    argument_mismatch = 2,

    pub fn quark() u32 {
        const cFn = @extern(*const fn () callconv(.C) u32, .{ .name = "g_invoke_error_quark" });
        const ret = cFn();
        return ret;
    }
};
pub const ObjectInfo = extern struct {
    parent: RegisteredTypeInfo,
    pub const Parent = RegisteredTypeInfo;
    pub fn findMethod(self: *ObjectInfo, _name: [*:0]const u8) ?*BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo, [*:0]const u8) callconv(.C) ?*BaseInfo, .{ .name = "g_object_info_find_method" });
        const ret = cFn(self.into(BaseInfo), _name);
        return ret;
    }

    pub fn findMethodUsingInterfaces(self: *ObjectInfo, _name: [*:0]const u8) struct {
        ret: ?*BaseInfo,
        implementor: *BaseInfo,
    } {
        var implementor_out: *BaseInfo = undefined;
        const _implementor = &implementor_out;
        const cFn = @extern(*const fn (*BaseInfo, [*:0]const u8, **BaseInfo) callconv(.C) ?*BaseInfo, .{ .name = "g_object_info_find_method_using_interfaces" });
        const ret = cFn(self.into(BaseInfo), _name, _implementor);
        return .{ .ret = ret, .implementor = implementor_out };
    }

    pub fn findSignal(self: *ObjectInfo, _name: [*:0]const u8) ?*BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo, [*:0]const u8) callconv(.C) ?*BaseInfo, .{ .name = "g_object_info_find_signal" });
        const ret = cFn(self.into(BaseInfo), _name);
        return ret;
    }

    pub fn findVfunc(self: *ObjectInfo, _name: [*:0]const u8) ?*BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo, [*:0]const u8) callconv(.C) ?*BaseInfo, .{ .name = "g_object_info_find_vfunc" });
        const ret = cFn(self.into(BaseInfo), _name);
        return ret;
    }

    pub fn findVfuncUsingInterfaces(self: *ObjectInfo, _name: [*:0]const u8) struct {
        ret: ?*BaseInfo,
        implementor: *BaseInfo,
    } {
        var implementor_out: *BaseInfo = undefined;
        const _implementor = &implementor_out;
        const cFn = @extern(*const fn (*BaseInfo, [*:0]const u8, **BaseInfo) callconv(.C) ?*BaseInfo, .{ .name = "g_object_info_find_vfunc_using_interfaces" });
        const ret = cFn(self.into(BaseInfo), _name, _implementor);
        return .{ .ret = ret, .implementor = implementor_out };
    }

    pub fn getAbstract(self: *ObjectInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_object_info_get_abstract" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getClassStruct(self: *ObjectInfo) ?*StructInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) ?*BaseInfo, .{ .name = "g_object_info_get_class_struct" });
        const ret = cFn(self.into(BaseInfo));
        return if (ret) |r| r.tryInto(StructInfo).? else null;
    }

    pub fn getConstant(self: *ObjectInfo, _n: i32) *ConstantInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_object_info_get_constant" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(ConstantInfo).?;
        return ret;
    }

    pub fn getField(self: *ObjectInfo, _n: i32) *FieldInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_object_info_get_field" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(FieldInfo).?;
        return ret;
    }

    pub fn getFinal(self: *ObjectInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_object_info_get_final" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getFundamental(self: *ObjectInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_object_info_get_fundamental" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getGetValueFunction(self: *ObjectInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) ?[*:0]u8, .{ .name = "g_object_info_get_get_value_function" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getInterface(self: *ObjectInfo, _n: i32) *InterfaceInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_object_info_get_interface" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(InterfaceInfo).?;
        return ret;
    }

    pub fn getMethod(self: *ObjectInfo, _n: i32) *FunctionInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_object_info_get_method" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(FunctionInfo).?;
        return ret;
    }

    pub fn getNConstants(self: *ObjectInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_object_info_get_n_constants" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getNFields(self: *ObjectInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_object_info_get_n_fields" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getNInterfaces(self: *ObjectInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_object_info_get_n_interfaces" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getNMethods(self: *ObjectInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_object_info_get_n_methods" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getNProperties(self: *ObjectInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_object_info_get_n_properties" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getNSignals(self: *ObjectInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_object_info_get_n_signals" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getNVfuncs(self: *ObjectInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_object_info_get_n_vfuncs" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getParent(self: *ObjectInfo) ?*BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) ?*BaseInfo, .{ .name = "g_object_info_get_parent" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getProperty(self: *ObjectInfo, _n: i32) *PropertyInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_object_info_get_property" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(PropertyInfo).?;
        return ret;
    }

    pub fn getRefFunction(self: *ObjectInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) ?[*:0]u8, .{ .name = "g_object_info_get_ref_function" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getSetValueFunction(self: *ObjectInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) ?[*:0]u8, .{ .name = "g_object_info_get_set_value_function" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getSignal(self: *ObjectInfo, _n: i32) *SignalInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_object_info_get_signal" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(SignalInfo).?;
        return ret;
    }

    pub fn getTypeInit(self: *ObjectInfo) [*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) [*:0]u8, .{ .name = "g_object_info_get_type_init" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getTypeName(self: *ObjectInfo) [*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) [*:0]u8, .{ .name = "g_object_info_get_type_name" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getUnrefFunction(self: *ObjectInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) ?[*:0]u8, .{ .name = "g_object_info_get_unref_function" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }
    pub fn getVfunc(self: *ObjectInfo, _n: i32) *VFuncInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_object_info_get_vfunc" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(VFuncInfo).?;
        return ret;
    }
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.ObjectInfoExt;
};
pub const PropertyInfo = extern struct {
    parent: BaseInfo,
    pub const Parent = BaseInfo;
    pub fn getFlags(self: *PropertyInfo) core.ParamFlags {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) core.ParamFlags, .{ .name = "g_property_info_get_flags" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getGetter(self: *PropertyInfo) ?*BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) ?*BaseInfo, .{ .name = "g_property_info_get_getter" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getOwnershipTransfer(self: *PropertyInfo) Transfer {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) Transfer, .{ .name = "g_property_info_get_ownership_transfer" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getSetter(self: *PropertyInfo) ?*BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) ?*BaseInfo, .{ .name = "g_property_info_get_setter" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getType(self: *PropertyInfo) *TypeInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) *BaseInfo, .{ .name = "g_property_info_get_type" });
        const ret = cFn(self.into(BaseInfo)).tryInto(TypeInfo).?;
        return ret;
    }
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.PropertyInfoExt;
};
pub const RegisteredTypeInfo = extern struct {
    parent: BaseInfo,
    pub const Parent = BaseInfo;
    pub fn getGType(self: *RegisteredTypeInfo) core.Type {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) core.Type, .{ .name = "g_registered_type_info_get_g_type" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }
    pub fn getTypeInit(self: *RegisteredTypeInfo) [*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) [*:0]u8, .{ .name = "g_registered_type_info_get_type_init" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }
    pub fn getTypeName(self: *RegisteredTypeInfo) [*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) [*:0]u8, .{ .name = "g_registered_type_info_get_type_name" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.RegisteredTypeInfoExt;
};
pub const SignalInfo = extern struct {
    parent: CallableInfo,
    pub const Parent = CallableInfo;
    pub fn getClassClosure(self: *SignalInfo) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) *BaseInfo, .{ .name = "g_signal_info_get_class_closure" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getFlags(self: *SignalInfo) core.SignalFlags {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) core.SignalFlags, .{ .name = "g_signal_info_get_flags" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn trueStopsEmit(self: *SignalInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_signal_info_true_stops_emit" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.SignalInfoExt;
};
pub const StructInfo = extern struct {
    parent: RegisteredTypeInfo,
    pub const Parent = RegisteredTypeInfo;
    pub fn findField(self: *StructInfo, _name: [*:0]const u8) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo, [*:0]const u8) callconv(.C) *BaseInfo, .{ .name = "g_struct_info_find_field" });
        const ret = cFn(self.into(BaseInfo), _name);
        return ret;
    }

    pub fn findMethod(self: *StructInfo, _name: [*:0]const u8) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo, [*:0]const u8) callconv(.C) *BaseInfo, .{ .name = "g_struct_info_find_method" });
        const ret = cFn(self.into(BaseInfo), _name);
        return ret;
    }

    pub fn getAlignment(self: *StructInfo) u64 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) u64, .{ .name = "g_struct_info_get_alignment" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getField(self: *StructInfo, _n: i32) *FieldInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_struct_info_get_field" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(FieldInfo).?;
        return ret;
    }

    pub fn getMethod(self: *StructInfo, _n: i32) *FunctionInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_struct_info_get_method" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(FunctionInfo).?;
        return ret;
    }

    pub fn getNFields(self: *StructInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_struct_info_get_n_fields" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getNMethods(self: *StructInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_struct_info_get_n_methods" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getSize(self: *StructInfo) u64 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) u64, .{ .name = "g_struct_info_get_size" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn isForeign(self: *StructInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_struct_info_is_foreign" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn isGtypeStruct(self: *StructInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_struct_info_is_gtype_struct" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.StructInfoExt;
};
pub const TypeInfo = extern struct {
    parent: BaseInfo,
    pub const Parent = BaseInfo;
    pub fn argumentFromHashPointer(self: *TypeInfo, _hash_pointer: ?*anyopaque, _arg: *Argument) void {
        const cFn = @extern(*const fn (*BaseInfo, ?*anyopaque, *Argument) callconv(.C) void, .{ .name = "g_type_info_argument_from_hash_pointer" });
        const ret = cFn(self.into(BaseInfo), _hash_pointer, _arg);
        return ret;
    }

    pub fn getArrayFixedSize(self: *TypeInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_type_info_get_array_fixed_size" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getArrayLength(self: *TypeInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_type_info_get_array_length" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getArrayType(self: *TypeInfo) ArrayType {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) ArrayType, .{ .name = "g_type_info_get_array_type" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getInterface(self: *TypeInfo) ?*BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) ?*BaseInfo, .{ .name = "g_type_info_get_interface" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getParamType(self: *TypeInfo, _n: i32) *TypeInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_type_info_get_param_type" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(TypeInfo).?;
        return ret;
    }

    pub fn getStorageType(self: *TypeInfo) TypeTag {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) TypeTag, .{ .name = "g_type_info_get_storage_type" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getTag(self: *TypeInfo) TypeTag {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) TypeTag, .{ .name = "g_type_info_get_tag" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn hashPointerFromArgument(self: *TypeInfo, _arg: *Argument) ?*anyopaque {
        const cFn = @extern(*const fn (*BaseInfo, *Argument) callconv(.C) ?*anyopaque, .{ .name = "g_type_info_hash_pointer_from_argument" });
        const ret = cFn(self.into(BaseInfo), _arg);
        return ret;
    }

    pub fn isPointer(self: *TypeInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_type_info_is_pointer" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn isZeroTerminated(self: *TypeInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_type_info_is_zero_terminated" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.TypeInfoExt;
};
pub const UnionInfo = extern struct {
    parent: RegisteredTypeInfo,
    pub const Parent = RegisteredTypeInfo;
    pub fn findMethod(self: *UnionInfo, _name: [*:0]const u8) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo, [*:0]const u8) callconv(.C) *BaseInfo, .{ .name = "g_union_info_find_method" });
        const ret = cFn(self.into(BaseInfo), _name);
        return ret;
    }

    pub fn getAlignment(self: *UnionInfo) u64 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) u64, .{ .name = "g_union_info_get_alignment" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getDiscriminator(self: *UnionInfo, _n: i32) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_union_info_get_discriminator" });
        const ret = cFn(self.into(BaseInfo), _n);
        return ret;
    }

    pub fn getDiscriminatorOffset(self: *UnionInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_union_info_get_discriminator_offset" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getDiscriminatorType(self: *UnionInfo) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) *BaseInfo, .{ .name = "g_union_info_get_discriminator_type" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getField(self: *UnionInfo, _n: i32) *FieldInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_union_info_get_field" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(FieldInfo).?;
        return ret;
    }

    pub fn getMethod(self: *UnionInfo, _n: i32) *FunctionInfo {
        const cFn = @extern(*const fn (*BaseInfo, i32) callconv(.C) *BaseInfo, .{ .name = "g_union_info_get_method" });
        const ret = cFn(self.into(BaseInfo), _n).tryInto(FunctionInfo).?;
        return ret;
    }

    pub fn getNFields(self: *UnionInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_union_info_get_n_fields" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getNMethods(self: *UnionInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_union_info_get_n_methods" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getSize(self: *UnionInfo) u64 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) u64, .{ .name = "g_union_info_get_size" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn isDiscriminated(self: *UnionInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) bool, .{ .name = "g_union_info_is_discriminated" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.UnionInfoExt;
};
pub const ValueInfo = extern struct {
    parent: BaseInfo,
    pub const Parent = BaseInfo;
    pub fn getValue(self: *ValueInfo) i64 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i64, .{ .name = "g_value_info_get_value" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getAddress(self: *ValueInfo, _implementor_gtype: core.Type) error{GError}!?*anyopaque {
        var _error: ?*core.Error = null;
        const cFn = @extern(*const fn (*BaseInfo, core.Type, *?*core.Error) callconv(.C) ?*anyopaque, .{ .name = "g_vfunc_info_get_address" });
        const ret = cFn(self.into(BaseInfo), _implementor_gtype, &_error);
        if (_error) |some| {
            core.setError(some);
            return error.GError;
        }
        return ret;
    }
    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.ValueInfoExt;
};
pub const VFuncInfo = extern struct {
    parent: CallableInfo,
    pub const Parent = CallableInfo;
    pub fn getFlags(self: *VFuncInfo) VFuncInfoFlags {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) VFuncInfoFlags, .{ .name = "g_vfunc_info_get_flags" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getInvoker(self: *VFuncInfo) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) *BaseInfo, .{ .name = "g_vfunc_info_get_invoker" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getOffset(self: *VFuncInfo) i32 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) i32, .{ .name = "g_vfunc_info_get_offset" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub fn getSignal(self: *VFuncInfo) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.C) *BaseInfo, .{ .name = "g_vfunc_info_get_signal" });
        const ret = cFn(self.into(BaseInfo));
        return ret;
    }

    pub usingnamespace core.Extend(@This());

    pub usingnamespace ext.VFuncInfoExt;
};
