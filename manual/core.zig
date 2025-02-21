const glib = @import("glib");
const gobject = @import("gobject");

const std = @import("std");

pub fn deprecated(value: anytype) @TypeOf(value) {
    if (@TypeOf(value) == void) {
        @compileError("deprecated");
    }
    return value;
}

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

/// Inherits from Self.Parent
pub fn Extend(comptime Self: type) type {
    return struct {
        /// Calls inherited method
        pub fn __call(self: *Self, comptime method: []const u8, args: anytype) if (CallMethod(Self, method)) |R| R else @compileError(std.fmt.comptimePrint("{s}.{s}: no such method", .{ @typeName(Self), method })) {
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

        fn Property(comptime T: type) type {
            return struct {
                object: *gobject.Object,
                property_name: [*:0]const u8,

                pub fn get(self: @This()) Arg(T) {
                    var property_value = Value.new(T);
                    defer property_value.unset();
                    self.object.getProperty(self.property_name, &property_value);
                    return Value.get(&property_value, T);
                }

                pub fn set(self: @This(), value: Arg(T)) void {
                    var property_value = Value.new(T);
                    defer property_value.unset();
                    Value.set(&property_value, T, value);
                    self.object.setProperty(self.property_name, &property_value);
                }
            };
        }

        pub fn property(self: *Self, comptime T: type, property_name: [*:0]const u8) Property(T) {
            return .{
                .object = self.into(gobject.Object),
                .property_name = property_name,
            };
        }

        /// Connects a callback function to a signal for a particular object
        pub fn signalConnect(self: *Self, signal: [*:0]const u8, callback_func: anytype, user_data: anytype, flags: gobject.ConnectFlags, comptime Contract: type) usize {
            var closure = ZigClosure.newWithContract(callback_func, user_data, Contract);
            if (flags.swapped) {
                const CallbackRaw = @TypeOf(callback_func);
                const Callback = if (@typeInfo(CallbackRaw) == .@"fn") CallbackRaw else std.meta.Child(CallbackRaw);
                std.debug.assert(@typeInfo(Callback).@"fn".params.len == user_data.len);
            }
            return gobject.signalConnectClosure(self.into(gobject.Object), signal, closure.cClosure(), flags.after);
        }

        /// Returns the interface of a given instance
        pub fn getInterface(self: *Self, comptime Interface: type) *Interface {
            return typeInstanceGetInterface(Interface, upCast(Interface, self));
        }
    };
}

/// Returns the interface of a given instance
fn typeInstanceGetInterface(comptime Interface: type, self: *Interface) *Interface {
    const class = unsafeCast(gobject.TypeInstance, self).g_class.?;
    return unsafeCast(Interface, gobject.typeInterfacePeek(class, Interface.gType()));
}

/// Gets return type of `method`
fn CallMethod(comptime T: type, comptime method: []const u8) ?type {
    if (comptime std.meta.hasFn(T, method)) {
        const method_info = @typeInfo(@TypeOf(@field(T, method))).@"fn";
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
        const method_info = @typeInfo(@TypeOf(method_fn)).@"fn";
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
    if (@typeInfo(T) == .@"enum") return true; // Enum or Type
    if (@typeInfo(T) == .@"struct" and @typeInfo(T).@"struct".layout == .@"packed") return true; // Flags
    if (T == [*:0]const u8) return true; // String
    if (@typeInfo(T) == .pointer and @typeInfo(T).pointer.size == .one) return true; // Pointer
    return false;
}

/// How should `value: T` be passed as function argument
fn Arg(comptime T: type) type {
    return if (isBasicType(T)) T else *T;
}

/// Reverse of `Arg(T)`
fn ReverseArg(comptime T: type) type {
    return if (@typeInfo(T) == .pointer and Arg(std.meta.Child(T)) == T) std.meta.Child(T) else T;
}

/// An opaque structure used to hold different types of values
const Value = struct {
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
        } else if (comptime @typeInfo(T) == .pointer and @typeInfo(T).pointer.size == .one) {
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
    pub fn get(self: *Self, comptime T: type) Arg(T) {
        if (comptime T == void) @compileError("Cannot get Value with type void");
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
        if (comptime @typeInfo(T) == .@"enum") {
            comptime std.debug.assert(@typeInfo(T).@"enum".is_exhaustive);
            return @enumFromInt(self.getEnum());
        }
        if (comptime @typeInfo(T) == .@"struct" and @typeInfo(T).@"struct".layout == .@"packed") {
            return @bitCast(self.getFlags());
        }
        if (comptime T == [*:0]const u8) return self.getString();
        if (comptime @typeInfo(T) == .pointer and @typeInfo(T).pointer.size == .one) return @ptrCast(self.getPointer());
        if (comptime T == glib.Variant) return self.getVariant().?;
        if (comptime T == gobject.ParamSpec) return self.getParam();
        if (comptime @hasDecl(T, "__call")) return downCast(T, self.getObject().?).?;
        return unsafeCast(T, self.getBoxed().?);
    }

    /// Set the contents of a Value
    pub fn set(self: *Self, comptime T: type, arg_value: Arg(T)) void {
        if (comptime T == void) {
            @compileError("Cannot set Value with type void");
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
        } else if (comptime @typeInfo(T) == .@"enum") {
            comptime std.debug.assert(@typeInfo(T).@"enum".is_exhaustive);
            self.setEnum(@intFromEnum(arg_value));
        } else if (comptime @typeInfo(T) == .@"struct" and @typeInfo(T).@"struct".layout == .@"packed") {
            self.setFlags(@bitCast(arg_value));
        } else if (comptime T == [*:0]const u8) {
            self.setString(arg_value);
        } else if (comptime @typeInfo(T) == .pointer and @typeInfo(T).pointer.size == .one) {
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

/// Represents a callback supplied by the programmer
pub const ZigClosure = extern struct {
    c_closure: gobject.Closure,
    callback: *const anyopaque,
    c_callback: ?*const anyopaque,
    reserved: [0]u8,
    // args: Args

    fn marshal(comptime Callback: type, comptime n_param: usize) fn (*ZigClosure, *gobject.Value, u32, [*]gobject.Value) callconv(.c) void {
        const Args = std.meta.ArgsTuple(Callback);
        return struct {
            fn marshal(zig_closure: *ZigClosure, return_value: *gobject.Value, n_param_values: u32, param_values: [*]gobject.Value) callconv(.c) void {
                const args: *Args = @ptrFromInt(@intFromPtr(zig_closure) + @sizeOf(ZigClosure));
                const params = param_values[0..n_param_values];
                inline for (0..n_param) |idx| {
                    const field_idx = std.fmt.comptimePrint("{}", .{idx});
                    const FieldType = @FieldType(Args, field_idx);
                    if (@typeInfo(FieldType) == .optional and @typeInfo(std.meta.Child(FieldType)) == .pointer) {
                        if (params[idx].getPointer() == null) {
                            @field(args, field_idx) = null;
                        } else {
                            @field(args, field_idx) = Value.get(&params[idx], ReverseArg(std.meta.Child(FieldType)));
                        }
                    } else {
                        @field(args, field_idx) = Value.get(&params[idx], ReverseArg(FieldType));
                    }
                }
                const ret = @call(.auto, @as(*const Callback, @ptrCast(zig_closure.callback)), args.*);
                if (@TypeOf(ret) != void) {
                    Value.set(return_value, ReverseArg(@TypeOf(ret)), ret);
                }
            }
        }.marshal;
    }

    fn cInvoke(comptime Callback: type, comptime n_param: usize) fn (...) callconv(.c) @typeInfo(Callback).@"fn".return_type.? {
        const Args = std.meta.ArgsTuple(Callback);
        return struct {
            fn invoke(...) callconv(.c) @typeInfo(Callback).@"fn".return_type.? {
                var args: Args = undefined;
                var va_list = @cVaStart();
                inline for (0..n_param) |idx| {
                    const field_idx = std.fmt.comptimePrint("{}", .{idx});
                    @field(args, field_idx) = @cVaArg(&va_list, @FieldType(Args, field_idx));
                }
                const zig_closure = @cVaArg(&va_list, *ZigClosure);
                @cVaEnd(&va_list);
                const stored_args: *Args = @ptrFromInt(@intFromPtr(zig_closure) + @sizeOf(ZigClosure));
                inline for (n_param..args.len) |idx| {
                    const field_idx = std.fmt.comptimePrint("{}", .{idx});
                    @field(args, field_idx) = @field(stored_args, field_idx);
                }
                return @call(.auto, @as(*const Callback, @ptrCast(zig_closure.callback)), args);
            }
        }.invoke;
    }

    /// Creates a new closure which invokes `callback_func` with `user_data` as the last parameters.
    pub fn new(callback_func: anytype, user_data: anytype) *ZigClosure {
        if (@TypeOf(callback_func) == @TypeOf(null)) {
            return @ptrCast(gobject.Closure.newSimple(@sizeOf(ZigClosure), null));
        }
        const Callback = blk: {
            const T = @TypeOf(callback_func);
            if (!(@typeInfo(T) == .@"fn" or (@typeInfo(T) == .pointer and @typeInfo(std.meta.Child(T)) == .@"fn"))) {
                @compileError("ZigClosure.new: 'callback_func' should be of type Fn or FnPtr.");
            }
            break :blk if (@typeInfo(T) == .@"fn") T else std.meta.Child(T);
        };
        {
            const T = @TypeOf(user_data);
            if (!(@typeInfo(T) == .@"struct" and @typeInfo(T).@"struct".is_tuple)) {
                @compileError("ZigClosure.new: 'user_data' should be of type Tuple.");
            }
        }
        const Args = std.meta.ArgsTuple(Callback);
        var self: *ZigClosure = @ptrCast(gobject.Closure.newSimple(@sizeOf(ZigClosure) + @sizeOf(Args), null));
        self.callback = @ptrCast(if (@typeInfo(@TypeOf(callback_func)) == .pointer) callback_func else &callback_func);
        const args: *Args = @ptrFromInt(@intFromPtr(self) + @sizeOf(ZigClosure));
        const n_param = args.len - user_data.len;
        inline for (0..user_data.len) |idx| {
            @field(args, std.fmt.comptimePrint("{}", .{n_param + idx})) = @field(user_data, std.fmt.comptimePrint("{}", .{idx}));
        }
        self.c_closure.setMarshal(@ptrCast(&marshal(Callback, n_param)));
        self.c_callback = @ptrCast(&cInvoke(Callback, n_param));
        return self;
    }

    pub inline fn newWithContract(callback_func: anytype, user_data: anytype, comptime Contract: type) *ZigClosure {
        const closure = new(callback_func, user_data);
        comptime if (@TypeOf(callback_func) != @TypeOf(null)) {
            const CallbackRaw = @TypeOf(callback_func);
            const Callback = if (@typeInfo(CallbackRaw) == .@"fn") CallbackRaw else std.meta.Child(CallbackRaw);
            const callback_info = @typeInfo(Callback).@"fn";
            const contract_info = @typeInfo(Contract).@"fn";
            std.debug.assert(callback_info.return_type == contract_info.return_type);
            for (0..callback_info.params.len - user_data.len) |idx| {
                std.debug.assert(callback_info.params[idx].type == contract_info.params[idx].type);
            }
        };
        return closure;
    }

    pub inline fn cClosure(self: *ZigClosure) *gobject.Closure {
        return @ptrCast(self);
    }

    /// For internal use
    pub inline fn cCallback(self: *ZigClosure) ?gobject.Callback {
        return @ptrCast(self.c_callback);
    }

    /// For internal use
    pub inline fn cData(self: *ZigClosure) ?*anyopaque {
        if (self.c_callback != null) {
            return @ptrCast(self);
        } else {
            @branchHint(.unlikely);
            return null;
        }
    }

    /// For internal use
    pub inline fn cDestroy(self: *ZigClosure) ?glib.DestroyNotify {
        _ = self;
        return null;
    }
};

// closure end
// -----------

// --------------
// subclass begin

/// Creates a new instance of an Object subtype and sets its properties using the provided map
pub fn newObject(comptime T: type, properties: anytype) *T {
    const info = @typeInfo(@TypeOf(properties));
    comptime std.debug.assert(info == .@"struct");
    const n_props = info.@"struct".fields.len;
    var names: [n_props][*:0]const u8 = undefined;
    var values: [n_props]gobject.Value = undefined;
    inline for (info.@"struct".fields, 0..) |field, idx| {
        names[idx] = field.name;
        const V = blk: {
            if (@typeInfo(field.type) == .pointer and @typeInfo(field.type).pointer.size == .one) {
                const pointer_child = @typeInfo(field.type).pointer.child;
                if (@typeInfo(pointer_child) == .array and @typeInfo(pointer_child).array.child == u8 and std.meta.sentinel(pointer_child) == @as(u8, 0)) break :blk [*:0]const u8;
                if (comptime !isBasicType(pointer_child)) break :blk pointer_child;
            }
            break :blk field.type;
        };
        values[idx] = Value.new(V);
        Value.set(&values[idx], V, @field(properties, field.name));
    }
    defer for (&values) |*value| value.unset();
    return unsafeCast(T, gobject.Object.newWithProperties(T.gType(), names[0..], values[0..]));
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
    const signal_info = @typeInfo(std.meta.Child(std.meta.Child(signal_field_type))).@"fn"; // ?*const fn(args...) return_type
    const return_type = Value.new(signal_info.return_type.?).g_type;
    var param_types: [signal_info.params.len - 1]Type = undefined;
    inline for (signal_info.params[1..], &param_types) |param, *ty| {
        var is_gtyped = false;
        if (@typeInfo(param.type.?) == .Pointer and @typeInfo(param.type.?).Pointer.size == .one) {
            if (std.meta.hasFn(std.meta.Child(param.type.?), "gType")) {
                is_gtyped = true;
            }
        }
        if (is_gtyped) {
            ty.* = std.meta.Child(param.type.?).gType();
        } else {
            ty.* = Value.new(param.type.?).g_type;
        }
    }
    return gobject.signalNewv(signal_name.ptr, Object.gType(), signal_flags, class_closure, accumulator, accu_data, null, return_type, param_types[0..]);
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
    const info = @typeInfo(T).@"struct";
    inline for (info.fields) |field| {
        if (field.default_value_ptr) |default_value_ptr| {
            const default_value = @as(*align(1) const field.type, @ptrCast(default_value_ptr)).*;
            @field(value, field.name) = default_value;
        }
    }
}

/// Registers a new static type
pub fn registerType(comptime Object: type, name: [*:0]const u8, flags: gobject.TypeFlags) Type {
    if (@hasDecl(Object, "Override")) {
        checkOverride(Object, Object.Override);
    }
    const Class: type = Object.Class;
    const class_init = struct {
        fn trampoline(class: *Class) callconv(.c) void {
            if (typeTag(Object).private_offset != 0) {
                _ = gobject.typeClassAdjustPrivateOffset(class, &typeTag(Object).private_offset);
            }
            init(Class, class);
            if (comptime @hasDecl(Object, "Override")) {
                classOverride(Class, Object.Override, class);
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
        fn trampoline(self: *Object) callconv(.c) void {
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
        if (@hasDecl(Object, "Override") and @hasDecl(Object, "Interfaces")) {
            inline for (Object.Interfaces) |Interface| {
                interfaceOverride(Interface, Object.Override, type_id);
            }
        }
        glib.onceInitLeave(&typeTag(Object).type_id, @intFromEnum(type_id));
    }
    return typeTag(Object).type_id;
}

fn classOverride(comptime Class: type, comptime Override: type, class: *Class) void {
    inline for (comptime std.meta.declarations(Override)) |decl| {
        if (@hasField(Class, decl.name)) {
            @field(class, decl.name) = @field(Override, decl.name);
        }
    }
    if (@hasField(Class, "parent_class")) {
        classOverride(@FieldType(Class, "parent_class"), Override, @ptrCast(class));
    }
}

fn interfaceOverride(comptime Interface: type, comptime Override: type, type_id: Type) void {
    const interface_init = struct {
        pub fn trampoline(interface: *Interface) callconv(.c) void {
            inline for (comptime std.meta.declarations(Override)) |decl| {
                if (@hasField(Interface, decl.name)) {
                    @field(interface, decl.name) = @field(Override, decl.name);
                }
            }
        }
    }.trampoline;
    var info: gobject.InterfaceInfo = .{
        .interface_init = @ptrCast(&interface_init),
        .interface_finalize = null,
        .interface_data = null,
    };
    gobject.typeAddInterfaceStatic(type_id, Interface.gType(), &info);
}

fn checkOverride(comptime Object: type, comptime Override: type) void {
    comptime {
        const decls = std.meta.declarations(Override);
        var overriden_count = [_]usize{0} ** decls.len;
        if (@hasDecl(Object, "Interfaces")) {
            for (Object.Interfaces) |Interface| {
                for (decls, 0..) |decl, idx| {
                    if (@hasField(Interface, decl.name)) {
                        // @compileLog("Overrides", Interface, decl.name);
                        overriden_count[idx] += 1;
                    }
                }
            }
        }
        var T: type = Object;
        while (true) {
            if (T != gobject.InitiallyUnowned and @hasDecl(T, "Class")) {
                const Class: type = T.Class;
                for (decls, 0..) |decl, idx| {
                    if (@hasField(Class, decl.name)) {
                        overriden_count[idx] += 1;
                    }
                }
            }
            if (@hasDecl(T, "Parent")) {
                T = T.Parent;
            } else {
                break;
            }
        }
        for (overriden_count, 0..) |count, idx| {
            if (count == 0) {
                @compileError("'" ++ decls[idx].name ++ "' does not override any symbol");
            }
            if (count > 1) {
                @compileError("'" ++ decls[idx].name ++ "' overrides multiple symbols");
            }
        }
    }
}

/// Registers a new static type
pub fn registerInterface(comptime Interface: type, name: [*:0]const u8) Type {
    const class_init = struct {
        pub fn trampoline(self: *Interface) callconv(.c) void {
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

// subclass end
// ------------
