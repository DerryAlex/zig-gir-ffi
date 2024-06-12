const glib = @import("GLib.zig");
const gobject = @import("GObject.zig");
const gio = @import("Gio.zig");

const std = @import("std");

pub const Configs = struct {
    disable_deprecated: bool = true,
};

/// deprecated
pub const Deprecated = opaque {};

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

/// UCS-4
pub const Unichar = u32;

// re-exports
pub const Array = glib.Array;
pub const ByteArray = glib.ByteArray;
pub const Error = glib.Error;
pub const HashTable = glib.HashTable;
pub const List = glib.List;
pub const PtrArray = glib.PtrArray;
pub const SList = glib.SList;

fn isBasicType(comptime T: type) bool {
    if (T == void) return true;
    if (T == bool) return true;
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
    if (@typeInfo(T) == .Enum) return true; // Enum or Type
    if (@typeInfo(T) == .Struct and @typeInfo(T).Struct.layout == .@"packed") return true; // Flag
    if (T == [*:0]const u8) return true; // String
    if (@typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One) return true; // Pointer
    return false;
}

fn Arg(comptime T: type) type {
    return if (isBasicType(T)) T else *T;
}

const ZigValue = struct {
    const Self = gobject.Value;

    const Int = @Type(@typeInfo(c_int));
    const Uint = @Type(@typeInfo(c_uint));
    const Long = @Type(@typeInfo(c_long));
    const Ulong = @Type(@typeInfo(c_ulong));

    pub fn new(comptime T: type) Self {
        var value = std.mem.zeroes(Self);
        if (comptime T == void) {
            value.g_type = .none; // for internal use
        } else if (comptime T == bool) {
            _ = value.init(.boolean);
        } else if (comptime T == i8) {
            _ = value.init(.char);
        } else if (comptime T == u8) {
            _ = value.init(.uchar);
        } else if (comptime T == Int) {
            _ = value.init(.int);
        } else if (comptime T == Uint) {
            _ = value.init(.uint);
        } else if (comptime T == i64) {
            _ = value.init(.int64);
        } else if (comptime T == u64) {
            _ = value.init(.uint64);
        } else if (comptime T == Long) {
            _ = value.init(.long);
        } else if (comptime T == Ulong) {
            _ = value.init(.ulong);
        } else if (comptime T == f32) {
            _ = value.init(.float);
        } else if (comptime T == f64) {
            _ = value.init(.double);
        } else if (comptime T == [*:0]const u8) {
            _ = value.init(.string);
        } else if (comptime @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One) {
            _ = value.init(.pointer);
        } else if (comptime T == glib.Variant) {
            _ = value.init(.variant);
        } else if (comptime T == gobject.ParamSpec) {
            _ = value.init(.param);
        } else if (comptime @hasDecl(T, "gType")) {
            _ = value.init(T.gType());
        } else {
            @compileError(std.fmt.comptimePrint("Cannot initialize Value with type {s}", .{@typeName(T)}));
        }
        return value;
    }

    pub fn get(self: Self, comptime T: type) Arg(T) {
        if (comptime T == void) @compileError("Cannot initialize Value with type void");
        if (comptime T == bool) return self.getBoolean();
        if (comptime T == i8) return self.getSchar();
        if (comptime T == u8) return self.getUchar();
        if (comptime T == Int) return self.getInt();
        if (comptime T == Uint) return self.getUint();
        if (comptime T == i64) return self.getInt64();
        if (comptime T == u64) return self.getUint64();
        if (comptime T == Long) return self.getLong();
        if (comptime T == Ulong) return self.getUlong();
        if (comptime T == f32) return self.getFloat();
        if (comptime T == f64) return self.getDouble();
        if (comptime T == Type) return self.getGtype();
        if (comptime @typeInfo(T) == .Enum) {
            comptime std.debug.assert(@typeInfo(T).Enum.is_exhaustive);
            return @enumFromInt(self.getEnum());
        }
        if (comptime @typeInfo(T) == .Struct and @typeInfo(T).Struct.layout == .@"packed") {
            return @bitCast(self.getFlags());
        }
        if (comptime T == [*:0]const u8) return self.getString();
        if (comptime @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One) return @ptrCast(self.getPointer());
        if (comptime T == glib.Variant) return self.getVariant().?;
        if (comptime T == gobject.ParamSpec) return self.getParam();
        if (comptime @hasDecl(T, "__call")) return downCast(T, self.getObject()).?;
        return @ptrCast(self.getBoxed().?);
    }

    pub fn set(self: *Self, comptime T: type, arg_value: Arg(T)) void {
        if (comptime T == void) {
            @compileError("Cannot initialize Value with type void");
        } else if (comptime T == bool) {
            self.setBoolean(arg_value);
        } else if (comptime T == i8) {
            self.setSchar(arg_value);
        } else if (comptime T == u8) {
            self.setUchar(arg_value);
        } else if (comptime T == Int) {
            self.setInt(arg_value);
        } else if (comptime T == Uint) {
            self.setUint(arg_value);
        } else if (comptime T == i64) {
            self.setInt64(arg_value);
        } else if (comptime T == u64) {
            self.setUint64(arg_value);
        } else if (comptime T == Long) {
            self.setLong(arg_value);
        } else if (comptime T == Ulong) {
            self.setUlong(arg_value);
        } else if (comptime T == f32) {
            self.setFloat(arg_value);
        } else if (comptime T == f64) {
            self.setDouble(arg_value);
        } else if (comptime T == Type) {
            self.setGtype(arg_value);
        } else if (comptime @typeInfo(T) == .Enum) {
            comptime std.debug.assert(@typeInfo(T).Enum.is_exhaustive);
            self.setEnum(@intFromEnum(arg_value));
        } else if (comptime @typeInfo(T) == .Struct and @typeInfo(T).Struct.layout == .@"packed") {
            self.setFlags(@bitCast(arg_value));
        } else if (comptime T == [*:0]const u8) {
            self.setString(arg_value);
        } else if (comptime @typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One) {
            self.setPointer(arg_value);
        } else if (comptime T == glib.Variant) {
            self.setVariant(arg_value);
        } else if (comptime T == gobject.ParamSpec) {
            self.setParam(arg_value);
        } else if (comptime @hasDecl(T, "__call")) {
            self.setObject(upCast(gobject.Object, arg_value));
        } else {
            self.setBoxed(arg_value);
        }
    }
};

