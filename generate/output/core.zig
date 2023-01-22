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

pub const Boolean = enum(c_int) {
    False = 0,
    True = 1,

    pub fn fromBool(self: bool) Boolean {
        return @intToEnum(Boolean, @boolToInt(self));
    }

    pub fn toBool(self: Boolean) bool {
        return @enumToInt(self) != 0;
    }

    pub fn format(self: Boolean, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.writeAll(if (self.toBool()) "true" else "false");
    }
};

/// UCS-4
pub const Unichar = u32;

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
    Object = 80,
    Variant = 84,
    _,
};

pub fn FlagsBuilder(comptime T: type) type {
    return struct {
        value: meta.Tag(T) = 0,

        const Self = @This();

        pub fn set(self: *Self, bit: T) *Self {
            self.value |= @enumToInt(bit);
            return self;
        }

        pub fn unset(self: *Self, bit: T) *Self {
            self.value &= ~@enumToInt(bit);
            return self;
        }

        pub fn build(self: Self) T {
            return @intToEnum(T, self.value);
        }
    };
}

// type end
// --------

// ----------
// cast begin

pub fn alignedPtrCast(comptime T: type, ptr: *anyopaque) T {
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
    return GObject.typeCheckInstanceIsA(alignedPtrCast(*GObject.TypeInstance, ptr), type_id).toBool();
}

pub fn upCast(comptime T: type, object: anytype) T {
    comptimeTypeCheck(T, @TypeOf(object));
    return T{ .instance = alignedPtrCast(*T.cType(), object.instance) };
}

pub fn downCast(comptime T: type, object: anytype) ?T {
    comptimeTypeCheck(@TypeOf(object), T);
    if (!runtimeTypeCheck(object.instance, T.gType())) return null;
    return T{ .instance = alignedPtrCast(*T.cType(), object.instance) };
}

pub fn dynamicCast(comptime T: type, ptr: *anyopaque) ?T {
    if (!runtimeTypeCheck(ptr, T.gType())) return null;
    return T{ .instance = alignedPtrCast(*T.cType(), ptr) };
}

pub fn unsafeCast(comptime T: type, ptr: *anyopaque) T {
    return T{ .instance = alignedPtrCast(*T.cType(), ptr) };
}

// cast end
// --------

// -------------
// closure begin

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn coreAllocatorDeinit() bool {
    return gpa.deinit();
}

