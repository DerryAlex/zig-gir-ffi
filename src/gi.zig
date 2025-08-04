//! Interfaces for GObject Introspection

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const StringArrayHashMapUnmanaged = std.StringArrayHashMapUnmanaged;
const Writer = std.Io.Writer;
const fmt = @import("fmt.zig");

/// `Repository` is used to manage namespaces.
pub const Repository = struct {
    allocator: Allocator,
    vtable: VTable,
    _search_paths: ArrayListUnmanaged([]const u8) = .empty,
    namespaces: StringArrayHashMapUnmanaged(Namespace) = .empty,

    pub const Error = Allocator.Error || error{FileNotFound};

    pub const VTable = struct {
        load: *const fn (self: *Repository, namespace: []const u8, version: ?[]const u8) Error!void,

        pub fn chain(comptime first: VTable, comptime second: VTable) VTable {
            const chained = struct {
                fn load(self: *Repository, namespace: []const u8, version: ?[]const u8) Error!void {
                    first.load(self, namespace, version) catch {
                        try second.load(self, namespace, version);
                    };
                }
            };
            return .{ .load = chained.load };
        }

        /// Load namespace from .gir files
        pub const gir: VTable = .{
            .load = @import("backend/gir.zig").load,
        };

        /// Load namespace from .typelib files
        pub const typelib: VTable = .{
            .load = @import("backend/typelib.zig").load,
        };
    };

    pub fn init(allocator: Allocator, vtable: VTable) Repository {
        return .{
            .allocator = allocator,
            .vtable = vtable,
        };
    }

    pub fn deinit(self: *Repository) void {
        self.search_paths.deinit(self.allocator);
        for (self.namespaces.values()) |*ns| {
            ns.deinit();
        }
        self.namespaces.deinit(self.allocator);
    }

    /// Append `dir` to search path.
    pub fn appendSearchPath(self: *Repository, dir: []const u8) Allocator.Error!void {
        try self._search_paths.append(self.allocator, dir);
    }

    /// Load `namespace` if it isn't ready.
    pub fn load(self: *Repository, namespace: []const u8, version: ?[]const u8) Error!void {
        if (self.namespaces.contains(namespace)) return;
        try self.vtable.load(self, namespace, version);
    }
};

pub const Namespace = struct {
    name: []const u8,
    dependencies: ArrayListUnmanaged([]const u8) = .empty,
    infos: ArrayListUnmanaged(Info) = .empty,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Namespace {
        return .{ .name = try allocator.dupe(u8, name) };
    }

    pub fn deinit(self: *Namespace, allocator: Allocator) void {
        for (self.dependencies.items) |dep| allocator.free(dep);
        self.dependencies.deinit(allocator);
        for (self.infos.items) |*info| info.deinit(allocator);
        self.infos.deinit(allocator);
        allocator.free(self.name);
    }
};

/// Closed interface for Info structs.
pub const Info = union(enum) {
    arg: Arg,
    callback: Callback,
    function: Function,
    signal: Signal,
    vfunc: VFunc,
    constant: Constant,
    @"enum": Enum,
    flags: Flags,
    interface: Interface,
    object: Object,
    @"struct": Struct,
    @"union": Union,
    field: Field,
    property: Property,
    type: Type,
    unresolved: Unresolved,
    value: Value,

    pub fn deinit(self: *Info, allocator: Allocator) void {
        switch (self.*) {
            inline else => |*info| info.deinit(allocator),
        }
    }

    pub fn getBase(self: *Info) *const Base {
        return switch (self.*) {
            inline else => |*info| info.getBase(),
        };
    }

    pub fn format(self: *Info, writer: *Writer) Writer.Error!void {
        switch (self.*) {
            inline else => |*info| try info.format(writer),
        }
    }
};