// type end
// --------

// -----------
// error begin

var err: ?*glib.Error = null;

/// Set information about an error.GError that has occurred
pub fn setError(_err: *glib.Error) void {
    if (err != null) unreachable;
    err = _err;
}

/// Get information about an error.GError that has occurred
pub fn getError() *glib.Error {
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
        pub fn trait(comptime U: type) bool {
            if (U == T) return true;
            if (@hasDecl(U, "Prerequisites")) {
                for (U.Prerequisites) |Prerequisite| {
                    if (trait(Prerequisite)) return true;
                }
            }
            if (@hasDecl(U, "Interfaces")) {
                for (U.Interfaces) |Interface| {
                    if (trait(Interface)) return true;
                }
            }
            if (@hasDecl(U, "Parent")) {
                if (trait(U.Parent)) return true;
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
    return dynamicCast(T, object);
}

/// Converts to type T safely
pub inline fn dynamicCast(comptime T: type, object: anytype) ?*T {
    return if (gobject.typeCheckInstanceIsA(unsafeCast(gobject.TypeInstance, object), T.gType())) unsafeCast(T, object) else null;
}

/// Converts to type T.
/// It is the caller's responsibility to ensure that the cast is legal.
pub inline fn unsafeCast(comptime T: type, object: anytype) *T {
    return @ptrCast(@alignCast(object));
}

fn CallMethod(comptime T: type, comptime method: []const u8) union(enum) {
    Ok: type,
    Err: void,
} {
    if (comptime @hasDecl(T, method)) {
        const method_info = @typeInfo(@TypeOf(@field(T, method)));
        comptime std.debug.assert(method_info.Fn.params[0].is_generic or std.meta.Child(method_info.Fn.params[0].type.?) == T);
        return .{ .Ok = method_info.Fn.return_type.? };
    }
    if (comptime @hasDecl(T, "Prerequisites")) {
        inline for (T.Prerequisites) |Prerequisite| {
            switch (comptime CallMethod(Prerequisite, method)) {
                .Ok => |U| return .{ .Ok = U },
                .Err => {},
            }
        }
    }
    if (comptime @hasDecl(T, "Interfaces")) {
        inline for (T.Interfaces) |Interface| {
            switch (comptime CallMethod(Interface, method)) {
                .Ok => |U| return .{ .Ok = U },
                .Err => {},
            }
        }
    }
    if (comptime @hasDecl(T, "Parent")) {
        switch (comptime CallMethod(T.Parent, method)) {
            .Ok => |U| return .{ .Ok = U },
            .Err => {},
        }
    }
    return .{ .Err = {} };
}

fn callMethod(self: anytype, comptime Self: type, comptime method: []const u8, args: anytype) switch (CallMethod(std.meta.Child(@TypeOf(self)), method)) {
    .Ok => |T| T,
    .Err => @compileError(std.fmt.comptimePrint("{s}.{s}: no such method", .{ @typeName(std.meta.Child(@TypeOf(self))), method })),
} {
    if (comptime @hasDecl(Self, method)) {
        const method_fn = @field(Self, method);
        const method_info = @typeInfo(@TypeOf(method_fn));
        if (comptime method_info.Fn.params[0].is_generic) {
            return @call(.auto, method_fn, .{self} ++ args);
        } else {
            return @call(.auto, method_fn, .{self.into(Self)} ++ args);
        }
    }
    if (comptime @hasDecl(Self, "Prerequisites")) {
        inline for (Self.Prerequisites) |Prerequisite| {
            switch (comptime CallMethod(Prerequisite, method)) {
                .Ok => |_| return callMethod(self, Prerequisite, method, args),
                .Err => {},
            }
        }
    }
    if (comptime @hasDecl(Self, "Interfaces")) {
        inline for (Self.Interfaces) |Interface| {
            switch (comptime CallMethod(Interface, method)) {
                .Ok => |_| return callMethod(self, Interface, method, args),
                .Err => {},
            }
        }
    }
    if (comptime @hasDecl(Self, "Parent")) {
        switch (comptime CallMethod(Self.Parent, method)) {
            .Ok => |_| return callMethod(self, Self.Parent, method, args),
            .Err => {},
        }
    }
    @compileError(std.fmt.comptimePrint("{s}.{s}: no such method", .{ Self, method }));
}

pub fn Extend(comptime Self: type) type {
    return struct {
        /// Calls inherited method
        pub fn __call(self: *Self, comptime method: []const u8, args: anytype) switch (CallMethod(Self, method)) {
            .Ok => |T| T,
            .Err => @compileError(std.fmt.comptimePrint("{s}.{s}: no such method", .{ @typeName(Self), method })),
        } {
            return callMethod(self, Self, method, args);
        }

        /// Converts to base type T
        pub fn into(self: *Self, comptime T: type) *T {
            return upCast(T, self);
        }

        /// Converts to derived type T
        pub fn tryInto(self: *Self, comptime T: type) ?*T {
            return downCast(T, self);
        }

        /// Gets a property of an object
        pub fn get(self: *Self, comptime T: type, property_name: [*:0]const u8) Arg(T) {
            var property = gobject.Value.new(T);
            defer property.unset();
            self.into(gobject.Object).getProperty(property_name, &property);
            return ZigValue.get(&property, T);
        }

        /// Sets a property on an object
        pub fn set(self: *Self, comptime T: type, property_name: [*:0]const u8, value: if (isBasicType(T)) T else *T) void {
            var property = gobject.Value.new(T);
            defer property.unset();
            ZigValue.set(&property, T, value);
            self.into(gobject.Object).setProperty(property_name, &property);
        }

        /// Connects a callback function to a signal for a particular object
        pub fn connect(self: *Self, signal: [*:0]const u8, handler: anytype, args: anytype, comptime flags: gobject.ConnectFlags, comptime signature: []const type) usize {
            var closure = zig_closure(handler, args, if (flags.swapped) signature[0..1] else signature);
            const closure_new_fn = if (flags.swapped) cclosureNewSwap else cclosureNew;
            const cclosure = closure_new_fn(@ptrCast(closure.c_closure()), closure.c_data(), @ptrCast(closure.c_destroy()));
            return gobject.signalConnectClosure(self.into(gobject.Object), signal, cclosure, flags.after);
        }

        /// Connects a notify signal for a property
        pub fn connectNotify(self: *Self, property_name: [*:0]const u8, handler: anytype, args: anytype, comptime flags: gobject.ConnectFlags) usize {
            var buf: [32]u8 = undefined;
            const signal = std.fmt.bufPrintZ(buf[0..], "notify::{s}", .{property_name}) catch @panic("No Space Left");
            return self.connect(signal, handler, args, flags, &.{ void, *Self, *gobject.ParamSpec });
        }
    };
}

// OOP inheritance end
// -------------------

// -------------
// closure begin

/// A closure represents a callback supplied by the programmer
pub fn ZigClosure(comptime FnPtr: type, comptime Args: type, comptime signature: []const type) type {
    comptime std.debug.assert(@typeInfo(Args) == .Struct and @typeInfo(Args).Struct.is_tuple);
    comptime std.debug.assert(@typeInfo(FnPtr) == .Pointer and @typeInfo(FnPtr).Pointer.size == .One);
    const n_arg = @typeInfo(Args).Struct.fields.len;
    if (comptime std.meta.Child(FnPtr) == void) {
        comptime std.debug.assert(n_arg == 0);
        return struct {
            const Self = @This();
            pub fn new(_: FnPtr, _: Args) !*Self {
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

    comptime std.debug.assert(@typeInfo(std.meta.Child(FnPtr)) == .Fn);
    comptime std.debug.assert(1 <= signature.len and signature.len <= 7);
    const n_param = @typeInfo(std.meta.Child(FnPtr)).Fn.params.len;
    return struct {
        handler: FnPtr,
        args: Args,
        once: bool,

        const Self = @This();

        /// Creates a new closure which invokes `handler` with `args` as the last parameters
        pub fn new(handler: FnPtr, args: Args) !*Self {
            const allocator = std.heap.c_allocator;
            var closure = try allocator.create(Self);
            closure.handler = handler;
            closure.args = args;
            closure.once = false;
            return closure;
        }

        pub usingnamespace if (signature.len == 1) struct {
            /// Invokes the closure, i.e. executes the callback represented by the closure
            pub fn invoke(self: *Self) callconv(.C) signature[0] {
                defer if (self.once) {
                    self.deinit();
                };
                return @call(.auto, self.handler, self.args);
            }
        } else struct {};

        pub usingnamespace if (signature.len == 2) struct {
            /// Invokes the closure, i.e. executes the callback represented by the closure
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
            /// Invokes the closure, i.e. executes the callback represented by the closure
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
            /// Invokes the closure, i.e. executes the callback represented by the closure
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
            /// Invokes the closure, i.e. executes the callback represented by the closure
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
            /// Invokes the closure, i.e. executes the callback represented by the closure
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
            /// Invokes the closure, i.e. executes the callback represented by the closure
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

        /// The closure is only valid for the duration of the first callback invocation
        pub fn setOnce(self: *Self) void {
            self.once = true;
        }

        /// Free its memory
        pub fn deinit(self: *Self) callconv(.C) void {
            std.heap.c_allocator.destroy(self);
        }

        /// The C callback function to invoke
        pub inline fn c_closure(_: *Self) @TypeOf(&Self.invoke) {
            return &Self.invoke;
        }

        /// The data to pass to callback
        pub inline fn c_data(self: *Self) *Self {
            return self;
        }

        /// The destroy function to be called when data is no longer used
        pub inline fn c_destroy(_: *Self) @TypeOf(&Self.deinit) {
            return &Self.deinit;
        }
    };
}

/// Creates a new closure which invokes `handler` with `args` as the last parameters
pub fn zig_closure(handler: anytype, args: anytype, comptime signature: []const type) *ZigClosure(@TypeOf(&handler), @TypeOf(args), signature) {
    return ZigClosure(@TypeOf(&handler), @TypeOf(args), signature).new(&handler, args) catch @panic("Out of Memory");
}

fn cclosureNew(callback_func: gobject.Callback, user_data: ?*anyopaque, destroy_data: gobject.ClosureNotify) *gobject.Closure {
    const g_cclosure_new = @extern(*const fn (gobject.Callback, ?*anyopaque, gobject.ClosureNotify) callconv(.C) *gobject.Closure, .{ .name = "g_cclosure_new" });
    return g_cclosure_new(callback_func, user_data, destroy_data);
}

fn cclosureNewSwap(callback_func: gobject.Callback, user_data: ?*anyopaque, destroy_data: gobject.ClosureNotify) *gobject.Closure {
    const g_cclosure_new_swap = @extern(*const fn (gobject.Callback, ?*anyopaque, gobject.ClosureNotify) callconv(.C) *gobject.Closure, .{ .name = "g_cclosure_new_swap" });
    return g_cclosure_new_swap(callback_func, user_data, destroy_data);
}

// closure end
// -----------

// --------------
// subclass begin

fn objectNewWithProperties(object_type: Type, names: ?[][*:0]const u8, values: ?[]gobject.Value) *gobject.Object {
    if (names) |_| {
        std.debug.assert(names.?.len == values.?.len);
    } else {
        std.debug.assert(values == null);
    }
    const g_object_new_with_properties = @extern(*const fn (Type, c_uint, ?[*][*:0]const u8, ?[*]gobject.Value) callconv(.C) *gobject.Object, .{ .name = "g_object_new_with_properties" });
    return g_object_new_with_properties(object_type, if (names) |some| @intCast(some.len) else 0, if (names) |some| some.ptr else null, if (values) |some| some.ptr else null);
}

/// Creates a new instance of an Object subtype and sets its properties using the provided arrays
pub fn newObject(comptime T: type, properties: anytype) *T {
    const info = @typeInfo(@TypeOf(properties));
    comptime std.debug.assert(info == .Struct);
    const n_props = info.Struct.fields.len;
    var names: [n_props][*:0]const u8 = undefined;
    var values: [n_props]gobject.Value = undefined;
    inline for (info.Struct.fields, 0..) |field, idx| {
        names[idx] = field.name;
        const V = blk: {
            if (@typeInfo(field.type) == .Pointer and @typeInfo(field.type).Pointer.size == .One) {
                const pointer_child = @typeInfo(field.type).Pointer.child;
                if (@typeInfo(pointer_child) == .Array and @typeInfo(pointer_child).Array.child == u8 and std.meta.sentinel(pointer_child) == @as(u8, 0)) break :blk [*:0]const u8;
                if (comptime !isBasicType(pointer_child)) break :blk pointer_child;
            }
            break :blk field.type;
        };
        values[idx] = ZigValue.new(V);
        ZigValue.set(&values[idx], V, @field(properties, field.name));
    }
    defer for (&values) |*value| value.unset();
    return unsafeCast(T, objectNewWithProperties(T.gType(), if (n_props != 0) names[0..] else null, if (n_props != 0) values[0..] else null));
}

fn signalNewv(signal_name: [*:0]const u8, itype: Type, signal_flags: gobject.SignalFlags, class_closure: ?*gobject.Closure, accumulator: anytype, accu_data: anytype, c_marshaller: ?gobject.ClosureMarshal, return_type: Type, param_types: ?[]Type) u32 {
    var accumulator_closure = zig_closure(accumulator, accu_data, &.{ bool, *gobject.SignalInvocationHint, *gobject.Value, *gobject.Value });
    const g_signal_newv = @extern(*const fn ([*:0]const u8, Type, gobject.SignalFlags, ?*gobject.Closure, ?gobject.SignalAccumulator, ?*anyopaque, ?gobject.ClosureMarshal, Type, c_uint, ?[*]Type) callconv(.C) c_uint, .{ .name = "g_signal_newv" });
    return g_signal_newv(signal_name, itype, signal_flags, class_closure, @ptrCast(accumulator_closure.c_closure()), accumulator_closure.c_data(), c_marshaller, return_type, if (param_types) |some| @intCast(some.len) else 0, if (param_types) |some| some.ptr else null);
}

/// Creates a new signal
pub fn newSignal(comptime Object: type, comptime signal_name: [:0]const u8, signal_flags: gobject.SignalFlags, accumulator: anytype, accu_data: anytype) u32 {
    const Class = Object.Class;
    std.debug.assert(signal_flags.run_first or signal_flags.run_last or signal_flags.run_cleanup);
    comptime var field_name: [signal_name.len:0]u8 = undefined;
    comptime {
        @memcpy(field_name[0..], signal_name[0..]);
        for (&field_name) |*c| {
            if (c.* == '-') {
                c.* = '_';
            }
        }
    }
    const class_closure = gobject.signalTypeCclosureNew(Object.gType(), @offsetOf(Class, &field_name));
    const signal_field_type = std.meta.FieldType(Class, std.meta.stringToEnum(std.meta.FieldEnum(Class), &field_name).?);
    const signal_info = @typeInfo(std.meta.Child(std.meta.Child(signal_field_type))); // ?*const fn(args...) return_type
    const return_type = ZigValue.new(signal_info.Fn.return_type.?).g_type;
    var param_types: [signal_info.Fn.params.len - 1]Type = undefined;
    inline for (signal_info.Fn.params[1..], &param_types) |param, *T| {
        var is_gtyped = false;
        if (@typeInfo(param.type.?) == .Pointer and @typeInfo(param.type.?).Pointer.size == .One) {
            if (@hasDecl(std.meta.Child(param.type.?), "type")) {
                is_gtyped = true;
            }
        }
        if (is_gtyped) {
            T.* = std.meta.Child(param.type.?).gType();
        } else {
            T.* = ZigValue.new(param.type.?).g_type;
        }
    }
    return signalNewv(signal_name.ptr, Object.gType(), signal_flags, class_closure, accumulator, accu_data, null, return_type, param_types[0..]);
}

const TypeTag = struct {
    type_id: Type = .invalid,
    private_offset: c_int = 0,
};

pub fn typeTag(comptime Object: type) *TypeTag {
    const Static = struct {
        comptime {
            _ = Object;
        }

        var tag = TypeTag{};
    };
    return &Static.tag;
}

fn init(comptime T: type, value: *T) void {
    const info = @typeInfo(T).Struct;
    inline for (info.fields) |field| {
        if (field.default_value) |some| {
            const field_const_ptr_type = @Type(.{ .Pointer = .{ .size = .One, .is_const = true, .is_volatile = false, .alignment = @alignOf(field.type), .address_space = .generic, .child = field.type, .is_allowzero = false, .sentinel = null } });
            @field(value, field.name) = @as(field_const_ptr_type, @ptrCast(@alignCast(some))).*;
        }
    }
}

fn overrideMethods(comptime Class: type, comptime C: type, class: *C) void {
    const info = @typeInfo(C).Struct;
    inline for (info.fields) |field| {
        if (@hasDecl(Class, field.name ++ "_override")) {
            const field_info = @typeInfo(field.type);
            if (field_info == .Optional) {
                const optional_child_info = @typeInfo(field_info.Optional.child);
                if (optional_child_info == .Pointer) {
                    const pointer_child_info = @typeInfo(optional_child_info.Pointer.child);
                    if (pointer_child_info == .Fn) {
                        @field(class, field.name) = &@field(Class, field.name ++ "_override");
                    }
                }
            }
        }
    }
}

fn doClassOverride(comptime Class: type, comptime T: type, class: *anyopaque) void {
    if (comptime @hasDecl(T, "Parent")) {
        doClassOverride(Class, T.Parent, class);
    }
    if (comptime @hasDecl(T, "Class")) {
        overrideMethods(Class, T.Class, @ptrCast(@alignCast(class)));
    }
}

/// Registers a new static type
pub fn registerType(comptime Object: type, name: [*:0]const u8, flags: gobject.TypeFlags) Type {
    const Class: type = Object.Class;
    const class_init = struct {
        fn trampoline(class: *Class) callconv(.C) void {
            if (typeTag(Object).private_offset != 0) {
                _ = gobject.typeClassAdjustPrivateOffset(class, &typeTag(Object).private_offset);
            }
            if (comptime @hasDecl(Class, "properties")) {
                @as(*gobject.ObjectClass, @ptrCast(class)).installProperties(Class.properties());
            }
            if (comptime @hasDecl(Class, "signals")) {
                _ = Class.signals();
            }
            init(Class, class);
            if (comptime @hasDecl(Class, "init")) {
                class.init();
            }
            if (comptime @hasDecl(Object, "Parent")) {
                doClassOverride(Class, Object.Parent, class);
            }
        }
    }.trampoline;
    const instance_init = struct {
        fn trampoline(self: *Object) callconv(.C) void {
            if (comptime @hasDecl(Object, "Private")) {
                self.private = @ptrFromInt(@as(usize, @bitCast(@as(isize, @bitCast(@intFromPtr(self))) + typeTag(Object).private_offset)));
                init(Object.Private, self.private);
            }
            init(Object, self);
            if (comptime @hasDecl(Object, "init")) {
                self.init();
            }
        }
    }.trampoline;
    if (glib.onceInitEnter(&typeTag(Object).type_id)) {
        var info: gobject.TypeInfo = .{
            .class_size = @sizeOf(Class),
            .base_init = null,
            .base_finalize = null,
            .class_init = @ptrCast(&class_init),
            .class_finalize = null,
            .class_data = null,
            .instance_size = @sizeOf(Object),
            .n_preallocs = 0,
            .instance_init = @ptrCast(&instance_init),
            .value_table = null,
        };
        const type_id = gobject.typeRegisterStatic(Object.Parent.gType(), name, &info, flags);
        if (@hasDecl(Object, "Private")) {
            typeTag(Object).private_offset = gobject.typeAddInstancePrivate(type_id, @sizeOf(Object.Private));
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
                var interface_info: gobject.InterfaceInfo = .{
                    .interface_init = @ptrCast(&interface_init),
                    .interface_finalize = null,
                    .interface_data = null,
                };
                gobject.typeAddInterfaceStatic(type_id, Interface.gType(), &interface_info);
            }
        }
        glib.onceInitLeave(&typeTag(Object).type_id, @intFromEnum(type_id));
    }
    return typeTag(Object).type_id;
}

/// Registers a new static type
pub fn registerInterface(comptime Interface: type, name: [*:0]const u8) Type {
    const class_init = struct {
        pub fn trampoline(self: *Interface) callconv(.C) void {
            if (comptime @hasDecl(Interface, "properties")) {
                for (Interface.properties()) |property| {
                    gobject.Object.interfaceInstallProperty(@ptrCast(self), property);
                }
            }
            init(Interface, self);
            if (comptime @hasDecl(Interface, "init")) {
                self.init();
            }
        }
    }.trampoline;
    if (glib.onceInitEnter(&typeTag(Interface).type_id)) {
        var info: gobject.TypeInfo = .{
            .class_size = @sizeOf(Interface),
            .base_init = null,
            .base_finalize = null,
            .class_init = @ptrCast(&class_init),
            .class_finalize = null,
            .class_data = null,
            .instance_size = 0,
            .n_preallocs = 0,
            .instance_init = null,
            .value_table = null,
        };
        const type_id = gobject.typeRegisterStatic(.interface, name, &info, .{});
        if (comptime @hasDecl(Interface, "Prerequisites")) {
            inline for (Interface.Prerequisites) |Prerequisite| {
                gobject.typeInterfaceAddPrerequisite(type_id, Prerequisite.gType());
            }
        }
        glib.onceInitLeave(&typeTag(Interface).type_id, @intFromEnum(type_id));
    }
    return typeTag(Interface).type_id;
}

/// Returns the interface of a given instance
pub fn typeInstanceGetInterface(comptime Interface: type, self: *Interface) *Interface {
    const class = unsafeCast(gobject.TypeInstance, self).g_class.?;
    return unsafeCast(Interface, gobject.typeInterfacePeek(class, Interface.gType()));
}

// subclass end
// ------------
