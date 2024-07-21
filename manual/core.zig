const glib = @import("glib.zig");
const gobject = @import("gobject.zig");

const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");

pub const Configs = struct {
    disable_deprecated: bool = true,
};
pub const config: Configs = if (@hasDecl(root, "gi_configs")) root.gi_configs else .{};

/// Deprecated
pub const Deprecated = if (builtin.is_test)
    struct {
        skip_zig_test: void = {},
    }
else
    @compileError("deprecated");

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
/// Contains the public fields of a GArray
pub const Array = glib.Array;
/// Contains the public fields of a GByteArray
pub const ByteArray = glib.ByteArray;
/// The GError structure contains information about an error that has occurred
pub const Error = glib.Error;
/// The GHashTable struct is an opaque data structure to represent a Hash Table
pub const HashTable = glib.HashTable;
/// The GList struct is used for each element in a doubly-linked list
pub const List = glib.List;
/// Contains the public fields of a pointer array
pub const PtrArray = glib.PtrArray;
/// The GSList struct is used for each element in the singly-linked list
pub const SList = glib.SList;

// type end
// --------

// -----------
// error begin

var err: ?*glib.Error = null;

/// Sets information about an error.GError that has occurred
pub fn setError(_err: *glib.Error) void {
    if (err != null) unreachable;
    err = _err;
}

/// Gets information about an error.GError that has occurred
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
        pub fn trait(comptime S: type) bool {
            if (S == T) return true;
            if (@hasDecl(S, "Prerequisites")) {
                for (S.Prerequisites) |Prerequisite| {
                    if (trait(Prerequisite)) return true;
                }
            }
            if (@hasDecl(S, "Interfaces")) {
                for (S.Interfaces) |Interface| {
                    if (trait(Interface)) return true;
                }
            }
            if (@hasDecl(S, "Parent")) {
                if (trait(S.Parent)) return true;
            }
            return false;
        }
    }.trait;
}

/// Converts to base type T
pub inline fn upCast(comptime T: type, object: anytype) *T {
    const S = std.meta.Child(@TypeOf(object));
    if (comptime !isA(T)(S)) {
        @compileError(std.fmt.comptimePrint("{s} cannot be upcast to {s}", .{ @typeName(S), @typeName(T) }));
    }
    return unsafeCast(T, object);
}

