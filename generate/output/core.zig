const GLib = @import("GLib.zig");
const GObject = @import("GObject.zig");
const Gio = @import("Gio.zig");
pub usingnamespace GLib;
pub usingnamespace GObject;
pub usingnamespace Gio;
const std = @import("std");
const meta = std.meta;
const assert = std.debug.assert;

// ----------
// type begin

pub const Unsupported = @compileError("Unsupported");

pub const Boolean = packed struct {
    value: c_int,

    pub const True = Boolean{ .value = 1 };
    pub const False = Boolean{ .value = 0 };

    pub fn toBool(self: Boolean) bool {
        return self.value != 0;
    }

    pub fn format(self: Boolean, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.writeAll(if (self.value == 0) "false" else "true");
    }
};

pub const GType = packed struct {
    value: usize,

    pub const Invalid = GType{ .value = 0 };
    pub const None = GType{ .value = 4 };
    pub const Interface = GType{ .value = 8 };
    pub const Char = GType{ .value = 12 };
    pub const UChar = GType{ .value = 16 };
    pub const Boolean = GType{ .value = 20 };
    pub const Int = GType{ .value = 24 };
    pub const Uint = GType{ .value = 28 };
    pub const Long = GType{ .value = 32 };
    pub const Ulong = GType{ .value = 36 };
    pub const Int64 = GType{ .value = 40 };
    pub const Uint64 = GType{ .value = 44 };
    pub const Enum = GType{ .value = 48 };
    pub const Flags = GType{ .value = 52 };
    pub const Float = GType{ .value = 56 };
    pub const Double = GType{ .value = 60 };
    pub const String = GType{ .value = 64 };
    pub const Pointer = GType{ .value = 68 };
    pub const Boxed = GType{ .value = 72 };
    pub const Object = GType{ .value = 80 };
    pub const Variant = GType{ .value = 84 };
};

/// UCS-4
pub const Unichar = u32;

// type end
// --------

// ----------
// cast begin

pub fn alignedCast(comptime T: type, ptr: *anyopaque) T {
    comptime assert(meta.trait.isSingleItemPtr(T));
    return @ptrCast(T, @alignCast(@alignOf(T), ptr));
}

pub fn isA(comptime T: type) meta.trait.TraitFn {
    const Closure = struct {
        pub fn trait(comptime Ty: type) bool {
            return T.isAImpl(Ty) or (@hasDecl(Ty, "Parent") and T.isAImpl(Ty.Parent));
        }
    };
    return Closure.trait;
}

fn comptimeTypeCheck(comptime U: type, comptime V: type) void {
    if (comptime !isA(U)(V)) @compileError(std.fmt.comptimePrint("{s} cannot cast into {s}", .{ @typeName(V), @typeName(U) }));
}

fn runtimeTypeCheck(ptr: *anyopaque, type_id: GType) bool {
    return GObject.typeCheckInstanceIsA(alignedCast(*GObject.TypeInstance, ptr), type_id).toBool();
}

pub fn upCast(comptime T: type, object: anytype) T {
    comptimeTypeCheck(T, @TypeOf(object));
    return T{ .instance = alignedCast(*T.cType(), object.instance) };
}

pub fn downCast(comptime T: type, object: anytype) ?T {
    comptimeTypeCheck(@TypeOf(object), T);
    if (!runtimeTypeCheck(object.instance, T.gType())) return null;
    return T{ .instance = alignedCast(*T.cType(), object.instance) };
}

pub fn dynamicCast(comptime T: type, ptr: *anyopaque) ?T {
    if (!runtimeTypeCheck(ptr, T.gType())) return null;
    return T{ .instance = alignedCast(*T.cType(), ptr) };
}

pub fn unsafeCast(comptime T: type, ptr: *anyopaque) T {
    return T{ .instance = alignedCast(*T.cType(), ptr) };
}

// cast end
// --------

// -------------
// closure begin

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

