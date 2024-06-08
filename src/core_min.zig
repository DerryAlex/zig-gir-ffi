const std = @import("std");

// ----------
// type begin

/// A numerical value which represents the unique identifier of a registered type
pub const Type = enum(usize) {
    invalid = 0,
    none = 4,
    interface = 8,
    char = 12,
    uchar = 16,
    boolean = 20,
    int = 24,
    uint = 28,
    long = 32,
    ulong = 36,
    int64 = 40,
    uint64 = 44,
    @"enum" = 48,
    flags = 52,
    float = 56,
    double = 60,
    string = 64,
    pointer = 68,
    boxed = 72,
    param = 76,
    object = 80,
    variant = 84,
    _,
};

// type end
// --------

// -----------
// error begin

var err: ?*Error = null;

/// Set information about an error.GError that has occurred
pub fn setError(_err: *Error) void {
    if (err != null) unreachable;
    err = _err;
}

/// Get information about an error.GError that has occurred
pub fn getError() *Error {
    defer err = null;
    return err.?;
}

// error end
// ---------

// ---------------------
// OOP inheritance begin

/// Returns a function to check whether a type can be cast to T
pub fn isA(comptime T: type) fn (type) bool {
    return struct {
        pub fn trait(comptime Ty: type) bool {
            if (Ty == T) return true;
            if (@hasDecl(Ty, "Prerequisites")) {
                for (Ty.Prerequisites) |Prerequisite| {
                    if (trait(Prerequisite)) return true;
                }
            }
            if (@hasDecl(Ty, "Interfaces")) {
                for (Ty.Interfaces) |Interface| {
                    if (trait(Interface)) return true;
                }
            }
            if (@hasDecl(Ty, "Parent")) {
                if (trait(Ty.Parent)) return true;
            }
            return false;
        }
    }.trait;
}

/// Converts to base type T
pub inline fn upCast(comptime T: type, object: anytype) *T {
    comptime std.debug.assert(isA(T)(std.meta.Child(@TypeOf(object))));
    return unsafeCast(T, object);
}

/// Converts to derived type T
pub inline fn downCast(comptime T: type, object: anytype) ?*T {
    comptime std.debug.assert(isA(std.meta.Child(@TypeOf(object)))(T));
    //TODO: return dynamicCast(T, object);
    return unsafeCast(T, object);
}

/// Converts to type T safely
pub inline fn dynamicCast(comptime T: type, object: anytype) ?*T {
    return if (typeCheckInstanceIsA(unsafeCast(TypeInstance, object), T.gType())) unsafeCast(T, object) else null;
}

/// Converts to type T.
/// It is the caller's responsibility to ensure that the cast is legal.
pub inline fn unsafeCast(comptime T: type, object: anytype) *T {
    return @ptrCast(@alignCast(object));
}

pub fn Extend(comptime Self: type) type {
    return struct {
        /// Converts to base type T
        pub fn into(self: *Self, comptime T: type) *T {
            return upCast(T, self);
        }

        /// Converts to derived type T
        pub fn tryInto(self: *Self, comptime T: type) ?*T {
            return downCast(T, self);
        }
    };
}

// OOP inheritance end
// -------------------

// ----------
// GLib begin

pub const Bytes = opaque {};

pub const Data = opaque {};

pub const Error = extern struct {
    domain: u32,
    code: i32,
    message: ?[*:0]const u8,
};

pub const List = extern struct {
    data: ?*anyopaque,
    next: ?*List,
    prev: ?*List,
};

pub const SList = extern struct {
    data: ?*anyopaque,
    next: ?*SList,
};

pub const OptionGroup = opaque {};

// GLib end
// --------

// -------------
// GObject begin

pub const Closure = extern struct {
    ref_count: u32,
    meta_marshal_nouse: u32,
    n_guards: u32,
    n_fnotifiers: u32,
    n_inotifiers: u32,
    in_inotify: u32,
    floating: u32,
    derivative_flag: u32,
    in_marshal: u32,
    is_invalid: u32,
    marshal: ?*anyopaque,
    data: ?*anyopaque,
    notifiers: ?*anyopaque,
};

pub const Object = extern struct {
    g_type_instance: TypeInstance,
    ref_count: u32,
    qdata: ?*Data,
};

pub const ObjectClass = extern struct {
    g_type_class: TypeClass,
    construct_properties: ?*SList,
    constructor: ?*anyopaque,
    set_property: ?*anyopaque,
    get_property: ?*anyopaque,
    dispose: ?*anyopaque,
    finalize: ?*anyopaque,
    dispatch_properties_changed: ?*anyopaque,
    notify: ?*anyopaque,
    constructed: ?*anyopaque,
    flags: u64,
    n_construct_properties: u64,
    pspecs: ?*anyopaque,
    n_pspecs: u64,
    pdummy: [3]?*anyopaque,
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

pub const TypeClass = extern struct {
    g_type: Type,
};

pub const TypeInstance = extern struct {
    g_class: ?*TypeClass,
};

pub const _Value__data__union = extern union {
    v_int: i32,
    v_uint: u32,
    v_long: i64,
    v_ulong: u64,
    v_int64: i64,
    v_uint64: u64,
    v_float: f32,
    v_double: f64,
    v_pointer: ?*anyopaque,
};

pub const Value = extern struct {
    g_type: Type,
    data: [2]_Value__data__union,
};

pub fn typeCheckInstanceIsA(_instance: *TypeInstance, _iface_type: Type) bool {
    const cFn = @extern(*const fn (*TypeInstance, Type) callconv(.C) bool, .{ .name = "g_type_check_instance_is_a" });
    const ret = cFn(_instance, _iface_type);
    return ret;
}

// GObject end
// -----------
