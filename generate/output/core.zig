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
// meta begin

pub fn FnReturnType(comptime T: type) type {
    const fn_info = @typeInfo(T);
    return if (fn_info.Fn.return_type) |some| some else void;
}

pub fn maybeUnused(arg: anytype) void {
    _ = arg;
}

// meta end
// --------

// ----------
// type begin

pub const Unsupported = @compileError("Unsupported");

pub const Boolean = c_int;
pub const True: Boolean = 1;
pub const False: Boolean = 0;

pub inline fn intToBool(value: Boolean) bool {
    return if (value == 0) false else true;
}

pub inline fn boolToInt(value: bool) Boolean {
    return @boolToInt(value);
}

pub const GType = usize;

/// UCS-4
pub const Unichar = u32;

// type end
// --------

// ----------
// cast begin

pub fn isA(comptime T: type) meta.trait.TraitFn {
    return T.isAImpl;
}

pub fn upCast(comptime T: type, object: anytype) T {
    const U = @TypeOf(object);
    comptime assert(isA(GObject.Object)(T) and isA(GObject.Object)(U));
    comptime assert(isA(T)(U));
    return T{ .instance = @ptrCast(*T.cType(), @alignCast(@alignOf(*T.cType()), object.instance)) };
}

pub fn downCast(comptime T: type, object: anytype) ?T {
    const U = @TypeOf(object);
    comptime assert(isA(GObject.Object)(T) and isA(GObject.Object)(U));
    comptime assert(isA(U)(T));
    const TypeInstance = *GObject.TypeInstanceImpl;
    if (!GObject.typeCheckInstanceIsA(.{ .instance = @ptrCast(TypeInstance, @alignCast(@alignOf(TypeInstance), object.instance)) }, T.gType())) return null;
    return T{ .instance = @ptrCast(*T.cType(), @alignCast(@alignOf(*T.cType()), object.instance)) };
}

pub fn dynamicCast(comptime T: type, object: anytype) ?T {
    const U = @TypeOf(object);
    comptime assert(isA(GObject.Object)(T) and isA(GObject.Object)(U));
    const TypeInstance = *GObject.TypeInstanceImpl;
    if (!GObject.typeCheckInstanceIsA(.{ .instance = @ptrCast(TypeInstance, @alignCast(@alignOf(TypeInstance), object.instance)) }, T.gType())) return null;
    return T{ .instance = @ptrCast(*T.cType(), @alignCast(@alignOf(*T.cType()), object.instance)) };
}

pub fn unsafeCast(comptime T: type, object: anytype) T {
    const U = @TypeOf(object);
    comptime assert(isA(GObject.Object)(T) and isA(GObject.Object)(U));
    return T{ .instance = @ptrCast(*T.cType(), @alignCast(@alignOf(*T.cType()), object.instance)) };
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
            pub fn invoke(object: signature[1], self: *Self) callconv(.C) signature[0] {
                return @call(.auto, self.func, .{object} ++ self.args);
            }
        } else struct {};

        pub usingnamespace if (!swapped and signature.len == 3) struct {
            pub fn invoke(object: signature[1], arg2: signature[2], self: *Self) callconv(.C) signature[0] {
                return @call(.auto, self.func, .{ object, arg2 } ++ self.args);
            }
        } else struct {};

        pub usingnamespace if (!swapped and signature.len == 4) struct {
            pub fn invoke(object: signature[1], arg2: signature[2], arg3: signature[3], self: *Self) callconv(.C) signature[0] {
                return @call(.auto, self.func, .{ object, arg2, arg3 } ++ self.args);
            }
        } else struct {};

        pub usingnamespace if (!swapped and signature.len == 5) struct {
            pub fn invoke(object: signature[1], arg2: signature[2], arg3: signature[3], arg4: signature[4], self: *Self) callconv(.C) signature[0] {
                return @call(.auto, self.func, .{ object, arg2, arg3, arg4 } ++ self.args);
            }
        } else struct {};

        pub usingnamespace if (!swapped and signature.len == 6) struct {
            pub fn invoke(object: signature[1], arg2: signature[2], arg3: signature[3], arg4: signature[4], arg5: signature[5], self: *Self) callconv(.C) signature[0] {
                return @call(.auto, self.func, .{ object, arg2, arg3, arg4, arg5 } ++ self.args);
            }
        } else struct {};

        pub usingnamespace if (!swapped and signature.len == 7) struct {
            pub fn invoke(object: signature[1], arg2: signature[2], arg3: signature[3], arg4: signature[4], arg5: signature[5], arg6: signature[6], self: *Self) callconv(.C) signature[0] {
                return @call(.auto, self.func, .{ object, arg2, arg3, arg4, arg5, arg6 } ++ self.args);
            }
        } else struct {};

        pub fn deinit(self: *Self, closure: GObject.Closure) callconv(.C) void {
            _ = closure;
            const allocator = gpa.allocator();
            allocator.destroy(self);
        }
    };
}

pub fn createZigClosure(func: anytype, args: anytype, comptime swapped: bool, comptime signature: anytype) *ZigClosure(@TypeOf(func), @TypeOf(args), swapped, signature) {
    const allocator = gpa.allocator();
    const closure = allocator.create(ZigClosure(@TypeOf(func), @TypeOf(args), swapped, signature)) catch @panic("Out Of Memory");
    closure.func = func;
    closure.args = args;
    return closure;
}

// closure end
// -----------

// -------------
// connect begin

extern fn g_signal_connect_data(GObject.Object, [*:0]const u8, GObject.Callback, ?*anyopaque, GObject.ClosureNotify, GObject.ConnectFlags) usize;

pub const ZigConnectFlags = struct {
    after: bool = false,
    swapped: bool = false,
};

pub fn connect(object: anytype, comptime signal: [*:0]const u8, comptime handler: anytype, args: anytype, comptime flags: ZigConnectFlags, comptime signature: anytype) usize {
    const Closure = ZigClosure(@TypeOf(&handler), @TypeOf(args), flags.swapped, signature);
    const closure: *Closure = createZigClosure(&handler, args, flags.swapped, signature);
    const closure_invoke = @ptrCast(GObject.Callback, &Closure.invoke);
    const closure_deinit = @ptrCast(GObject.ClosureNotify, &Closure.deinit);
    const flag = (if (flags.after) @enumToInt(GObject.ConnectFlags.After) else 0) | (if (flags.swapped) @enumToInt(GObject.ConnectFlags.Swapped) else 0);
    return g_signal_connect_data(upCast(GObject.Object, object), signal, closure_invoke, closure, closure_deinit, @intToEnum(GObject.ConnectFlags, flag));
}

// connect end
// -----------
