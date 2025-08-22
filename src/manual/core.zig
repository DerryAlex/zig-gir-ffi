const core = @This();
const std = @import("std");
const assert = std.debug.assert;
const GLib = @import("GLib.zig");
const GObject = @import("GObject.zig");

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
    /// placeholder for `Type`
    type = std.math.maxInt(usize),
    _,

    /// Resolves zig's type to `Type`.
    pub fn from(comptime T: type) Type {
        switch (comptime comptimeType(T)) {
            .invalid, .@"enum", .flags, .type => {
                if (@hasDecl(T, "gType")) return T.gType();
                @compileError(std.fmt.comptimePrint("Cannot obtain gType of {s}", .{@typeName(T)}));
            },
            else => |t| return t,
        }
    }

    /// Returns `Type` of `Type`.
    pub fn gType() Type {
        const cFn = @extern(*const fn () callconv(.c) Type, .{ .name = "g_gtype_get_type" });
        return cFn();
    }
};

const Int = @Type(@typeInfo(c_int));
const UInt = @Type(@typeInfo(c_uint));
const Long = @Type(@typeInfo(c_long));
const ULong = @Type(@typeInfo(c_ulong));

/// Resolves zig's type to `Type` at comptime.
/// Fallback to `.invalid` if impossible.
fn comptimeType(comptime T: type) Type {
    if (T == void) return .none;
    if (T == i8) return .char;
    if (T == u8) return .uchar;
    if (T == bool) return .boolean;
    if (T == c_int or T == Int) return .int;
    if (T == c_uint or T == UInt) return .uint;
    if (T == c_long or T == Long) return .long;
    if (T == c_ulong or T == ULong) return .ulong;
    if (T == i64) return .int64;
    if (T == u64) return .uint64;
    if (T == f32) return .float;
    if (T == f64) return .double;
    if (T == [*:0]const u8) return .string;
    if (T == GObject.ParamSpec) return .param;
    if (T == GObject.Object) return .object;
    if (T == GLib.Variant) return .variant;
    if (T == Type) return .type;
    switch (@typeInfo(T)) {
        .@"enum" => |e| if (e.is_exhaustive) return .@"enum",
        .@"struct" => |s| if (s.layout == .@"packed") return .flags,
        .pointer => |p| if (p.size == .one) return .pointer,
        else => {},
    }
    return .invalid;
}

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
    const instance = unsafeCast(GObject.TypeInstance, object);
    return if (GObject.typeCheckInstanceIsA(instance, .from(T))) unsafeCast(T, instance) else null;
}

/// Converts to type T.
///
/// Safety: It is the caller's responsibility to ensure that the cast is legal.
pub inline fn unsafeCast(comptime T: type, object: anytype) *T {
    return @ptrCast(@alignCast(object));
}

/// Inherits from Self.Parent
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

        /// Returns the class of a given object
        pub fn getClass(self: *Self, comptime Object: type) *Object.Class {
            const instance = unsafeCast(GObject.TypeInstance, upCast(Object, self));
            const class = instance.g_class.?;
            return unsafeCast(Object.Class, class);
        }

        /// Returns the parent class of a given object
        pub fn getParentClass(self: *Self, comptime Object: type) *Object.Class {
            const instance = unsafeCast(GObject.TypeInstance, upCast(Object, self));
            const class = instance.g_class.?;
            const p_class = class.peekParent();
            return unsafeCast(Object.Class, p_class);
        }

        /// Returns the interface of a given instance
        pub fn getIface(self: *Self, comptime Interface: type) *Interface.Class {
            const instance = unsafeCast(GObject.TypeInstance, upCast(Interface, self));
            const class = instance.g_class.?;
            const interface = GObject.TypeInterface.peek(class, .from(Interface)).?;
            return unsafeCast(Interface.Class, interface);
        }
    };
}

// OOP inheritance end
// -------------------

// -----------
// value begin

