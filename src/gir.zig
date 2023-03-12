const c = @import("main.zig").c;
const std = @import("std");
const assert = std.debug.assert;
const helper = @import("helper.zig");
const enable_deprecated = helper.enable_deprecated;
const snakeToCamel = helper.snakeToCamel;
const isZigKeyword = helper.isZigKeyword;

pub const ArrayType = enum(c.GIArrayType) {
    C = c.GI_ARRAY_TYPE_C,
    Array = c.GI_ARRAY_TYPE_ARRAY,
    PtrArray = c.GI_ARRAY_TYPE_PTR_ARRAY,
    ByteArray = c.GI_ARRAY_TYPE_BYTE_ARRAY,
};

pub const Direction = enum(c.GIDirection) {
    In = c.GI_DIRECTION_IN,
    Out = c.GI_DIRECTION_OUT,
    Inout = c.GI_DIRECTION_INOUT,
};

pub const InfoType = enum(c.GIInfoType) {
    Invalid = c.GI_INFO_TYPE_INVALID,
    Function = c.GI_INFO_TYPE_FUNCTION,
    Callback = c.GI_INFO_TYPE_CALLBACK,
    Struct = c.GI_INFO_TYPE_STRUCT,
    Boxed = c.GI_INFO_TYPE_BOXED,
    Enum = c.GI_INFO_TYPE_ENUM,
    Flags = c.GI_INFO_TYPE_FLAGS,
    Object = c.GI_INFO_TYPE_OBJECT,
    Interface = c.GI_INFO_TYPE_INTERFACE,
    Constant = c.GI_INFO_TYPE_CONSTANT,
    Invalid0 = c.GI_INFO_TYPE_INVALID_0,
    Union = c.GI_INFO_TYPE_UNION,
    Value = c.GI_INFO_TYPE_VALUE,
    Signal = c.GI_INFO_TYPE_SIGNAL,
    VFunc = c.GI_INFO_TYPE_VFUNC,
    Property = c.GI_INFO_TYPE_PROPERTY,
    Field = c.GI_INFO_TYPE_FIELD,
    Arg = c.GI_INFO_TYPE_ARG,
    Type = c.GI_INFO_TYPE_TYPE,
    Unresolved = c.GI_INFO_TYPE_UNRESOLVED,
};

pub const ScopeType = enum(c.GIScopeType) {
    Invalid = c.GI_SCOPE_TYPE_INVALID,
    Call = c.GI_SCOPE_TYPE_CALL,
    Async = c.GI_SCOPE_TYPE_ASYNC,
    Notified = c.GI_SCOPE_TYPE_NOTIFIED,
    Forever = c.GI_SCOPE_TYPE_FOREVER,
};

pub const Transfer = enum(c.GITransfer) {
    Nothing = c.GI_TRANSFER_NOTHING,
    Container = c.GI_TRANSFER_CONTAINER,
    Everything = c.GI_TRANSFER_EVERYTHING,
};

pub const TypeTag = enum(c.GITypeTag) {
    Void = c.GI_TYPE_TAG_VOID,
    Boolean = c.GI_TYPE_TAG_BOOLEAN,
    Int8 = c.GI_TYPE_TAG_INT8,
    UInt8 = c.GI_TYPE_TAG_UINT8,
    Int16 = c.GI_TYPE_TAG_INT16,
    UInt16 = c.GI_TYPE_TAG_UINT16,
    Int32 = c.GI_TYPE_TAG_INT32,
    UInt32 = c.GI_TYPE_TAG_UINT32,
    Int64 = c.GI_TYPE_TAG_INT64,
    UInt64 = c.GI_TYPE_TAG_UINT64,
    Float = c.GI_TYPE_TAG_FLOAT,
    Double = c.GI_TYPE_TAG_DOUBLE,
    GType = c.GI_TYPE_TAG_GTYPE,
    Utf8 = c.GI_TYPE_TAG_UTF8,
    Filename = c.GI_TYPE_TAG_FILENAME,
    Array = c.GI_TYPE_TAG_ARRAY,
    Interface = c.GI_TYPE_TAG_INTERFACE,
    GList = c.GI_TYPE_TAG_GLIST,
    GSList = c.GI_TYPE_TAG_GSLIST,
    GHash = c.GI_TYPE_TAG_GHASH,
    Error = c.GI_TYPE_TAG_ERROR,
    Unichar = c.GI_TYPE_TAG_UNICHAR,
};

pub const FieldInfoFlags = packed struct(c.GIFieldInfoFlags) {
    readable: bool = false,
    writable: bool = false,
    _padding: u30 = 0,
};

test "FieldInfoFlags" {
    var flags: FieldInfoFlags = .{};
    {
        flags.readable = true;
        assert(@bitCast(c.GIFieldInfoFlags, flags) == c.GI_FIELD_IS_READABLE);
        flags.readable = false;
    }
    {
        flags.writable = true;
        assert(@bitCast(c.GIFieldInfoFlags, flags) == c.GI_FIELD_IS_WRITABLE);
        flags.writable = false;
    }
}

pub const FunctionInfoFlags = packed struct(c.GIFunctionInfoFlags) {
    is_method: bool = false,
    is_constructor: bool = false,
    is_getter: bool = false,
    is_setter: bool = false,
    wraps_vfunc: bool = false,
    throws: bool = false,
    _padding: u26 = 0,
};

test "FunctionInfoFlags" {
    var flags: FunctionInfoFlags = .{};
    {
        flags.is_method = true;
        assert(@bitCast(c.GIFunctionInfoFlags, flags) == c.GI_FUNCTION_IS_METHOD);
        flags.is_method = false;
    }
    {
        flags.is_constructor = true;
        assert(@bitCast(c.GIFunctionInfoFlags, flags) == c.GI_FUNCTION_IS_CONSTRUCTOR);
        flags.is_constructor = false;
    }
    {
        flags.is_getter = true;
        assert(@bitCast(c.GIFunctionInfoFlags, flags) == c.GI_FUNCTION_IS_GETTER);
        flags.is_getter = false;
    }
    {
        flags.is_setter = true;
        assert(@bitCast(c.GIFunctionInfoFlags, flags) == c.GI_FUNCTION_IS_SETTER);
        flags.is_setter = false;
    }
    {
        flags.wraps_vfunc = true;
        assert(@bitCast(c.GIFunctionInfoFlags, flags) == c.GI_FUNCTION_WRAPS_VFUNC);
        flags.wraps_vfunc = false;
    }
    {
        flags.throws = true;
        assert(@bitCast(c.GIFunctionInfoFlags, flags) == c.GI_FUNCTION_THROWS);
        flags.throws = false;
    }
}

pub const ParamFlags = packed struct(c.GParamFlags) {
    readable: bool = false,
    writable: bool = false,
    construct: bool = false,
    construct_only: bool = false,
    lax_validation: bool = false,
    static_name: bool = false,
    static_nick: bool = false,
    static_blurb: bool = false,
    _padding0: u22 = 0,
    explicit_notify: bool = false,
    deprecated: bool = false,
};

test "ParamFlags" {
    var flags: ParamFlags = .{};
    {
        flags.readable = true;
        assert(@bitCast(c.GParamFlags, flags) == c.G_PARAM_READABLE);
        flags.readable = false;
    }
    {
        flags.writable = true;
        assert(@bitCast(c.GParamFlags, flags) == c.G_PARAM_WRITABLE);
        flags.writable = false;
    }
    {
        flags.construct = true;
        assert(@bitCast(c.GParamFlags, flags) == c.G_PARAM_CONSTRUCT);
        flags.construct = false;
    }
    {
        flags.construct_only = true;
        assert(@bitCast(c.GParamFlags, flags) == c.G_PARAM_CONSTRUCT_ONLY);
        flags.construct_only = false;
    }
    {
        flags.lax_validation = true;
        assert(@bitCast(c.GParamFlags, flags) == c.G_PARAM_LAX_VALIDATION);
        flags.lax_validation = false;
    }
    {
        flags.static_name = true;
        assert(@bitCast(c.GParamFlags, flags) == c.G_PARAM_STATIC_NAME);
        flags.static_name = false;
    }
    {
        flags.static_nick = true;
        assert(@bitCast(c.GParamFlags, flags) == c.G_PARAM_STATIC_NICK);
        flags.static_nick = false;
    }
    {
        flags.static_blurb = true;
        assert(@bitCast(c.GParamFlags, flags) == c.G_PARAM_STATIC_BLURB);
        flags.static_blurb = false;
    }
    {
        flags.explicit_notify = true;
        assert(@bitCast(c.GParamFlags, flags) == c.G_PARAM_EXPLICIT_NOTIFY);
        flags.explicit_notify = false;
    }
    {
        flags.deprecated = true;
        assert(@bitCast(c.GParamFlags, flags) == c.G_PARAM_DEPRECATED);
        flags.deprecated = false;
    }
}

pub const SignalFlags = packed struct(c.GSignalFlags) {
    run_first: bool = false,
    run_last: bool = false,
    run_cleanup: bool = false,
    no_recurse: bool = false,
    detailed: bool = false,
    action: bool = false,
    no_hooks: bool = false,
    must_collect: bool = false,
    deprecated: bool = false,
    _padding0: u8 = 0,
    accumulator_first_run: bool = false,
    _padding: u14 = 0,
};

