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

pub const Boolean = enum(c_int) {
    False = 0,
    True = 1,

    pub inline fn fromBool(value: bool) Boolean {
        return @intToEnum(Boolean, @boolToInt(value));
    }

    pub inline fn toBool(self: Boolean) bool {
        return @enumToInt(self) != @enumToInt(Boolean.False);
    }

    pub fn format(self: Boolean, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("{}", self.toBool());
    }
};

pub const GType = enum(usize) {
    Invalid = 0,
    None = 4,
    Interface = 8,
    Char = 12,
    Uchar = 16,
    Boolean = 20,
    Int = 24,
    Uint = 28,
    Long = 32,
    Ulong = 36,
    Int64 = 40,
    Uint64 = 44,
    Enum = 48,
    Flags = 52,
    Float = 56,
    Double = 60,
    String = 64,
    Pointer = 68,
    Boxed = 72,
    Param = 76,
    Object = 80,
    Variant = 84,
    _,

    pub fn gType() GType {
        return GObject.gtypeGetType();
    }
};

/// UCS-4
pub const Unichar = u32;

// type end
// --------

pub fn Expected(comptime T: type, comptime E: type) type {
    return union(enum) {
        value: T,
        err: E,
    };
}

pub fn Flags(comptime T: type) type {
    return struct {
        value: meta.tag(T),

        const Self = @This();

        pub inline fn @"|"(self: Self, f: Self) Self {
            return .{ .value = @intToEnum(T, @enumToInt(self.value) | @enumToInt(f.value)) };
        }

        pub inline fn @"&"(self: Self, f: Self) Self {
            return .{ .value = @intToEnum(T, @enumToInt(self.value) & @enumToInt(f.value)) };
        }

        pub inline fn @"^"(self: Self, f: Self) Self {
            return .{ .value = @intToEnum(T, @enumToInt(self.value) ^ @enumToInt(f.value)) };
        }

        pub inline fn @"-"(self: Self, f: Self) Self {
            return .{ .value = @intToEnum(T, @enumToInt(self.value) & ~@enumToInt(f.value)) };
        }

        pub inline fn @"~"(self: Self) Self {
            return .{ .value = @intToEnum(T, ~@enumToInt(self.value)) };
        }

        pub inline fn isEmpty(self: Self) bool {
            return @enumToInt(self.value) == 0;
        }

        pub inline fn intersects(self: Self, f: Self) bool {
            return @enumToInt(self.value) & @enumToInt(f.value) != 0;
        }

        pub inline fn contains(self: Self, f: Self) bool {
            return @enumToInt(self.value) & @enumToInt(f.value) == @enumToInt(f.value);
        }
    };
}