/// `Base` is the common base struct of all other Info structs.
pub const Base = struct {
    name: []const u8,
    namespace: []const u8 = &.{},

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Base {
        if (std.mem.indexOfScalar(u8, name, '.')) |pos| return .{
            .name = try allocator.dupe(u8, name[pos + 1 ..]),
            .namespace = try allocator.dupe(u8, name[0..pos]),
        };
        return .{ .name = try allocator.dupe(u8, name) };
    }

    pub fn deinit(self: *Base, allocator: Allocator) void {
        allocator.free(self.name);
        allocator.free(self.namespace);
    }

    pub fn format(self: *const Base, writer: *Writer) Writer.Error!void {
        if (self.namespace.len > 0) try writer.print("{s}.", .{self.namespace});
        try writer.print("{s}", .{self.name});
    }
};

/// `Arg` represents an argument of a callable.
pub const Arg = struct {
    base: Base,
    type_info: ?*Type = null,
    // basic information
    direction: Direction = .in,
    ownership_transfer: Transfer = .nothing,
    caller_allocates: bool = false,
    may_be_null: bool = false,
    optional: bool = false,
    // closure information
    closure_index: ?usize = null,
    destroy_index: ?usize = null,
    scope: ScopeType = .invalid,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Arg {
        return .{ .base = try .init(allocator, name) };
    }

    pub fn deinit(self: *Arg, allocator: Allocator) void {
        if (self.type_info) |t| {
            t.deinit(allocator);
            allocator.destroy(t);
        }
        self.base.deinit(allocator);
    }

    pub fn getBase(self: *Arg) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *Arg, writer: *Writer) Writer.Error!void {
        _ = self;
        _ = writer;
        unreachable;
    }
};

pub const Callable = struct {
    base: Base,
    args: ArrayListUnmanaged(Arg) = .empty,
    return_type: ?*Type = null,
    // basic information
    can_throw_gerror: bool = false,
    is_method: bool = false,
    may_return_null: bool = false,
    skip_return: bool = false,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Callable {
        return .{ .base = try .init(allocator, name) };
    }

    pub fn deinit(self: *Callable, allocator: Allocator) void {
        for (self.args.items) |*a| a.deinit(allocator);
        self.args.deinit(allocator);
        if (self.return_type) |r| r.deinit(allocator);
        self.base.deinit(allocator);
    }
};

/// `Callback` represents a callback.
pub const Callback = struct {
    callable: Callable,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Callback {
        return .{ .callable = try .init(allocator, name) };
    }

    pub fn deinit(self: *Callback, allocator: Allocator) void {
        self.callable.deinit(allocator);
    }

    pub fn getBase(self: *Callback) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *Callback, writer: *Writer) Writer.Error!void {
        try writer.print("pub const {s} = {f}", .{ self.getBase().name, fmt.CallbackFormatter{ .callback = self } });
    }
};

/// `Function` represents a function, method or constructor.
pub const Function = struct {
    callable: Callable,
    symbol: ?[]const u8 = null,
    flags: FunctionFlags = .{},

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Function {
        return .{ .callable = try .init(allocator, name) };
    }

    pub fn deinit(self: *Function, allocator: Allocator) void {
        self.callable.deinit(allocator);
        if (self.symbol) |s| {
            allocator.free(s);
        }
    }

    pub fn getBase(self: *Function) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *Function, writer: *Writer) Writer.Error!void {
        try writer.print("{f}", .{fmt.FunctionFormatter{ .function = self }});
    }
};

/// `Signal` represents a signal.
pub const Signal = struct {
    callable: Callable,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Signal {
        return .{ .callable = try .init(allocator, name) };
    }

    pub fn deinit(self: *Signal, allocator: Allocator) void {
        self.callable.deinit(allocator);
    }

    pub fn getBase(self: *Signal) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *Signal, writer: *Writer) Writer.Error!void {
        _ = self;
        _ = writer;
        unreachable;
    }
};

/// `VFunc` represents a virtual function.
pub const VFunc = struct {
    callable: Callable,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!VFunc {
        return .{ .callable = try .init(allocator, name) };
    }

    pub fn deinit(self: *VFunc, allocator: Allocator) void {
        self.callable.deinit(allocator);
    }

    pub fn getBase(self: *VFunc) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *VFunc, writer: *Writer) Writer.Error!void {
        _ = self;
        _ = writer;
        unreachable;
    }
};

