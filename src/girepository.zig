pub const core = @import("core_min.zig");
const std = @import("std");
const assert = std.debug.assert;

const root = @import("root");
const Namespace = root.Namespace;
const Identifier = root.Identifier;
const snakeToCamel = root.snakeToCamel;
const camelToSnake = root.camelToSnake;

// @manual
pub const BitField = struct {
    var remaining: ?isize = null;

    pub fn reset() void {
        BitField.remaining = null;
    }

    pub fn begin(bits: isize, offset: isize, writer: anytype) !void {
        assert(BitField.remaining == null);
        BitField.remaining = bits;
        try writer.print("_{d} : packed struct(u{d}) {{\n", .{ offset, bits });
    }

    pub fn end(writer: anytype) !void {
        assert(BitField.remaining != null);
        if (BitField.remaining.? != 0) {
            try writer.print("_: u{d},\n", .{BitField.remaining.?});
        }
        BitField.remaining = null;
        try writer.writeAll("},\n");
    }

    pub fn ensure(bits: isize, alloc: isize, offset: isize, writer: anytype) !void {
        assert(BitField.remaining != null);
        if (BitField.remaining.? < bits) {
            try BitField.end(writer);
            try BitField.begin(alloc, offset, writer);
        }
    }

    pub fn emit(bits: isize) void {
        assert(BitField.remaining != null);
        BitField.remaining.? -= bits;
    }
};