pub fn ValueZ(comptime T: type) type {
    return struct {
        value: GObject.Value = std.mem.zeroes(GObject.Value),

        const Self = @This();

        pub fn new() Self {
            var tmp: Self = .{};
            tmp.init();
            return tmp;
        }

        const Int = @Type(@typeInfo(c_int));
        const Uint = @Type(@typeInfo(c_uint));
        const Long = @Type(@typeInfo(c_long));
        const Ulong = @Type(@typeInfo(c_ulong));

        fn init(self: *Self) void {
            if (T == Boolean) {
                _ = self.value.init(.Boolean);
            } else if (T == i8) {
                _ = self.value.init(.Char);
            } else if (T == u8) {
                _ = self.value.init(.Uchar);
            } else if (T == Int) {
                _ = self.value.init(.Int);
            } else if (T == Uint) {
                _ = self.value.init(.Uint);
            } else if (T == i64) {
                _ = self.value.init(.Int64);
            } else if (T == u64) {
                _ = self.value.init(.UInt64);
            } else if (T == Long) {
                _ = self.value.init(.Long);
            } else if (T == Ulong) {
                _ = self.value.init(.Ulong);
            } else if (T == f32) {
                _ = self.value.init(.Float);
            } else if (T == f64) {
                _ = self.value.init(.Double);
            } else if (T == [*:0]const u8) {
                _ = self.value.init(.String);
            } else if (meta.trait.isSingleItemPtr(T)) {
                _ = self.value.init(.Pointer);
            } else if (T == GLib.Variant) {
                _ = self.value.init(.Variant);
            } else if (T == GObject.ParamSpec) {
                _ = self.value.init(.Param);
            } else if (@hasDecl(T, "gType")) {
                _ = self.value.init(T.gType());
            } else {
                @compileError(std.fmt.comptimePrint("Unsupported type {s} for GObject.Value", @typeName(T)));
            }
        }

        pub fn deinit(self: *Self) void {
            self.value.unset();
        }

        fn isBasic() bool {
            if (T == i8) return true;
            if (T == u8) return true;
            if (T == i16) return true;
            if (T == u16) return true;
            if (T == i32) return true;
            if (T == u32) return true;
            if (T == i64) return true;
            if (T == u64) return true;
            if (T == f32) return true;
            if (T == f64) return true;
            if (T == [*:0]const u8) return true; // String
            if (meta.trait.isSingleItemPtr(T)) return true; // Pointer
            if (meta.trait.is(.Enum)(T)) return true; // Enum(or Flags) or Boolean or GType
            return false;
        }

        pub fn get(self: *Self) if (isBasic()) T else *T {
            if (T == Boolean) {
                return self.value.getBoolean();
            } else if (T == i8) {
                return self.value.getSchar();
            } else if (T == u8) {
                return self.value.getUchar();
            } else if (T == Int) {
                return self.value.getInt();
            } else if (T == Uint) {
                return self.value.getUint();
            } else if (T == i64) {
                return self.value.getInt64();
            } else if (T == u64) {
                return self.value.getUint64();
            } else if (T == Long) {
                return self.value.getLong();
            } else if (T == Ulong) {
                return self.value.getUlong();
            } else if (T == f32) {
                return self.value.getFloat();
            } else if (T == f64) {
                return self.value.getDouble();
            } else if (T == GType) {
                return self.value.getGtype();
            } else if (meta.trait.is(.Enum)(T)) {
                return if (comptime @typeInfo(T).Enum.is_exhaustive) @intToEnum(T, self.gvalue.getEnum()) else @intToEnum(T, self.gvalue.getFlags());
            } else if (T == [*:0]const u8) {
                return self.value.getString();
            } else if (meta.trait.isSingleItemPtr(T)) {
                return @ptrCast(T, self.gvalue.getPointer());
            } else if (T == GLib.Variant) {
                return self.value.getVariant().?;
            } else if (T == GObject.ParamSpec) {
                return self.value.getParam();
            } else if (@hasDecl(T, "tryInto")) {
                const obj = self.value.getObject();
                return obj.tryInto(T).?;
            } else {
                return @ptrCast(*T, self.value.getBoxed().?);
            }
        }

        pub fn set(self: *Self, _value: if (isBasic()) T else *T) void {
            if (T == Boolean) {
                self.value.setBoolean(_value);
            } else if (T == i8) {
                self.value.setSchar(_value);
            } else if (T == u8) {
                self.value.setUchar(_value);
            } else if (T == Int) {
                self.value.setInt(_value);
            } else if (T == Uint) {
                self.value.setUint(_value);
            } else if (T == i64) {
                self.value.setInt64(_value);
            } else if (T == u64) {
                self.value.setUint64(_value);
            } else if (T == Long) {
                self.value.setLong(_value);
            } else if (T == Ulong) {
                self.value.setUlong(_value);
            } else if (T == f32) {
                self.value.setFloat(_value);
            } else if (T == f64) {
                self.value.setDouble(_value);
            } else if (T == GType) {
                self.value.setGtype(_value);
            } else if (meta.trait.is(.Enum)(T)) {
                if (@typeInfo(T).Enum.is_exhaustive) {
                    self.value.setEnum(@enumToInt(_value));
                } else {
                    self.value.setFlags(@enumToInt(_value));
                }
            } else if (T == [*:0]const u8) {
                self.value.setString(_value);
            } else if (meta.trait.isSingleItemPtr(T)) {
                self.value.setPointer(_value);
            } else if (T == GLib.Variant) {
                self.value.setVariant(_value);
            } else if (T == GObject.ParamSpec) {
                self.gvalue.setParam(_value);
            } else if (@hasDecl(T, "into")) {
                self.value.setObject(_value.into(GObject.Object));
            } else {
                self.value.setBoxed(_value);
            }
        }

        pub fn asValue(self: *Self) *GObject.Value {
            return &self.value;
        }
    };
}