/// Converts to derived type T
pub inline fn downCast(comptime T: type, object: anytype) ?*T {
    const S = std.meta.Child(@TypeOf(object));
    if (comptime !isA(S)(T)) {
        @compileError(std.fmt.comptimePrint("{s} cannot be downcast to {s}", .{ @typeName(S), @typeName(T) }));
    }
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

/// Gets return type of `method`
fn CallMethod(comptime T: type, comptime method: []const u8) ?type {
    if (comptime std.meta.hasFn(T, method)) {
        const method_info = @typeInfo(@TypeOf(@field(T, method))).Fn;
        comptime std.debug.assert(method_info.params[0].is_generic or std.meta.Child(method_info.params[0].type.?) == T);
        return method_info.return_type.?;
    }
    if (comptime @hasDecl(T, "Prerequisites")) {
        inline for (T.Prerequisites) |Prerequisite| {
            if (comptime CallMethod(Prerequisite, method)) |R| {
                return R;
            }
        }
    }
    if (comptime @hasDecl(T, "Interfaces")) {
        inline for (T.Interfaces) |Interface| {
            if (comptime CallMethod(Interface, method)) |R| {
                return R;
            }
        }
    }
    if (comptime @hasDecl(T, "Parent")) {
        if (comptime CallMethod(T.Parent, method)) |R| {
            return R;
        }
    }
    return null;
}

/// Invokes `method` with `args`
fn callMethod(self: anytype, comptime Self: type, comptime method: []const u8, args: anytype) if (CallMethod(Self, method)) |R| R else @compileError(std.fmt.comptimePrint("{s}.{s}: no such method", .{ @typeName(Self), method })) {
    if (std.meta.hasFn(Self, method)) {
        const method_fn = @field(Self, method);
        const method_info = @typeInfo(@TypeOf(method_fn)).Fn;
        return @call(.auto, method_fn, .{if (comptime method_info.params[0].is_generic) self else self.into(Self)} ++ args);
    }
    if (comptime @hasDecl(Self, "Prerequisites")) {
        inline for (Self.Prerequisites) |Prerequisite| {
            if (comptime CallMethod(Prerequisite, method)) |_| {
                return callMethod(self, Prerequisite, method, args);
            }
        }
    }
    if (comptime @hasDecl(Self, "Interfaces")) {
        inline for (Self.Interfaces) |Interface| {
            if (comptime CallMethod(Interface, method)) |_| {
                return callMethod(self, Interface, method, args);
            }
        }
    }
    if (comptime @hasDecl(Self, "Parent")) {
        if (comptime CallMethod(Self.Parent, method)) |_| {
            return callMethod(self, Self.Parent, method, args);
        }
    }
    @compileError(std.fmt.comptimePrint("{s}.{s}: no such method", .{ @typeName(Self), method }));
}

pub fn MethodMixin(comptime Self: type) type {
    return struct {
        self: *Self,

        pub fn invoke(this: @This(), comptime method: []const u8, args: anytype) if (CallMethod(Self, method)) |R| R else @compileError(std.fmt.comptimePrint("{s}.{s}: no such method", .{ @typeName(Self), method })) {
            const self = this.self;
            return callMethod(self, Self, method, args);
        }
    };
}

pub fn PropertyMixin(comptime Self: type) type {
    return struct {
        self: *Self,

        pub fn get(this: @This(), comptime T: type, property_name: [*:0]const u8) Arg(T) {
            var self = this.self;
            var property = ZigValue.new(T);
            defer property.unset();
            self.into(gobject.Object).getProperty(property_name, &property);
            return ZigValue.get(&property, T);
        }

        pub fn set(this: @This(), comptime T: type, property_name: [*:0]const u8, value: if (isBasicType(T)) T else *T) void {
            var self = this.self;
            var property = ZigValue.new(T);
            defer property.unset();
            ZigValue.set(&property, T, value);
            self.into(gobject.Object).setProperty(property_name, &property);
        }
    };
}

pub fn SignalMixin(comptime Self: type) type {
    return struct {
        self: *Self,

        pub fn connect(this: @This(), signal: [*:0]const u8, handler: anytype, args: anytype, comptime flags: gobject.ConnectFlags, comptime signature: []const type) usize {
            const self = this.self;
            var closure = zig_closure(handler, args, if (flags.swapped) signature[0..1] else signature);
            const closure_new_fn = if (flags.swapped) cclosureNewSwap else cclosureNew;
            const cclosure = closure_new_fn(closure.c_closure(), closure.c_data(), closure.c_destroy());
            return gobject.signalConnectClosure(self.into(gobject.Object), signal, cclosure, flags.after);
        }

        pub fn connectNotify(this: @This(), property_name: [*:0]const u8, handler: anytype, args: anytype, comptime flags: gobject.ConnectFlags) usize {
            var buf: [32]u8 = undefined;
            const signal = std.fmt.bufPrintZ(buf[0..], "notify::{s}", .{property_name}) catch @panic("No Space Left");
            return this.connect(signal, handler, args, flags, &.{ void, *Self, *gobject.ParamSpec });
        }
    };
}

// OOP inheritance end
// -------------------

// -----------
// value begin

/// Is `T` a basic C type
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
    if (@typeInfo(T) == .Struct and @typeInfo(T).Struct.layout == .@"packed") return true; // Flags
    if (T == [*:0]const u8) return true; // String
    if (@typeInfo(T) == .Pointer and @typeInfo(T).Pointer.size == .One) return true; // Pointer
    return false;
}

/// How should `value: T` be passed as function argument
fn Arg(comptime T: type) type {
    return if (isBasicType(T)) T else *T;
}