fn ZigClosure(comptime T: type, comptime U: type, comptime swapped: bool, comptime signature: []const type) type {
    comptime assert(meta.trait.isPtrTo(.Fn)(T));
    comptime assert(signature.len <= 7);

    return struct {
        func: T,
        args: U,

        const Self = @This();

        pub usingnamespace if (swapped) struct {
            pub fn invoke(self: *Self) callconv(.C) signature[0] {
                return @call(.auto, self.func, self.args);
            }
        } else struct {};

        pub usingnamespace if (!swapped and signature.len == 2) struct {
            pub fn invoke(object: signature[1], data: ?*anyopaque) callconv(.C) signature[0] {
                var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), data.?));
                return @call(.auto, self.func, .{object} ++ self.args);
            }
        } else struct {};

        pub usingnamespace if (!swapped and signature.len == 3) struct {
            pub fn invoke(object: signature[1], arg2: signature[2], data: ?*anyopaque) callconv(.C) signature[0] {
                var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), data.?));
                return @call(.auto, self.func, .{ object, arg2 } ++ self.args);
            }
        } else struct {};

        pub usingnamespace if (!swapped and signature.len == 4) struct {
            pub fn invoke(object: signature[1], arg2: signature[2], arg3: signature[3], data: ?*anyopaque) callconv(.C) signature[0] {
                var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), data.?));
                return @call(.auto, self.func, .{ object, arg2, arg3 } ++ self.args);
            }
        } else struct {};

        pub usingnamespace if (!swapped and signature.len == 5) struct {
            pub fn invoke(object: signature[1], arg2: signature[2], arg3: signature[3], arg4: signature[4], data: ?*anyopaque) callconv(.C) signature[0] {
                var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), data.?));
                return @call(.auto, self.func, .{ object, arg2, arg3, arg4 } ++ self.args);
            }
        } else struct {};

        pub usingnamespace if (!swapped and signature.len == 6) struct {
            pub fn invoke(object: signature[1], arg2: signature[2], arg3: signature[3], arg4: signature[4], arg5: signature[5], data: ?*anyopaque) callconv(.C) signature[0] {
                var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), data.?));
                return @call(.auto, self.func, .{ object, arg2, arg3, arg4, arg5 } ++ self.args);
            }
        } else struct {};

        pub usingnamespace if (!swapped and signature.len == 7) struct {
            pub fn invoke(object: signature[1], arg2: signature[2], arg3: signature[3], arg4: signature[4], arg5: signature[5], arg6: signature[6], data: ?*anyopaque) callconv(.C) signature[0] {
                var self = @ptrCast(*Self, @alignCast(@alignOf(*Self), data.?));
                return @call(.auto, self.func, .{ object, arg2, arg3, arg4, arg5, arg6 } ++ self.args);
            }
        } else struct {};

        pub fn deinit(self: *Self) callconv(.C) void {
            const allocator = gpa.allocator();
            allocator.destroy(self);
        }

        pub fn invoke_fn(self: *Self) @TypeOf(&(@This().invoke)) {
            _ = self;
            return &(@This().invoke);
        }

        pub fn deinit_fn(self: *Self) @TypeOf(&(@This().deinit)) {
            _ = self;
            return &(@This().deinit);
        }
    };
}

/// Create a closure
/// @func:      Function to be called
/// @args:      Extra custom arguments(by value)
/// @swapped:   Whether to only take custom arguments
/// @signature: A tuple describing callback, `signature[0]` for return type, `signature[1..]` for argument types
///             e.g. `.{void, Object}` for `*const fn(Object, ?*anyopaque) callconv(.C) void`
/// Use `closure.invoke_fn()` to get C callback
/// Call `closure.deinit()` to destroy closure, or pass `closure.deinit_fn()` as destroy function
pub fn createClosure(comptime func: anytype, args: anytype, comptime swapped: bool, comptime signature: []const type) *ZigClosure(@TypeOf(&func), @TypeOf(args), swapped, signature) {
    const allocator = gpa.allocator();
    const closure = allocator.create(ZigClosure(@TypeOf(&func), @TypeOf(args), swapped, signature)) catch @panic("Out Of Memory");
    closure.func = &func;
    closure.args = args;
    return closure;
}

// closure end
// -----------

// ----------
// misc begin