/// Is `T` a basic C type
fn isBasicType(comptime T: type) bool {
    return switch (comptime comptimeType(T)) {
        .invalid, .param, .object, .variant => false,
        else => true,
    };
}

/// How should `value: T` be passed as function argument
fn Arg(comptime T: type) type {
    return if (isBasicType(T)) T else *T;
}

/// Reverse of `Arg(T)`
fn ReverseArg(comptime T: type) type {
    return if (@typeInfo(T) == .pointer and Arg(std.meta.Child(T)) == T) std.meta.Child(T) else T;
}

/// A structure used to hold different types of values.
const ZigValue = extern struct {
    c_value: GObject.Value,

    const Self = @This();

    /// Initializes `Value` with the default value.
    pub fn init(comptime T: type) Self {
        var value = std.mem.zeroes(Self);
        _ = value.c_value.init(.from(T));
        return value;
    }

    /// Clears the current value.
    pub fn deinit(self: *Self) void {
        self.c_value.unset();
    }

    /// Get the contents of a `Value`.
    pub fn get(self: *Self, comptime T: type) Arg(T) {
        const v = &self.c_value;
        return switch (comptime comptimeType(T)) {
            .none => unreachable,
            .char => v.getSchar(),
            .uchar => v.getUchar(),
            .boolean => v.getBoolean(),
            .int => v.getInt(),
            .uint => v.getUint(),
            .long => v.getLong(),
            .ulong => v.getUlong(),
            .int64 => v.getInt64(),
            .uint64 => v.getUint64(),
            .@"enum" => @enumFromInt(v.getEnum()),
            .flags => @bitCast(v.getFlags()),
            .float => v.getFloat(),
            .double => v.getDouble(),
            .string => v.getString().?,
            .pointer => @ptrCast(v.getPointer()),
            .param => v.getParam(),
            .variant => v.getVariant().?,
            .type => v.getGtype(),
            else => if (comptime isA(GObject.Object)(T)) downCast(T, v.getObject().?) else unsafeCast(T, v.getBoxed().?),
        };
    }

    /// Set the contents of a `Value`.
    pub fn set(self: *Self, comptime T: type, value: Arg(T)) void {
        const v = &self.c_value;
        switch (comptime comptimeType(T)) {
            .none => unreachable,
            .char => v.setSchar(value),
            .uchar => v.setUchar(value),
            .boolean => v.setBoolean(value),
            .int => v.setInt(value),
            .uint => v.setUint(value),
            .long => v.setLong(value),
            .ulong => v.setUlong(value),
            .int64 => v.setInt64(value),
            .uint64 => v.setUint64(value),
            .@"enum" => v.setEnum(@intFromEnum(value)),
            .flags => v.setFlags(@bitCast(value)),
            .float => v.setFloat(value),
            .double => v.setDouble(value),
            .string => v.setString(value),
            .pointer => v.setPointer(value),
            .param => v.setParam(value),
            .variant => v.setVariant(value),
            .type => v.setGtype(value),
            else => if (comptime isA(GObject.Object)(T)) v.setObject(upCast(GObject.Object, value)) else v.setBoxed(value),
        }
    }
};

// value end
// ---------

// -------------
// closure begin