/// An opaque structure used to hold different types of values
const ZigValue = struct {
    const Self = gobject.Value;

    const Int = @Type(@typeInfo(c_int));
    const Uint = @Type(@typeInfo(c_uint));
    const Long = @Type(@typeInfo(c_long));
    const Ulong = @Type(@typeInfo(c_ulong));

    /// Initializes value with the default value
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

    /// Get the contents of a Value
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

    /// Set the contents of a Value
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

// value end
// ---------

// -------------
// closure begin

/// A no-op closure
const NopClosure = struct {
    const Self = @This();
    pub fn new(_: anytype, _: anytype) !*Self {
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

/// A closure represents a callback supplied by the programmer
pub fn ZigClosure(comptime FnPtr: type, comptime Args: type, comptime signature: []const type) type {
    comptime std.debug.assert(@typeInfo(Args) == .Struct and @typeInfo(Args).Struct.is_tuple);
    comptime std.debug.assert(@typeInfo(FnPtr) == .Pointer and @typeInfo(FnPtr).Pointer.size == .One);
    if (std.meta.Child(FnPtr) == void) {
        return NopClosure;
    }
    comptime std.debug.assert(@typeInfo(std.meta.Child(FnPtr)) == .Fn);
    comptime std.debug.assert(signature.len >= 1);

    const n_arg = @typeInfo(Args).Struct.fields.len;
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

        /// Invokes the closure, i.e. executes the callback represented by the closure
        pub fn invoke(...) callconv(.C) signature[0] {
            var va_list = @cVaStart();
            var args: std.meta.Tuple(signature[1..]) = undefined;
            inline for (1..signature.len) |i| {
                const idx = std.fmt.comptimePrint("{}", .{i - 1});
                @field(args, idx) = @cVaArg(&va_list, signature[i]);
            }
            const self: *Self = @cVaArg(&va_list, *Self);
            @cVaEnd(&va_list);

            defer if (self.once) {
                self.deinit();
            };
            if (comptime n_arg == 0) {
                var args_real: std.meta.Tuple(signature[1 .. n_param + 1]) = undefined;
                inline for (0..n_param) |i| {
                    const idx = std.fmt.comptimePrint("{}", .{i});
                    @field(args_real, idx) = @field(args, idx);
                }
                return @call(.auto, self.handler, args_real);
            } else {
                return @call(.auto, self.handler, args ++ self.args);
            }
        }

        /// The closure is only valid for the duration of the first callback invocation
        pub fn setOnce(self: *Self) void {
            self.once = true;
        }

        /// Free its memory
        pub fn deinit(self: *Self) callconv(.C) void {
            std.heap.c_allocator.destroy(self);
        }

        /// The C callback function to invoke
        pub inline fn c_closure(_: *Self) gobject.Callback {
            return @ptrCast(&invoke);
        }

        /// The data to pass to callback
        pub inline fn c_data(self: *Self) ?*anyopaque {
            return self;
        }

        /// The destroy function to be called when data is no longer used
        pub inline fn c_destroy(_: *Self) gobject.ClosureNotify {
            return @ptrCast(&deinit);
        }
    };
}

/// Creates a new closure which invokes `handler` with `args` as the last parameters
pub fn zig_closure(handler: anytype, args: anytype, comptime signature: []const type) *ZigClosure(@TypeOf(&handler), @TypeOf(args), signature) {
    return ZigClosure(@TypeOf(&handler), @TypeOf(args), signature).new(&handler, args) catch @panic("Out of Memory");
}

/// Creates a new closure which invokes `callback_func` with `user_data` as the last parameter.
/// `destroy_data` will be called as a finalize notifier on the GClosure.
fn cclosureNew(callback_func: gobject.Callback, user_data: ?*anyopaque, destroy_data: gobject.ClosureNotify) *gobject.Closure {
    const g_cclosure_new = @extern(*const fn (gobject.Callback, ?*anyopaque, gobject.ClosureNotify) callconv(.C) *gobject.Closure, .{ .name = "g_cclosure_new" });
    return g_cclosure_new(callback_func, user_data, destroy_data);
}

/// Creates a new closure which invokes `callback_func` with `user_data` as the first parameter.
/// `destroy_data` will be called as a finalize notifier on the GClosure.
fn cclosureNewSwap(callback_func: gobject.Callback, user_data: ?*anyopaque, destroy_data: gobject.ClosureNotify) *gobject.Closure {
    const g_cclosure_new_swap = @extern(*const fn (gobject.Callback, ?*anyopaque, gobject.ClosureNotify) callconv(.C) *gobject.Closure, .{ .name = "g_cclosure_new_swap" });
    return g_cclosure_new_swap(callback_func, user_data, destroy_data);
}

// closure end
// -----------

// --------------
// subclass begin

/// Creates a new instance of a GObject subtype and sets its properties using the provided arrays.
/// Both arrays must have exactly `n_properties elements`, and the names and values correspond by index.
fn objectNewWithProperties(object_type: Type, names: ?[][*:0]const u8, values: ?[]gobject.Value) *gobject.Object {
    if (names) |_| {
        std.debug.assert(names.?.len == values.?.len);
    } else {
        std.debug.assert(values == null);
    }
    const g_object_new_with_properties = @extern(*const fn (Type, c_uint, ?[*][*:0]const u8, ?[*]gobject.Value) callconv(.C) *gobject.Object, .{ .name = "g_object_new_with_properties" });
    return g_object_new_with_properties(object_type, if (names) |some| @intCast(some.len) else 0, if (names) |some| some.ptr else null, if (values) |some| some.ptr else null);
}

/// Creates a new instance of an Object subtype and sets its properties using the provided map
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

/// Creates a new signal. (This is usually done in the class initializer.)
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
    const signal_info = @typeInfo(std.meta.Child(std.meta.Child(signal_field_type))).Fn; // ?*const fn(args...) return_type
    const return_type = ZigValue.new(signal_info.return_type.?).g_type;
    var param_types: [signal_info.params.len - 1]Type = undefined;
    inline for (signal_info.params[1..], &param_types) |param, *ty| {
        var is_gtyped = false;
        if (@typeInfo(param.type.?) == .Pointer and @typeInfo(param.type.?).Pointer.size == .One) {
            if (std.meta.hasFn(std.meta.Child(param.type.?), "gType")) {
                is_gtyped = true;
            }
        }
        if (is_gtyped) {
            ty.* = std.meta.Child(param.type.?).gType();
        } else {
            ty.* = ZigValue.new(param.type.?).g_type;
        }
    }
    return signalNewv(signal_name.ptr, Object.gType(), signal_flags, class_closure, accumulator, accu_data, null, return_type, param_types[0..]);
}

/// Type-specific data
const TypeTag = struct {
    type_id: Type = .invalid,
    private_offset: c_int = 0,
};

/// Storage for the type-specific data
pub fn typeTag(comptime Object: type) *TypeTag {
    const Static = struct {
        comptime {
            _ = Object;
        }

        var tag = TypeTag{};
    };
    return &Static.tag;
}

/// Initializes all fields of the struct with their default value.
fn init(comptime T: type, value: *T) void {
    const info = @typeInfo(T).Struct;
    inline for (info.fields) |field| {
        if (field.default_value) |default_value_ptr| {
            const default_value = @as(*align(1) const field.type, @ptrCast(default_value_ptr)).*;
            @field(value, field.name) = default_value;
        }
    }
}

/// Initializes fields using provided values
fn overrideMethods(comptime Override: type, comptime Class: type, class: *Class) void {
    const info = @typeInfo(Class).Struct;
    inline for (info.fields) |field| {
        if (comptime @hasDecl(Override, field.name)) {
            comptime var field_info = @typeInfo(field.type);
            if (field_info == .Optional) {
                field_info = @typeInfo(field_info.Optional.child);
            }
            if (field_info == .Pointer) {
                const pointer_child_info = @typeInfo(field_info.Pointer.child);
                if (pointer_child_info == .Fn) {
                    @field(class, field.name) = @field(Override, field.name);
                }
            }
        }
    }
}

/// Overrides class virtual function
fn doClassOverride(comptime Class: type, comptime T: type, class: *anyopaque) void {
    if (comptime @hasDecl(T, "Parent")) {
        doClassOverride(Class, T.Parent, class);
    }
    if (comptime @hasDecl(T, "Class")) {
        const ParentClass = T.Class;
        const parent_class_name = @typeName(ParentClass)[(if (comptime std.mem.lastIndexOfScalar(u8, @typeName(ParentClass), '.')) |some| some + 1 else 0)..];
        if (comptime @hasDecl(Class, parent_class_name ++ "Override")) {
            const Override = @field(Class, parent_class_name ++ "Override");
            overrideMethods(Override, ParentClass, @ptrCast(@alignCast(class)));
        }
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
            init(Class, class);
            if (comptime @hasDecl(Object, "Parent")) {
                doClassOverride(Class, Object.Parent, class);
            }
            if (comptime @hasDecl(Class, "properties")) {
                @as(*gobject.ObjectClass, @ptrCast(class)).installProperties(Class.properties());
            }
            if (comptime @hasDecl(Class, "signals")) {
                _ = Class.signals();
            }
            if (comptime @hasDecl(Class, "init")) {
                class.init();
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
                    const interface_name = @typeName(Interface)[(if (std.mem.lastIndexOfScalar(u8, @typeName(Interface), '.')) |some| some + 1 else 0)..];
                    fn trampoline(self: *Interface) callconv(.C) void {
                        if (comptime @hasDecl(Object, interface_name ++ "Override")) {
                            const Override = @field(Object, interface_name ++ "Override");
                            if (@hasDecl(Override, "init")) {
                                Override.init(self);
                            }
                            overrideMethods(Override, Interface, self);
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

// ---------------
// ABI check begin

/// For internal use only
pub fn isAbiCompatitable(comptime U: type, comptime V: type) bool {
    var typeinfo_u = @typeInfo(U);
    var typeinfo_v = @typeInfo(V);

    if (typeinfo_u == .Opaque or typeinfo_v == .Opaque) return true;
    if (typeinfo_u == .Struct and @sizeOf(U) == 0 and @hasField(U, "skip_zig_test")) return true;
    if (typeinfo_v == .Struct and @sizeOf(V) == 0 and @hasField(V, "skip_zig_test")) return true;

    if (typeinfo_u == .Optional and @typeInfo(typeinfo_u.Optional.child) == .Pointer) {
        typeinfo_u = @typeInfo(typeinfo_u.Optional.child);
    }
    if (typeinfo_v == .Optional and @typeInfo(typeinfo_v.Optional.child) == .Pointer) {
        typeinfo_v = @typeInfo(typeinfo_v.Optional.child);
    }

    if (typeinfo_u == .Pointer and typeinfo_u.Pointer.size == .One and @typeInfo(typeinfo_u.Pointer.child) == .Array) {
        typeinfo_u = @typeInfo([*]@typeInfo(typeinfo_u.Pointer.child).Array.child);
    }
    if (typeinfo_v == .Pointer and typeinfo_v.Pointer.size == .One and @typeInfo(typeinfo_v.Pointer.child) == .Array) {
        typeinfo_v = @typeInfo([*]@typeInfo(typeinfo_v.Pointer.child).Array.child);
    }

    if (typeinfo_u == .Enum) {
        typeinfo_u = @typeInfo(typeinfo_u.Enum.tag_type);
    }
    if (typeinfo_v == .Enum) {
        typeinfo_v = @typeInfo(typeinfo_v.Enum.tag_type);
    }
    if (typeinfo_u == .Struct and typeinfo_u.Struct.layout == .@"packed") {
        typeinfo_u = @typeInfo(typeinfo_u.Struct.backing_integer.?);
    }
    if (typeinfo_v == .Struct and typeinfo_v.Struct.layout == .@"packed") {
        typeinfo_v = @typeInfo(typeinfo_v.Struct.backing_integer.?);
    }

    if (typeinfo_u == .Bool) {
        typeinfo_u = @typeInfo(c_int);
    }
    if (typeinfo_v == .Bool) {
        typeinfo_v = @typeInfo(c_int);
    }

    if (@as(std.builtin.TypeId, typeinfo_u) != @as(std.builtin.TypeId, typeinfo_v)) return false;

    switch (typeinfo_u) {
        .Type, .Void, .Bool, .ComptimeFloat, .ComptimeInt => return true,
        .Int => {
            const intinfo_u = typeinfo_u.Int;
            const intinfo_v = typeinfo_v.Int;
            if (intinfo_u.bits != intinfo_v.bits) return false;
            if (intinfo_u.signedness != intinfo_v.signedness) {
                // char and flags may be translated as unsigned
                if (intinfo_u.bits != 8 and intinfo_u.bits != 32) return false;
            }
            return true;
        },
        .Float => return typeinfo_u.Float.bits == typeinfo_v.Float.bits,
        .Pointer => {
            const pointerinfo_u = typeinfo_u.Pointer;
            const pointerinfo_v = typeinfo_v.Pointer;
            if (pointerinfo_u.size != .C and pointerinfo_v.size != .C) {
                var has_anyopaque = false;
                if (pointerinfo_u.size == .One and @typeInfo(pointerinfo_u.child) == .Opaque) has_anyopaque = true;
                if (pointerinfo_v.size == .One and @typeInfo(pointerinfo_v.child) == .Opaque) has_anyopaque = true;
                if (!has_anyopaque) {
                    if (pointerinfo_u.size != pointerinfo_v.size) return false;
                    if ((pointerinfo_u.sentinel == null) != (pointerinfo_v.sentinel == null)) return false;
                }
            } else {
                if (pointerinfo_u.size == .Slice or pointerinfo_v.size == .Slice) return false;
            }
            return isAbiCompatitable(pointerinfo_u.child, pointerinfo_v.child);
        },
        .Array => {
            const arrayinfo_u = typeinfo_u.Array;
            const arrayinfo_v = typeinfo_v.Array;
            return arrayinfo_u.len == arrayinfo_v.len and isAbiCompatitable(arrayinfo_u.child, arrayinfo_v.child);
        },
        .Struct => return typeinfo_u.Struct.layout == typeinfo_v.Struct.layout and @sizeOf(U) == @sizeOf(V),
        .Optional => return isAbiCompatitable(typeinfo_u.Optional.child, typeinfo_v.Optional.child),
        .Enum => return U == V,
        .Union => return typeinfo_u.Union.layout == typeinfo_v.Union.layout and @sizeOf(U) == @sizeOf(V),
        .Fn => {
            const fninfo_u = typeinfo_u.Fn;
            const fninfo_v = typeinfo_v.Fn;
            if (fninfo_u.calling_convention != fninfo_v.calling_convention) return false;
            if (fninfo_u.params.len != fninfo_v.params.len) return false;
            inline for (0..fninfo_u.params.len) |idx| {
                if (!isAbiCompatitable(fninfo_u.params[idx].type.?, fninfo_v.params[idx].type.?)) return false;
            }
            const return_type_u = fninfo_u.return_type.?;
            const return_type_v = fninfo_v.return_type.?;
            if (isAbiCompatitable(return_type_u, return_type_v)) {
                return true;
            } else if (@typeInfo(return_type_u) == .Pointer and @typeInfo(return_type_v) == .Pointer) {
                const UObj = @typeInfo(return_type_u).Pointer.child;
                const VObj = @typeInfo(return_type_v).Pointer.child;
                if (@typeInfo(UObj) == .Struct and @typeInfo(VObj) == .Struct) {
                    if (isA(gobject.Object)(UObj)) {
                        var flag = false;
                        comptime {
                            var T = UObj;
                            while (@hasDecl(T, "Parent")) {
                                T = T.Parent;
                                if (isAbiCompatitable(T, VObj)) {
                                    flag = true;
                                    break;
                                }
                            }
                        }
                        if (flag) return true;
                    }
                    if (isA(gobject.Object)(VObj)) {
                        var flag = false;
                        comptime {
                            var T = VObj;
                            while (@hasDecl(T, "Parent")) {
                                T = T.Parent;
                                if (isAbiCompatitable(UObj, T)) {
                                    flag = true;
                                    break;
                                }
                            }
                        }
                        if (flag) return true;
                    }
                }
            }
            return false;
        },
        else => unreachable,
    }
    return false;
}

// ABI check end
// -------------