// @manual
pub fn Iterator(comptime Context: type, comptime Item: type) type {
    const Int = @Type(@typeInfo(c_int));

    return struct {
        context: Context,
        index: Int = 0,
        capacity: Int,
        next_fn: *const fn (Context, Int) Item,

        const Self = @This();

        pub fn next(self: *Self) ?Item {
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            return self.next_fn(self.context, self.index);
        }
    };
}

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

    // @manual
    pub fn format(self_immut: *const ArgInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *ArgInfo = @constCast(self_immut);
        var option_type_only = false;
        var option_signal_param = false;
        inline for (fmt) |ch| {
            switch (ch) {
                't' => option_type_only = true,
                'p' => option_signal_param = true,
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        if (!option_type_only) {
            const name = self.into(BaseInfo).getName().?;
            try writer.print("_{s}: ", .{name});
        }
        const arg_type = self.getType();
        if (option_signal_param) {
            if (arg_type.getInterface()) |child_type| {
                switch (child_type.getType()) {
                    .@"enum", .flags => option_signal_param = false,
                    else => {},
                }
            } else {
                option_signal_param = false;
            }
        }
        if (self.getDirection() != .in or option_signal_param) {
            if (self.isOptional()) {
                if (self.mayBeNull()) {
                    try writer.print("{mnop}", .{arg_type});
                } else {
                    try writer.print("{mop}", .{arg_type});
                }
            } else {
                if (self.mayBeNull()) {
                    try writer.print("{mnp}", .{arg_type});
                } else {
                    try writer.print("{mn}", .{arg_type});
                }
            }
        } else {
            if (self.mayBeNull()) {
                try writer.print("{n}", .{arg_type});
            } else {
                try writer.print("{}", .{arg_type});
            }
        }
    }
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

    // @manual
    pub fn argsAlloc(self: *CallableInfo, allocator: std.mem.Allocator) ![]*ArgInfo {
        const args = try allocator.alloc(*ArgInfo, @intCast(self.getNArgs()));
        for (args, 0..) |*arg, index| {
            arg.* = self.getArg(@intCast(index));
        }
        return args;
    }

    const ArgsIter = Iterator(*CallableInfo, *ArgInfo);
    pub fn argsIter(self: *CallableInfo) ArgsIter {
        return .{ .context = self, .capacity = self.getNArgs(), .next_fn = getArg };
    }

    // @manual
    pub fn format(self_immut: *const CallableInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *CallableInfo = @constCast(self_immut);
        var type_annotation: enum { disable, enable, only } = .disable;
        var c_callconv = false;
        var vfunc = false;
        inline for (fmt) |ch| {
            switch (ch) {
                'e' => type_annotation = .enable,
                'o' => type_annotation = .only,
                'c' => c_callconv = true,
                'v' => vfunc = true,
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        var first = true;
        try writer.writeAll("(");
        if (self.isMethod()) {
            if (first) {
                first = false;
            } else {
                try writer.writeAll(", ");
            }
            const container = self.into(BaseInfo).getContainer().?;
            switch (type_annotation) {
                .disable => try writer.writeAll("self"),
                .enable => try writer.print("self: *{s}", .{container.getName().?}),
                .only => try writer.print("*{s}", .{container.getName().?}),
            }
        }
        if (vfunc) {
            if (type_annotation == .enable) {
                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }
                try writer.writeAll("_gtype: core.Type");
            }
        }
        var iter = self.argsIter();
        while (iter.next()) |arg| {
            if (first) {
                first = false;
            } else {
                try writer.writeAll(", ");
            }
            switch (type_annotation) {
                .disable => try writer.print("_{s}", .{arg.into(BaseInfo).getName().?}),
                .enable => try writer.print("{}", .{arg}),
                .only => try writer.print("{t}", .{arg}),
            }
        }
        if (self.canThrowGerror()) {
            if (first) {
                first = false;
            } else {
                try writer.writeAll(", ");
            }
            switch (type_annotation) {
                .disable => {
                    if (!vfunc) {
                        try writer.writeAll("&"); // method wrapper
                    }
                    try writer.writeAll("_error");
                },
                .enable => try writer.writeAll("_error: *?*core.Error"),
                .only => try writer.writeAll("*?*core.Error"),
            }
        }
        try writer.writeAll(") ");
        if (type_annotation != .disable) {
            if (c_callconv) {
                try writer.writeAll("callconv(.C) ");
            }
            if (self.skipReturn()) {
                try writer.writeAll("void");
            } else {
                const return_type = self.getReturnType();
                var ctor = false;
                if (self.into(BaseInfo).getType() == .function) {
                    if (self.tryInto(FunctionInfo).?.getFlags().is_constructor) {
                        ctor = true;
                    }
                }
                if (ctor) {
                    const container = self.into(BaseInfo).getContainer().?;
                    if (self.mayReturnNull()) {
                        try writer.writeAll("?");
                    }
                    try writer.print("*{s}", .{container.getName().?});
                } else {
                    if (self.mayReturnNull() or return_type.getTag() == .glist or return_type.getTag() == .gslist) {
                        try writer.print("{mn}", .{return_type});
                    } else {
                        try writer.print("{m}", .{return_type});
                    }
                }
            }
        }
    }
};
pub const CallbackInfo = extern struct {
    parent: CallableInfo,
    pub const Parent = CallableInfo;
    pub usingnamespace core.Extend(@This());

    // @manual
    pub fn format(self_immut: *CallbackInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *CallbackInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        try writer.writeAll("*const fn ");
        try writer.print("{ec}", .{self.into(CallableInfo)});
    }
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

    // @manual
    pub fn freeValue(self: *ConstantInfo, value: *Argument) void {
        const cFn = @extern(*const fn (*BaseInfo, *Argument) callconv(.C) void, .{ .name = "g_constant_info_free_value" });
        _ = cFn(self.into(BaseInfo), value);
    }

    // @manual
    pub fn getValue(self: *ConstantInfo, value: *Argument) c_int {
        const cFn = @extern(*const fn (*BaseInfo, *Argument) callconv(.C) c_int, .{ .name = "g_constant_info_get_value" });
        const ret = cFn(self.into(BaseInfo), value);
        return ret;
    }

    // @manual
    pub fn format(self_immut: *const ConstantInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *ConstantInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        try root.generateDocs(.{ .constant = self }, writer);
        try writer.print("pub const {s} = ", .{self.into(BaseInfo).getName().?});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("if (core.config.disable_deprecated) core.Deprecated else ");
        }
        var value: Argument = undefined;
        _ = self.getValue(&value);
        defer self.freeValue(&value);
        const value_type = self.getType();
        switch (value_type.getTag()) {
            .boolean => try writer.print("{}", .{value.v_boolean}),
            .int8 => try writer.print("{}", .{value.v_int8}),
            .uint8 => try writer.print("{}", .{value.v_uint8}),
            .int16 => try writer.print("{}", .{value.v_int16}),
            .uint16 => try writer.print("{}", .{value.v_uint16}),
            .int32 => try writer.print("{}", .{value.v_int32}),
            .uint32 => try writer.print("{}", .{value.v_uint32}),
            .int64 => try writer.print("{}", .{value.v_int64}),
            .uint64 => try writer.print("{}", .{value.v_uint64}),
            .float => try writer.print("{}", .{value.v_float}),
            .double => try writer.print("{}", .{value.v_double}),
            .utf8 => try writer.print("\"{s}\"", .{value.v_string.?}),
            .interface => {
                const value_namespace = self.into(BaseInfo).getNamespace().?;
                const value_name = self.into(BaseInfo).getName().?;
                try writer.writeAll("null");
                std.log.warn("[Guess] {s}.{s} is set to null", .{ value_namespace, value_name });
            },
            else => unreachable,
        }
        try writer.writeAll(";\n");
    }
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

    const ValueIter = Iterator(*EnumInfo, *ValueInfo);
    pub fn valueIter(self: *EnumInfo) ValueIter {
        return .{ .context = self, .capacity = self.getNValues(), .next_fn = getValue };
    }

    const MethodIter = Iterator(*EnumInfo, *FunctionInfo);
    pub fn methodIter(self: *EnumInfo) MethodIter {
        return .{ .context = self, .capacity = self.getNMethods(), .next_fn = getMethod };
    }

    // @manual
    pub fn formatValue(self: *EnumInfo, value: *ValueInfo, convert_func: ?[]const u8, writer: anytype) !void {
        const value_name = value.into(BaseInfo).getName().?;
        try writer.print("{}", .{Identifier{ .str = std.mem.span(value_name) }});

        if (convert_func) |func| {
            try writer.print(": @This() = @{s}(", .{func});
        } else {
            try writer.writeAll(" = ");
        }

        switch (self.getStorageType()) {
            .int32 => try writer.print("{d}", .{@as(i32, @intCast(value.getValue()))}),
            .uint32 => try writer.print("{d}", .{@as(u32, @intCast(value.getValue()))}),
            else => unreachable,
        }

        if (convert_func) |_| {
            try writer.writeAll(")");
        }
    }

    // @manual
    pub fn format(self_immut: *const EnumInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *EnumInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        try root.generateDocs(.{ .@"enum" = self }, writer);
        const name = self.into(BaseInfo).getName().?;
        try writer.print("pub const {s} = ", .{name});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("if (core.config.disable_deprecated) core.Deprecated else ");
        }
        try writer.writeAll("enum");
        switch (self.getStorageType()) {
            .int32 => try writer.writeAll("(i32)"),
            .uint32 => try writer.writeAll("(u32)"),
            else => unreachable,
        }
        try writer.writeAll("{\n");
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();
        var values = std.AutoHashMap(i64, void).init(allocator);
        defer values.deinit();
        var iter = self.valueIter();
        while (iter.next()) |value| {
            if (values.contains(value.getValue())) {
                continue;
            }
            values.put(value.getValue(), {}) catch @panic("Out of Memory");
            try self.formatValue(value, null, writer);
            try writer.writeAll(",\n");
        }
        iter = self.valueIter();
        while (iter.next()) |value| {
            if (values.remove(value.getValue())) continue;
            try writer.writeAll("pub const ");
            try self.formatValue(value, "enumFromInt", writer);
            try writer.writeAll(";\n");
        }
        var m_iter = self.methodIter();
        while (m_iter.next()) |method| {
            try writer.print("\n{}", .{method});
        }
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("};\n");
    }
};
pub const FlagsInfo = extern struct {
    parent: EnumInfo,
    pub const Parent = EnumInfo;
    pub usingnamespace core.Extend(@This());

    // @manual
    pub fn format(self_immut: *const FlagsInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *FlagsInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        try root.generateDocs(.{ .flags = self }, writer);
        const name = self.into(BaseInfo).getName().?;
        try writer.print("pub const {s} = ", .{name});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("if (core.config.disable_deprecated) core.Deprecated else ");
        }
        try writer.writeAll("packed struct");
        switch (self.into(EnumInfo).getStorageType()) {
            .int32 => try writer.writeAll("(i32)"),
            .uint32 => try writer.writeAll("(u32)"),
            else => unreachable,
        }
        try writer.writeAll("{\n");
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();
        var values = std.AutoHashMap(usize, []const u8).init(allocator);
        defer {
            var value_iter = values.valueIterator();
            while (value_iter.next()) |val| {
                allocator.free(val.*);
            }
            values.deinit();
        }
        var iter = self.into(EnumInfo).valueIter();
        while (iter.next()) |value| {
            const _value = value.getValue();
            if (_value <= 0 or !std.math.isPowerOfTwo(_value)) {
                continue;
            }
            const idx = std.math.log2_int(u32, @intCast(_value));
            if (values.contains(idx)) {
                continue;
            }
            var buf: [256]u8 = undefined;
            const name_v = camelToSnake(std.mem.span(value.into(BaseInfo).getName().?), buf[0..]);
            const name_dup = allocator.dupe(u8, name_v) catch @panic("Out of Memory");
            values.put(idx, name_dup) catch @panic("Out of Memory");
        }
        var padding_bits: usize = 0;
        for (0..32) |idx| {
            if (values.get(idx)) |name_v| {
                if (padding_bits != 0) {
                    try writer.print("_{d}: u{d} = 0,\n", .{ idx - padding_bits, padding_bits });
                    padding_bits = 0;
                }
                try writer.print("{}: bool = false,\n", .{Identifier{ .str = name_v }});
            } else {
                padding_bits += 1;
            }
        }
        if (padding_bits != 0) {
            try writer.print("_: u{d} = 0,\n", .{padding_bits});
        }
        iter = self.into(EnumInfo).valueIter();
        while (iter.next()) |value| {
            try writer.writeAll("pub const ");
            try self.into(EnumInfo).formatValue(value, "bitCast", writer);
            try writer.writeAll(";\n");
        }
        var m_iter = self.into(EnumInfo).methodIter();
        while (m_iter.next()) |method| {
            try writer.print("\n{}", .{method});
        }
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("};\n");
    }
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

    // @manual
    pub fn format(self_immut: *const FieldInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *FieldInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        const field_name = self.into(BaseInfo).getName().?;
        const field_type = self.getType();
        const field_size = self.getSize();
        if (field_size != 0) {
            const field_container_bits: usize = switch (field_type.getTag()) {
                .int32, .uint32 => 32,
                else => unreachable,
            };
            if (BitField.remaining == null) {
                try BitField.begin(field_container_bits, self.getOffset(), writer);
            } else {
                try BitField.ensure(field_size, field_container_bits, self.getOffset(), writer);
            }
            BitField.emit(field_size);
        } else if (BitField.remaining != null) {
            try BitField.end(writer);
        }
        try writer.print("{}", .{Identifier{ .str = std.mem.span(field_name) }});
        if (field_size == 0) {
            try writer.print(": {n},\n", .{field_type});
        } else if (field_size == 1) {
            try writer.writeAll(": bool,\n");
        } else {
            switch (field_type.getTag()) {
                .int32 => try writer.print(": i{d},\n", .{field_size}),
                .uint32 => try writer.print(": u{d},\n", .{field_size}),
                else => unreachable,
            }
        }
    }
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

    // @manual
    pub fn format(self_immut: *const FunctionInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *FunctionInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        const SliceInfo = struct {
            is_slice_ptr: bool = false,
            slice_len: usize = undefined,
            is_slice_len: bool = false,
            slice_ptr: usize = undefined,
        };
        const ClosureInfo = struct {
            scope: ScopeType = .invalid,
            is_func: bool = false,
            closure_data: usize = undefined,
            is_data: bool = false,
            closure_func: usize = undefined,
            is_destroy: bool = false,
            closure_destroy: usize = undefined,
        };

        var buffer: [4096]u8 = undefined;
        var fixed_buffer_allocator = std.heap.FixedBufferAllocator.init(buffer[0..]);
        const allocator = fixed_buffer_allocator.allocator();
        var buf: [256]u8 = undefined;
        const func_name = snakeToCamel(std.mem.span(self.into(BaseInfo).getName().?), buf[0..]);
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("pub usingnamespace if (core.config.disable_deprecated) struct{\n");
            try writer.print("pub const {}", .{Identifier{ .str = func_name }});
            try writer.writeAll(" = core.Deprecated;\n");
            try writer.writeAll("} else struct{\n");
        }
        try root.generateDocs(.{ .function = self }, writer);
        try writer.print("pub fn {}", .{Identifier{ .str = func_name }});
        const return_type = self.into(CallableInfo).getReturnType();
        const args = self.into(CallableInfo).argsAlloc(allocator) catch @panic("Out of Memory");
        var slice_info = allocator.alloc(SliceInfo, args.len) catch @panic("Out of Memory");
        @memset(slice_info[0..], .{});
        var closure_info = allocator.alloc(ClosureInfo, args.len) catch @panic("Out of Memory");
        @memset(closure_info[0..], .{});
        var n_out_param: usize = 0;
        for (args, 0..) |arg, idx| {
            if (arg.getDirection() == .out and !arg.isCallerAllocates()) {
                n_out_param += 1;
            }
            const arg_type = arg.getType();
            if (arg_type.getArrayLength() != -1) {
                const pos: usize = @intCast(arg_type.getArrayLength());
                slice_info[idx].is_slice_ptr = true;
                slice_info[idx].slice_len = pos;
                if (!slice_info[pos].is_slice_len) {
                    slice_info[pos].is_slice_len = true;
                    slice_info[pos].slice_ptr = idx;
                }
            }
            const arg_name = std.mem.span(arg.into(BaseInfo).getName().?);
            if (arg.getScope() != .invalid and arg.getClosure() != -1 and !std.mem.eql(u8, "data", arg_name[arg_name.len - 4 .. arg_name.len])) {
                closure_info[idx].scope = arg.getScope();
                closure_info[idx].is_func = true;
                if (arg.getClosure() != -1) {
                    const pos: usize = @intCast(arg.getClosure());
                    closure_info[idx].closure_data = pos;
                    closure_info[pos].is_data = true;
                    closure_info[pos].closure_func = idx;
                }
                if (arg.getDestroy() != -1) {
                    const pos: usize = @intCast(arg.getDestroy());
                    closure_info[idx].closure_destroy = pos;
                    closure_info[pos].is_destroy = true;
                    closure_info[pos].closure_func = idx;
                }
            }
        }
        const return_bool = return_type.getTag() == .boolean;
        const throw_bool = return_bool and (n_out_param > 0);
        const throw_error = self.into(CallableInfo).canThrowGerror();
        const skip_return = self.into(CallableInfo).skipReturn();
        const real_skip_return = skip_return or throw_bool;
        const n_out = n_out_param + @intFromBool(!real_skip_return);
        {
            try writer.writeAll("(");
            var first = true;
            if (self.into(CallableInfo).isMethod()) {
                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }
                const container = self.into(BaseInfo).getContainer().?;
                try writer.print("self: *{s}", .{container.getName().?});
            }
            for (args, 0..) |arg, idx| {
                if (arg.getDirection() == .out and !arg.isCallerAllocates()) continue;
                if (slice_info[idx].is_slice_len) continue;
                if (closure_info[idx].is_data) continue;
                if (closure_info[idx].is_destroy) continue;
                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }
                if (slice_info[idx].is_slice_ptr) {
                    try writer.print("_{s}s: ", .{arg.into(BaseInfo).getName().?});
                    if (arg.isOptional()) {
                        try writer.writeAll("?");
                    }
                    try writer.print("[]{}", .{arg.getType().getParamType(0)});
                } else if (closure_info[idx].is_func) {
                    try writer.print("{s}: anytype, {s}_args: anytype", .{ arg.into(BaseInfo).getName().?, arg.into(BaseInfo).getName().? });
                } else {
                    try writer.print("{}", .{arg});
                }
            }
            try writer.writeAll(") ");
            if (throw_error) {
                try writer.writeAll("error{GError}!");
            } else if (throw_bool) {
                try writer.writeAll("error{BooleanError}!");
            }
            if (n_out > 1) {
                try writer.writeAll("struct {\n");
            }
            if (!real_skip_return) {
                if (n_out > 1) {
                    try writer.writeAll("ret: ");
                }
                var ctor = false;
                if (self.getFlags().is_constructor) {
                    ctor = true;
                }
                if (return_bool) {
                    try writer.writeAll("bool");
                } else if (ctor) {
                    const container = self.into(BaseInfo).getContainer().?;
                    if (self.into(CallableInfo).mayReturnNull()) {
                        try writer.writeAll("?");
                    }
                    try writer.print("*{s}", .{container.getName().?});
                } else {
                    if (self.into(CallableInfo).mayReturnNull() or return_type.getTag() == .glist or return_type.getTag() == .gslist) {
                        try writer.print("{mn}", .{return_type});
                    } else {
                        try writer.print("{m}", .{return_type});
                    }
                }
                if (n_out > 1) {
                    try writer.writeAll(",\n");
                }
            }
            if (n_out_param > 0) {
                for (args, 0..) |arg, idx| {
                    if (arg.getDirection() != .out or arg.isCallerAllocates()) continue;
                    if (slice_info[idx].is_slice_len) continue;
                    if (n_out > 1) {
                        try writer.print("{s}: ", .{arg.into(BaseInfo).getName().?});
                    }
                    if (slice_info[idx].is_slice_ptr) {
                        if (arg.isOptional()) {
                            try writer.writeAll("?");
                        }
                        try writer.print("[]{}", .{arg.getType().getParamType(0)});
                    } else {
                        if (arg.mayBeNull()) {
                            try writer.print("{mn}", .{arg.getType()});
                        } else {
                            try writer.print("{m}", .{arg.getType()});
                        }
                    }
                    if (n_out > 1) {
                        try writer.writeAll(",\n");
                    }
                }
            }
            if (n_out > 1) {
                try writer.writeAll("}");
            }
        }
        try writer.writeAll(" {\n");
        // prepare error
        if (throw_error) {
            try writer.writeAll("var _error: ?*core.Error = null;\n");
        }
        // prepare input/inout
        for (args, 0..) |arg, idx| {
            if (arg.getDirection() == .out and !arg.isCallerAllocates()) continue;
            const arg_name = arg.into(BaseInfo).getName().?;
            if (slice_info[idx].is_slice_len) {
                const arg_type = arg.getType();
                const ptr_arg = args[slice_info[idx].slice_ptr];
                if (ptr_arg.isOptional()) {
                    try writer.print("const _{s}: {} = if (_{s}s) |some| @intCast(some.len) else 0;\n", .{ arg_name, arg_type, ptr_arg.into(BaseInfo).getName().? });
                } else {
                    try writer.print("const _{s}: {} = @intCast(_{s}s.len);\n", .{ arg_name, arg_type, ptr_arg.into(BaseInfo).getName().? });
                }
            }
            if (slice_info[idx].is_slice_ptr) {
                if (arg.isOptional()) {
                    try writer.print("const _{s} = if (_{s}s) |some| some.ptr else null;\n", .{ arg_name, arg_name });
                } else {
                    try writer.print("const _{s} = _{s}s.ptr;\n", .{ arg_name, arg_name });
                }
            }
            if (closure_info[idx].is_func) {
                try writer.print("var closure_{s} = core.zig_closure({s}, {s}_args, &.{{", .{ arg_name, arg_name, arg_name });
                const arg_type = arg.getType();
                if (arg_type.getInterface()) |interface| {
                    if (interface.getType() == .callback) {
                        const cb_return_type = interface.tryInto(CallableInfo).?.getReturnType();
                        if (interface.tryInto(CallableInfo).?.mayReturnNull() or cb_return_type.getTag() == .glist or cb_return_type.getTag() == .gslist) {
                            try writer.print("{mn}", .{cb_return_type});
                        } else {
                            try writer.print("{m}", .{cb_return_type});
                        }
                        var callback_args = interface.tryInto(CallableInfo).?.argsAlloc(allocator) catch @panic("Out of Memory");
                        if (callback_args.len > 0) {
                            for (callback_args[0 .. callback_args.len - 1]) |cb_arg| {
                                try writer.writeAll(", ");
                                try writer.print("{t}", .{cb_arg});
                            }
                        } else {
                            std.log.warn("[Generic Callback] {s}", .{self.getSymbol()});
                        }
                        assert(!interface.tryInto(CallableInfo).?.canThrowGerror());
                    } else {
                        try writer.writeAll("void");
                        std.log.warn("[Generic Callback] {s}", .{self.getSymbol()});
                    }
                } else {
                    try writer.writeAll("void");
                    std.log.warn("[Generic Callback] {s}", .{self.getSymbol()});
                }
                try writer.writeAll("});\n");
                switch (closure_info[idx].scope) {
                    .call => {
                        try writer.print("defer closure_{s}.deinit();\n", .{arg_name});
                    },
                    .@"async" => {
                        try writer.print("closure_{s}.setOnce();\n", .{arg_name});
                    },
                    .notified, .forever => {
                        //
                    },
                    else => unreachable,
                }
                try writer.print("const _{s}: {t} = @ptrCast(closure_{s}.c_closure());\n", .{ arg_name, arg, arg_name });
            }
            if (closure_info[idx].is_data) {
                const func_arg = args[closure_info[idx].closure_func];
                try writer.print("const _{s}: {t} = @ptrCast(closure_{s}.c_data());\n", .{ arg_name, arg, func_arg.into(BaseInfo).getName().? });
            }
            if (closure_info[idx].is_destroy) {
                const func_arg = args[closure_info[idx].closure_func];
                try writer.print("const _{s}: {t} = @ptrCast(closure_{s}.c_destroy());\n", .{ arg_name, arg, func_arg.into(BaseInfo).getName().? });
            }
        }
        // prepare output
        for (args) |arg| {
            if (arg.getDirection() != .out or arg.isCallerAllocates()) continue;
            const arg_name = arg.into(BaseInfo).getName().?;
            const arg_type = arg.getType();
            if (arg.mayBeNull()) {
                try writer.print("var {s}_out: {mn} = undefined;\n", .{ arg_name, arg_type });
            } else {
                try writer.print("var {s}_out: {m} = undefined;\n", .{ arg_name, arg_type });
            }
            try writer.print("const _{s} = &{s}_out;\n", .{ arg_name, arg_name });
        }
        try writer.writeAll("const cFn = @extern(*const fn");
        try writer.print("{oc}", .{self.into(CallableInfo)});
        try writer.print(", .{{ .name = \"{s}\"}});\n", .{self.getSymbol()});
        try writer.writeAll("const ret = cFn");
        try writer.print("{}", .{self.into(CallableInfo)});
        try writer.writeAll(";\n");
        if (skip_return) {
            try writer.writeAll("_ = ret;\n");
        }
        if (throw_error) {
            if (throw_bool) {
                try writer.writeAll("_ = ret;\n");
            }
            try writer.writeAll("if (_error) |some| {\n");
            try writer.writeAll("    core.setError(some);\n");
            try writer.writeAll("    return error.GError;\n");
            try writer.writeAll("}\n");
        } else if (throw_bool) {
            try writer.writeAll("if (ret) return error.BooleanError;\n");
        }
        try writer.writeAll("return ");
        var first = true;
        if (n_out > 1) {
            try writer.writeAll(".{ ");
        }
        if (!real_skip_return) {
            first = false;
            if (n_out > 1) {
                try writer.writeAll(".ret = ");
            }
            try writer.writeAll("ret");
        }
        if (n_out_param > 0) {
            for (args, 0..) |arg, idx| {
                if (arg.getDirection() != .out or arg.isCallerAllocates()) continue;
                if (slice_info[idx].is_slice_len) continue;
                if (n_out > 1) {
                    if (first) {
                        first = false;
                    } else {
                        try writer.writeAll(", ");
                    }
                }
                const arg_name = arg.into(BaseInfo).getName().?;
                if (n_out > 1) {
                    try writer.print(".{s} = ", .{arg_name});
                }
                try writer.print("{s}_out", .{arg_name});
                if (slice_info[idx].is_slice_ptr) {
                    const len_arg = args[slice_info[idx].slice_len];
                    try writer.writeAll("[0..@intCast(");
                    if (len_arg.getDirection() == .out and !len_arg.isCallerAllocates()) {
                        try writer.print("{s}_out", .{len_arg.into(BaseInfo).getName().?});
                    } else {
                        try writer.print("_{s}", .{len_arg.into(BaseInfo).getName().?});
                    }
                    try writer.writeAll(")]");
                }
            }
        }
        if (n_out > 1) {
            try writer.writeAll(" }");
        }
        try writer.writeAll(";\n");
        try writer.writeAll("}\n");
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("};\n");
        }
    }
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

    const PrerequisiteIter = Iterator(*InterfaceInfo, *BaseInfo);
    pub fn prerequisiteIter(self: *InterfaceInfo) PrerequisiteIter {
        return .{ .context = self, .capacity = self.getNPrerequisites(), .next_fn = getPrerequisite };
    }

    const PropertyIter = Iterator(*InterfaceInfo, *PropertyInfo);
    pub fn propertyIter(self: *InterfaceInfo) PropertyIter {
        return .{ .context = self, .capacity = self.getNProperties(), .next_fn = getProperty };
    }

    const MethodIter = Iterator(*InterfaceInfo, *FunctionInfo);
    pub fn methodIter(self: *InterfaceInfo) MethodIter {
        return .{ .context = self, .capacity = self.getNMethods(), .next_fn = getMethod };
    }

    const SignalIter = Iterator(*InterfaceInfo, *SignalInfo);
    pub fn signalIter(self: *InterfaceInfo) SignalIter {
        return .{ .context = self, .capacity = self.getNSignals(), .next_fn = getSignal };
    }

    const VFuncIter = Iterator(*InterfaceInfo, *VFuncInfo);
    pub fn vfuncIter(self: *InterfaceInfo) VFuncIter {
        return .{ .context = self, .capacity = self.getNVfuncs(), .next_fn = getVfunc };
    }

    const ConstantIter = Iterator(*InterfaceInfo, *ConstantInfo);
    pub fn constantIter(self: *InterfaceInfo) ConstantIter {
        return .{ .context = self, .capacity = self.getNConstants(), .next_fn = getConstant };
    }

    // @manual
    pub fn format(self_immut: *const InterfaceInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *InterfaceInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        try root.generateDocs(.{ .interface = self }, writer);
        var p_iter = self.propertyIter();
        while (p_iter.next()) |property| {
            try writer.print("{}", .{property});
        }
        const name = self.into(BaseInfo).getName().?;
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.print("pub const {s} = if (core.config.disable_deprecated) core.Deprecated else opaque {{\n", .{name});
        } else {
            try writer.print("pub const {s} = opaque {{\n", .{name});
        }
        var pre_iter = self.prerequisiteIter();
        if (pre_iter.capacity > 0) {
            var first = true;
            try writer.writeAll("pub const Prerequisites = [_]type{");
            while (pre_iter.next()) |prerequisite| {
                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }
                try writer.print("{}.{s}", .{ Namespace{ .str = std.mem.span(prerequisite.into(BaseInfo).getNamespace().?) }, prerequisite.into(BaseInfo).getName().? });
            }
            try writer.writeAll("};\n");
        }
        var c_iter = self.constantIter();
        while (c_iter.next()) |constant| {
            try writer.print("{}", .{constant});
        }
        var m_iter = self.methodIter();
        while (m_iter.next()) |method| {
            try writer.print("{}", .{method});
        }
        var v_iter = self.vfuncIter();
        while (v_iter.next()) |vfunc| {
            try writer.print("{}", .{vfunc});
        }
        var s_iter = self.signalIter();
        while (s_iter.next()) |signal| {
            try writer.print("{}", .{signal});
        }
        try writer.writeAll("pub usingnamespace core.Extend(@This());\n");
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("};\n");
    }
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

    const ConstantIter = Iterator(*ObjectInfo, *ConstantInfo);
    pub fn constantIter(self: *ObjectInfo) ConstantIter {
        return .{ .context = self, .capacity = self.getNConstants(), .next_fn = getConstant };
    }

    const FieldIter = Iterator(*ObjectInfo, *FieldInfo);
    pub fn fieldIter(self: *ObjectInfo) FieldIter {
        return .{ .context = self, .capacity = self.getNFields(), .next_fn = getField };
    }

    const InterfaceIter = Iterator(*ObjectInfo, *InterfaceInfo);
    pub fn interfaceIter(self: *ObjectInfo) InterfaceIter {
        return .{ .context = self, .capacity = self.getNInterfaces(), .next_fn = getInterface };
    }

    const MethodIter = Iterator(*ObjectInfo, *FunctionInfo);
    pub fn methodIter(self: *ObjectInfo) MethodIter {
        return .{ .context = self, .capacity = self.getNMethods(), .next_fn = getMethod };
    }

    const PropertyIter = Iterator(*ObjectInfo, *PropertyInfo);
    pub fn propertyIter(self: *ObjectInfo) PropertyIter {
        return .{ .context = self, .capacity = self.getNProperties(), .next_fn = getProperty };
    }

    const SignalIter = Iterator(*ObjectInfo, *SignalInfo);
    pub fn signalIter(self: *ObjectInfo) SignalIter {
        return .{ .context = self, .capacity = self.getNSignals(), .next_fn = getSignal };
    }

    const VFuncIter = Iterator(*ObjectInfo, *VFuncInfo);
    pub fn vfuncIter(self: *ObjectInfo) VFuncIter {
        return .{ .context = self, .capacity = self.getNVfuncs(), .next_fn = getVfunc };
    }

    // @manual
    pub fn format(self_immut: *const ObjectInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *ObjectInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        try root.generateDocs(.{ .object = self }, writer);
        var p_iter = self.propertyIter();
        while (p_iter.next()) |property| {
            try writer.print("{}", .{property});
        }
        const name = self.into(BaseInfo).getName().?;
        var iter = self.fieldIter();
        try writer.print("pub const {s} = ", .{name});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("if (core.config.disable_deprecated) core.Deprecated else ");
        }
        try writer.print("{s} {{\n", .{if (iter.capacity == 0) "opaque" else "extern struct"});
        BitField.reset();
        while (iter.next()) |field| {
            try writer.print("{}", .{field});
        }
        if (BitField.remaining != null) {
            try BitField.end(writer);
        }
        var i_iter = self.interfaceIter();
        if (i_iter.capacity > 0) {
            var first = true;
            try writer.writeAll("pub const Interfaces = [_]type{");
            while (i_iter.next()) |interface| {
                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }
                try writer.print("{}.{s}", .{ Namespace{ .str = std.mem.span(interface.into(BaseInfo).getNamespace().?) }, interface.into(BaseInfo).getName().? });
            }
            try writer.writeAll("};\n");
        }
        if (self.getParent()) |_parent| {
            try writer.print("pub const Parent = {}.{s};\n", .{ Namespace{ .str = std.mem.span(_parent.into(BaseInfo).getNamespace().?) }, _parent.into(BaseInfo).getName().? });
        }
        if (self.getClassStruct()) |_class| {
            try writer.print("pub const Class = {}.{s};\n", .{ Namespace{ .str = std.mem.span(_class.into(BaseInfo).getNamespace().?) }, _class.into(BaseInfo).getName().? });
        }
        var c_iter = self.constantIter();
        while (c_iter.next()) |constant| {
            try writer.print("{}", .{constant});
        }
        var m_iter = self.methodIter();
        while (m_iter.next()) |method| {
            try writer.print("{}", .{method});
        }
        var v_iter = self.vfuncIter();
        while (v_iter.next()) |vfunc| {
            try writer.print("{}", .{vfunc});
        }
        var s_iter = self.signalIter();
        while (s_iter.next()) |signal| {
            try writer.print("{}", .{signal});
        }
        try writer.writeAll("pub usingnamespace core.Extend(@This());\n");
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("};\n");
    }
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

    // @manual
    pub fn format(self_immut: *const PropertyInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *PropertyInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        try root.generateDocs(.{ .property = self }, writer);
    }
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

    // @manual
    pub fn format(self_immut: *const RegisteredTypeInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *RegisteredTypeInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        if (self.getGType() != .none) {
            try writer.writeAll("pub fn gType() core.Type {\n");
            const init_fn = std.mem.span(self.getTypeInit());
            if (std.mem.eql(u8, "intern", init_fn)) {
                if (@intFromEnum(self.getGType()) < 256 * 4) {
                    try writer.print("return @enumFromInt({});", .{@intFromEnum(self.getGType())});
                } else {
                    try writer.writeAll("@panic(\"Internal type\");");
                }
            } else {
                try writer.print("const cFn = @extern(*const fn () callconv(.C) core.Type, .{{ .name = \"{s}\" }});\n", .{init_fn});
                try writer.writeAll("return cFn();\n");
            }
            try writer.writeAll("}\n");
        }
    }
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

    // @manual
    pub fn format(self_immut: *const SignalInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *SignalInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        const container_name = self.into(BaseInfo).getContainer().?.getName().?;
        var buf: [256]u8 = undefined;
        const raw_name = std.mem.span(self.into(BaseInfo).getName().?);
        const name = snakeToCamel(raw_name, buf[0..]);
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("pub usingnamespace if (core.config.disable_deprecated) struct {\n");
            try writer.print("pub const connect{c}{s} = core.Deprecated;\n", .{ std.ascii.toUpper(name[0]), name[1..] });
            try writer.writeAll("} else struct {\n");
        }
        try root.generateDocs(.{ .signal = self }, writer);
        try writer.print("pub fn connect{c}{s}(self: *{s}, handler: anytype, args: anytype, comptime flags: gobject.ConnectFlags) usize {{\n", .{ std.ascii.toUpper(name[0]), name[1..], container_name });
        try writer.print("return self.connect(\"{s}\", handler, args, flags, &.{{", .{raw_name});
        const return_type = self.into(CallableInfo).getReturnType();
        var interface_returned = false;
        if (return_type.getInterface()) |child_type| {
            switch (child_type.getType()) {
                .@"enum", .flags => {},
                else => interface_returned = true,
            }
        }
        if (self.into(CallableInfo).mayReturnNull() or interface_returned) {
            try writer.print("{mn}", .{return_type});
        } else {
            try writer.print("{m}", .{return_type});
        }
        try writer.print(", *{s}", .{container_name});
        var iter = self.into(CallableInfo).argsIter();
        while (iter.next()) |arg| {
            try writer.print(", {tp}", .{arg});
        }
        try writer.writeAll("});\n");
        try writer.writeAll("}\n");
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("};\n");
        }
    }
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

    const FieldIter = Iterator(*StructInfo, *FieldInfo);
    pub fn fieldIter(self: *StructInfo) FieldIter {
        return .{ .context = self, .capacity = self.getNFields(), .next_fn = getField };
    }

    const MethodIter = Iterator(*StructInfo, *FunctionInfo);
    pub fn methodIter(self: *StructInfo) MethodIter {
        return .{ .context = self, .capacity = self.getNMethods(), .next_fn = getMethod };
    }

    // @manual
    pub fn format(self_immut: *const StructInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *StructInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        try root.generateDocs(.{ .@"struct" = self }, writer);
        const name = std.mem.span(self.into(BaseInfo).getName().?);
        const namespace = std.mem.span(self.into(BaseInfo).getNamespace().?);
        try writer.print("pub const {s} = ", .{name});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("if (core.config.disable_deprecated) core.Deprecated else ");
        }
        try writer.print("{s}{{\n", .{if (self.getSize() == 0) "opaque" else "extern struct"});
        BitField.reset();
        var iter = self.fieldIter();
        while (iter.next()) |field| {
            // TODO: https://github.com/ziglang/zig/issues/12325
            if (std.mem.eql(u8, namespace, "GObject") and std.mem.eql(u8, name, "Closure") and std.mem.eql(u8, std.mem.span(field.into(BaseInfo).getName().?), "notifiers")) {
                try writer.writeAll("notifiers: ?*anyopaque,\n");
                continue;
            }
            try writer.print("{}", .{field});
        }
        if (BitField.remaining != null) {
            try BitField.end(writer);
        }
        var m_iter = self.methodIter();
        while (m_iter.next()) |method| {
            try writer.print("\n{}", .{method});
        }
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("};\n");
    }
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

    // @manual
    pub fn format(self_immut: *const TypeInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *TypeInfo = @constCast(self_immut);
        var option_mut = false;
        var option_nullable = false;
        var option_out = false;
        var option_optional = false;
        inline for (fmt) |ch| {
            switch (ch) {
                'm' => option_mut = true,
                'n' => option_nullable = true,
                'o' => option_out = true,
                'p' => option_optional = true,
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        if (option_out) {
            if (option_optional) {
                try writer.writeAll("?");
            }
            try writer.writeAll("*");
        }

        switch (self.getTag()) {
            .void => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*anyopaque");
                } else {
                    try writer.writeAll("void");
                }
            },
            .boolean, .int8, .uint8, .int16, .uint16, .int32, .uint32, .int64, .uint64, .float, .double, .glist, .gslist, .ghash, .gtype, .@"error", .unichar => |t| {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll(switch (t) {
                    .boolean => "bool",
                    .int8 => "i8",
                    .uint8 => "u8",
                    .int16 => "i16",
                    .uint16 => "u16",
                    .int32 => "i32",
                    .uint32 => "u32",
                    .int64 => "i64",
                    .uint64 => "u64",
                    .float => "f32",
                    .double => "f64",
                    .glist => "core.List",
                    .gslist => "core.SList",
                    .ghash => "core.HashTable",
                    .gtype => "core.Type",
                    .@"error" => "core.Error",
                    .unichar => "core.Unichar",
                    else => unreachable,
                });
            },
            .utf8, .filename => {
                assert(self.isPointer());
                if (option_nullable) {
                    try writer.writeAll("?");
                }
                if (option_mut) {
                    try writer.writeAll("[*:0]u8");
                } else {
                    // string literals are const pointers to null-terminated arrays of u8
                    try writer.writeAll("[*:0]const u8");
                }
            },
            .array => {
                switch (self.getArrayType()) {
                    .c => {
                        const child_type = self.getParamType(0);
                        const size = self.getArrayFixedSize();
                        if (size != -1) {
                            if (self.isPointer()) {
                                if (option_nullable) {
                                    try writer.writeAll("?");
                                }
                                try writer.writeAll("*");
                            }
                            try writer.print("[{}]{n}", .{ size, child_type });
                        } else if (self.isZeroTerminated()) {
                            assert(self.isPointer());
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            if (child_type.isPointer()) {
                                try writer.print("[*:null]{n}", .{child_type});
                            } else {
                                switch (child_type.getTag()) {
                                    .int8, .uint8, .int16, .uint16, .int32, .uint32, .int64, .uint64, .float, .double, .unichar => {
                                        try writer.print("[*:0]{}", .{child_type});
                                    },
                                    else => {
                                        try writer.print("[*:std.mem.zeroes({n})]{n}", .{ child_type, child_type });
                                    },
                                }
                            }
                        } else {
                            assert(self.isPointer());
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            try writer.print("[*]{}", .{child_type});
                        }
                    },
                    .array, .ptr_array, .byte_array => |t| {
                        if (self.isPointer()) {
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            try writer.writeAll("*");
                        }
                        try writer.writeAll(switch (t) {
                            .array => "core.Array",
                            .ptr_array => "core.PtrArray",
                            .byte_array => "core.ByteArray",
                            else => unreachable,
                        });
                    },
                }
            },
            .interface => {
                const child_type = self.getInterface().?;
                switch (child_type.getType()) {
                    .callback => {
                        if (option_nullable) {
                            try writer.writeAll("?");
                        }
                        const callback_name = child_type.getName().?;
                        if (std.ascii.isUpper(callback_name[0])) {
                            try writer.print("{}.{s}", .{ Namespace{ .str = std.mem.span(child_type.getNamespace().?) }, child_type.getName().? });
                        } else {
                            try writer.print("{}", .{child_type.tryInto(CallbackInfo).?});
                        }
                    },
                    .@"struct", .boxed, .@"enum", .flags, .@"union" => {
                        if (self.isPointer()) {
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            try writer.writeAll("*");
                        }
                        try writer.print("{}.{s}", .{ Namespace{ .str = std.mem.span(child_type.getNamespace().?) }, child_type.getName().? });
                    },
                    .object, .interface => {
                        if (self.isPointer()) {
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            try writer.writeAll("*");
                        }
                        try writer.print("{}.{s}", .{ Namespace{ .str = std.mem.span(child_type.getNamespace().?) }, child_type.getName().? });
                    },
                    .invalid, .function, .constant, .invalid_0, .value, .signal, .vfunc, .property, .field, .arg, .type => unreachable,
                    .unresolved => {
                        try writer.print("{}.{s}", .{ Namespace{ .str = std.mem.span(child_type.getNamespace().?) }, child_type.getName().? });
                        std.log.warn("[Unresolved] {s}.{s}", .{ child_type.getNamespace().?, child_type.getName().? });
                    },
                }
            },
        }
    }
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

    const FieldIter = Iterator(*UnionInfo, *FieldInfo);
    pub fn fieldIter(self: *UnionInfo) FieldIter {
        return .{ .context = self, .capacity = self.getNFields(), .next_fn = getField };
    }

    const MethodIter = Iterator(*UnionInfo, *FunctionInfo);
    pub fn methodIter(self: *UnionInfo) MethodIter {
        return .{ .context = self, .capacity = self.getNMethods(), .next_fn = getMethod };
    }

    // @manual
    pub fn format(self_immut: *const UnionInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *UnionInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        try root.generateDocs(.{ .@"union" = self }, writer);
        try writer.print("pub const {s} = ", .{self.into(BaseInfo).getName().?});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("if (core.config.disable_deprecated) core.Deprecated else ");
        }
        try writer.writeAll("extern union{\n");
        var iter = self.fieldIter();
        while (iter.next()) |field| {
            try writer.print("{}", .{field});
        }
        var m_iter = self.methodIter();
        while (m_iter.next()) |method| {
            try writer.print("{}", .{method});
        }
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("};\n");
    }
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

    // @manual
    pub fn format(self_immut: *const VFuncInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *VFuncInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        var buf: [256]u8 = undefined;
        const raw_vfunc_name = std.mem.span(self.into(BaseInfo).getName().?);
        const vfunc_name = snakeToCamel(raw_vfunc_name, buf[0..]);
        const container = self.into(BaseInfo).getContainer().?;
        const class = switch (container.getType()) {
            .object => container.tryInto(ObjectInfo).?.getClassStruct().?,
            .interface => container.tryInto(InterfaceInfo).?.getIfaceStruct(),
            else => unreachable,
        };
        const class_name = class.into(BaseInfo).getName().?;
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("pub usingnamespace struct {} else struct {\n");
        }
        try root.generateDocs(.{ .vfunc = self }, writer);
        try writer.print("pub fn {s}V", .{vfunc_name});
        try writer.print("{ev}", .{self.into(CallableInfo)});
        try writer.writeAll(" {\n");
        try writer.print("const vFn = @as(*{s}, @ptrCast(gobject.typeClassPeek(_gtype))).{s}.?;", .{ class_name, raw_vfunc_name });
        try writer.writeAll("const ret = vFn");
        try writer.print("{v}", .{self.into(CallableInfo)});
        try writer.writeAll(";\n");
        if (self.into(CallableInfo).skipReturn()) {
            try writer.writeAll("_ = ret;\n");
        }
        if (self.into(CallableInfo).skipReturn()) {
            try writer.writeAll("return {};\n");
        } else {
            try writer.writeAll("return ret;\n");
        }
        try writer.writeAll("}\n");
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("};\n");
        }
    }
};
