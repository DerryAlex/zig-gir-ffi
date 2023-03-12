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

/// A numerical value which represents the unique identifier of a registered type
pub const Type = enum(usize) {
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
};

/// UCS-4
pub const Unichar = u32;

/// Wrapper for GValue
pub fn ValueZ(comptime T: type) type {
    return struct {
        value: GObject.Value,

        const Self = @This();

        const Int = @Type(@typeInfo(c_int));
        const Uint = @Type(@typeInfo(c_uint));
        const Long = @Type(@typeInfo(c_long));
        const Ulong = @Type(@typeInfo(c_ulong));

        pub fn init() Self {
            // var value = std.mem.zeroes(GObject.Value);
            var value: GObject.Value = .{ .g_type = .Invalid, .data = .{ .{ .v_pointer = null }, .{ .v_pointer = null } } };
            if (comptime T == void) {
                value.g_type = .None; // for internal use
            } else if (comptime T == bool) {
                _ = value.init(.Boolean);
            } else if (comptime T == i8) {
                _ = value.init(.Char);
            } else if (comptime T == u8) {
                _ = value.init(.Uchar);
            } else if (comptime T == Int) {
                _ = value.init(.Int);
            } else if (comptime T == Uint) {
                _ = value.init(.Uint);
            } else if (comptime T == i64) {
                _ = value.init(.Int64);
            } else if (comptime T == u64) {
                _ = value.init(.UInt64);
            } else if (comptime T == Long) {
                _ = value.init(.Long);
            } else if (comptime T == Ulong) {
                _ = value.init(.Ulong);
            } else if (comptime T == f32) {
                _ = value.init(.Float);
            } else if (comptime T == f64) {
                _ = value.init(.Double);
            } else if (comptime T == [*:0]const u8) {
                _ = value.init(.String);
            } else if (comptime meta.trait.isSingleItemPtr(T)) {
                _ = value.init(.Pointer);
            } else if (comptime T == GLib.Variant) {
                _ = value.init(.Variant);
            } else if (comptime T == GObject.ParamSpec) {
                _ = value.init(.Param);
            } else if (comptime @hasDecl(T, "type")) {
                _ = value.init(T.type());
            } else {
                @compileError(std.fmt.comptimePrint("cannot initialize GValue with type {s}", @typeName(T)));
            }
            return .{ .value = value };
        }

        pub fn deinit(self: *Self) void {
            self.value.unset();
        }

        const is_basic = gen_is_basic: {
            if (T == void) break :gen_is_basic true;
            if (T == bool) break :gen_is_basic true;
            if (T == i8) break :gen_is_basic true;
            if (T == u8) break :gen_is_basic true;
            if (T == i16) break :gen_is_basic true;
            if (T == u16) break :gen_is_basic true;
            if (T == i32) break :gen_is_basic true;
            if (T == u32) break :gen_is_basic true;
            if (T == i64) break :gen_is_basic true;
            if (T == u64) break :gen_is_basic true;
            if (T == f32) break :gen_is_basic true;
            if (T == f64) break :gen_is_basic true;
            if (meta.trait.is(.Enum)(T)) break :gen_is_basic true; // Enum(or Flags) or Type
            if (T == [*:0]const u8) break :gen_is_basic true; // String
            if (meta.trait.isSingleItemPtr(T)) break :gen_is_basic true; // Pointer
            break :gen_is_basic false;
        };

        pub fn get(self: Self) if (is_basic) T else *T {
            if (comptime T == void) ("Cannot initialize GValue with type void");
            if (comptime T == bool) return self.value.getBoolean();
            if (comptime T == i8) return self.value.getSchar();
            if (comptime T == u8) return self.value.getUchar();
            if (comptime T == Int) return self.value.getInt();
            if (comptime T == Uint) return self.value.getUint();
            if (comptime T == i64) return self.value.getInt64();
            if (comptime T == u64) return self.value.getUint64();
            if (comptime T == Long) return self.value.getLong();
            if (comptime T == Ulong) return self.value.getUlong();
            if (comptime T == f32) return self.value.getFloat();
            if (comptime T == f64) return self.value.getDouble();
            if (comptime T == Type) return self.value.getGtype();
            if (comptime meta.trait.is(.Enum)(T)) {
                if (@typeInfo(T).Enum.is_exhaustive) {
                    return @intToEnum(T, self.value.getEnum());
                } else {
                    return @intToEnum(T, self.value.getFlags());
                }
            }
            if (comptime T == [*:0]const u8) return self.value.getString();
            if (comptime meta.trait.isSingleItemPtr(T)) return @ptrCast(T, self.gvalue.getPointer());
            if (comptime T == GLib.Variant) return self.value.getVariant().?;
            if (comptime T == GObject.ParamSpec) return self.value.getParam();
            if (comptime @hasDecl(T, "__call")) return downCast(T, self.value.getObject()).?;
            return @ptrCast(*T, self.value.getBoxed().?);
        }

        pub fn set(self: *Self, arg_value: if (is_basic) T else *T) void {
            if (comptime T == void) {
                @compileError("cannot initialize GValue with type void");
            } else if (comptime T == bool) {
                self.value.setBoolean(arg_value);
            } else if (comptime T == i8) {
                self.value.setSchar(arg_value);
            } else if (comptime T == u8) {
                self.value.setUchar(arg_value);
            } else if (comptime T == Int) {
                self.value.setInt(arg_value);
            } else if (comptime T == Uint) {
                self.value.setUint(arg_value);
            } else if (comptime T == i64) {
                self.value.setInt64(arg_value);
            } else if (comptime T == u64) {
                self.value.setUint64(arg_value);
            } else if (comptime T == Long) {
                self.value.setLong(arg_value);
            } else if (comptime T == Ulong) {
                self.value.setUlong(arg_value);
            } else if (comptime T == f32) {
                self.value.setFloat(arg_value);
            } else if (comptime T == f64) {
                self.value.setDouble(arg_value);
            } else if (comptime T == Type) {
                self.value.setGtype(arg_value);
            } else if (comptime meta.trait.is(.Enum)(T)) {
                if (@typeInfo(T).Enum.is_exhaustive) {
                    self.value.setEnum(@enumToInt(arg_value));
                } else {
                    self.value.setFlags(@enumToInt(arg_value));
                }
            } else if (comptime T == [*:0]const u8) {
                self.value.setString(arg_value);
            } else if (comptime meta.trait.isSingleItemPtr(T)) {
                self.value.setPointer(arg_value);
            } else if (comptime T == GLib.Variant) {
                self.value.setVariant(arg_value);
            } else if (comptime T == GObject.ParamSpec) {
                self.gvalue.setParam(arg_value);
            } else if (comptime @hasDecl(T, "__call")) {
                self.value.setObject(upCast(GObject.Object, arg_value));
            } else {
                self.value.setBoxed(arg_value);
            }
        }
    };
}