// ---------
// OOP begin

/// U is subclass of V?
fn isA(comptime U: type, comptime V: type) bool {
    if (U == V) return true;
    if (@hasDecl(U, "Prerequisites")) {
        for (U.Prerequisites) |prerequisite| {
            if (isA(prerequisite, V)) return true;
        }
    }
    if (@hasDecl(U, "Interfaces")) {
        for (U.Interfaces) |interface| {
            if (isA(interface, V)) return true;
        }
    }
    if (@hasDecl(U, "Parent")) {
        if (isA(U.Parent, V)) return true;
    }
    return false;
}

pub inline fn upCast(comptime T: type, object: anytype) *T {
    comptime assert(isA(meta.Child(@TypeOf(object)), T));
    return unsafeCast(T, object);
}

pub inline fn downCast(comptime T: type, object: anytype) ?*T {
    comptime assert(isA(T, meta.Child(@TypeOf(object))));
    return dynamicCast(T, object);
}

pub inline fn dynamicCast(comptime T: type, object: anytype) ?*T {
    return if (GObject.typeCheckInstanceIsA(unsafeCast(GObject.TypeInstance, object), T.gType()).toBool()) unsafeCast(T, object) else null;
}

pub inline fn unsafeCast(comptime T: type, object: anytype) *T {
    return @ptrCast(*T, @alignCast(@alignOf(*T), object));
}

pub fn DispatchZ(comptime T: type, comptime method: []const u8) ?type {
    if (@hasDecl(T, "Prerequisites")) {
        for (T.Prerequisites) |prerequisite| {
            if (prerequisite.CallZ(method)) |some| return some;
        }
    }
    if (@hasDecl(T, "Interfaces")) {
        for (T.Interfaces) |interface| {
            if (interface.CallZ(method)) |some| return some;
        }
    }
    if (@hasDecl(T, "Parent")) {
        if (T.Parent.CallZ(method)) |some| return some;
    }
    return null;
}

pub fn dispatchZ(self: anytype, comptime method: []const u8, args: anytype) DispatchZ(meta.Child(@TypeOf(self)), method).? {
    const T = meta.Child(@TypeOf(self));
    if (@hasDecl(T, "Prerequisites")) {
        inline for (T.Prerequisites) |prerequisite| {
            if (comptime prerequisite.CallZ(method)) |_| {
                return self.into(prerequisite).callZ(method, args);
            }
        }
    }
    if (@hasDecl(T, "Interfaces")) {
        inline for (T.Interfaces) |interface| {
            if (comptime interface.CallZ(method)) |_| {
                return self.into(interface).callZ(method, args);
            }
        }
    }
    if (@hasDecl(T, "Parent")) {
        if (T.Parent.CallZ(method)) |_| {
            return self.into(T.Parent).callZ(method, args);
        }
    }
}

// OOP end
// -------

// -------------
// closure begin

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

fn cclosureNew(callback_func: GObject.Callback, user_data: ?*anyopaque, destroy_data: GObject.ClosureNotify) *GObject.Closure {
    return struct {
        pub extern fn g_cclosure_new(GObject.Callback, ?*anyopaque, GObject.ClosureNotify) *GObject.Closure;
    }.g_cclosure_new(callback_func, user_data, destroy_data);
}

fn cclosureNewSwap(callback_func: GObject.Callback, user_data: ?*anyopaque, destroy_data: GObject.ClosureNotify) *GObject.Closure {
    return struct {
        pub extern fn g_cclosure_new_swap(GObject.Callback, ?*anyopaque, GObject.ClosureNotify) *GObject.Closure;
    }.g_cclosure_new_swap(callback_func, user_data, destroy_data);
}