/// Represents a callback supplied by the programmer
pub const ZigClosure = extern struct {
    // CClosure fields
    c_closure: GObject.Closure,
    c_callback: ?*const anyopaque,
    // fields
    callback: ?*const anyopaque,
    n_param: u32,
    once: bool,
    reserved: [0]u8,
    // args: Args

    const Self = @This();

    /// Convert the arguments for the invocation from `Value`s into a suitable form,
    /// perform the callback on the converted arguments,
    /// and transform the return value back into a `Value`.
    fn marshal(closure: *GObject.Closure, return_value: ?*GObject.Value, n_param_values: u32, param_values: [*]GObject.Value, invocation_hint: ?*anyopaque, marshal_data: ?*anyopaque) callconv(.c) void {
        const cMarshalGeneric = @extern(GObject.ClosureMarshal, .{ .name = "g_cclosure_marshal_generic" });
        const self: *Self = @ptrCast(closure);
        assert(self.n_param <= n_param_values);
        cMarshalGeneric(closure, return_value, self.n_param, param_values, invocation_hint, marshal_data);
    }

    /// Invokes the callback of type `Fn`.
    fn cInvoke(comptime Fn: type) fn (...) callconv(.c) @typeInfo(Fn).@"fn".return_type.? {
        const Args = std.meta.ArgsTuple(Fn);
        return struct {
            fn invoke(...) callconv(.c) @typeInfo(Fn).@"fn".return_type.? {
                var va_list = @cVaStart();
                const self = @cVaArg(&va_list, *ZigClosure);
                const args: *Args = @ptrFromInt(@intFromPtr(self) + @sizeOf(ZigClosure));
                const n_arg = args.len;
                inline for (0..n_arg) |idx| {
                    if (idx == 0) continue;
                    if (idx >= self.n_param) break;
                    const field_idx = std.fmt.comptimePrint("{}", .{idx});
                    @field(args, field_idx) = @cVaArg(&va_list, @FieldType(Args, field_idx));
                }
                if (n_arg > 0 and self.n_param > 0) {
                    @field(args, "0") = @cVaArg(&va_list, @FieldType(Args, "0"));
                }
                @cVaEnd(&va_list);
                defer if (self.once) self.deinit();
                return @call(.auto, @as(*const Fn, @ptrCast(self.callback)), args.*);
            }
        }.invoke;
    }

    /// Creates a new closure which invokes `callback_func` with `user_data` as the last parameters.
    pub fn create(callback_func: anytype, user_data: anytype) *ZigClosure {
        if (@TypeOf(callback_func) == @TypeOf(null)) {
            return @ptrCast(GObject.Closure.newSimple(@sizeOf(ZigClosure), null));
        }
        const Fn = blk: {
            const T = @TypeOf(callback_func);
            if (!(@typeInfo(T) == .@"fn" or (@typeInfo(T) == .pointer and @typeInfo(std.meta.Child(T)) == .@"fn"))) {
                @compileError("ZigClosure.create: 'callback_func' should be of type Fn or FnPtr.");
            }
            break :blk if (@typeInfo(T) == .@"fn") T else std.meta.Child(T);
        };
        {
            const T = @TypeOf(user_data);
            if (!(@typeInfo(T) == .@"struct" and @typeInfo(T).@"struct".is_tuple)) {
                @compileError("ZigClosure.create: 'user_data' should be of type Tuple.");
            }
        }
        const Args = std.meta.ArgsTuple(Fn);
        var self: *ZigClosure = @ptrCast(GObject.Closure.newSimple(@sizeOf(ZigClosure) + @sizeOf(Args), null));
        self.callback = @ptrCast(if (@typeInfo(@TypeOf(callback_func)) == .pointer) callback_func else &callback_func);
        const args: *Args = @ptrFromInt(@intFromPtr(self) + @sizeOf(ZigClosure));
        const n_param = args.len - user_data.len;
        inline for (0..user_data.len) |idx| {
            @field(args, std.fmt.comptimePrint("{}", .{n_param + idx})) = @field(user_data, std.fmt.comptimePrint("{}", .{idx}));
        }
        self.c_closure.marshal = @ptrCast(&marshal);
        self.c_closure._0.derivative_flag = true; // makes `data` first parameter
        self.c_callback = &cInvoke(Fn);
        self.n_param = n_param;
        self.c_closure.data = self;
        return self;
    }

    /// Creates a new closure which invokes `callback_func` with `user_data` as the last parameters.
    /// Callback type is checked.
    pub inline fn createChecked(comptime Fn: type, callback_func: anytype, user_data: anytype) *ZigClosure {
        comptime if (@TypeOf(callback_func) != @TypeOf(null)) {
            const CallbackRaw = @TypeOf(callback_func);
            const Callback = if (@typeInfo(CallbackRaw) == .@"fn") CallbackRaw else std.meta.Child(CallbackRaw);
            const callback_info = @typeInfo(Callback).@"fn";
            const contract_info = @typeInfo(Fn).@"fn";
            assert(callback_info.return_type == contract_info.return_type);
            for (0..callback_info.params.len - user_data.len) |idx| {
                assert(callback_info.params[idx].type == contract_info.params[idx].type);
            }
        };
        return create(callback_func, user_data);
    }

    /// Invalidates its calling environment,
    /// and ignore future invocations.
    pub fn deinit(self: *ZigClosure) void {
        self.c_closure.invalidate();
    }
};