test "SignalFlags" {
    var flags: SignalFlags = .{};
    {
        flags.run_first = true;
        assert(@bitCast(c.GSignalFlags, flags) == c.G_SIGNAL_RUN_FIRST);
        flags.run_first = false;
    }
    {
        flags.run_last = true;
        assert(@bitCast(c.GSignalFlags, flags) == c.G_SIGNAL_RUN_LAST);
        flags.run_last = false;
    }
    {
        flags.run_cleanup = true;
        assert(@bitCast(c.GSignalFlags, flags) == c.G_SIGNAL_RUN_CLEANUP);
        flags.run_cleanup = false;
    }
    {
        flags.no_recurse = true;
        assert(@bitCast(c.GSignalFlags, flags) == c.G_SIGNAL_NO_RECURSE);
        flags.no_recurse = false;
    }
    {
        flags.detailed = true;
        assert(@bitCast(c.GSignalFlags, flags) == c.G_SIGNAL_DETAILED);
        flags.detailed = false;
    }
    {
        flags.action = true;
        assert(@bitCast(c.GSignalFlags, flags) == c.G_SIGNAL_ACTION);
        flags.action = false;
    }
    {
        flags.no_hooks = true;
        assert(@bitCast(c.GSignalFlags, flags) == c.G_SIGNAL_NO_HOOKS);
        flags.no_hooks = false;
    }
    {
        flags.must_collect = true;
        assert(@bitCast(c.GSignalFlags, flags) == c.G_SIGNAL_MUST_COLLECT);
        flags.must_collect = false;
    }
    {
        flags.deprecated = true;
        assert(@bitCast(c.GSignalFlags, flags) == c.G_SIGNAL_DEPRECATED);
        flags.deprecated = false;
    }
    {
        flags.accumulator_first_run = true;
        assert(@bitCast(c.GSignalFlags, flags) == c.G_SIGNAL_ACCUMULATOR_FIRST_RUN);
        flags.accumulator_first_run = false;
    }
}

pub const VFuncInfoFlags = packed struct(c.GIVFuncInfoFlags) {
    must_chain_up: bool = false,
    must_override: bool = false,
    must_not_override: bool = false,
    throws: bool = false,
    _padding: u28 = 0,
};

test "VFuncInfoFlags" {
    var flags: VFuncInfoFlags = .{};
    {
        flags.must_chain_up = true;
        assert(@bitCast(c.GIVFuncInfoFlags, flags) == c.GI_VFUNC_MUST_CHAIN_UP);
        flags.must_chain_up = false;
    }
    {
        flags.must_override = true;
        assert(@bitCast(c.GIVFuncInfoFlags, flags) == c.GI_VFUNC_MUST_OVERRIDE);
        flags.must_override = false;
    }
    {
        flags.must_not_override = true;
        assert(@bitCast(c.GIVFuncInfoFlags, flags) == c.GI_VFUNC_MUST_NOT_OVERRIDE);
        flags.must_not_override = false;
    }
    {
        flags.throws = true;
        assert(@bitCast(c.GIVFuncInfoFlags, flags) == c.GI_VFUNC_THROWS);
        flags.throws = false;
    }
}

pub const BaseInfo = struct {
    info: *c.GIBaseInfo,

    pub fn deinit(self: BaseInfo) void {
        c.g_base_info_unref(self.info);
    }

    pub fn asCallable(self: BaseInfo) CallableInfo {
        assert(c.GI_IS_CALLABLE_INFO(self.info));
        return .{ .info = self.info };
    }

    pub fn asRegisteredType(self: BaseInfo) RegisteredTypeInfo {
        assert(c.GI_IS_REGISTERED_TYPE_INFO(self.info));
        return .{ .info = self.info };
    }

    pub fn asArg(self: BaseInfo) ArgInfo {
        assert(c.GI_IS_ARG_INFO(self.info));
        return .{ .info = self.info };
    }

    pub fn asConstant(self: BaseInfo) ConstantInfo {
        assert(c.GI_IS_CONSTANT_INFO(self.info));
        return .{ .info = self.info };
    }

    pub fn asValue(self: BaseInfo) ValueInfo {
        assert(c.GI_IS_VALUE_INFO(self.info));
        return .{ .info = self.info };
    }

    pub fn asField(self: BaseInfo) FieldInfo {
        assert(c.GI_IS_FIELD_INFO(self.info));
        return .{ .info = self.info };
    }

    pub fn asProperty(self: BaseInfo) PropertyInfo {
        assert(c.GI_IS_PROPERTY_INFO(self.info));
        return .{ .info = self.info };
    }

    pub fn asType(self: BaseInfo) TypeInfo {
        assert(c.GI_IS_TYPE_INFO(self.info));
        return .{ .info = self.info };
    }

    pub fn name(self: BaseInfo) ?[:0]const u8 {
        return std.mem.span(@as(?[*:0]const u8, c.g_base_info_get_name(self.info)));
    }

    pub fn namespace(self: BaseInfo) [:0]const u8 {
        return std.mem.span(c.g_base_info_get_namespace(self.info));
    }

    pub fn container(self: BaseInfo) BaseInfo {
        return .{ .info = c.g_base_info_get_container(self.info) };
    }

    pub fn @"type"(self: BaseInfo) InfoType {
        return @intToEnum(InfoType, c.g_base_info_get_type(self.info));
    }

    pub fn isDeprecated(self: BaseInfo) bool {
        return c.g_base_info_is_deprecated(self.info) != 0;
    }
};