// --------------------

/// Type for reporting recoverable runtime errors (`E` = `*GLib.Error`)
pub fn Expected(comptime T: type, comptime E: type) type {
    return union(enum) {
        Ok: T,
        Err: E,
    };
}

/// Helper for C style bitmask
pub fn Flags(comptime T: type) type {
    return struct {
        pub inline fn @"|"(self: T, rhs: T) T {
            return @intToEnum(T, @enumToInt(self) | @enumToInt(rhs));
        }

        pub inline fn @"|="(self: *T, rhs: T) void {
            self.* = @intToEnum(T, @enumToInt(self.*) | @enumToInt(rhs));
        }

        pub inline fn @"&"(self: T, rhs: T) T {
            return @intToEnum(T, @enumToInt(self) & @enumToInt(rhs));
        }

        pub inline fn @"&="(self: *T, rhs: T) void {
            self.* = @intToEnum(T, @enumToInt(self.*) & @enumToInt(rhs));
        }

        pub inline fn @"^"(self: T, rhs: T) T {
            return @intToEnum(T, @enumToInt(self) ^ @enumToInt(rhs));
        }

        pub inline fn @"^="(self: *T, rhs: T) void {
            self.* = @intToEnum(T, @enumToInt(self.*) ^ @enumToInt(rhs));
        }

        pub inline fn @"-"(self: T, rhs: T) T {
            return @intToEnum(T, @enumToInt(self) & ~@enumToInt(rhs));
        }

        pub inline fn @"-="(self: *T, rhs: T) void {
            self.* = @intToEnum(T, @enumToInt(self.*) & ~@enumToInt(rhs));
        }

        pub inline fn @"~"(self: T) T {
            return @intToEnum(T, ~@enumToInt(self));
        }

        pub inline fn empty(self: T) bool {
            return @enumToInt(self) == 0;
        }

        pub inline fn intersects(self: T, rhs: T) bool {
            return @enumToInt(self) & @enumToInt(rhs) != 0;
        }

        pub inline fn contains(self: T, rhs: T) bool {
            return @enumToInt(self) & @enumToInt(rhs) == @enumToInt(rhs);
        }
    };
}