/// Type-safe wrapper for closure.
pub fn Closure(comptime FnOrPtr: type) type {
    return struct {
        closure: *ZigClosure,

        const Self = @This();

        const Fn: type = blk: {
            if (@typeInfo(FnOrPtr) != .pointer or @typeInfo(std.meta.Child(FnOrPtr)) != .@"fn") break :blk FnOrPtr;
            var fn_info = @typeInfo(std.meta.Child(FnOrPtr)).@"fn";
            // remove `data: void *` in c callback
            if (fn_info.calling_convention.eql(.c)) {
                const params = fn_info.params;
                const n_param = params.len;
                if (n_param > 0 and params[n_param - 1].type.? == ?*anyopaque) fn_info.params = params[0 .. n_param - 1];
            }
            break :blk @Type(.{ .@"fn" = fn_info });
        };

        pub fn init(callback_func: anytype, user_data: anytype) Self {
            return .{ .closure = .createChecked(Fn, callback_func, user_data) };
        }

        pub fn deinit(self: Self) void {
            self.closure.invalidate();
        }

        pub inline fn callback(self: Self) ?GObject.Callback {
            return @ptrCast(self.closure.c_callback);
        }

        pub inline fn data(self: Self) ?*anyopaque {
            return self.closure.c_closure.data;
        }

        pub inline fn destroy(self: Self) ?GLib.DestroyNotify {
            _ = self;
            return null;
        }
    };
}

// closure end
// -----------

// --------------
// subclass begin