pub const CallableInfo = struct {
    info: *c.GICallableInfo,

    pub fn asBase(self: CallableInfo) BaseInfo {
        return .{ .info = self.info };
    }

    pub fn asFunction(self: CallableInfo) FunctionInfo {
        assert(c.GI_IS_FUNCTION_INFO(self.info));
        return .{ .info = self.info };
    }

    pub fn asCallback(self: CallableInfo) CallbackInfo {
        assert(self.asBase().type() == .Callback);
        return .{ .info = self.info };
    }

    pub fn asSignal(self: CallableInfo) SignalInfo {
        assert(c.GI_IS_SIGNAL_INFO(self.info));
        return .{ .info = self.info };
    }

    pub fn asVFunc(self: CallableInfo) VFuncInfo {
        assert(c.GI_IS_VFUNC_INFO(self.info));
        return .{ .info = self.info };
    }

    pub fn canThrow(self: CallableInfo) bool {
        return c.g_callable_info_can_throw_gerror(self.info) != 0;
    }

    pub fn callerOwns(self: CallableInfo) Transfer {
        return @intToEnum(Transfer, c.g_callable_info_get_caller_owns(self.info));
    }

    pub fn instanceOwnershipTransfer(self: CallableInfo) Transfer {
        return @intToEnum(Transfer, c.g_callable_info_get_instance_ownership_transfer(self.info));
    }

    pub fn returnType(self: CallableInfo) TypeInfo {
        return .{ .info = c.g_callable_info_get_return_type(self.info) };
    }

    pub fn isMethod(self: CallableInfo) bool {
        return c.g_callable_info_is_method(self.info) != 0;
    }

    pub fn mayReturnNull(self: CallableInfo) bool {
        return c.g_callable_info_may_return_null(self.info) != 0;
    }

    pub fn skipReturn(self: CallableInfo) bool {
        return c.g_callable_info_skip_return(self.info) != 0;
    }

    const ArgsIter = struct {
        callable_info: CallableInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?ArgInfo = null,

        pub fn next(self: *ArgsIter) ?ArgInfo {
            if (self.ret) |some| {
                some.asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = ArgInfo{ .info = c.g_callable_info_get_arg(self.callable_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn argsIter(self: CallableInfo) ArgsIter {
        return .{ .callable_info = self, .capacity = @intCast(usize, c.g_callable_info_get_n_args(self.info)) };
    }

    pub fn argsAlloc(self: CallableInfo, allocator: std.mem.Allocator) ![]ArgInfo {
        var args = try allocator.alloc(ArgInfo, @intCast(usize, c.g_callable_info_get_n_args(self.info)));
        for (args, 0..) |*arg, index| {
            arg.* = .{ .info = c.g_callable_info_get_arg(self.info, @intCast(c_int, index)) };
        }
        return args;
    }

    fn format_helper(self: CallableInfo, writer: anytype, type_annotation: bool, c_callconv: bool, vfunc: bool) !void {
        var first = true;
        try writer.writeAll("(");
        if (self.isMethod()) {
            if (first) {
                first = false;
            } else {
                try writer.writeAll(", ");
            }
            const container = self.asBase().container();
            if (type_annotation) {
                try writer.print("self: *{s}", .{container.name().?});
            } else {
                try writer.writeAll("self");
            }
        }
        if (vfunc) {
            if (type_annotation) {
                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }
                try writer.writeAll("_type: core.Type");
            }
        }
        var iter = self.argsIter();
        while (iter.next()) |arg| {
            if (first) {
                first = false;
            } else {
                try writer.writeAll(", ");
            }
            if (type_annotation) {
                try writer.print("{}", .{arg});
            } else {
                const arg_name = arg.asBase().name().?;
                try writer.print("arg_{s}", .{arg_name});
            }
        }
        if (self.canThrow()) {
            if (first) {
                first = false;
            } else {
                try writer.writeAll(", ");
            }
            if (type_annotation) {
                try writer.writeAll("_error: *?*core.Error");
            } else {
                if (!vfunc) {
                    try writer.writeAll("&"); // method wrapper
                }
                try writer.writeAll("_error");
            }
        }
        try writer.writeAll(") ");
        if (type_annotation) {
            if (c_callconv) {
                try writer.writeAll("callconv(.C) ");
            }
            if (self.skipReturn()) {
                try writer.writeAll("void");
            } else {
                const return_type = self.returnType();
                defer return_type.asBase().deinit();
                var generic_gtk_widget = false;
                const func_name = self.asBase().name().?;
                if (func_name.len >= 3 and std.mem.eql(u8, "new", func_name[0..3])) {
                    if (return_type.interface()) |interface| {
                        defer interface.deinit();
                        if (std.mem.eql(u8, "Gtk", interface.namespace()) and std.mem.eql(u8, "Widget", interface.name().?)) {
                            generic_gtk_widget = true;
                        }
                    }
                }
                if (generic_gtk_widget) {
                    const container = self.asBase().container();
                    if (self.mayReturnNull()) {
                        try writer.writeAll("?");
                    }
                    try writer.print("*{s}", .{container.name().?});
                } else {
                    if (self.mayReturnNull() or return_type.tag() == .GList or return_type.tag() == .GSList) {
                        try writer.print("{&?}", .{return_type});
                    } else {
                        try writer.print("{&}", .{return_type});
                    }
                }
            }
        }
    }
};

const SliceInfo = struct {
    is_slice_ptr: bool = false,
    slice_len: usize = undefined,
    is_slice_len: bool = false,
    slice_ptr: usize = undefined,
};

const ClosureInfo = struct {
    scope: ScopeType = .Invalid,
    is_func: bool = false,
    closure_data: usize = undefined,
    is_data: bool = false,
    closure_func: usize = undefined,
    is_destroy: bool = false,
    closure_destroy: usize = undefined,
};

pub const FunctionInfo = struct {
    info: *c.GIFunctionInfo,

    pub fn asCallable(self: FunctionInfo) CallableInfo {
        return .{ .info = self.info };
    }

    pub fn flags(self: FunctionInfo) FunctionInfoFlags {
        return @bitCast(FunctionInfoFlags, c.g_function_info_get_flags(self.info));
    }

    pub fn property(self: FunctionInfo) ?PropertyInfo {
        return if (c.g_function_info_get_property(self.info)) |some| PropertyInfo{ .info = some } else null;
    }

    pub fn symbol(self: FunctionInfo) [:0]const u8 {
        return std.mem.span(c.g_function_info_get_symbol(self.info));
    }

    pub fn vfunc(self: FunctionInfo) ?VFuncInfo {
        return if (c.g_function_info_get_vfunc(self.info)) |some| VFuncInfo{ .info = some } else null;
    }

    pub fn format(self: FunctionInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        if (self.asCallable().asBase().isDeprecated() and !enable_deprecated) return;
        var buffer: [4096]u8 = undefined;
        var fixed_buffer_allocator = std.heap.FixedBufferAllocator.init(buffer[0..]);
        const allocator = fixed_buffer_allocator.allocator();
        var buf: [256]u8 = undefined;
        const func_name = snakeToCamel(self.asCallable().asBase().name().?, buf[0..]);
        if (isZigKeyword(func_name)) {
            try writer.print("pub fn @\"{s}\"", .{func_name});
        } else if (std.mem.eql(u8, "self", func_name)) {
            try writer.writeAll("pub fn getSelf");
        } else {
            try writer.print("pub fn {s}", .{func_name});
        }
        const return_type = self.asCallable().returnType();
        defer return_type.asBase().deinit();
        var args = self.asCallable().argsAlloc(allocator) catch @panic("Out of Memory");
        defer {
            for (args) |arg| {
                arg.asBase().deinit();
            }
        }
        var slice_info = allocator.alloc(SliceInfo, args.len) catch @panic("Out of Memory");
        std.mem.set(SliceInfo, slice_info[0..], .{});
        var closure_info = allocator.alloc(ClosureInfo, args.len) catch @panic("Out of Memory");
        std.mem.set(ClosureInfo, closure_info[0..], .{});
        var n_out_param: usize = 0;
        for (args, 0..) |arg, idx| {
            if (arg.direction() == .Out and !arg.isCallerAllocates()) {
                n_out_param += 1;
            }
            const arg_type = arg.type();
            defer arg_type.asBase().deinit();
            if (arg_type.arrayLength()) |pos| {
                slice_info[idx].is_slice_ptr = true;
                slice_info[idx].slice_len = pos;
                if (!slice_info[pos].is_slice_len) {
                    slice_info[pos].is_slice_len = true;
                    slice_info[pos].slice_ptr = idx;
                }
            }
            const arg_name = arg.asBase().name().?;
            if (arg.scope() != .Invalid and arg.closure() != null and !std.mem.eql(u8, "data", arg_name[arg_name.len - 4 .. arg_name.len])) {
                closure_info[idx].scope = arg.scope();
                closure_info[idx].is_func = true;
                if (arg.closure()) |pos| {
                    closure_info[idx].closure_data = pos;
                    closure_info[pos].is_data = true;
                    closure_info[pos].closure_func = idx;
                }
                if (arg.destroy()) |pos| {
                    closure_info[idx].closure_destroy = pos;
                    closure_info[pos].is_destroy = true;
                    closure_info[pos].closure_func = idx;
                }
            }
        }
        const return_bool = return_type.tag() == .Boolean;
        const throw_bool = return_bool and (n_out_param > 0);
        const throw_error = self.asCallable().canThrow();
        const skip_return = self.asCallable().skipReturn();
        {
            try writer.writeAll("(");
            var first = true;
            if (self.asCallable().isMethod()) {
                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }
                const container = self.asCallable().asBase().container();
                try writer.print("self: *{s}", .{container.name().?});
            }
            for (args, 0..) |arg, idx| {
                if (arg.direction() == .Out and !arg.isCallerAllocates()) continue;
                if (slice_info[idx].is_slice_len) continue;
                if (closure_info[idx].is_data) continue;
                if (closure_info[idx].is_destroy) continue;
                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }
                const arg_type = arg.type();
                defer arg_type.asBase().deinit();
                if (slice_info[idx].is_slice_ptr) {
                    try writer.print("argz_{s}: ", .{arg.asBase().name().?});
                    if (arg.isOptional()) {
                        try writer.writeAll("?");
                    }
                    try writer.print("[]{}", .{arg.type().paramType(0)});
                } else if (closure_info[idx].is_func) {
                    try writer.print("argz_{s}: anytype, argz_{s}_args: anytype", .{ arg.asBase().name().?, arg.asBase().name().? });
                } else {
                    try writer.print("{}", .{arg});
                }
            }
            try writer.writeAll(") ");
            if (throw_bool or throw_error) {
                try writer.writeAll("core.Expected(");
            }
            if (n_out_param > 0) {
                try writer.writeAll("struct {\n");
                try writer.writeAll("ret: ");
            }
            if (skip_return or throw_bool) {
                try writer.writeAll("void");
            } else {
                var generic_gtk_widget = false;
                if (func_name.len >= 3 and std.mem.eql(u8, "new", func_name[0..3])) {
                    if (return_type.interface()) |interface| {
                        if (std.mem.eql(u8, "Gtk", interface.namespace()) and std.mem.eql(u8, "Widget", interface.name().?)) {
                            generic_gtk_widget = true;
                        }
                    }
                }
                if (return_bool) {
                    try writer.writeAll("bool");
                }
                else if (generic_gtk_widget) {
                    const container = self.asCallable().asBase().container();
                    if (self.asCallable().mayReturnNull()) {
                        try writer.writeAll("?");
                    }
                    try writer.print("*{s}", .{container.name().?});
                } else {
                    if (self.asCallable().mayReturnNull() or return_type.tag() == .GList or return_type.tag() == .GSList) {
                        try writer.print("{&?}", .{return_type});
                    } else {
                        try writer.print("{&}", .{return_type});
                    }
                }
            }
            if (n_out_param > 0) {
                try writer.writeAll(",\n");
                for (args, 0..) |arg, idx| {
                    if (arg.direction() != .Out or arg.isCallerAllocates()) continue;
                    if (slice_info[idx].is_slice_len) continue;
                    const arg_type = arg.type();
                    defer arg_type.asBase().deinit();
                    if (slice_info[idx].is_slice_ptr) {
                        try writer.print("{s}: ", .{arg.asBase().name().?});
                        if (arg.isOptional()) {
                            try writer.writeAll("?");
                        }
                        try writer.print("[]{}", .{arg.type().paramType(0)});
                    } else {
                        if (arg.mayBeNull()) {
                            try writer.print("{s}: {&?}", .{ arg.asBase().name().?, arg.type() });
                        } else {
                            try writer.print("{s}: {&}", .{ arg.asBase().name().?, arg.type() });
                        }
                    }
                    try writer.writeAll(",\n");
                }
                try writer.writeAll("}");
            }
            if (throw_error) {
                try writer.writeAll(", *core.Error)");
            } else if (throw_bool) {
                try writer.writeAll(", void)");
            }
        }
        try writer.writeAll(" {\n");
        // prepare error
        if (throw_error) {
            try writer.writeAll("var _error: ?*core.Error = null;\n");
        }
        // prepare input/inout
        for (args, 0..) |arg, idx| {
            if (arg.direction() == .Out and !arg.isCallerAllocates()) continue;
            const arg_name = arg.asBase().name().?;
            if (slice_info[idx].is_slice_len) {
                const arg_type = arg.type();
                defer arg_type.asBase().deinit();
                const ptr_arg = args[slice_info[idx].slice_ptr];
                if (ptr_arg.isOptional()) {
                    try writer.print("var arg_{s} = if (argz_{s}) |some| @intCast({}, some.len) else 0;\n", .{ arg_name, ptr_arg.asBase().name().?, arg_type });
                } else {
                    try writer.print("var arg_{s} = @intCast({}, argz_{s}.len);\n", .{ arg_name, arg_type, ptr_arg.asBase().name().? });
                }
            }
            if (slice_info[idx].is_slice_ptr) {
                if (arg.isOptional()) {
                    try writer.print("var arg_{s} = if (argz_{s}) |some| some.ptr else null;\n", .{ arg_name, arg_name });
                } else {
                    try writer.print("var arg_{s} = argz_{s}.ptr;\n", .{ arg_name, arg_name });
                }
            }
            if (closure_info[idx].is_func) {
                try writer.print("var closure_{s} = core.ClosureZ(@TypeOf(&argz_{s}), @TypeOf(argz_{s}_args), &[_]type{{", .{ arg_name, arg_name, arg_name });
                const arg_type = arg.type();
                defer arg_type.asBase().deinit();
                if (arg_type.interface()) |interface| {
                    defer interface.deinit();
                    if (interface.type() == .Callback) {
                        const cb_return_type = interface.asCallable().returnType();
                        defer cb_return_type.asBase().deinit();
                        if (interface.asCallable().mayReturnNull() or cb_return_type.tag() == .GList or cb_return_type.tag() == .GSList) {
                            try writer.print("{&?}", .{cb_return_type});
                        } else {
                            try writer.print("{&}", .{cb_return_type});
                        }
                        var callback_args = interface.asCallable().argsAlloc(allocator) catch @panic("Out of Memory");
                        defer {
                            for (callback_args) |cb_arg| {
                                cb_arg.asBase().deinit();
                            }
                        }
                        if (callback_args.len > 0) {
                            for (callback_args[0 .. callback_args.len - 1]) |cb_arg| {
                                try writer.writeAll(", ");
                                try writer.print("{$}", .{cb_arg});
                            }
                        } else {
                            std.log.warn("[Generic Callback] {s}", .{self.symbol()});
                        }
                        if (interface.asCallable().canThrow()) {
                            std.log.warn("[Throwable Callback] {s}", .{self.symbol()});
                        }
                    } else {
                        try writer.writeAll("void");
                        std.log.warn("[Generic Callback] {s}", .{self.symbol()});
                    }
                } else {
                    try writer.writeAll("void");
                    std.log.warn("[Generic Callback] {s}", .{self.symbol()});
                }
                try writer.print("}}).new(null, argz_{s}, argz_{s}_args) catch @panic(\"Out of Memory\");\n", .{ arg_name, arg_name });
                switch (closure_info[idx].scope) {
                    .Call => {
                        try writer.print("defer closure_{s}.deinit();\n", .{arg_name});
                    },
                    .Async => {
                        try writer.print("closure_{s}.setOnce();\n", .{arg_name});
                    },
                    .Notified, .Forever => {
                        // no op
                    },
                    else => unreachable,
                }
                try writer.print("var arg_{s} = @ptrCast({$}, closure_{s}.c_closure());\n", .{ arg_name, arg, arg_name });
            }
            if (closure_info[idx].is_data) {
                const func_arg = args[closure_info[idx].closure_func];
                try writer.print("var arg_{s} = @ptrCast({$}, closure_{s}.c_data());\n", .{ arg_name, arg, func_arg.asBase().name().? });
            }
            if (closure_info[idx].is_destroy) {
                const func_arg = args[closure_info[idx].closure_func];
                try writer.print("var arg_{s} = @ptrCast({$}, closure_{s}.c_destroy());\n", .{ arg_name, arg, func_arg.asBase().name().? });
            }
        }
        // prepare output
        for (args) |arg| {
            if (arg.direction() != .Out or arg.isCallerAllocates()) continue;
            const arg_name = arg.asBase().name().?;
            const arg_type = arg.type();
            defer arg_type.asBase().deinit();
            if (arg.mayBeNull()) {
                try writer.print("var out_{s}: {&?} = undefined;\n", .{ arg_name, arg_type });
            } else {
                try writer.print("var out_{s}: {&} = undefined;\n", .{ arg_name, arg_type });
            }
            try writer.print("var arg_{s} = &out_{s};\n", .{ arg_name, arg_name });
        }
        try writer.print("const ffi_fn = struct {{ extern \"c\" fn {s}", .{self.symbol()});
        try self.asCallable().format_helper(writer, true, false, false);
        try writer.print("; }}.{s};\n", .{self.symbol()});
        try writer.writeAll("const ret = ffi_fn");
        try self.asCallable().format_helper(writer, false, false, false);
        try writer.writeAll(";\n");
        if (skip_return) {
            try writer.writeAll("_ = ret;\n");
        }
        if (throw_error) {
            if (throw_bool) {
                try writer.writeAll("_ = ret;\n");
            }
            try writer.writeAll("if (_error) |some| return .{.Err = some};\n");
            try writer.writeAll("return .{.Ok = ");
        } else if (throw_bool) {
            try writer.writeAll("if (ret) return .{.Err = {}};\n");
            try writer.writeAll("return .{.Ok = ");
        } else {
            try writer.writeAll("return ");
        }
        if (n_out_param > 0) {
            try writer.writeAll(".{ .ret = ");
        }
        if (skip_return or throw_bool) {
            try writer.writeAll("{}");
        } else {
            try writer.writeAll("ret");
        }
        if (n_out_param > 0) {
            for (args, 0..) |arg, idx| {
                if (arg.direction() != .Out or arg.isCallerAllocates()) continue;
                if (slice_info[idx].is_slice_len) continue;
                try writer.writeAll(", ");
                const arg_name = arg.asBase().name().?;
                try writer.print(".{s} = out_{s}", .{ arg_name, arg_name });
                if (slice_info[idx].is_slice_ptr) {
                    const len_arg = args[slice_info[idx].slice_len];
                    try writer.writeAll("[0..@intCast(usize, ");
                    if (len_arg.direction() == .Out and !len_arg.isCallerAllocates()) {
                        try writer.print("out_{s}", .{len_arg.asBase().name().?});
                    } else {
                        try writer.print("arg_{s}", .{len_arg.asBase().name().?});
                    }
                    try writer.writeAll(")]");
                }
            }
            try writer.writeAll("}");
        }
        if (throw_bool or throw_error) {
            try writer.writeAll("};\n");
        } else {
            try writer.writeAll(";\n");
        }
        try writer.writeAll("}\n");
    }
};

pub const CallbackInfo = struct {
    info: *c.GICallbackInfo,

    pub fn asCallable(self: CallbackInfo) CallableInfo {
        return .{ .info = self.info };
    }

    pub fn format(self: CallbackInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        if (self.asCallable().asBase().isDeprecated() and !enable_deprecated) return;
        try writer.writeAll("*const fn ");
        try self.asCallable().format_helper(writer, true, true, false);
    }
};

pub const SignalInfo = struct {
    info: *c.GISignalInfo,

    pub fn asCallable(self: SignalInfo) CallableInfo {
        return .{ .info = self.info };
    }

    pub fn flags(self: SignalInfo) SignalFlags {
        return @bitCast(SignalFlags, c.g_signal_info_get_flags(self.info));
    }

    pub fn classClosure(self: SignalInfo) ?VFuncInfo {
        return if (c.g_signal_info_get_class_closure(self.info)) |some| VFuncInfo{ .info = some } else null;
    }

    pub fn trueStopsEmit(self: SignalInfo) bool {
        return c.g_signal_info_true_stops_emit(self.info) != 0;
    }

    pub fn format(self: SignalInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        if (self.asCallable().asBase().isDeprecated() and !enable_deprecated) return;
        const container_name = self.asCallable().asBase().container().name().?;
        var buf: [256]u8 = undefined;
        const raw_name = self.asCallable().asBase().name().?;
        const name = snakeToCamel(raw_name, buf[0..]);
        try writer.print("pub fn connect{c}{s}(self: *{s}, handler: anytype, args: anytype, flags: core.ConnectFlagsZ) usize {{\n", .{ std.ascii.toUpper(name[0]), name[1..], container_name });
        try writer.print("return core.connect(self.into(core.Object), \"{s}\", handler, args, flags, &[_]type{{", .{raw_name});
        const return_type = self.asCallable().returnType();
        defer return_type.asBase().deinit();
        if (self.asCallable().mayReturnNull()) {
            try writer.print("{&*}", .{return_type});
        } else {
            try writer.print("{&}", .{return_type});
        }
        try writer.print(", *{s}", .{container_name});
        var iter = self.asCallable().argsIter();
        while (iter.next()) |arg| {
            try writer.print(", {$}", .{arg});
        }
        try writer.writeAll("});\n");
        try writer.writeAll("}\n");
        // connect swapped
        try writer.print("pub fn connect{c}{s}Swap(self: *{s}, handler: anytype, args: anytype, flags: core.ConnectFlagsZ) usize {{\n", .{ std.ascii.toUpper(name[0]), name[1..], container_name });
        try writer.print("return core.connectSwap(self.into(core.Object), \"{s}\", handler, args, flags, &[_]type{{", .{raw_name});
        if (self.asCallable().mayReturnNull()) {
            try writer.print("{&*}", .{return_type});
        } else {
            try writer.print("{&}", .{return_type});
        }
        try writer.writeAll("});\n");
        try writer.writeAll("}\n");
    }
};

pub const VFuncInfo = struct {
    info: *c.GIVFuncInfo,

    pub fn asCallable(self: VFuncInfo) CallableInfo {
        return .{ .info = self.info };
    }

    pub fn flags(self: VFuncInfo) VFuncInfoFlags {
        return @bitCast(VFuncInfoFlags, c.g_vfunc_info_get_flags(self.info));
    }

    pub fn offset(self: VFuncInfo) c_int {
        return c.g_vfunc_info_get_offset(self.info);
    }

    pub fn signal(self: VFuncInfo) ?SignalInfo {
        return if (c.g_vfunc_info_get_signal(self.info)) |some| SignalInfo{ .info = some } else null;
    }

    pub fn invoker(self: VFuncInfo) ?FunctionInfo {
        return if (c.g_vfunc_info_get_invoker(self.info)) |some| FunctionInfo{ .info = some } else null;
    }

    pub fn format(self: VFuncInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        if (self.asCallable().asBase().isDeprecated() and !enable_deprecated) return;
        var buf: [256]u8 = undefined;
        const raw_vfunc_name = self.asCallable().asBase().name().?;
        const vfunc_name = snakeToCamel(raw_vfunc_name, buf[0..]);
        const container = self.asCallable().asBase().container();
        const class = switch (container.type()) {
            .Object => container.asRegisteredType().asObject().classStruct().?,
            .Interface => container.asRegisteredType().asInterface().ifaceStruct().?,
            else => unreachable,
        };
        defer class.asRegisteredType().asBase().deinit();
        const class_name = class.asRegisteredType().asBase().name().?;
        try writer.print("pub fn {s}V", .{vfunc_name});
        try self.asCallable().format_helper(writer, true, false, true);
        try writer.writeAll(" {\n");
        try writer.print("const vfunc_fn = @ptrCast(*{s}, core.typeClassPeek(_type)).{s}.?;", .{ class_name, raw_vfunc_name });
        try writer.writeAll("const ret = vfunc_fn");
        try self.asCallable().format_helper(writer, false, false, true);
        try writer.writeAll(";\n");
        if (self.asCallable().skipReturn()) {
            try writer.writeAll("_ = ret;\n");
        }
        if (self.asCallable().skipReturn()) {
            try writer.writeAll("return {};\n");
        } else {
            try writer.writeAll("return ret;\n");
        }
        try writer.writeAll("}\n");
    }
};

pub const RegisteredTypeInfo = struct {
    info: *c.GIRegisteredTypeInfo,

    pub fn asBase(self: RegisteredTypeInfo) BaseInfo {
        return .{ .info = self.info };
    }

    pub fn asEnum(self: RegisteredTypeInfo) EnumInfo {
        assert(c.GI_IS_ENUM_INFO(self.info));
        return .{ .info = self.info };
    }

    pub fn asStruct(self: RegisteredTypeInfo) StructInfo {
        assert(c.GI_IS_STRUCT_INFO(self.info));
        return .{ .info = self.info };
    }

    pub fn asUnion(self: RegisteredTypeInfo) UnionInfo {
        assert(c.GI_IS_UNION_INFO(self.info));
        return .{ .info = self.info };
    }

    pub fn asObject(self: RegisteredTypeInfo) ObjectInfo {
        assert(c.GI_IS_OBJECT_INFO(self.info));
        return .{ .info = self.info };
    }

    pub fn asInterface(self: RegisteredTypeInfo) InterfaceInfo {
        assert(c.GI_IS_INTERFACE_INFO(self.info));
        return .{ .info = self.info };
    }

    pub fn typeName(self: RegisteredTypeInfo) [:0]const u8 {
        return std.mem.span(c.g_registered_type_info_get_type_name(self.info));
    }

    pub fn typeInit(self: RegisteredTypeInfo) [:0]const u8 {
        return std.mem.span(c.g_registered_type_info_get_type_init(self.info));
    }

    pub fn gType(self: RegisteredTypeInfo) c.GType {
        return c.g_registered_type_info_get_g_type(self.info);
    }

    pub fn format_helper(self: RegisteredTypeInfo, writer: anytype) !void {
        if (self.gType() != c.G_TYPE_NONE) {
            try writer.writeAll("pub fn @\"type\"() core.Type {\n");
            const init_fn = self.typeInit();
            if (std.mem.eql(u8, "intern", init_fn)) {
                if (self.gType() < 256 * 4) {
                    try writer.print("return @intToEnum(core.Type, {});", .{self.gType()});
                } else {
                    try writer.writeAll("@panic(\"Internal type\");");
                }            
            } else {
                try writer.print("const ffi_fn = struct {{ extern \"c\" fn {s}() core.Type; }}.{s};\n", .{ init_fn, init_fn });
                try writer.writeAll("return ffi_fn();\n");
            }
            try writer.writeAll("}\n");
        }
    }
};

pub const EnumInfo = struct {
    info: *c.GIEnumInfo,

    pub fn asRegisteredType(self: EnumInfo) RegisteredTypeInfo {
        return .{ .info = self.info };
    }

    pub fn storageType(self: EnumInfo) TypeTag {
        return @intToEnum(TypeTag, c.g_enum_info_get_storage_type(self.info));
    }

    pub fn errorDomain(self: EnumInfo) ?[:0]const u8 {
        return std.mem.span(@as(?[*:0]const u8, c.g_enum_info_get_error_domain(self.info)));
    }

    const ValueIter = struct {
        enum_info: EnumInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?ValueInfo = null,

        pub fn next(self: *ValueIter) ?ValueInfo {
            if (self.ret) |some| {
                some.asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = ValueInfo{ .info = c.g_enum_info_get_value(self.enum_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn valueIter(self: EnumInfo) ValueIter {
        return .{ .enum_info = self, .capacity = @intCast(usize, c.g_enum_info_get_n_values(self.info)) };
    }

    const MethodIter = struct {
        enum_info: EnumInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?FunctionInfo = null,

        pub fn next(self: *MethodIter) ?FunctionInfo {
            if (self.ret) |some| {
                some.asCallable().asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = FunctionInfo{ .info = c.g_enum_info_get_method(self.enum_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn methodIter(self: EnumInfo) MethodIter {
        return .{ .enum_info = self, .capacity = @intCast(usize, c.g_enum_info_get_n_methods(self.info)) };
    }

    pub fn format(self: EnumInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        if (self.asRegisteredType().asBase().isDeprecated() and !enable_deprecated) return;
        var option_is_flag = false;
        for (fmt) |ch| {
            if (ch == '_') {
                option_is_flag = true;
                break;
            }
        }
        try writer.print("pub const {s} = enum", .{self.asRegisteredType().asBase().name().?});
        switch (self.storageType()) {
            .Int32 => {
                try writer.writeAll("(i32)");
            },
            .UInt32 => {
                try writer.writeAll("(u32)");
            },
            else => unreachable,
        }
        try writer.writeAll("{\n");
        var last_value: ?i64 = null;
        var iter = self.valueIter();
        while (iter.next()) |value| {
            if (last_value) |some| {
                if (some == value.value()) continue;
            }
            last_value = value.value();
            var buf: [256]u8 = undefined;
            const value_name = snakeToCamel(value.asBase().name().?, buf[0..]);
            if (std.ascii.isAlphabetic(value_name[0])) {
                try writer.print("{c}{s} = ", .{ std.ascii.toUpper(value_name[0]), value_name[1..] });
            } else {
                try writer.print("@\"{s}\" = ", .{value_name});
            }

            if (option_is_flag) {
                switch (self.storageType()) {
                    .Int32 => {
                        const _value = @intCast(i32, value.value());
                        if (_value >= 0) {
                            try writer.print("0x{x}", .{_value});
                        } else {
                            try writer.print("@bitCast(i32, 0x{x})", .{@bitCast(u32, _value)});
                        }
                    },
                    .UInt32 => {
                        try writer.print("0x{x}", .{@intCast(u32, value.value())});
                    },
                    else => unreachable,
                }
            } else {
                switch (self.storageType()) {
                    .Int32 => {
                        try writer.print("{d}", .{@intCast(i32, value.value())});
                    },
                    .UInt32 => {
                        try writer.print("{d}", .{@intCast(u32, value.value())});
                    },
                    else => unreachable,
                }
            }
            try writer.writeAll(",\n");
        }
        if (option_is_flag) {
            try writer.writeAll("_,\n");
            try writer.writeAll("pub usingnamespace core.Flags(@This());\n");
        }
        var m_iter = self.methodIter();
        while (m_iter.next()) |method| {
            try writer.print("\n{}", .{method});
        }
        try self.asRegisteredType().format_helper(writer);
        try writer.writeAll("};\n");
    }
};

pub const StructInfo = struct {
    info: *c.GIStructInfo,

    pub fn asRegisteredType(self: StructInfo) RegisteredTypeInfo {
        return .{ .info = self.info };
    }

    pub fn alignment(self: StructInfo) usize {
        return c.g_struct_info_get_alignment(self.info);
    }

    pub fn size(self: StructInfo) usize {
        return c.g_struct_info_get_size(self.info);
    }

    pub fn isGTypeStruct(self: StructInfo) usize {
        return c.g_struct_info_is_gtype_struct(self.info);
    }

    pub fn isForeign(self: StructInfo) usize {
        return c.g_struct_info_is_foreign(self.info);
    }

    const FieldIter = struct {
        struct_info: StructInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?FieldInfo = null,

        pub fn next(self: *FieldIter) ?FieldInfo {
            if (self.ret) |some| {
                some.asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = FieldInfo{ .info = c.g_struct_info_get_field(self.struct_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn fieldIter(self: StructInfo) FieldIter {
        return .{ .struct_info = self, .capacity = @intCast(usize, c.g_struct_info_get_n_fields(self.info)) };
    }

    const MethodIter = struct {
        struct_info: StructInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?FunctionInfo = null,

        pub fn next(self: *MethodIter) ?FunctionInfo {
            if (self.ret) |some| {
                some.asCallable().asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = FunctionInfo{ .info = c.g_struct_info_get_method(self.struct_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn methodIter(self: StructInfo) MethodIter {
        return .{ .struct_info = self, .capacity = @intCast(usize, c.g_struct_info_get_n_methods(self.info)) };
    }

    pub fn format(self: StructInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        if (self.asRegisteredType().asBase().isDeprecated() and !enable_deprecated) return;
        try writer.print("pub const {s} = {s}{{\n", .{ self.asRegisteredType().asBase().name().?, if (self.size() == 0) "opaque" else "extern struct" });
        var iter = self.fieldIter();
        while (iter.next()) |field| {
            try writer.print("{}", .{field});
        }
        var m_iter = self.methodIter();
        while (m_iter.next()) |method| {
            try writer.print("{}", .{method});
        }
        try self.asRegisteredType().format_helper(writer);
        try writer.writeAll("};\n");
    }
};

pub const UnionInfo = struct {
    info: *c.GIUnionInfo,

    pub fn asRegisteredType(self: UnionInfo) RegisteredTypeInfo {
        return .{ .info = self.info };
    }

    pub fn isDiscriminated(self: UnionInfo) bool {
        return c.g_union_info_is_discriminated(self.info) != 0;
    }

    pub fn discriminatorOffset(self: UnionInfo) usize {
        return @intCast(usize, c.g_union_info_get_discriminator_offset(self.info));
    }

    pub fn discriminatorType(self: UnionInfo) TypeInfo {
        return .{ .info = c.g_union_info_get_discriminator_type(self.info) };
    }

    pub fn discriminator(self: UnionInfo, n: usize) ConstantInfo {
        return .{ .info = c.g_union_info_get_discriminator(self.info, @intCast(c_int, n)) };
    }

    pub fn size(self: UnionInfo) usize {
        return c.g_union_info_get_size(self.info);
    }

    pub fn alignment(self: UnionInfo) usize {
        return c.g_union_info_get_alignment(self.info);
    }

    const FieldIter = struct {
        union_info: UnionInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?FieldInfo = null,

        pub fn next(self: *FieldIter) ?FieldInfo {
            if (self.ret) |some| {
                some.asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = FieldInfo{ .info = c.g_union_info_get_field(self.union_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn fieldIter(self: UnionInfo) FieldIter {
        return .{ .union_info = self, .capacity = @intCast(usize, c.g_union_info_get_n_fields(self.info)) };
    }

    const MethodIter = struct {
        union_info: UnionInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?FunctionInfo = null,

        pub fn next(self: *MethodIter) ?FunctionInfo {
            if (self.ret) |some| {
                some.asCallable().asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = FunctionInfo{ .info = c.g_union_info_get_method(self.union_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn methodIter(self: UnionInfo) MethodIter {
        return .{ .union_info = self, .capacity = @intCast(usize, c.g_union_info_get_n_methods(self.info)) };
    }

    pub fn format(self: UnionInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        if (self.asRegisteredType().asBase().isDeprecated() and !enable_deprecated) return;
        try writer.print("pub const {s} = extern union{{\n", .{self.asRegisteredType().asBase().name().?});
        var iter = self.fieldIter();
        while (iter.next()) |field| {
            try writer.print("{}", .{field});
        }
        var m_iter = self.methodIter();
        while (m_iter.next()) |method| {
            try writer.print("{}", .{method});
        }
        try self.asRegisteredType().format_helper(writer);
        try writer.writeAll("};\n");
    }
};

pub const ObjectInfo = struct {
    info: *c.GIObjectInfo,

    pub fn asRegisteredType(self: ObjectInfo) RegisteredTypeInfo {
        return .{ .info = self.info };
    }

    pub fn abstract(self: ObjectInfo) bool {
        return c.g_object_info_get_abstract(self.info) != 0;
    }

    pub fn fundamental(self: ObjectInfo) bool {
        return c.g_object_info_get_fundamental(self.info) != 0;
    }

    pub fn final(self: ObjectInfo) bool {
        return c.g_object_info_get_final(self.info) != 0;
    }

    pub fn parent(self: ObjectInfo) ?ObjectInfo {
        return if (c.g_object_info_get_parent(self.info)) |some| ObjectInfo{ .info = some } else null;
    }

    pub fn typeName(self: ObjectInfo) [:0]const u8 {
        return std.mem.span(c.g_object_info_get_type_name(self.info));
    }

    pub fn typeInit(self: ObjectInfo) [:0]const u8 {
        return std.mem.span(c.g_object_info_get_type_init(self.info));
    }

    pub fn classStruct(self: ObjectInfo) ?StructInfo {
        return if (c.g_object_info_get_class_struct(self.info)) |some| StructInfo{ .info = some } else null;
    }

    const ConstantIter = struct {
        object_info: ObjectInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?ConstantInfo = null,

        pub fn next(self: *ConstantIter) ?ConstantInfo {
            if (self.ret) |some| {
                some.asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = ConstantInfo{ .info = c.g_object_info_get_constant(self.object_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn constantIter(self: ObjectInfo) ConstantIter {
        return .{ .object_info = self, .capacity = @intCast(usize, c.g_object_info_get_n_constants(self.info)) };
    }

    const FieldIter = struct {
        object_info: ObjectInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?FieldInfo = null,

        pub fn next(self: *FieldIter) ?FieldInfo {
            if (self.ret) |some| {
                some.asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = FieldInfo{ .info = c.g_object_info_get_field(self.object_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn fieldIter(self: ObjectInfo) FieldIter {
        return .{ .object_info = self, .capacity = @intCast(usize, c.g_object_info_get_n_fields(self.info)) };
    }

    const InterfaceIter = struct {
        object_info: ObjectInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?InterfaceInfo = null,

        pub fn next(self: *InterfaceIter) ?InterfaceInfo {
            if (self.ret) |some| {
                some.asRegisteredType().asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = InterfaceInfo{ .info = c.g_object_info_get_interface(self.object_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn interfaceIter(self: ObjectInfo) InterfaceIter {
        return .{ .object_info = self, .capacity = @intCast(usize, c.g_object_info_get_n_interfaces(self.info)) };
    }

    const MethodIter = struct {
        object_info: ObjectInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?FunctionInfo = null,

        pub fn next(self: *MethodIter) ?FunctionInfo {
            if (self.ret) |some| {
                some.asCallable().asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = FunctionInfo{ .info = c.g_object_info_get_method(self.object_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn methodIter(self: ObjectInfo) MethodIter {
        return .{ .object_info = self, .capacity = @intCast(usize, c.g_object_info_get_n_methods(self.info)) };
    }

    const PropertyIter = struct {
        object_info: ObjectInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?PropertyInfo = null,

        pub fn next(self: *PropertyIter) ?PropertyInfo {
            if (self.ret) |some| {
                some.asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = PropertyInfo{ .info = c.g_object_info_get_property(self.object_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn propertyIter(self: ObjectInfo) PropertyIter {
        return .{ .object_info = self, .capacity = @intCast(usize, c.g_object_info_get_n_properties(self.info)) };
    }

    const SignalIter = struct {
        object_info: ObjectInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?SignalInfo = null,

        pub fn next(self: *SignalIter) ?SignalInfo {
            if (self.ret) |some| {
                some.asCallable().asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = SignalInfo{ .info = c.g_object_info_get_signal(self.object_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn signalIter(self: ObjectInfo) SignalIter {
        return .{ .object_info = self, .capacity = @intCast(usize, c.g_object_info_get_n_signals(self.info)) };
    }

    const VFuncIter = struct {
        object_info: ObjectInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?VFuncInfo = null,

        pub fn next(self: *VFuncIter) ?VFuncInfo {
            if (self.ret) |some| {
                some.asCallable().asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = VFuncInfo{ .info = c.g_object_info_get_vfunc(self.object_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn vfuncIter(self: ObjectInfo) VFuncIter {
        return .{ .object_info = self, .capacity = @intCast(usize, c.g_object_info_get_n_vfuncs(self.info)) };
    }

    pub fn format(self: ObjectInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        if (self.asRegisteredType().asBase().isDeprecated() and !enable_deprecated) return;
        const name = self.asRegisteredType().asBase().name().?;
        var iter = self.fieldIter();
        try writer.print("pub const {s} = {s} {{\n", .{ name, if (iter.capacity == 0) "opaque" else "extern struct" });
        while (iter.next()) |field| {
            try writer.print("{}", .{field});
        }
        var i_iter = self.interfaceIter();
        if (i_iter.capacity > 0) {
            var first = true;
            try writer.writeAll("pub const Interfaces = [_]type{");
            while (i_iter.next()) |interface| {
                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }
                try writer.print("{s}.{s}", .{ interface.asRegisteredType().asBase().namespace(), interface.asRegisteredType().asBase().name().? });
            }
            try writer.writeAll("};\n");
        }
        if (self.parent()) |_parent| {
            try writer.print("pub const Parent = {s}.{s};", .{ _parent.asRegisteredType().asBase().namespace(), _parent.asRegisteredType().asBase().name().? });
        }
        var c_iter = self.constantIter();
        while (c_iter.next()) |constant| {
            try writer.print("{}", .{constant});
        }
        var m_iter = self.methodIter();
        while (m_iter.next()) |method| {
            try writer.print("{}", .{method});
        }
        var v_iter = self.vfuncIter();
        while (v_iter.next()) |vfunc| {
            try writer.print("{}", .{vfunc});
        }
        var p_iter = self.propertyIter();
        while (p_iter.next()) |property| {
            try writer.print("{}", .{property});
        }
        var s_iter = self.signalIter();
        while (s_iter.next()) |signal| {
            try writer.print("{}", .{signal});
        }
        try writer.writeAll("pub usingnamespace core.Extend(@This());\n");
        try self.asRegisteredType().format_helper(writer);
        try writer.writeAll("};\n");
    }
};

pub const InterfaceInfo = struct {
    info: *c.GIInterfaceInfo,

    pub fn asRegisteredType(self: InterfaceInfo) RegisteredTypeInfo {
        return .{ .info = self.info };
    }

    pub fn ifaceStruct(self: InterfaceInfo) ?StructInfo {
        return if (c.g_interface_info_get_iface_struct(self.info)) |some| StructInfo{ .info = some } else null;
    }

    const PrerequisiteIter = struct {
        interface_info: InterfaceInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?BaseInfo = null,

        pub fn next(self: *PrerequisiteIter) ?BaseInfo {
            if (self.ret) |some| {
                some.deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = BaseInfo{ .info = c.g_interface_info_get_prerequisite(self.interface_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn prerequisiteIter(self: InterfaceInfo) PrerequisiteIter {
        return .{ .interface_info = self, .capacity = @intCast(usize, c.g_interface_info_get_n_prerequisites(self.info)) };
    }

    const PropertyIter = struct {
        interface_info: InterfaceInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?PropertyInfo = null,

        pub fn next(self: *PropertyIter) ?PropertyInfo {
            if (self.ret) |some| {
                some.asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = PropertyInfo{ .info = c.g_interface_info_get_property(self.interface_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn propertyIter(self: InterfaceInfo) PropertyIter {
        return .{ .interface_info = self, .capacity = @intCast(usize, c.g_interface_info_get_n_properties(self.info)) };
    }

    const MethodIter = struct {
        interface_info: InterfaceInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?FunctionInfo = null,

        pub fn next(self: *MethodIter) ?FunctionInfo {
            if (self.ret) |some| {
                some.asCallable().asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = FunctionInfo{ .info = c.g_interface_info_get_method(self.interface_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn methodIter(self: InterfaceInfo) MethodIter {
        return .{ .interface_info = self, .capacity = @intCast(usize, c.g_interface_info_get_n_methods(self.info)) };
    }

    const SignalIter = struct {
        interface_info: InterfaceInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?SignalInfo = null,

        pub fn next(self: *SignalIter) ?SignalInfo {
            if (self.ret) |some| {
                some.asCallable().asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = SignalInfo{ .info = c.g_interface_info_get_signal(self.interface_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn signalIter(self: InterfaceInfo) SignalIter {
        return .{ .interface_info = self, .capacity = @intCast(usize, c.g_interface_info_get_n_signals(self.info)) };
    }

    const VFuncIter = struct {
        interface_info: InterfaceInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?VFuncInfo = null,

        pub fn next(self: *VFuncIter) ?VFuncInfo {
            if (self.ret) |some| {
                some.asCallable().asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = VFuncInfo{ .info = c.g_interface_info_get_vfunc(self.interface_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn vfuncIter(self: InterfaceInfo) VFuncIter {
        return .{ .interface_info = self, .capacity = @intCast(usize, c.g_interface_info_get_n_vfuncs(self.info)) };
    }

    const ConstantIter = struct {
        interface_info: InterfaceInfo,
        index: usize = 0,
        capacity: usize,
        ret: ?ConstantInfo = null,

        pub fn next(self: *ConstantIter) ?ConstantInfo {
            if (self.ret) |some| {
                some.asBase().deinit();
                self.ret = null;
            }
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            self.ret = ConstantInfo{ .info = c.g_interface_info_get_constant(self.interface_info.info, @intCast(c_int, self.index)) };
            return self.ret;
        }
    };

    pub fn constantIter(self: InterfaceInfo) ConstantIter {
        return .{ .interface_info = self, .capacity = @intCast(usize, c.g_interface_info_get_n_constants(self.info)) };
    }

    pub fn format(self: InterfaceInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        if (self.asRegisteredType().asBase().isDeprecated() and !enable_deprecated) return;
        const name = self.asRegisteredType().asBase().name().?;
        try writer.print("pub const {s} = opaque {{\n", .{name});
        var pre_iter = self.prerequisiteIter();
        if (pre_iter.capacity > 0) {
            var first = true;
            try writer.writeAll("pub const Prerequisites = [_]type{");
            while (pre_iter.next()) |prerequisite| {
                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }
                try writer.print("{s}.{s}", .{ prerequisite.asRegisteredType().asBase().namespace(), prerequisite.asRegisteredType().asBase().name().? });
            }
            try writer.writeAll("};\n");
        }
        var c_iter = self.constantIter();
        while (c_iter.next()) |constant| {
            try writer.print("{}", .{constant});
        }
        var m_iter = self.methodIter();
        while (m_iter.next()) |method| {
            try writer.print("{}", .{method});
        }
        var v_iter = self.vfuncIter();
        while (v_iter.next()) |vfunc| {
            try writer.print("{}", .{vfunc});
        }
        var p_iter = self.propertyIter();
        while (p_iter.next()) |property| {
            try writer.print("{}", .{property});
        }
        var s_iter = self.signalIter();
        while (s_iter.next()) |signal| {
            try writer.print("{}", .{signal});
        }
        try writer.writeAll("pub usingnamespace core.Extend(@This());\n");
        try self.asRegisteredType().format_helper(writer);
        try writer.writeAll("};\n");
    }
};

pub const ArgInfo = struct {
    info: *c.GIArgInfo,

    pub fn asBase(self: ArgInfo) BaseInfo {
        return .{ .info = self.info };
    }

    pub fn closure(self: ArgInfo) ?usize {
        const index = c.g_arg_info_get_closure(self.info);
        return if (index != -1) @intCast(usize, index) else null;
    }

    pub fn destroy(self: ArgInfo) ?usize {
        const index = c.g_arg_info_get_destroy(self.info);
        return if (index != -1) @intCast(usize, index) else null;
    }

    pub fn direction(self: ArgInfo) Direction {
        return @intToEnum(Direction, c.g_arg_info_get_direction(self.info));
    }

    pub fn ownershipTransfer(self: ArgInfo) Transfer {
        return @intToEnum(Transfer, c.g_arg_info_get_ownership_transfer(self.info));
    }

    pub fn scope(self: ArgInfo) ScopeType {
        return @intToEnum(ScopeType, c.g_arg_info_get_scope(self.info));
    }

    pub fn @"type"(self: ArgInfo) TypeInfo {
        return .{ .info = c.g_arg_info_get_type(self.info) };
    }

    pub fn mayBeNull(self: ArgInfo) bool {
        return c.g_arg_info_may_be_null(self.info) != 0;
    }

    pub fn isCallerAllocates(self: ArgInfo) bool {
        return c.g_arg_info_is_caller_allocates(self.info) != 0;
    }

    pub fn isOptional(self: ArgInfo) bool {
        return c.g_arg_info_is_optional(self.info) != 0;
    }

    pub fn isReturnValue(self: ArgInfo) bool {
        return c.g_arg_info_is_return_value(self.info) != 0;
    }

    pub fn isSkip(self: ArgInfo) bool {
        return c.g_arg_info_is_skip(self.info) != 0;
    }

    pub fn format(self: ArgInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        var option_type_only = false;
        for (fmt) |ch| {
            if (ch == '$') {
                option_type_only = true;
            }
        }
        if (!option_type_only) {
            const name = self.asBase().name().?;
            try writer.print("arg_{s}: ", .{name});
        }
        const arg_type = self.type();
        defer arg_type.asBase().deinit();
        if (self.direction() != .In) {
            if (self.isOptional()) {
                if (self.mayBeNull()) {
                    try writer.print("{_&?*}", .{arg_type});
                } else {
                    try writer.print("{_&*}", .{arg_type});
                }
            } else {
                if (self.mayBeNull()) {
                    try writer.print("{&?*}", .{arg_type});
                } else {
                    try writer.print("{&*}", .{arg_type});
                }
            }
        } else {
            if (self.mayBeNull()) {
                try writer.print("{??}", .{arg_type});
            } else {
                try writer.print("{}", .{arg_type});
            }
        }
    }
};

pub const ConstantInfo = struct {
    info: *c.GIConstantInfo,

    pub fn asBase(self: ConstantInfo) BaseInfo {
        return .{ .info = self.info };
    }

    pub fn @"type"(self: ConstantInfo) TypeInfo {
        return .{ .info = c.g_constant_info_get_type(self.info) };
    }

    pub fn format(self: ConstantInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        if (self.asBase().isDeprecated() and !enable_deprecated) return;
        try writer.print("pub const {s} = ", .{self.asBase().name().?});
        var value: c.GIArgument = undefined;
        _ = c.g_constant_info_get_value(self.info, &value);
        defer c.g_constant_info_free_value(self.info, &value);
        const value_type = self.type();
        defer value_type.asBase().deinit();
        switch (value_type.tag()) {
            .Boolean => {
                try writer.print("{}", .{value.v_boolean == 0});
            },
            .Int8 => {
                try writer.print("{}", .{value.v_int8});
            },
            .UInt8 => {
                try writer.print("{}", .{value.v_uint8});
            },
            .Int16 => {
                try writer.print("{}", .{value.v_int16});
            },
            .UInt16 => {
                try writer.print("{}", .{value.v_uint16});
            },
            .Int32 => {
                try writer.print("{}", .{value.v_int32});
            },
            .UInt32 => {
                try writer.print("{}", .{value.v_uint32});
            },
            .Int64 => {
                try writer.print("{}", .{value.v_int64});
            },
            .UInt64 => {
                try writer.print("{}", .{value.v_uint64});
            },
            .Float => {
                try writer.print("{}", .{value.v_float});
            },
            .Double => {
                try writer.print("{}", .{value.v_double});
            },
            .Utf8 => {
                try writer.print("\"{s}\"", .{value.v_string});
            },
            .Interface => {
                const value_namespace = self.asBase().namespace();
                const value_name = self.asBase().name().?;
                if (std.mem.eql(u8, "HarfBuzz", value_namespace) and std.mem.eql(u8, "LANGUAGE_INVALID", value_name)) {
                    try writer.writeAll("null");
                } else {
                    try writer.writeAll("null");
                    std.log.warn("[Guess] {s}.{s} is set to null", .{ value_namespace, value_name });
                }
            },
            else => unreachable,
        }
        try writer.writeAll(";\n");
    }
};

pub const FieldInfo = struct {
    info: *c.GIFieldInfo,

    pub fn asBase(self: FieldInfo) BaseInfo {
        return .{ .info = self.info };
    }

    pub fn flags(self: FieldInfo) FieldInfoFlags {
        return @bitCast(FieldInfoFlags, c.g_field_info_get_flags(self.info));
    }

    pub fn offset(self: FieldInfo) usize {
        return @intCast(usize, c.g_field_info_get_offset(self.info));
    }

    pub fn size(self: FieldInfo) usize {
        return @intCast(usize, c.g_field_info_get_size(self.info));
    }

    pub fn @"type"(self: FieldInfo) TypeInfo {
        return .{ .info = c.g_field_info_get_type(self.info) };
    }

    pub fn format(self: FieldInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        const field_name = self.asBase().name().?;
        const field_type = self.type();
        defer field_type.asBase().deinit();
        if (isZigKeyword(field_name)) {
            try writer.print("@\"{s}\"", .{field_name});
        } else {
            try writer.print("{s}", .{field_name});
        }
        try writer.print(": {??},\n", .{field_type});
    }
};

pub const PropertyInfo = struct {
    info: *c.GIPropertyInfo,

    pub fn asBase(self: PropertyInfo) BaseInfo {
        return .{ .info = self.info };
    }

    pub fn flags(self: PropertyInfo) ParamFlags {
        return @bitCast(ParamFlags, c.g_property_info_get_flags(self.info));
    }

    pub fn ownershipTransfer(self: PropertyInfo) Transfer {
        return @bitCast(Transfer, c.g_property_info_get_ownership_transfer(self.info));
    }

    pub fn @"type"(self: PropertyInfo) TypeInfo {
        return .{ .info = c.g_property_info_get_type(self.info) };
    }

    pub fn getter(self: PropertyInfo) ?FunctionInfo {
        return if (c.g_property_info_get_getter(self.info)) |some| FunctionInfo{ .info = some } else null;
    }

    pub fn setter(self: PropertyInfo) ?FunctionInfo {
        return if (c.g_property_info_get_setter(self.info)) |some| FunctionInfo{ .info = some } else null;
    }

    /// helper function
    pub fn isBasicTypeProperty(self: PropertyInfo) bool {
        const property_type = self.type();
        defer property_type.asBase().deinit();
        switch (property_type.tag()) {
            .Interface => {
                const interface = property_type.interface().?;
                defer interface.deinit();
                switch (interface.type()) {
                    .Enum, .Flags => return true,
                    else => return false,
                }
            },
            else => return true,
        }
    }

    pub fn format(self: PropertyInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        var buf: [256]u8 = undefined;
        const raw_name = self.asBase().name().?;
        const name = snakeToCamel(raw_name, buf[0..]);
        const container_name = self.asBase().container().name().?;
        const property_type = self.type();
        defer property_type.asBase().deinit();
        const _flags = self.flags();
        if (_flags.readable) {
            if (self.getter()) |some| {
                defer some.asCallable().asBase().deinit();
            } else {
                try writer.print("pub fn get{c}{s}(self: *{s}) {s}{&} {{\n", .{ std.ascii.toUpper(name[0]), name[1..], container_name, if (self.isBasicTypeProperty()) "" else "*", property_type });
                try writer.print("var property_value = core.ValueZ({}).init();\n", .{property_type});
                try writer.writeAll("defer property_value.deinit();\n");
                try writer.print("self.__call(\"getProperty\", .{{ \"{s}\", &property_value.value }});\n", .{raw_name});
                try writer.writeAll("return property_value.get();\n");
                try writer.writeAll("}\n");
            }
        }
        if (_flags.writable and !_flags.construct_only) {
            if (self.setter()) |some| {
                defer some.asCallable().asBase().deinit();
            } else {
                try writer.print("pub fn set{c}{s}(self: *{s}, arg_value: {s}{}) void {{\n", .{ std.ascii.toUpper(name[0]), name[1..], container_name, if (self.isBasicTypeProperty()) "" else "*", property_type });
                try writer.print("var property_value = core.ValueZ({}).init();\n", .{property_type});
                try writer.writeAll("defer property_value.deinit();\n");
                try writer.writeAll("property_value.set(arg_value);\n");
                try writer.print("self.__call(\"setProperty\", .{{ \"{s}\", &property_value.value }});\n", .{raw_name});
                try writer.writeAll("}");
            }
            try writer.print("pub fn connect{c}{s}Notify(self: *{s}, handler: anytype, args: anytype, flags: core.ConnectFlagsZ) usize {{\n", .{ std.ascii.toUpper(name[0]), name[1..], container_name });
            try writer.print("return core.connect(self.into(core.Object), \"notify::{s}\", handler, args, flags, &[_]type{{ void, *{s}, *core.ParamSpec }});\n", .{ raw_name, container_name });
            try writer.writeAll("}\n");
            try writer.print("pub fn connect{c}{s}NotifySwap(self: *{s}, handler: anytype, args: anytype, flags: core.ConnectFlagsZ) usize {{\n", .{ std.ascii.toUpper(name[0]), name[1..], container_name });
            try writer.print("return core.connectSwap(self.into(core.Object), \"notify::{s}\", handler, args, flags, &[_]type{{ void }});\n", .{raw_name});
            try writer.writeAll("}\n");
        }
    }
};

pub const TypeInfo = struct {
    info: *c.GITypeInfo,

    pub fn asBase(self: TypeInfo) BaseInfo {
        return .{ .info = self.info };
    }

    pub fn isPointer(self: TypeInfo) bool {
        return c.g_type_info_is_pointer(self.info) != 0;
    }

    pub fn tag(self: TypeInfo) TypeTag {
        return @intToEnum(TypeTag, c.g_type_info_get_tag(self.info));
    }

    pub fn paramType(self: TypeInfo, n: usize) TypeInfo {
        return .{ .info = c.g_type_info_get_param_type(self.info, @intCast(c_int, n)) };
    }

    pub fn interface(self: TypeInfo) ?BaseInfo {
        return if (c.g_type_info_get_interface(self.info)) |some| BaseInfo{ .info = some } else null;
    }

    pub fn arrayLength(self: TypeInfo) ?usize {
        const index = c.g_type_info_get_array_length(self.info);
        return if (index != -1) @intCast(usize, index) else null;
    }

    pub fn arrayFixedSize(self: TypeInfo) ?usize {
        const size = c.g_type_info_get_array_fixed_size(self.info);
        return if (size != -1) @intCast(usize, size) else null;
    }

    pub fn isZeroTerminated(self: TypeInfo) bool {
        return c.g_type_info_is_zero_terminated(self.info) != 0;
    }

    pub fn arrayType(self: TypeInfo) ?ArrayType {
        const ty = c.g_type_info_get_array_type(self.info);
        return if (ty != -1) @intToEnum(ArrayType, ty) else null;
    }

    pub fn format(self: TypeInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        var option_mut = false;
        var option_nullable = false;
        var option_out = false;
        var option_optional = false;
        for (fmt) |ch| {
            if (ch == '&') {
                option_mut = true;
            }
            if (ch == '?') {
                option_nullable = true;
            }
            if (ch == '*') {
                option_out = true;
            }
            if (ch == '_') {
                option_optional = true;
            }
        }
        if (option_out) {
            if (option_optional) {
                try writer.writeAll("?");
            }
            try writer.writeAll("*");
        }

        switch (self.tag()) {
            .Void => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*anyopaque");
                } else {
                    try writer.writeAll("void");
                }
            },
            .Boolean => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("bool");
            },
            .Int8 => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("i8");
            },
            .UInt8 => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("u8");
            },
            .Int16 => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("i16");
            },
            .UInt16 => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("u16");
            },
            .Int32 => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("i32");
            },
            .UInt32 => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("u32");
            },
            .Int64 => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("i64");
            },
            .UInt64 => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("u64");
            },
            .Float => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("f32");
            },
            .Double => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("f64");
            },
            .GType => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("core.Type");
            },
            .Utf8, .Filename => {
                assert(self.isPointer());
                if (option_nullable) {
                    try writer.writeAll("?");
                }
                if (option_mut) {
                    try writer.writeAll("[*:0]u8");
                } else {
                    // string literals are const pointers to null-terminated arrays of u8
                    try writer.writeAll("[*:0]const u8");
                }
            },
            .Array => {
                switch (self.arrayType().?) {
                    .C => {
                        const child_type = self.paramType(0);
                        defer child_type.asBase().deinit();
                        if (self.arrayFixedSize()) |size| {
                            if (self.isPointer()) {
                                if (option_nullable) {
                                    try writer.writeAll("?");
                                }
                                try writer.writeAll("*");
                            }
                            try writer.print("[{}]{??}", .{ size, child_type });
                        } else if (self.isZeroTerminated()) {
                            assert(self.isPointer());
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            if (child_type.isPointer()) {
                                try writer.print("[*:null]{??}", .{child_type});
                            } else {
                                switch (child_type.tag()) {
                                    .Int8, .UInt8, .Int16, .UInt16, .Int32, .UInt32, .Int64, .UInt64, .Float, .Double, .Unichar => {
                                        try writer.print("[*:0]{}", .{child_type});
                                    },
                                    else => {
                                        try writer.print("[*:std.mem.zeroes({??})]{??}", .{child_type, child_type});
                                    }
                                }
                            }
                        } else {
                            assert(self.isPointer());
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            try writer.print("[*]{}", .{child_type});
                        }
                    },
                    .Array => {
                        if (self.isPointer()) {
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            try writer.writeAll("*");
                        }
                        try writer.writeAll("core.Array");
                    },
                    .PtrArray => {
                        if (self.isPointer()) {
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            try writer.writeAll("*");
                        }
                        try writer.writeAll("core.PtrArray");
                    },
                    .ByteArray => {
                        if (self.isPointer()) {
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            try writer.writeAll("*");
                        }
                        try writer.writeAll("core.ByteArray");
                    },
                }
            },
            .Interface => {
                const child_type = self.interface().?;
                defer child_type.deinit();
                switch (child_type.type()) {
                    .Callback => {
                        if (option_nullable) {
                            try writer.writeAll("?");
                        }
                        const callback_name = child_type.name().?;
                        if (std.ascii.isUpper(callback_name[0])) {
                            try writer.print("{s}.{s}", .{ child_type.namespace(), child_type.name().? });
                        } else {
                            try writer.print("{}", .{child_type.asCallable().asCallback()});
                        }
                    },
                    .Struct, .Boxed, .Enum, .Flags, .Union => {
                        if (self.isPointer()) {
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            try writer.writeAll("*");
                        }
                        try writer.print("{s}.{s}", .{ child_type.namespace(), child_type.name().? });
                    },
                    .Object, .Interface => {
                        if (self.isPointer()) {
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            try writer.writeAll("*");
                        }
                        try writer.print("{s}.{s}", .{ child_type.namespace(), child_type.name().? });
                    },
                    .Invalid, .Function, .Constant, .Invalid0, .Value, .Signal, .VFunc, .Property, .Field, .Arg, .Type => unreachable,
                    .Unresolved => {
                        try writer.print("{s}.{s}", .{ child_type.namespace(), child_type.name().? });
                        std.log.warn("[Unresolved] {s}.{s}", .{ child_type.namespace(), child_type.name().? });
                    },
                }
            },
            .GList => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("core.List");
            },
            .GSList => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("core.SList");
            },
            .GHash => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("core.HashTable");
            },
            .Error => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("core.Error");
            },
            .Unichar => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll("core.Unichar");
            },
        }
    }
};

pub const ValueInfo = struct {
    info: *c.GIValueInfo,

    pub fn asBase(self: ValueInfo) BaseInfo {
        return .{ .info = self.info };
    }

    pub fn value(self: ValueInfo) i64 {
        return c.g_value_info_get_value(self.info);
    }
};