pub fn ClosureZ(comptime Fn: type, comptime Args: type, comptime signature: []const type) type {
    comptime assert(meta.trait.isPtrTo(.Fn)(Fn));
    comptime assert(meta.trait.isTuple(Args));
    comptime assert(1 <= signature.len and signature.len <= 7);

    return struct {
        handler: Fn,
        args: Args,
        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn new(allocator: ?std.mem.Allocator, handler: Fn, args: Args) !*Self {
            const real_allocator = if (allocator) |some| some else gpa.allocator();
            var closure = try real_allocator.create(Self);
            closure.handler = handler;
            closure.args = args;
            closure.allocator = real_allocator;
            return closure;
        }

        pub usingnamespace if (signature.len == 1) struct {
            pub fn invoke(self: *Self) callconv(.C) signature[0] {
                return @call(.auto, self.handler, self.args);
            }
        } else struct {};

        pub usingnamespace if (signature.len == 2) struct {
            pub fn invoke(arg1: signature[1], self: *Self) callconv(.C) signature[0] {
                return @call(.auto, self.handler, .{arg1} ++ self.args);
            }
        } else struct {};

        pub usingnamespace if (signature.len == 3) struct {
            pub fn invoke(arg1: signature[1], arg2: signature[2], self: *Self) callconv(.C) signature[0] {
                return @call(.auto, self.handler, .{ arg1, arg2 } ++ self.args);
            }
        } else struct {};

        pub usingnamespace if (signature.len == 4) struct {
            pub fn invoke(arg1: signature[1], arg2: signature[2], arg3: signature[3], self: *Self) callconv(.C) signature[0] {
                return @call(.auto, self.handler, .{ arg1, arg2, arg3 } ++ self.args);
            }
        } else struct {};

        pub usingnamespace if (signature.len == 5) struct {
            pub fn invoke(arg1: signature[1], arg2: signature[2], arg3: signature[3], arg4: signature[4], self: *Self) callconv(.C) signature[0] {
                return @call(.auto, self.handler, .{ arg1, arg2, arg3, arg4 } ++ self.args);
            }
        } else struct {};

        pub usingnamespace if (signature.len == 6) struct {
            pub fn invoke(arg1: signature[1], arg2: signature[2], arg3: signature[3], arg4: signature[4], arg5: signature[5], self: *Self) callconv(.C) signature[0] {
                return @call(.auto, self.handler, .{ arg1, arg2, arg3, arg4, arg5 } ++ self.args);
            }
        } else struct {};

        pub usingnamespace if (signature.len == 7) struct {
            pub fn invoke(arg1: signature[1], arg2: signature[2], arg3: signature[3], arg4: signature[4], arg5: signature[5], arg6: signature[6], self: *Self) callconv(.C) signature[0] {
                return @call(.auto, self.handler, .{ arg1, arg2, arg3, arg4, arg5, arg6 } ++ self.args);
            }
        } else struct {};

        pub fn deinit(self: *Self) void {
            self.allocator.destroy(self);
        }

        pub fn toClosure(self: *Self) *GObject.Closure {
            return cclosureNew(@ptrCast(GObject.Callback, &Self.invoke), self, @ptrCast(GObject.ClosureNotify, &Self.deinit));
        }

        pub fn toClosureSwap(self: *Self) *GObject.Closure {
            comptime assert(signature.len == 1);
            return cclosureNewSwap(@ptrCast(GObject.Callback, &Self.invoke), self, @ptrCast(GObject.ClosureNotify, &Self.deinit));
        }
    };
}

pub const ConnectFlagsZ = struct {
    after: bool = false,
    allocator: ?std.mem.Allocator = null,
};

pub fn connectZ(object: *GObject.Object, signal: [*:0]const u8, handler: anytype, args: anytype, flags: ConnectFlagsZ, comptime signature: []const type) usize {
    var closure = ClosureZ(@TypeOf(&handler), @TypeOf(args), signature).new(flags.allocator, handler, args) catch @panic("Out of Memory");
    return GObject.signalConnectClosure(object, signal, closure.toClosure(), Boolean.fromBool(flags.after));
}

pub fn connectSwapZ(object: *GObject.Object, signal: [*:0]const u8, handler: anytype, args: anytype, flags: ConnectFlagsZ, comptime signature: []const type) usize {
    comptime assert(signature.len == 1);
    var closure = ClosureZ(@TypeOf(&handler), @TypeOf(args), signature).new(flags.allocator, handler, args) catch @panic("Out of Memory");
    return GObject.signalConnectClosure(object, signal, closure.toClosureSwap(), Boolean.fromBool(flags.after));
}

// closure end
// -----------
