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

    pub fn new(value: bool) Boolean {
        return .{ .value = @boolToInt(value) };
    }

    pub fn get(self: Boolean) bool {
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

pub fn isA(comptime T: type) meta.trait.TraitFn {
    return T.isAImpl;
}

fn runtimeTypeCheck(ptr: *anyopaque, type_id: GType) bool {
    const T = *GObject.TypeInstanceImpl;
    return GObject.typeCheckInstanceIsA(.{ .instance = @ptrCast(T, @alignCast(@alignOf(T), ptr)) }, type_id).get();
}

pub fn upCast(comptime T: type, object: anytype) T {
    const U = @TypeOf(object);
    comptime assert(isA(T)(U));
    return T{ .instance = @ptrCast(*T.cType(), @alignCast(@alignOf(*T.cType()), object.instance)) };
}

pub fn downCast(comptime T: type, object: anytype) ?T {
    const U = @TypeOf(object);
    comptime assert(isA(U)(T));
    if (!runtimeTypeCheck(object.instance, T.gType())) return null;
    return T{ .instance = @ptrCast(*T.cType(), @alignCast(@alignOf(*T.cType()), object.instance)) };
}

pub fn dynamicCast(comptime T: type, object: anytype) ?T {
    if (!runtimeTypeCheck(object.instance, T.gType())) return null;
    return T{ .instance = @ptrCast(*T.cType(), @alignCast(@alignOf(*T.cType()), object.instance)) };
}

pub fn unsafeCast(comptime T: type, object: anytype) T {
    return T{ .instance = @ptrCast(*T.cType(), @alignCast(@alignOf(*T.cType()), object.instance)) };
}

pub fn dynamicCastPtr(comptime T: type, ptr: *anyopaque) ?T {
    if (!runtimeTypeCheck(ptr, T.gType())) return null;
    return T{ .instance = @ptrCast(*T.cType(), @alignCast(@alignOf(*T.cType()), ptr)) };
}

pub fn unsafeCastPtr(comptime T: type, ptr: *anyopaque) T {
    return T{ .instance = @ptrCast(*T.cType(), @alignCast(@alignOf(*T.cType()), ptr)) };
}

// cast end
// --------

// -------------
// closure begin

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

fn ZigClosure(comptime T: type, comptime U: type, comptime swapped: bool, comptime signature: anytype) type {
    comptime assert(meta.trait.isPtrTo(.Fn)(T));

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
pub fn createClosure(comptime func: anytype, args: anytype, comptime swapped: bool, comptime signature: anytype) *ZigClosure(@TypeOf(&func), @TypeOf(args), swapped, signature) {
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

pub usingnamespace struct {
    extern fn g_free(?*const anyopaque) void;

    /// Supress `discard const`
    pub fn freeDiscardConst(mem: ?*const anyopaque) void {
        g_free(mem);
    }
};

// misc end
// --------

// ----------------------------------
// indirectly available binding begin

pub usingnamespace struct {
    extern fn g_signal_connect_data(GObject.Object, [*:0]const u8, GObject.Callback, ?*anyopaque, GObject.ClosureNotify, GObject.ConnectFlags) c_ulong;

    pub const ZigConnectFlags = struct {
        after: bool = false,
        swapped: bool = false,
    };

    pub fn connect(object: anytype, comptime signal: [*:0]const u8, comptime handler: anytype, args: anytype, comptime flags: ZigConnectFlags, comptime signature: anytype) usize {
        const closure = createClosure(handler, args, flags.swapped, signature);
        const closure_invoke = @ptrCast(GObject.Callback, closure.invoke_fn());
        const closure_deinit = @ptrCast(GObject.ClosureNotify, closure.deinit_fn());
        const flag = (if (flags.after) @enumToInt(GObject.ConnectFlags.After) else 0) | (if (flags.swapped) @enumToInt(GObject.ConnectFlags.Swapped) else 0);
        return g_signal_connect_data(upCast(GObject.Object, object), signal, closure_invoke, closure, closure_deinit, @intToEnum(GObject.ConnectFlags, flag));
    }
};

pub usingnamespace struct {
    extern fn g_object_new_with_properties(GType, c_uint, ?[*][*:0]const u8, ?[*]GObject.Value.cType()) GObject.Object;

    pub fn newObject(object_type: GType, names: ?[][*:0]const u8, values: ?[]GObject.Value.cType()) GObject.Object {
        assert((names == null) == (values == null));
        if (names) |_| assert(names.?.len == values.?.len);
        return g_object_new_with_properties(object_type, if (names) |some| @intCast(c_uint, some.len) else 0, if (names) |some| some.ptr else null, if (values) |some| some.ptr else null);
    }
};

// pub usingnamespace struct {
//     extern fn g_hash_table_new_full(GLib.HashFunc, GLib.EqualFunc, ?GLib.DestroyNotify, ?GLib.DestroyNotify) GLib.HashTable;

//     pub fn newHashTable(hash_func: GLib.HashFunc, key_equal_func: GLib.EqualFunc, key_destroy_func: ?GLib.DestroyNotify, value_destroy_func: ?GLib.DestroyNotify) GLib.HashTable {
//         return g_hash_table_new_full(hash_func, key_equal_func, key_destroy_func, value_destroy_func);
//     }
// };

pub usingnamespace struct {
    extern fn g_type_register_static_simple(GType, [*:0]const u8, c_uint, GObject.ClassInitFunc, c_uint, GObject.InstanceInitFunc, GObject.TypeFlags) GType;

    pub fn typeRegisterStaticSimple(parent_type: GType, type_name: [*:0]const u8, class_size: usize, class_init: GObject.ClassInitFunc, instance_size: usize, instance_init: GObject.InstanceInitFunc, flags: GObject.TypeFlags) GType {
        return g_type_register_static_simple(parent_type, type_name, @intCast(c_uint, class_size), class_init, @intCast(c_uint, instance_size), instance_init, flags);
    }
};

// indirectly available binding end
// --------------------------------