/// Creates a new instance of an `Object` subtype.
pub fn newObject(comptime T: type) *T {
    const cFn = @extern(*const fn (Type, ?[*:0]const u8, ...) callconv(.c) *GObject.Object, .{ .name = "g_object_new" });
    return unsafeCast(T, cFn(.from(T), null));
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
fn initStruct(comptime T: type, value: *T) void {
    const info = @typeInfo(T).@"struct";
    inline for (info.fields) |field| {
        if (field.default_value_ptr) |default_value_ptr| {
            const default_value = @as(*align(1) const field.type, @ptrCast(default_value_ptr)).*;
            @field(value, field.name) = default_value;
        }
    }
}

/// Registers a new static type
pub fn registerType(comptime Object: type, name: [*:0]const u8, flags: GObject.TypeFlags) Type {
    if (@hasDecl(Object, "Override")) {
        checkOverride(Object, Object.Override);
    }
    const Class: type = Object.Class;
    const class_init = struct {
        fn trampoline(class: *Class) callconv(.c) void {
            if (typeTag(Object).private_offset != 0) {
                _ = GObject.typeClassAdjustPrivateOffset(class, &typeTag(Object).private_offset);
            }
            initStruct(Class, class);
            if (comptime @hasDecl(Object, "Override")) {
                overrideClass(Object, Object.Override, class);
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
                initStruct(Object.Private, self.private);
            }
            initStruct(Object, self);
            if (comptime @hasDecl(Object, "init")) {
                self.init();
            }
        }
    }.trampoline;
    if (GLib.onceInitEnter(&typeTag(Object).type_id)) {
        var info: GObject.TypeInfo = .{
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
        const type_id = GObject.typeRegisterStatic(.from(Object.Parent), name, &info, flags);
        if (@hasDecl(Object, "Private")) {
            typeTag(Object).private_offset = GObject.typeAddInstancePrivate(type_id, @sizeOf(Object.Private));
        }
        if (@hasDecl(Object, "Override") and @hasDecl(Object, "Interfaces")) {
            inline for (Object.Interfaces) |Interface| {
                overrideInterface(Interface, Object.Override, type_id);
            }
        }
        GLib.onceInitLeave(&typeTag(Object).type_id, @intFromEnum(type_id));
    }
    return typeTag(Object).type_id;
}

fn overrideClass(comptime Object: type, comptime Override: type, class: *Object.Class) void {
    const Class = Object.Class;
    inline for (comptime std.meta.declarations(Override)) |decl| {
        if (@hasField(Class, decl.name)) {
            @field(class, decl.name) = @field(Override, decl.name);
        }
    }
    if (@hasDecl(Object, "Parent")) {
        overrideClass(Object.Parent, Override, @ptrCast(class));
    }
}

fn overrideInterface(comptime Interface: type, comptime Override: type, type_id: Type) void {
    const Class = Interface.Class;
    const interface_init = struct {
        pub fn trampoline(interface: *Class) callconv(.c) void {
            inline for (comptime std.meta.declarations(Override)) |decl| {
                if (@hasField(Class, decl.name)) {
                    @field(interface, decl.name) = @field(Override, decl.name);
                }
            }
        }
    }.trampoline;
    var info: GObject.InterfaceInfo = .{
        .interface_init = @ptrCast(&interface_init),
        .interface_finalize = null,
        .interface_data = null,
    };
    GObject.typeAddInterfaceStatic(type_id, .from(Interface), &info);
}

fn checkOverride(comptime Object: type, comptime Override: type) void {
    comptime {
        const decls = std.meta.declarations(Override);
        var overriden_count = [_]usize{0} ** decls.len;
        if (@hasDecl(Object, "Interfaces")) {
            for (Object.Interfaces) |Interface| {
                const Class = Interface.Class;
                for (decls, 0..) |decl, idx| {
                    if (@hasField(Class, decl.name)) {
                        overriden_count[idx] += 1;
                    }
                }
            }
        }
        var T: type = Object;
        while (true) {
            if (@hasDecl(T, "Class")) {
                const Class: type = T.Class;
                for (decls, 0..) |decl, idx| {
                    if (@hasField(Class, decl.name)) {
                        overriden_count[idx] += 1;
                    }
                }
                if (T != GObject.InitiallyUnowned and @hasDecl(T, "Parent")) {
                    T = T.Parent;
                } else {
                    break;
                }
            }
        }
        for (overriden_count, 0..) |count, idx| {
            if (count == 0) {
                @compileError("'" ++ decls[idx].name ++ "' does not override any method");
            }
            if (count > 1) {
                @compileError("'" ++ decls[idx].name ++ "' overrides multiple methods");
            }
        }
    }
}

/// Registers a new static type
pub fn registerInterface(comptime Interface: type, name: [*:0]const u8) Type {
    const Class: type = Interface.Class;
    const class_init = struct {
        pub fn trampoline(class: *Class) callconv(.c) void {
            initStruct(Class, class);
            if (comptime @hasDecl(Interface, "init")) {
                class.init();
            }
        }
    }.trampoline;
    if (GLib.onceInitEnter(&typeTag(Interface).type_id)) {
        var info: GObject.TypeInfo = .{
            .class_size = @sizeOf(Class),
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
        const type_id = GObject.typeRegisterStatic(.interface, name, &info, .{});
        if (comptime @hasDecl(Interface, "Prerequisites")) {
            inline for (Interface.Prerequisites) |Prerequisite| {
                GObject.typeInterfaceAddPrerequisite(type_id, .from(Prerequisite));
            }
        }
        GLib.onceInitLeave(&typeTag(Interface).type_id, @intFromEnum(type_id));
    }
    return typeTag(Interface).type_id;
}

// subclass end
// ------------

// ------------
// signal begin

pub const HandlerId = ULong;

/// A simple implementation of signal and slot mechanism.
pub fn SimpleSignal(comptime Fn: type) type {
    return extern struct {
        slots: [8]?*ZigClosure = @splat(null),
        n_slot: usize = 0,

        const Self = @This();

        const Args = std.meta.ArgsTuple(Fn);
        const Return = @typeInfo(Fn).@"fn".return_type.?;
        comptime {
            assert(Return == void);
        }

        /// Connects a closure to a signal for a particular object.
        pub fn connect(self: *Self, closure: Closure(Fn), flags: GObject.ConnectFlags) HandlerId {
            if (flags.after) std.log.warn("SimpleSignal.connect: unsupported flag 'after'", .{});
            if (flags.swapped) std.log.warn("SimpleSignal.connect: unsupported flag 'swapped'", .{});
            self.slots[self.n_slot] = closure.closure;
            defer self.n_slot += 1;
            return self.n_slot;
        }

        /// Disconnects a handler from an instance.
        pub fn disconnect(self: *Self, id: HandlerId) void {
            if (id >= self.n_slot or self.slots[id] == null) {
                std.log.warn("SimpleSignal {*} has no handler with id {}", .{ self, id });
                return;
            }
            self.slots[id] = null;
        }

        /// Emits a signal. Signal emission is done synchronously.
        pub fn emit(self: *Self, args: Args) void {
            for (self.slots[0..self.n_slot]) |_slot| {
                if (_slot) |slot| {
                    @call(.auto, @as(*const fn (...) callconv(.c) void, @ptrCast(slot.c_callback)), .{slot} ++ args);
                }
            }
        }
    };
}

/// Type-safe wrapper for signal.
pub fn Signal(comptime Fn: type, comptime name: [:0]const u8) type {
    return struct {
        const Self = @This();

        /// Connects a closure to a signal for a particular object.
        pub fn connect(self: *Self, closure: Closure(Fn), flags: GObject.ConnectFlags) HandlerId {
            const Object = std.meta.Child(@typeInfo(Fn).@"fn".params[0].type.?);
            const _signals: *@FieldType(Object, "_signals") = @fieldParentPtr(name, self);
            const object: *Object = @alignCast(@fieldParentPtr("_signals", _signals));
            if (flags.swapped) std.log.warn("Signal.connect: unsupported flag 'swapped'", .{});
            return GObject.signalConnectClosure(object.into(GObject.Object), name, @ptrCast(closure.closure), flags.after);
        }
    };
}

// signal end
// ----------

// --------------
// property begin

/// Type-safe wrapper for property.
///
/// Safety: property should be at offset 0 of an object.
pub fn Property(comptime T: type, comptime name: [:0]const u8) type {
    return struct {
        const Self = @This();

        pub fn get(self: *Self) Arg(T) {
            var prop: ZigValue = .init(T);
            defer prop.deinit();
            const object = dynamicCast(GObject.Object, self).?;
            object.getProperty(name, &prop.c_value);
            return prop.get(T);
        }

        pub fn set(self: *Self, value: Arg(T)) void {
            var prop: ZigValue = .init(T);
            defer prop.deinit();
            prop.set(T, value);
            const object = dynamicCast(GObject.Object, self).?;
            object.setProperty(name, &prop.c_value);
        }

        pub fn connectNotify(self: *Self, closure: Closure(fn (*GObject.Object, *GObject.ParamSpec) void), flags: GObject.ConnectFlags) HandlerId {
            const object = dynamicCast(GObject.Object, self).?;
            return GObject.signalConnectClosure(object, "notify::" ++ name, @ptrCast(closure.closure), flags.after);
        }
    };
}

// property end
// ------------