/// `Constant` represents a constant.
pub const Constant = struct {
    base: Base,
    type_tag: TypeTag = .void,
    value: Argument = .{ .v_pointer = null },

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Constant {
        return .{ .base = try .init(allocator, name) };
    }

    pub fn deinit(self: *Constant, allocator: Allocator) void {
        self.base.deinit(allocator);
    }

    pub fn getBase(self: *Constant) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *Constant, writer: *Writer) Writer.Error!void {
        try writer.print("{f}", .{fmt.ConstantFormatter{ .constant = self }});
    }
};

pub const RegisteredType = struct {
    base: Base,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!RegisteredType {
        return .{ .base = try .init(allocator, name) };
    }

    pub fn deinit(self: *RegisteredType, allocator: Allocator) void {
        self.base.deinit(allocator);
    }
};

/// `Enum` represents an enumeration.
pub const Enum = struct {
    base: RegisteredType,
    storage_type: TypeTag = .void,
    values: ArrayListUnmanaged(Value) = .empty,
    methods: ArrayListUnmanaged(Function) = .empty,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Enum {
        return .{ .base = try .init(allocator, name) };
    }

    pub fn deinit(self: *Enum, allocator: Allocator) void {
        for (self.values.items) |*v| v.deinit(allocator);
        self.values.deinit(allocator);
        for (self.methods.items) |*m| m.deinit(allocator);
        self.methods.deinit(allocator);
        self.base.deinit(allocator);
    }

    pub fn getBase(self: *Enum) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *Enum, writer: *Writer) Writer.Error!void {
        try writer.print("{f}", .{fmt.EnumFormatter{ .context = self }});
    }
};

/// `Flags` represents an enumeration which defines flag values (independently set bits).
pub const Flags = struct {
    base: Enum,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Flags {
        return .{ .base = try .init(allocator, name) };
    }

    pub fn deinit(self: *Flags, allocator: Allocator) void {
        self.base.deinit(allocator);
    }

    pub fn getBase(self: *Flags) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *Flags, writer: *Writer) Writer.Error!void {
        try writer.print("{f}", .{fmt.FlagsFormatter{ .context = self }});
    }
};

/// `Interface` represents an interface type.
pub const Interface = struct {
    base: RegisteredType,
    constants: ArrayListUnmanaged(Constant) = .empty,
    methods: ArrayListUnmanaged(Function) = .empty,
    prerequisites: ArrayListUnmanaged(Info) = .empty,
    properties: ArrayListUnmanaged(Property) = .empty,
    signals: ArrayListUnmanaged(Signal) = .empty,
    vfuncs: ArrayListUnmanaged(VFunc) = .empty,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Interface {
        return .{ .base = try .init(allocator, name) };
    }

    pub fn deinit(self: *Interface, allocator: Allocator) void {
        for (self.constants.items) |*c| c.deinit(allocator);
        self.constants.deinit(allocator);
        for (self.methods.items) |*m| m.deinit(allocator);
        self.methods.deinit(allocator);
        for (self.prerequisites.items) |*p| p.deinit(allocator);
        self.prerequisites.deinit(allocator);
        for (self.properties.items) |*p| p.deinit(allocator);
        self.properties.deinit(allocator);
        for (self.signals.items) |*s| s.deinit(allocator);
        self.signals.deinit(allocator);
        for (self.vfuncs.items) |*v| v.deinit(allocator);
        self.vfuncs.deinit(allocator);
        self.base.deinit(allocator);
    }

    pub fn getBase(self: *Interface) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *Interface, writer: *Writer) Writer.Error!void {
        try writer.print("{f}", .{fmt.InterfaceFormatter{ .context = self }});
    }
};