// type end
// --------

// ---------------------
// OOP inheritance begin

pub fn isA(comptime T: type) meta.trait.TraitFn {
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

pub inline fn upCast(comptime T: type, object: anytype) *T {
    comptime assert(isA(T)(meta.Child(@TypeOf(object))));
    return unsafeCast(T, object);
}

pub inline fn downCast(comptime T: type, object: anytype) ?*T {
    comptime assert(isA(meta.Child(@TypeOf(object)))(T));
    return dynamicCast(T, object);
}

pub inline fn dynamicCast(comptime T: type, object: anytype) ?*T {
    return if (GObject.typeCheckInstanceIsA(unsafeCast(GObject.TypeInstance, object), T.type())) unsafeCast(T, object) else null;
}

pub inline fn unsafeCast(comptime T: type, object: anytype) *T {
    return @ptrCast(*T, @alignCast(@alignOf(*T), object));
}

fn CallMethod(comptime T: type, comptime method: []const u8) Expected(type, void) {
    if (comptime @hasDecl(T, method)) {
        const method_info = @typeInfo(@TypeOf(@field(T, method)));
        comptime assert(meta.Child(method_info.Fn.params[0].type.?) == T);
        return .{ .Ok = method_info.Fn.return_type.? };
    }
    if (comptime @hasDecl(T, "Prerequisites")) {
        inline for (T.Prerequisites) |Prerequisite| {
            switch (comptime CallMethod(Prerequisite, method)) {
                .Ok => |Ty| return .{ .Ok = Ty },
                .Err => {},
            }
        }
    }
    if (comptime @hasDecl(T, "Interfaces")) {
        inline for (T.Interfaces) |Interface| {
            switch (comptime CallMethod(Interface, method)) {
                .Ok => |Ty| return .{ .Ok = Ty },
                .Err => {},
            }
        }
    }
    if (comptime @hasDecl(T, "Parent")) {
        switch (comptime CallMethod(T.Parent, method)) {
            .Ok => |Ty| return .{ .Ok = Ty },
            .Err => {},
        }
    }
    return .{ .Err = {} };
}

fn callMethod(self: anytype, comptime method: []const u8, args: anytype) switch (CallMethod(meta.Child(@TypeOf(self)), method)) {
    .Ok => |T| T,
    .Err => @compileError(std.fmt.comptimePrint("{s}.{s}: no such method", .{ @typeName(meta.Child(@TypeOf(self))), method })),
} {
    const Self = meta.Child(@TypeOf(self));
    if (comptime @hasDecl(Self, method)) {
        return @call(.auto, @field(Self, method), .{self} ++ args);
    }
    if (comptime @hasDecl(Self, "Prerequisites")) {
        inline for (Self.Prerequisites) |Prerequisite| {
            switch (comptime CallMethod(Prerequisite, method)) {
                .Ok => |_| return callMethod(upCast(Prerequisite, self), method, args),
                .Err => {},
            }
        }
    }
    if (comptime @hasDecl(Self, "Interfaces")) {
        inline for (Self.Interfaces) |Interface| {
            switch (comptime CallMethod(Interface, method)) {
                .Ok => |_| return callMethod(upCast(Interface, self), method, args),
                .Err => {},
            }
        }
    }
    if (comptime @hasDecl(Self, "Parent")) {
        switch (comptime CallMethod(Self.Parent, method)) {
            .Ok => |_| return callMethod(upCast(Self.Parent, self), method, args),
            .Err => {},
        }
    }
    unreachable;
}

/// Helper for object
pub fn Extend(comptime Self: type) type {
    return struct {
        pub fn __call(self: *Self, comptime method: []const u8, args: anytype) switch (CallMethod(Self, method)) {
            .Ok => |T| T,
            .Err => @compileError(std.fmt.comptimePrint("{s}.{s}: no such method", .{ @typeName(Self), method })),
        } {
            return callMethod(self, method, args);
        }

        pub fn into(self: *Self, comptime T: type) *T {
            return upCast(T, self);
        }

        pub fn tryInto(self: *Self, comptime T: type) ?*T {
            return downCast(T, self);
        }
    };
}

// OOP inheritance end
// -------------------

// -------------
// closure begin

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn ClosureZ(comptime FnPtr: type, comptime Args: type, comptime signature: []const type) type {
    comptime assert(meta.trait.isTuple(Args));
    const n_arg = @typeInfo(Args).Struct.fields.len;
    if (comptime meta.trait.isPtrTo(.Void)(FnPtr)) {
        comptime assert(n_arg == 0);
        return struct {
            const Self = @This();
            pub fn new(_: ?std.mem.Allocator, _: FnPtr, _: Args) !*Self {
                return undefined;
            }
            pub fn invoke() callconv(.C) void {}
            pub fn setOnce(_: *Self) void {}
            pub fn deinit(_: *Self) callconv(.C) void {}
            pub inline fn c_closure(_: *Self) ?*anyopaque {
                return null;
            }
            pub inline fn c_data(_: *Self) ?*anyopaque {
                return null;
            }
            pub inline fn c_destroy(_: *Self) ?*anyopaque {
                return null;
            }
        };
    }

    comptime assert(meta.trait.isPtrTo(.Fn)(FnPtr));
    comptime assert(1 <= signature.len and signature.len <= 7);
    const n_param = @typeInfo(meta.Child(FnPtr)).Fn.params.len;
    return struct {
        handler: FnPtr,
        args: Args,
        once: bool,
        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn new(allocator: ?std.mem.Allocator, handler: FnPtr, args: Args) !*Self {
            const real_allocator = if (allocator) |some| some else gpa.allocator();
            var closure = try real_allocator.create(Self);
            closure.handler = handler;
            closure.args = args;
            closure.once = false;
            closure.allocator = real_allocator;
            return closure;
        }

        pub usingnamespace if (signature.len == 1) struct {
            pub fn invoke(self: *Self) callconv(.C) signature[0] {
                defer if (self.once) {
                    self.deinit();
                };
                return @call(.auto, self.handler, self.args);
            }
        } else struct {};

        pub usingnamespace if (signature.len == 2) struct {
            pub fn invoke(arg1: signature[1], self: *Self) callconv(.C) signature[0] {
                defer if (self.once) {
                    self.deinit();
                };
                if (n_arg == 0 and n_param == 0) {
                    return @call(.auto, self.handler, .{});
                } else {
                    return @call(.auto, self.handler, .{arg1} ++ self.args);
                }
            }
        } else struct {};

        pub usingnamespace if (signature.len == 3) struct {
            pub fn invoke(arg1: signature[1], arg2: signature[2], self: *Self) callconv(.C) signature[0] {
                defer if (self.once) {
                    self.deinit();
                };
                if (n_arg == 0 and n_param == 0) {
                    @call(.auto, self.handler, .{});
                } else if (n_arg == 0 and n_param == 1) {
                    @call(.auto, self.handler, .{arg1});
                } else {
                    return @call(.auto, self.handler, .{ arg1, arg2 } ++ self.args);
                }
            }
        } else struct {};

        pub usingnamespace if (signature.len == 4) struct {
            pub fn invoke(arg1: signature[1], arg2: signature[2], arg3: signature[3], self: *Self) callconv(.C) signature[0] {
                defer if (self.once) {
                    self.deinit();
                };
                if (n_arg == 0 and n_param == 0) {
                    @call(.auto, self.handler, .{});
                } else if (n_arg == 0 and n_param == 1) {
                    @call(.auto, self.handler, .{arg1});
                } else if (n_arg == 0 and n_param == 2) {
                    return @call(.auto, self.handler, .{ arg1, arg2 });
                } else {
                    return @call(.auto, self.handler, .{ arg1, arg2, arg3 } ++ self.args);
                }
            }
        } else struct {};

        pub usingnamespace if (signature.len == 5) struct {
            pub fn invoke(arg1: signature[1], arg2: signature[2], arg3: signature[3], arg4: signature[4], self: *Self) callconv(.C) signature[0] {
                defer if (self.once) {
                    self.deinit();
                };
                if (n_arg == 0 and n_param == 0) {
                    @call(.auto, self.handler, .{});
                } else if (n_arg == 0 and n_param == 1) {
                    @call(.auto, self.handler, .{arg1});
                } else if (n_arg == 0 and n_param == 2) {
                    return @call(.auto, self.handler, .{ arg1, arg2 });
                } else if (n_arg == 0 and n_param == 3) {
                    return @call(.auto, self.handler, .{ arg1, arg2, arg3 });
                } else {
                    return @call(.auto, self.handler, .{ arg1, arg2, arg3, arg4 } ++ self.args);
                }
            }
        } else struct {};

        pub usingnamespace if (signature.len == 6) struct {
            pub fn invoke(arg1: signature[1], arg2: signature[2], arg3: signature[3], arg4: signature[4], arg5: signature[5], self: *Self) callconv(.C) signature[0] {
                defer if (self.once) {
                    self.deinit();
                };
                if (n_arg == 0 and n_param == 0) {
                    @call(.auto, self.handler, .{});
                } else if (n_arg == 0 and n_param == 1) {
                    @call(.auto, self.handler, .{arg1});
                } else if (n_arg == 0 and n_param == 2) {
                    return @call(.auto, self.handler, .{ arg1, arg2 });
                } else if (n_arg == 0 and n_param == 3) {
                    return @call(.auto, self.handler, .{ arg1, arg2, arg3 });
                } else if (n_arg == 0 and n_param == 4) {
                    return @call(.auto, self.handler, .{ arg1, arg2, arg3, arg4 });
                } else {
                    return @call(.auto, self.handler, .{ arg1, arg2, arg3, arg4, arg5 } ++ self.args);
                }
            }
        } else struct {};

        pub usingnamespace if (signature.len == 7) struct {
            pub fn invoke(arg1: signature[1], arg2: signature[2], arg3: signature[3], arg4: signature[4], arg5: signature[5], arg6: signature[6], self: *Self) callconv(.C) signature[0] {
                defer if (self.once) {
                    self.deinit();
                };
                if (n_arg == 0 and n_param == 0) {
                    @call(.auto, self.handler, .{});
                } else if (n_arg == 0 and n_param == 1) {
                    @call(.auto, self.handler, .{arg1});
                } else if (n_arg == 0 and n_param == 2) {
                    return @call(.auto, self.handler, .{ arg1, arg2 });
                } else if (n_arg == 0 and n_param == 3) {
                    return @call(.auto, self.handler, .{ arg1, arg2, arg3 });
                } else if (n_arg == 0 and n_param == 4) {
                    return @call(.auto, self.handler, .{ arg1, arg2, arg3, arg4 });
                } else if (n_arg == 0 and n_param == 5) {
                    return @call(.auto, self.handler, .{ arg1, arg2, arg3, arg4, arg5 });
                } else {
                    return @call(.auto, self.handler, .{ arg1, arg2, arg3, arg4, arg5, arg6 } ++ self.args);
                }
            }
        } else struct {};

        pub fn setOnce(self: *Self) void {
            self.once = true;
        }

        pub fn deinit(self: *Self) callconv(.C) void {
            self.allocator.destroy(self);
        }

        pub inline fn c_closure(_: *Self) @TypeOf(&Self.invoke) {
            return &Self.invoke;
        }

        pub inline fn c_data(self: *Self) *Self {
            return self;
        }

        pub inline fn c_destroy(_: *Self) @TypeOf(&Self.deinit) {
            return &Self.deinit;
        }
    };
}

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

pub const ConnectFlagsZ = struct {
    after: bool = false,
    allocator: ?std.mem.Allocator = null,
};

/// Wrapper for g_signal_connect_closure
pub fn connect(object: *GObject.Object, signal: [*:0]const u8, handler: anytype, args: anytype, flags: ConnectFlagsZ, comptime signature: []const type) usize {
    var closure = ClosureZ(@TypeOf(&handler), @TypeOf(args), signature).new(flags.allocator, handler, args) catch @panic("Out of Memory");
    var cclosure = cclosureNew(@ptrCast(GObject.Callback, closure.c_closure()), closure.c_data(), @ptrCast(GObject.ClosureNotify, closure.c_destroy()));
    return GObject.signalConnectClosure(object, signal, cclosure, flags.after);
}

/// Wrapper for g_signal_connect_closure
pub fn connectSwap(object: *GObject.Object, signal: [*:0]const u8, handler: anytype, args: anytype, flags: ConnectFlagsZ, comptime signature: []const type) usize {
    comptime assert(signature.len == 1);
    var closure = ClosureZ(@TypeOf(&handler), @TypeOf(args), signature).new(flags.allocator, handler, args) catch @panic("Out of Memory");
    var cclosure = cclosureNewSwap(@ptrCast(GObject.Callback, closure.c_closure()), closure.c_data(), @ptrCast(GObject.ClosureNotify, closure.c_destroy()));
    return GObject.signalConnectClosure(object, signal, cclosure, flags.after);
}

// closure end
// -----------

// --------------
// subclass begin

fn objectNewWithProperties(object_type: Type, names: ?[][*:0]const u8, values: ?[]GObject.Value) *GObject.Object {
    if (names) |_| {
        assert(names.?.len == values.?.len);
    } else {
        assert(values == null);
    }
    return struct {
        pub extern fn g_object_new_with_properties(Type, c_uint, ?[*][*:0]const u8, ?[*]GObject.Value) *GObject.Object;
    }.g_object_new_with_properties(object_type, if (names) |some| @intCast(c_uint, some.len) else 0, if (names) |some| some.ptr else null, if (values) |some| some.ptr else null);
}

/// Wrapper for g_object_new_with_properties
pub fn newObject(comptime T: type, names: ?[][*:0]const u8, values: ?[]GObject.Value) *T {
    return unsafeCast(T, objectNewWithProperties(T.type(), names, values));
}

fn signalNewv(signal_name: [*:0]const u8, itype: Type, signal_flags: GObject.SignalFlags, class_closure: ?*GObject.Closure, accumulator: anytype, accu_data: anytype, c_marshaller: ?GObject.ClosureMarshal, return_type: Type, param_types: ?[]Type) u32 {
    var accumulator_closure = ClosureZ(@TypeOf(&accumulator), @TypeOf(accu_data), &[_]type{ bool, *GObject.SignalInvocationHint, *GObject.Value, *GObject.Value }).new(null, &accumulator, accu_data) catch @panic("Out of Memory");
    return struct {
        pub extern fn g_signal_newv([*:0]const u8, Type, GObject.SignalFlags, ?*GObject.Closure, ?GObject.SignalAccumulator, ?*anyopaque, ?GObject.ClosureMarshal, Type, c_uint, ?[*]Type) c_uint;
    }.g_signal_newv(signal_name, itype, signal_flags, class_closure, @ptrCast(?GObject.SignalAccumulator, accumulator_closure.c_closure()), accumulator_closure.c_data(), c_marshaller, return_type, if (param_types) |some| @intCast(c_uint, some.len) else 0, if (param_types) |some| some.ptr else null);
}

pub const SignalFlagsZ = struct {
    run_first: bool = false,
    run_last: bool = false,
    run_cleanup: bool = false,
    no_recurse: bool = false,
    detailed: bool = false,
    action: bool = false,
    no_hooks: bool = false,
    must_collect: bool = false,
    deprecated: bool = false,
    accumulator_first_run: bool = false,
};

/// Wrapper for g_signal_newv
pub fn newSignal(comptime Class: type, comptime Object: type, comptime signal_name: [:0]const u8, signal_flags: SignalFlagsZ, accumulator: anytype, accu_data: anytype) u32 {
    assert(signal_flags.run_first or signal_flags.run_last or signal_flags.run_cleanup);
    var flags = std.mem.zeroes(GObject.SignalFlags);
    if (signal_flags.run_first) {
        flags.@"|="(.RunFirst);
    }
    if (signal_flags.run_last) {
        flags.@"|="(.RunLast);
    }
    if (signal_flags.run_cleanup) {
        flags.@"|="(.RunCleanup);
    }
    if (signal_flags.no_recurse) {
        flags.@"|="(.NoRecurse);
    }
    if (signal_flags.detailed) {
        flags.@"|="(.Detailed);
    }
    if (signal_flags.action) {
        flags.@"|="(.Action);
    }
    if (signal_flags.no_hooks) {
        flags.@"|="(.NoHooks);
    }
    if (signal_flags.must_collect) {
        flags.@"|="(.MustCollect);
    }
    if (signal_flags.deprecated) {
        flags.@"|="(.Deprecated);
    }
    if (signal_flags.accumulator_first_run) {
        flags.@"|="(.AccumulatorFirstRun);
    }
    comptime var field_name: [signal_name.len:0]u8 = undefined;
    comptime {
        std.mem.copy(u8, field_name[0..], signal_name[0..]);
        for (&field_name) |*c| {
            if (c.* == '-') {
                c.* = '_';
            }
        }
    }
    var class_closure = GObject.signalTypeCclosureNew(Object.type(), @offsetOf(Class, &field_name));
    const signal_field_type = meta.FieldType(Class, meta.stringToEnum(meta.FieldEnum(Class), &field_name).?);
    const signal_info = @typeInfo(meta.Child(if (meta.trait.is(.Optional)(signal_field_type)) meta.Child(signal_field_type) else signal_field_type));
    var return_type = ValueZ(signal_info.Fn.return_type.?).init().value.g_type;
    var param_types: [signal_info.Fn.params.len - 1]Type = undefined;
    inline for (signal_info.Fn.params[1..], &param_types) |param, *ty| {
        var is_gtyped = false;
        if (meta.trait.isSingleItemPtr(param.type.?)) {
            if (@hasDecl(meta.Child(param.type.?), "type")) {
                is_gtyped = true;
            }
        }
        if (is_gtyped) {
            ty.* = meta.Child(param.type.?).type();
        } else {
            ty.* = ValueZ(param.type.?).init().value.g_type;
        }
    }
    return signalNewv(signal_name.ptr, Object.type(), flags, class_closure, accumulator, accu_data, null, return_type, param_types[0..]);
}

const TypeTag = struct {
    type_id: Type = .Invalid,
    private_offset: c_int = 0,
};

pub fn typeTag(comptime Object: type) *TypeTag {
    _ = Object;
    const Static = struct {
        var tag = TypeTag{};
    };
    return &Static.tag;
}

fn init(comptime T: type, value: *T) void {
    const info = @typeInfo(T).Struct;
    inline for (info.fields) |field| {
        if (field.default_value) |some| {
            const field_const_ptr_type = @Type(.{ .Pointer = .{ .size = .One, .is_const = true, .is_volatile = false, .alignment = @alignOf(field.type), .address_space = .generic, .child = field.type, .is_allowzero = false, .sentinel = null } });
            @field(value, field.name) = @ptrCast(field_const_ptr_type, @alignCast(@alignOf(field.type), some)).*;
        }
    }
}

pub const TypeFlagsZ = struct {
    abstract: bool = false,
    value_abstract: bool = false,
    final: bool = false,
};

/// Wrapper for g_type_register_static
pub fn registerType(comptime Class: type, comptime Object: type, name: [*:0]const u8, flags: TypeFlagsZ) Type {
    const class_init = struct {
        fn trampoline(class: *Class) callconv(.C) void {
            if (typeTag(Object).private_offset != 0) {
                _ = GObject.typeClassAdjustPrivateOffset(class, &typeTag(Object).private_offset);
            }
            if (comptime @hasDecl(Class, "constructed")) {
                @ptrCast(*GObject.ObjectClass, class).constructed = &Class.constructed;
            }
            if (comptime @hasDecl(Class, "dispose")) {
                @ptrCast(*GObject.ObjectClass, class).dispose = &Class.dispose;
            }
            if (comptime @hasDecl(Class, "finalize")) {
                @ptrCast(*GObject.ObjectClass, class).finalize = &Class.finalize;
            }
            if (comptime @hasDecl(Class, "getProperty")) {
                @ptrCast(*GObject.ObjectClass, class).get_property = &Class.getProperty;
            }
            if (comptime @hasDecl(Class, "setProperty")) {
                @ptrCast(*GObject.ObjectClass, class).set_property = &Class.setProperty;
            }
            if (comptime @hasDecl(Class, "properties")) {
                @ptrCast(*GObject.ObjectClass, class).installProperties(Class.properties());
            }
            if (comptime @hasDecl(Class, "signals")) {
                _ = Class.signals();
            }
            init(Class, class);
            if (comptime @hasDecl(Class, "init")) {
                class.init();
            }
        }
    }.trampoline;
    const instance_init = struct {
        fn trampoline(self: *Object) callconv(.C) void {
            if (comptime @hasDecl(Object, "Private")) {
                self.private = @intToPtr(*Object.Private, @bitCast(usize, @bitCast(isize, @ptrToInt(self)) + typeTag(Object).private_offset));
                init(Object.Private, self.private);
            }
            init(Object, self);
            if (comptime @hasDecl(Object, "init")) {
                self.init();
            }
        }
    }.trampoline;
    if (GLib.onceInitEnter(&typeTag(Object).type_id)) {
        var _flags: GObject.TypeFlags = .None;
        if (flags.abstract) {
            _flags.@"|="(.Abstract);
        }
        if (flags.value_abstract) {
            _flags.@"|="(.ValueAbstract);
        }
        if (flags.final) {
            _flags.@"|="(.Final);
        }
        var info: GObject.TypeInfo = .{ .class_size = @sizeOf(Class), .base_init = null, .base_finalize = null, .class_init = @ptrCast(GObject.ClassInitFunc, &class_init), .class_finalize = null, .class_data = null, .instance_size = @sizeOf(Object), .n_preallocs = 0, .instance_init = @ptrCast(GObject.InstanceInitFunc, &instance_init), .value_table = null };
        const type_id = GObject.typeRegisterStatic(Object.Parent.type(), name, &info, _flags);
        if (@hasDecl(Object, "Private")) {
            typeTag(Object).private_offset = GObject.typeAddInstancePrivate(type_id, @sizeOf(Object.Private));
        }
        if (@hasDecl(Object, "Interfaces")) {
            inline for (Object.Interfaces) |Interface| {
                const interface_init = struct {
                    const init_func = "init" ++ @typeName(Interface)[(if (std.mem.lastIndexOfScalar(u8, @typeName(Interface), '.')) |some| some + 1 else 0)..];
                    fn trampoline(self: *Interface) callconv(.C) void {
                        if (comptime @hasDecl(Object, init_func)) {
                            @call(.auto, @field(Object, init_func), .{self});
                        }
                    }
                }.trampoline;
                var interface_info: GObject.InterfaceInfo = .{ .interface_init = @ptrCast(GObject.InterfaceInitFunc, &interface_init), .interface_finalize = null, .interface_data = null };
                GObject.typeAddInterfaceStatic(type_id, Interface.type(), &interface_info);
            }
        }
        GLib.onceInitLeave(&typeTag(Object).type_id, @enumToInt(type_id));
    }
    return typeTag(Object).type_id;
}

/// Wrapper for g_type_register_static
pub fn registerInterface(comptime Interface: type, name: [*:0]const u8) Type {
    const class_init = struct {
        pub fn trampoline(self: *Interface) callconv(.C) void {
            if (comptime @hasDecl(Interface, "properties")) {
                for (Interface.properties()) |property| {
                    GObject.Object.interfaceInstallProperty(@ptrCast(*GObject.TypeInterface, self), property);
                }
            }
            init(Interface, self);
            if (comptime @hasDecl(Interface, "init")) {
                self.init();
            }
        }
    }.trampoline;
    if (GLib.onceInitEnter(&typeTag(Interface).type_id)) {
        var info: GObject.TypeInfo = .{ .class_size = @sizeOf(Interface), .base_init = null, .base_finalize = null, .class_init = @ptrCast(GObject.ClassInitFunc, &class_init), .class_finalize = null, .class_data = null, .instance_size = 0, .n_preallocs = 0, .instance_init = null, .value_table = null };
        const type_id = GObject.typeRegisterStatic(.Interface, name, &info, .None);
        if (comptime @hasDecl(Interface, "Prerequisites")) {
            inline for (Interface.Prerequisites) |Prerequisite| {
                GObject.typeInterfaceAddPrerequisite(type_id, Prerequisite.type());
            }
        }
        GLib.onceInitLeave(&typeTag(Interface).type_id, @enumToInt(type_id));
    }
    return typeTag(Interface).type_id;
}

pub fn typeInstanceGetInterface(comptime Interface: type, self: *Interface) *Interface {
    const class = unsafeCast(GObject.TypeInstance, self).g_class.?;
    return unsafeCast(Interface, GObject.typeInterfacePeek(class, Interface.type()));
}

// subclass end
// ------------