fn ClosureZ(comptime T: type, comptime U: type, comptime swapped: bool, comptime signature: []const type) type {
    comptime assert(meta.trait.isPtrTo(.Fn)(T));
    comptime assert(signature.len <= 7);

    return struct {
        func: T,
        args: U,

        const Self = @This();

        pub usingnamespace if (swapped or (!swapped and signature.len == 1)) struct {
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

        pub fn invoke_fn(_: *Self) @TypeOf(&(@This().invoke)) {
            return &(@This().invoke);
        }

        pub fn deinit_fn(_: *Self) @TypeOf(&(@This().deinit)) {
            return &(@This().deinit);
        }

        pub fn toClosure(self: *Self) *GObject.Closure {
            if (swapped) {
                return cclosureNewSwap(@ptrCast(GObject.Callback, self.invoke_fn()), self, @ptrCast(GObject.ClosureNotify, self.deinit_fn()));
            } else {
                return cclosureNew(@ptrCast(GObject.Callback, self.invoke_fn()), self, @ptrCast(GObject.ClosureNotify, self.deinit_fn()));
            }
        }

        pub fn toWatchedClosure(self: *Self, object: GObject.Object) *GObject.Closure {
            var closure = self.toClosure();
            object.watchClosure(closure);
            return closure;
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
pub fn createClosure(comptime func: anytype, args: anytype, comptime swapped: bool, comptime signature: []const type) *ClosureZ(@TypeOf(func), @TypeOf(args), swapped, signature) {
    const allocator = gpa.allocator();
    const closure = allocator.create(ClosureZ(@TypeOf(func), @TypeOf(args), swapped, signature)) catch @panic("Out Of Memory");
    closure.func = func;
    closure.args = args;
    return closure;
}

// closure end
// -----------

// ------------
// signal begin

fn ConnectionSlotZ(comptime signature: []const type) type {
    if (signature.len == 1) return *const fn (?*anyopaque) callconv(.C) signature[0];
    if (signature.len == 2) return *const fn (signature[1], ?*anyopaque) callconv(.C) signature[0];
    if (signature.len == 3) return *const fn (signature[1], signature[2], ?*anyopaque) callconv(.C) signature[0];
    if (signature.len == 4) return *const fn (signature[1], signature[2], signature[3], ?*anyopaque) callconv(.C) signature[0];
    if (signature.len == 5) return *const fn (signature[1], signature[2], signature[3], signature[4], ?*anyopaque) callconv(.C) signature[0];
    if (signature.len == 6) return *const fn (signature[1], signature[2], signature[3], signature[4], signature[5], ?*anyopaque) callconv(.C) signature[0];
    if (signature.len == 7) return *const fn (signature[1], signature[2], signature[3], signature[4], signature[5], signature[6], ?*anyopaque) callconv(.C) signature[0];
    @compileError("Unsuppoted signature for connection");
}

fn ConnectionZ(comptime signature: []const type) type {
    comptime assert(signature.len <= 7);
    const ReturnType = signature[0];
    const Slot = ConnectionSlotZ(signature);
    const ClosureSlot = ConnectionSlotZ(&[_]type{ReturnType});

    return struct {
        disabled: bool = false,
        swapped: bool,
        slot: Slot,
        extra_args: *anyopaque,
        extra_args_size: usize,

        const Self = @This();

        pub fn disable(self: *Self) void {
            self.disabled = true;
        }

        pub fn enable(self: *Self) void {
            self.disabled = false;
        }

        pub fn onEmit(self: *Self, args: anytype) union(enum) {
            Ok: ReturnType,
            Err: void,
        } {
            if (self.disabled) return .{ .Err = {} };
            return if (self.swapped) .{ .Ok = @ptrCast(ClosureSlot, self.slot)(self.extra_args) } else .{ .Ok = @call(.auto, self.slot, args ++ .{self.extra_args}) };
        }
    };
}

pub fn SignalZ(comptime signature: []const type) type {
    const ReturnType = signature[0];
    const Connection = ConnectionZ(signature);
    const Accumulator = *const fn (ReturnType, ReturnType) struct {
        stop: bool,
        value: ReturnType,
    };

    return struct {
        disabled: bool = false,
        default_connection: ?*ConnectionZ(signature) = null,
        connections: std.ArrayList(*Connection),
        connections_after: std.ArrayList(*Connection),
        accumulator: ?Accumulator = null,
        acc_value: ?ReturnType = null,

        const Self = @This();

        pub fn init() Self {
            return Self{ .connections = std.ArrayList(*Connection).init(gpa.allocator()), .connections_after = std.ArrayList(*Connection).init(gpa.allocator()) };
        }

        pub fn initAccumulator(accumulator: *Accumulator) Self {
            return Self{ .connections = std.ArrayList(*Connection).init(gpa.allocator()), .connections_after = std.ArrayList(*Connection).init(gpa.allocator()), .accumulator = accumulator };
        }

        pub fn deinit(self: *Self) void {
            if (self.default_connection) |connection| {
                destroyConnection(connection);
            }
            for (self.connections.items) |connection| {
                destroyConnection(connection);
            }
            self.connections.deinit();
            for (self.connections_after.items) |connection| {
                destroyConnection(connection);
            }
            self.connections_after.deinit();
            self.disabled = true;
        }

        fn createConnection(comptime handler: anytype, args: anytype, comptime flags: ConnectFlagsZ) *Connection {
            const allocator = gpa.allocator();
            var closure = createClosure(&handler, args, flags.swapped, signature);
            const ExtraArgs = meta.Child(@TypeOf(closure));
            var connection = allocator.create(Connection) catch @panic("Out Of Memory");
            const slot = if (!flags.swapped) closure.invoke_fn() else @ptrCast(ConnectionSlotZ(signature), closure.invoke_fn());
            connection.* = .{ .swapped = flags.swapped, .slot = slot, .extra_args = closure, .extra_args_size = @sizeOf(ExtraArgs) };
            return connection;
        }

        fn destroyConnection(conncetion: *Connection) void {
            const allocator = gpa.allocator();
            allocator.free(@ptrCast([*]u8, conncetion.extra_args)[0..conncetion.extra_args_size]);
            allocator.destroy(conncetion);
        }

        fn notifySlot(self: *Self, connection: *Connection, args: anytype) bool {
            var ret = connection.onEmit(args);
            return switch (ret) {
                .Ok => |return_value| gen_ret: {
                    if (self.accumulator) |accumulator| {
                        if (self.acc_value) |_| {
                            var tmp = accumulator(self.acc_value.?, return_value);
                            self.acc_value = tmp.value;
                            break :gen_ret tmp.stop;
                        } else {
                            self.acc_value = return_value;
                            break :gen_ret false;
                        }
                    } else {
                        if (connection == self.default_connection) {
                            self.acc_value = return_value;
                        }
                        break :gen_ret false;
                    }
                },
                .Err => false,
            };
        }

        pub fn overrideDefault(self: *Self, comptime handler: anytype, args: anytype, comptime flags: ConnectFlagsZ) *Connection {
            var connection = createConnection(handler, args, flags);
            if (self.default_connection) |some| {
                const allocator = gpa.allocator();
                allocator.destroy(some);
            }
            self.default_connection = connection;
            return connection;
        }

        pub fn connect(self: *Self, comptime handler: anytype, args: anytype, comptime flags: ConnectFlagsZ) *Connection {
            var connection = createConnection(handler, args, flags);
            if (flags.after) {
                self.connections_after.append(connection) catch @panic("Out Of Memory");
            } else {
                self.connections.append(connection) catch @panic("Out Of Memory");
            }
            return connection;
        }

        pub fn disable(self: *Self) void {
            self.disabled = true;
        }

        pub fn enable(self: *Self) void {
            self.disabled = false;
        }

        pub fn emit(self: *Self, args: anytype) union(enum) {
            Ok: ReturnType,
            Err: void,
        } {
            if (self.disabled) return .{ .Err = {} };
            self.acc_value = null;
            for (self.connections.items) |connection| {
                if (self.notifySlot(connection, args)) return .{ .Ok = self.acc_value.? };
            }
            if (self.default_connection) |connection| {
                if (self.notifySlot(connection, args)) return .{ .Ok = self.acc_value.? };
            }
            for (self.connections_after.items) |connection| {
                if (self.notifySlot(connection, args)) return .{ .Ok = self.acc_value.? };
            }
            return if (self.acc_value) |some| .{ .Ok = some } else .{ .Err = {} };
        }
    };
}

// signal end
// ----------

// -------------
// connect begin

pub const ConnectFlagsZ = struct {
    after: bool = false,
    swapped: bool = false,
};

pub fn connectZ(object: GObject.Object, comptime signal: [*:0]const u8, comptime handler: anytype, args: anytype, comptime flags: ConnectFlagsZ, comptime signature: []const type) usize {
    const closure = createClosure(&handler, args, flags.swapped, signature);
    const closure_invoke = @ptrCast(GObject.Callback, closure.invoke_fn());
    const closure_deinit = @ptrCast(GObject.ClosureNotify, closure.deinit_fn());
    var flags_builder = FlagsBuilder(GObject.ConnectFlags){};
    if (flags.after) {
        _ = flags_builder.set(.After);
    }
    if (flags.swapped) {
        _ = flags_builder.set(.Swapped);
    }
    return signalConnectData(object, signal, closure_invoke, closure, closure_deinit, flags_builder.build());
}

// connect end
// -----------

// --------------
// type tag begin

const TypeTag = struct {
    type_id: GType = .Invalid,
    private_offset: c_int = 0,
};

pub fn typeTag(comptime Instance: type) *TypeTag {
    _ = Instance;
    const Static = struct {
        var tag = TypeTag{};
    };
    return &Static.tag;
}

// type tag end
// ------------

// -------------------
// register type begin

pub const TypeFlagsZ = struct {
    abstract: bool = false,
    value_abstract: bool = false,
    final: bool = false,
    register_fn: ?*const fn (GType) void = null,
};

/// Convenience wrapper for Type implementations
/// Instance should be a wrapped type
/// Boilerplates for register_fn:
/// var interface_info: core.InterfaceInfo = .{ .interface_init = @ptrCast(InstanceInitFunc, &init_fn), .interface_finalize = null, .interface_data = null };
/// core.typeAddInterfaceStatic(instance_gtype, interface_gtype, &interface_info);
pub fn registerType(comptime Class: type, comptime Instance: type, name: [*:0]const u8, comptime flags: TypeFlagsZ) GType {
    const class_init = struct {
        pub fn trampoline(self: *Class) callconv(.C) void {
            if (typeTag(Instance).private_offset != 0) {
                _ = GObject.typeClassAdjustPrivateOffset(self, &typeTag(Instance).private_offset);
            }
            if (@hasDecl(Class, "init")) {
                self.init();
            }
        }
    }.trampoline;
    const instance_init = struct {
        pub fn trampoline(self: Instance) callconv(.C) void {
            if (@hasDecl(Instance.cType(), "Private")) {
                self.instance.private = @intToPtr(*Instance.cType().Private, @bitCast(usize, @bitCast(isize, @ptrToInt(self.instance)) + typeTag(Instance).private_offset));
            }
            if (@hasDecl(Instance, "init")) {
                self.init();
            }
        }
    }.trampoline;
    if (GLib.onceInitEnter(&typeTag(Instance).type_id).toBool()) {
        var builder = FlagsBuilder(GObject.TypeFlags){};
        if (flags.abstract) {
            _ = builder.set(.Abstract);
        }
        if (flags.value_abstract) {
            _ = builder.set(.ValueAbstract);
        }
        if (flags.final) {
            _ = builder.set(.Final);
        }
        var type_id = typeRegisterStaticSimple(Instance.Parent.gType(), name, @sizeOf(Class), @ptrCast(GObject.ClassInitFunc, &class_init), @sizeOf(Instance.cType()), @ptrCast(GObject.InstanceInitFunc, &instance_init), builder.build());
        if (@hasDecl(Instance.cType(), "Private")) {
            typeTag(Instance).private_offset = GObject.typeAddInstancePrivate(type_id, @sizeOf(Instance.cType().Private));
        }
        if (flags.register_fn) |func| {
            func(type_id);
        }
        defer GLib.onceInitLeave(&typeTag(Instance).type_id, @enumToInt(type_id));
    }
    return typeTag(Instance).type_id;
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

// register type end
// -----------------

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

// ---------------------
// manual bindings begin

/// Creates a new closure which invokes callback_func with user_data as the last parameter.
/// destroy_data will be called as a finalize notifier on the GClosure.
/// @callback_func: The function to invoke.
/// @user_data:     User data to pass to callback_func.
/// @destroy_data:  Destroy notify to be called when user_data is no longer used.
/// Return:         A floating reference to a new GCClosure.
pub fn cclosureNew(callback_func: GObject.Callback, user_data: ?*anyopaque, destroy_data: GObject.ClosureNotify) *GObject.Closure {
    return struct {
        pub extern fn g_cclosure_new(GObject.Callback, ?*anyopaque, GObject.ClosureNotify) *GObject.Closure;
    }.g_cclosure_new(callback_func, user_data, destroy_data);
}

/// Creates a new closure which invokes callback_func with user_data as the first parameter.
/// destroy_data will be called as a finalize notifier on the GClosure.
/// @callback_func: The function to invoke.
/// @user_data:     User data to pass to callback_func.
/// @destroy_data:  Destroy notify to be called when user_data is no longer used.
/// Return:         A floating reference to a new GCClosure.
pub fn cclosureNewSwap(callback_func: GObject.Callback, user_data: ?*anyopaque, destroy_data: GObject.ClosureNotify) *GObject.Closure {
    return struct {
        pub extern fn g_cclosure_new_swap(GObject.Callback, ?*anyopaque, GObject.ClosureNotify) *GObject.Closure;
    }.g_cclosure_new_swap(callback_func, user_data, destroy_data);
}

/// Creates a new instance of a GObject subtype and sets its properties using the provided arrays.
/// Both arrays must have exactly n_properties elements, and the names and values correspond by index.
/// Construction parameters (see G_PARAM_CONSTRUCT, G_PARAM_CONSTRUCT_ONLY) which are not explicitly specified are set to their default values.
/// @object_type:  The object type to instantiate.
/// @n_properties: The number of properties.
/// @names:        The names of each property to be set.
/// @values:       The values of each property to be set.
/// Return:        A new instance of object_type
pub fn objectNewWithProperties(object_type: GType, names: ?[][*:0]const u8, values: ?[]GObject.Value) GObject.Object {
    assert((names == null) == (values == null));
    if (names) |_| assert(names.?.len == values.?.len);
    return struct {
        pub extern fn g_object_new_with_properties(GType, c_uint, ?[*][*:0]const u8, ?[*]GObject.Value) GObject.Object;
    }.g_object_new_with_properties(object_type, if (names) |some| @intCast(c_uint, some.len) else 0, if (names) |some| some.ptr else null, if (values) |some| some.ptr else null);
}

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
pub fn signalConnectData(instance: GObject.Object, detailed_signal: [*:0]const u8, c_handler: GObject.Callback, data: ?*anyopaque, destroy_data: ?GObject.ClosureNotify, connect_flags: GObject.ConnectFlags) usize {
    return struct {
        pub extern fn g_signal_connect_data(GObject.Object, [*:0]const u8, GObject.Callback, ?*anyopaque, ?GObject.ClosureNotify, GObject.ConnectFlags) c_ulong;
    }.g_signal_connect_data(instance, detailed_signal, c_handler, data, destroy_data, connect_flags);
}

/// Creates a new signal. (This is usually done in the class initializer.)
/// A signal name consists of segments consisting of ASCII letters and digits, separated by either the - or _ character.
/// The first character of a signal name must be a letter. Names which violate these rules lead to undefined behaviour.
/// These are the same rules as for property naming (see g_param_spec_internal()).
/// When registering a signal and looking up a signal, either separator can be used, but they cannot be mixed.
/// Using - is considerably more efficient. Using _ is discouraged.
/// If c_marshaller is NULL, g_cclosure_marshal_generic() will be used as the marshaller for this signal.
/// @signal_name:   The name for the signal.
/// @itype:         The type this signal pertains to. It will also pertain to types which are derived from this type.
/// @signal_flags:  A combination of GSignalFlags specifying detail of when the default handler is to be invoked.
///                 You should at least specify G_SIGNAL_RUN_FIRST or G_SIGNAL_RUN_LAST.
/// @class_clousre: The closure to invoke on signal emission; may be NULL.
/// @accumulator:   The accumulator for this signal; may be NULL.
/// @accu_data:     User data for the accumulator.
/// @c_marshaller:  The function to translate arrays of parameter values to signal emissions into C language callback invocations or NULL.
/// @return_type:   The type of return value, or G_TYPE_NONE for a signal without a return value.
/// @n_params:      The length of param_types.
/// @param_types:   An array of types, one for each parameter (may be NULL if n_params is zero)
/// Return:         The signal id.
pub fn signalNewv(signal_name: [*:0]const u8, itype: GType, signal_flags: GObject.SignalFlags, class_closure: ?*GObject.Closure, accumulator: ?GObject.SignalAccumulator, accu_data: ?*anyopaque, c_marshaller: ?GObject.ClosureMarshal, return_type: GType, param_types: ?[]GType) u32 {
    return struct {
        pub extern fn g_signal_newv([*:0]const u8, GType, GObject.SignalFlags, ?*GObject.Closure, ?GObject.SignalAccumulator, ?*anyopaque, ?GObject.ClosureMarshal, GType, c_uint, ?[*]GType) c_uint;
    }.g_signal_newv(signal_name, itype, signal_flags, class_closure, accumulator, accu_data, c_marshaller, return_type, if (param_types) |some| @intCast(c_uint, some.len) else 0, if (param_types) |some| some.ptr else null);
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

// manual bindings end
// -------------------
