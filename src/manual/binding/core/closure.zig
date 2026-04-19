const std = @import("std");
const GLib = @import("../GLib.zig");
const GObject = @import("../GObject.zig");

const assert = std.debug.assert;

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
        self.c_closure._1.derivative_flag = true; // makes `data` first parameter
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
            // compiler pushes `param_types` to be const, which might be a bug
            const param_types: [fn_info.params.len]type = @splat(@TypeOf(null));
            for (fn_info.params, param_types) |param, *param_ty| {
                param_ty.* = param.type.?;
            }
            break :blk @Fn(&param_types, &@splat(.{}), fn_info.return_type.?, .{});
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