pub fn FnReturnType(comptime T: type) type {
    const fn_info = @typeInfo(T);
    return if (fn_info.Fn.return_type) |some| some else void;
}

/// Suppress `unused`
pub fn maybeUnused(arg: anytype) void {
    _ = arg;
}

/// Supress `discard const`
pub fn freeDiscardConst(mem: ?*const anyopaque) void {
    struct {
        pub extern fn g_free(?*const anyopaque) void;
    }.g_free(mem);
}

// misc end
// --------

pub const ConnectFlagsZ = struct {
    after: bool = false,
    swapped: bool = false,
};

/// Connects a GCallback function to a signal for a particular object.
/// Similar to g_signal_connect(), but allows to provide a GClosureNotify for the data which will be called when the signal handler is disconnected and no longer used.
/// Specify connect_flags if you need ..._after() or ..._swapped() variants of this function.
/// @instance:        The instance to connect to.
/// @detailed_signal: A string of the form "signal-name::detail".
/// @c_handler:       The GCallback to connect.
/// @data:            Data to pass to c_handler calls.
/// @destroy_data:    A GClosureNotify for data.
/// @connect_flags:   A combination of GConnectFlags.
/// Return:           The handler ID (always greater than 0 for successful connections)
pub fn connect(object: GObject.Object, comptime signal: [*:0]const u8, comptime handler: anytype, args: anytype, comptime flags: ConnectFlagsZ, comptime signature: []const type) usize {
    const closure = createClosure(handler, args, flags.swapped, signature);
    const closure_invoke = @ptrCast(GObject.Callback, closure.invoke_fn());
    const closure_deinit = @ptrCast(GObject.ClosureNotify, closure.deinit_fn());
    const flag = (if (flags.after) @enumToInt(GObject.ConnectFlags.After) else 0) | (if (flags.swapped) @enumToInt(GObject.ConnectFlags.Swapped) else 0);
    return struct {
        pub extern fn g_signal_connect_data(GObject.Object, [*:0]const u8, GObject.Callback, ?*anyopaque, GObject.ClosureNotify, GObject.ConnectFlags) c_ulong;
    }.g_signal_connect_data(object, signal, closure_invoke, closure, closure_deinit, @intToEnum(GObject.ConnectFlags, flag));
}

/// Creates a new instance of a GObject subtype and sets its properties using the provided arrays.
/// Both arrays must have exactly n_properties elements, and the names and values correspond by index.
/// Construction parameters (see G_PARAM_CONSTRUCT, G_PARAM_CONSTRUCT_ONLY) which are not explicitly specified are set to their default values.
/// @object_type:  The object type to instantiate.
/// @n_properties: The number of properties.
/// @names:        The names of each property to be set.
/// @values:       The values of each property to be set.
/// Return:        A new instance of object_type
pub fn newObject(object_type: GType, names: ?[][*:0]const u8, values: ?[]GObject.Value) GObject.Object {
    assert((names == null) == (values == null));
    if (names) |_| assert(names.?.len == values.?.len);
    return struct {
        pub extern fn g_object_new_with_properties(GType, c_uint, ?[*][*:0]const u8, ?[*]GObject.Value) GObject.Object;
    }.g_object_new_with_properties(object_type, if (names) |some| @intCast(c_uint, some.len) else 0, if (names) |some| some.ptr else null, if (values) |some| some.ptr else null);
}

/// Registers type_name as the name of a new static type derived from parent_type.
/// The value of flags determines the nature (e.g. abstract or not) of the type.
/// It works by filling a GTypeInfo struct and calling g_type_register_static().
/// @parent_type:   Type from which this type will be derived.
/// @type_name:     0-terminated string used as the name of the new type.
/// @class_size:    Size of the class structure (see GTypeInfo)
/// @class_init:    Location of the class initialization function (see GTypeInfo)
/// @instance_size: Size of the instance structure (see GTypeInfo)
/// @instance_init: Location of the instance initialization function (see GTypeInfo)
/// @flags:         Bitwise combination of GTypeFlags values.
/// Return:         The new type identifier.
pub fn typeRegisterStaticSimple(parent_type: GType, type_name: [*:0]const u8, class_size: usize, class_init: ?GObject.ClassInitFunc, instance_size: usize, instance_init: ?GObject.InstanceInitFunc, flags: GObject.TypeFlags) GType {
    return struct {
        pub extern fn g_type_register_static_simple(GType, [*:0]const u8, c_uint, ?GObject.ClassInitFunc, c_uint, ?GObject.InstanceInitFunc, GObject.TypeFlags) GType;
    }.g_type_register_static_simple(parent_type, type_name, @intCast(c_uint, class_size), class_init, @intCast(c_uint, instance_size), instance_init, flags);
}