/// `Object` represents a classed type.
pub const Object = struct {
    base: RegisteredType,
    class_struct: ?*Base = null,
    parent: ?*Base = null,
    constants: ArrayListUnmanaged(Constant) = .empty,
    fields: ArrayListUnmanaged(Field) = .empty,
    interfaces: ArrayListUnmanaged(Interface) = .empty,
    methods: ArrayListUnmanaged(Function) = .empty,
    properties: ArrayListUnmanaged(Property) = .empty,
    signals: ArrayListUnmanaged(Signal) = .empty,
    vfuncs: ArrayListUnmanaged(VFunc) = .empty,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Object {
        return .{ .base = try .init(allocator, name) };
    }

    pub fn deinit(self: *Object, allocator: Allocator) void {
        if (self.class_struct) |c| {
            c.deinit(allocator);
            allocator.destroy(c);
        }
        if (self.parent) |p| {
            p.deinit(allocator);
            allocator.destroy(p);
        }
        for (self.constants.items) |*c| c.deinit(allocator);
        self.constants.deinit(allocator);
        for (self.interfaces.items) |*i| i.deinit(allocator);
        self.interfaces.deinit(allocator);
        for (self.methods.items) |*m| m.deinit(allocator);
        self.methods.deinit(allocator);
        for (self.properties.items) |*p| p.deinit(allocator);
        self.properties.deinit(allocator);
        for (self.signals.items) |*s| s.deinit(allocator);
        self.signals.deinit(allocator);
        for (self.vfuncs.items) |*v| v.deinit(allocator);
        self.vfuncs.deinit(allocator);
        self.base.deinit(allocator);
    }

    pub fn getBase(self: *Object) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *Object, writer: *Writer) Writer.Error!void {
        try writer.print("{f}", .{fmt.ObjectFormatter{ .context = self }});
    }
};

/// `Struct` represents a generic C structure type.
pub const Struct = struct {
    base: RegisteredType,
    fields: ArrayListUnmanaged(Field) = .empty,
    methods: ArrayListUnmanaged(Function) = .empty,
    size: usize = 0,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Struct {
        return .{ .base = try .init(allocator, name) };
    }

    pub fn deinit(self: *Struct, allocator: Allocator) void {
        for (self.fields.items) |*f| f.deinit(allocator);
        self.fields.deinit(allocator);
        for (self.methods.items) |*m| m.deinit(allocator);
        self.methods.deinit(allocator);
        self.base.deinit(allocator);
    }

    pub fn getBase(self: *Struct) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *Struct, writer: *Writer) Writer.Error!void {
        try writer.print("{f}", .{fmt.StructFormatter{ .context = self }});
    }
};

/// `Union` represents a union type.
pub const Union = struct {
    base: RegisteredType,
    fields: ArrayListUnmanaged(Field) = .empty,
    methods: ArrayListUnmanaged(Function) = .empty,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Union {
        return .{ .base = try .init(allocator, name) };
    }

    pub fn deinit(self: *Union, allocator: Allocator) void {
        for (self.fields.items) |*f| f.deinit(allocator);
        self.fields.deinit(allocator);
        for (self.methods.items) |*m| m.deinit(allocator);
        self.methods.deinit(allocator);
        self.base.deinit(allocator);
    }

    pub fn getBase(self: *Union) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *Union, writer: *Writer) Writer.Error!void {
        try writer.print("{f}", .{fmt.UnionFormatter{ .context = self }});
    }
};

/// `Field` represents a field of a struct, union, or object.
pub const Field = struct {
    base: Base,
    offset: usize = 0,
    size: usize = 0,
    type_info: ?*Type = null,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Field {
        return .{ .base = try .init(allocator, name) };
    }

    pub fn deinit(self: *Field, allocator: Allocator) void {
        if (self.type_info) |t| {
            t.deinit(allocator);
            allocator.destroy(t);
        }
        self.base.deinit(allocator);
    }

    pub fn getBase(self: *Field) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *Field, writer: *Writer) Writer.Error!void {
        _ = self;
        _ = writer;
        unreachable;
    }
};

/// `Property` represents a property in a `GObject`.
pub const Property = struct {
    base: Base,
    type_info: ?*Type = null,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Property {
        return .{ .base = try .init(allocator, name) };
    }

    pub fn deinit(self: *Property, allocator: Allocator) void {
        if (self.type_info) |t| {
            t.deinit(allocator);
            allocator.destroy(t);
        }
        self.base.deinit(allocator);
    }

    pub fn getBase(self: *Property) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *Property, writer: *Writer) Writer.Error!void {
        _ = self;
        _ = writer;
        unreachable;
    }
};