pub const TypeFlagsZ = struct {
    abstract: bool = false,
    value_abstract: bool = false,
    final: bool = false,
    register_fn: ?*const fn(GType) void = null,
};

/// Convenience wrapper for Type implementations
/// Instance should be a wrapped type
/// Boilerplates for register_fn:
/// (ADD_PRIVATE)         private_offset = core.typeAddInstancePrivate(instance_gtype, @sizeOf(PrivateImpl));
/// (IMPLEMENT_INTERFACE) var interface_info: core.InterfaceInfo = .{ .interface_init = @ptrCast(InstanceInitFunc, &init_fn), .interface_finalize = null, .interface_data = null };
///                       core.typeAddInterfaceStatic(instance_gtype, interface_gtype, &interface_info);
pub fn registerType(comptime Class: type, comptime Instance: type, name: [*:0]const u8, comptime flags: TypeFlagsZ) GType {
    comptime var class_init: ?GObject.ClassInitFunc = null;
    comptime var instance_init: ?GObject.InstanceInitFunc = null;
    comptime {
        if (@hasDecl(Class, "init")) {
            const init_fn: fn (*Class) callconv(.C) void = Class.init;
            class_init = @ptrCast(GObject.ClassInitFunc, &init_fn);
        }
        if (@hasDecl(Instance, "init")) {
            const init_fn: fn (Instance) callconv(.C) void = Instance.init;
            instance_init = @ptrCast(GObject.InstanceInitFunc, &init_fn);
        }
    }
    const Static = struct {
        var type_id: GType = GType.Invalid;
    };
    if (GLib.onceInitEnter(&Static.type_id).toBool()) {
        const flag = (if (flags.abstract) @enumToInt(GObject.TypeFlags.Abstract) else 0) | (if (flags.value_abstract) @enumToInt(GObject.TypeFlags.ValueAbstrace) else 0) | (if (flags.final) @enumToInt(GObject.TypeFlags.Final) else 0);
        var type_id = typeRegisterStaticSimple(Instance.Parent.gType(), name, @sizeOf(Class), class_init, @sizeOf(Instance.cType()), instance_init, @intToEnum(GObject.TypeFlags, flag));
        if (flags.register_fn) |func| {
            func(type_id);
        }
        defer GLib.onceInitLeave(&Static.type_id, type_id.value);
    }
    return Static.type_id;
}

/// Convenience wrapper for Interface definitions
/// Boliterplates for register_fn:
/// core.typeInterfaceAddPrerequisite(interface_gtype, prerequisite_gtype);
pub fn registerInterface(comptime Interface: type, name: [*:0]const u8, comptime flags: TypeFlagsZ) GType {
    comptime var class_init: ?GObject.ClassInitFunc = null;
    comptime {
        if (@hasDecl(Interface, "init")) {
            const init_fn: fn (*Interface) callconv(.C) void = Interface.init;
            class_init = @ptrCast(GObject.ClassInitFunc, &init_fn);
        }
    }
    const Static = struct {
        var type_id: GType = GType.Invalid;
    };
    if (GLib.onceInitEnter(&Static.type_id).toBool()) {
        var type_id = typeRegisterStaticSimple(GType.Interface, name, @sizeOf(Interface), class_init, 0, null, .None);
        if (flags.register_fn) |func| {
            func(type_id);
        }
        defer GLib.onceInitLeave(&Static.type_id, type_id.value);
    }
    return Static.type_id;
}