/// `Type` represents a type, including information about direction and transfer.
pub const Type = struct {
    base: Base,
    // basic information
    tag: TypeTag = .void,
    pointer: bool = false,
    // array information
    array_type: ArrayType = .c,
    array_fixed_size: ?usize = null,
    array_length_index: ?usize = null,
    zero_terminated: bool = false,
    param_type: ?*Type = null,
    // interface information
    interface: ?*Base = null,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Type {
        return .{ .base = try .init(allocator, name) };
    }

    pub fn deinit(self: *Type, allocator: Allocator) void {
        if (self.param_type) |p| {
            p.deinit(allocator);
            allocator.destroy(p);
        }
        if (self.interface) |i| {
            i.deinit(allocator);
            allocator.destroy(i);
        }
        self.base.deinit(allocator);
    }

    pub fn getBase(self: *Type) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *Type, writer: *Writer) Writer.Error!void {
        _ = self;
        _ = writer;
        unreachable;
    }
};

/// `Unresolved` represents an unresolved symbol.
pub const Unresolved = struct {
    base: Base,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Unresolved {
        return .{ .base = try .init(allocator, name) };
    }

    pub fn deinit(self: *Unresolved, allocator: Allocator) void {
        self.base.deinit(allocator);
    }

    pub fn getBase(self: *Unresolved) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *Unresolved, writer: *Writer) Writer.Error!void {
        _ = self;
        _ = writer;
        unreachable;
    }
};

/// `Value` represents a value in an enumeration.
pub const Value = struct {
    base: Base,
    value: i64 = 0,

    pub fn init(allocator: Allocator, name: []const u8) Allocator.Error!Value {
        return .{ .base = try .init(allocator, name) };
    }

    pub fn deinit(self: *Value, allocator: Allocator) void {
        self.base.deinit(allocator);
    }

    pub fn getBase(self: *Value) *const Base {
        return @ptrCast(self);
    }

    pub fn format(self: *Value, writer: *Writer) Writer.Error!void {
        _ = self;
        _ = writer;
        unreachable;
    }
};

// enums
pub const ArrayType = enum(u32) {
    c = 0,
    array = 1,
    ptr_array = 2,
    byte_array = 3,
};

pub const Direction = enum(u32) {
    in = 0,
    out = 1,
    inout = 2,
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
};

pub const ScopeType = enum(u32) {
    invalid = 0,
    call = 1,
    async = 2,
    notified = 3,
    forever = 4,
};

// flags
pub const FieldFlags = packed struct(u32) {
    readable: bool = false,
    writable: bool = false,
    _: u30 = 0,
};

pub const FunctionFlags = packed struct(u32) {
    is_method: bool = false,
    is_constructor: bool = false,
    is_getter: bool = false,
    is_setter: bool = false,
    wraps_vfunc: bool = false,
    is_async: bool = false,
    _: u26 = 0,
};

pub const ParamFlags = packed struct(u32) {
    readable: bool = false,
    writable: bool = false,
    construct: bool = false,
    construct_only: bool = false,
    lax_validation: bool = false,
    static_name: bool = false,
    static_nick: bool = false,
    static_blurb: bool = false,
    _8: u22 = 0,
    explicit_notify: bool = false,
    deprecated: bool = false,

    pub const readwrite: @This() = .{ .readable = true, .writeable = true };
};

pub const SignalFlags = packed struct(u32) {
    run_first: bool = false,
    run_last: bool = false,
    run_cleanup: bool = false,
    no_recurse: bool = false,
    detailed: bool = false,
    action: bool = false,
    no_hooks: bool = false,
    must_collect: bool = false,
    deprecated: bool = false,
    _9: u8 = 0,
    accumulator_first_run: bool = false,
    _: u14 = 0,
};

pub const VFuncFlags = packed struct(u32) {
    chain_up: bool = false,
    must_override: bool = false,
    must_not_override: bool = false,
    _: u29 = 0,
};

// structs
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
    v_short: c_short,
    v_ushort: c_ushort,
    v_int: c_int,
    v_uint: c_uint,
    v_long: c_long,
    v_ulong: c_ulong,
    v_ssize: isize,
    v_size: usize,
    v_string: ?[*:0]const u8,
    v_pointer: ?*anyopaque,
};
