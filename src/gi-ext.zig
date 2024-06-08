const gi = @import("girepository.zig");
const BaseInfo = gi.BaseInfo;
const UnresolvedInfo = gi.UnresolvedInfo;
const ArgInfo = gi.ArgInfo;
const CallableInfo = gi.CallableInfo;
const CallbackInfo = gi.CallbackInfo;
const ConstantInfo = gi.ConstantInfo;
const EnumInfo = gi.EnumInfo;
const FlagsInfo = gi.FlagsInfo;
const FieldInfo = gi.FieldInfo;
const FunctionInfo = gi.FunctionInfo;
const InterfaceInfo = gi.InterfaceInfo;
const ObjectInfo = gi.ObjectInfo;
const PropertyInfo = gi.PropertyInfo;
const RegisteredTypeInfo = gi.RegisteredTypeInfo;
const SignalInfo = gi.SignalInfo;
const StructInfo = gi.StructInfo;
const TypeInfo = gi.TypeInfo;
const UnionInfo = gi.UnionInfo;
const ValueInfo = gi.ValueInfo;
const VFuncInfo = gi.VFuncInfo;

fn Iterator(comptime Context: type, comptime Item: type) type {
    const Int = @Type(@typeInfo(c_int));

    return struct {
        context: Context,
        index: Int = 0,
        capacity: Int,
        next_fn: *const fn (Context, Int) Item,

        const Self = @This();

        pub fn next(self: *Self) ?Item {
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            return self.next_fn(self.context, self.index);
        }
    };
}

// helper functions
const std = @import("std");
const assert = std.debug.assert;
const root = @import("root");
const Namespace = root.Namespace;
const Identifier = root.Identifier;

fn snakeToCamel(src: []const u8, buf: []u8) []u8 {
    var len: usize = 0;
    var upper = false;
    for (src) |ch| {
        if (ch == '_' or ch == '-') {
            upper = true;
        } else {
            if (upper) {
                buf[len] = std.ascii.toUpper(ch);
            } else {
                buf[len] = ch;
            }
            len += 1;
            upper = false;
        }
    }
    return buf[0..len];
}

fn camelToSnake(src: []const u8, buf: []u8) []u8 {
    var len: usize = 0;
    var idx: usize = 0;
    for (src) |ch| {
        if (idx != 0 and std.ascii.isUpper(ch)) {
            buf[len] = '_';
            len += 1;
        }
        buf[len] = ch;
        len += 1;
        idx += 1;
    }
    return buf[0..len];
}

// extensions
pub const ArgInfoExt = struct {
    pub fn format(self_immut: *const ArgInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *ArgInfo = @constCast(self_immut);
        var option_type_only = false;
        var option_signal_param = false;
        inline for (fmt) |ch| {
            switch (ch) {
                't' => option_type_only = true,
                'p' => option_signal_param = true,
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        if (!option_type_only) {
            const name = self.into(BaseInfo).getName().?;
            try writer.print("_{s}: ", .{name});
        }
        const arg_type = self.getType();
        if (option_signal_param) {
            if (arg_type.getInterface()) |child_type| {
                switch (child_type.getType()) {
                    .@"enum", .flags => option_signal_param = false,
                    else => {},
                }
            } else {
                option_signal_param = false;
            }
        }
        if (self.getDirection() != .in or option_signal_param) {
            if (self.isOptional()) {
                if (self.mayBeNull()) {
                    try writer.print("{mnop}", .{arg_type});
                } else {
                    try writer.print("{mop}", .{arg_type});
                }
            } else {
                if (self.mayBeNull()) {
                    try writer.print("{mnp}", .{arg_type});
                } else {
                    try writer.print("{mn}", .{arg_type});
                }
            }
        } else {
            if (self.mayBeNull()) {
                try writer.print("{n}", .{arg_type});
            } else {
                try writer.print("{}", .{arg_type});
            }
        }
    }
};

pub const CallableInfoExt = struct {
    pub fn argsAlloc(self: *CallableInfo, allocator: std.mem.Allocator) ![]*ArgInfo {
        const args = try allocator.alloc(*ArgInfo, @intCast(self.getNArgs()));
        for (args, 0..) |*arg, index| {
            arg.* = self.getArg(@intCast(index));
        }
        return args;
    }

    const ArgsIter = Iterator(*CallableInfo, *ArgInfo);
    pub fn argsIter(self: *CallableInfo) ArgsIter {
        return .{ .context = self, .capacity = self.getNArgs(), .next_fn = CallableInfo.getArg };
    }

    pub fn format(self_immut: *const CallableInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *CallableInfo = @constCast(self_immut);
        var type_annotation: enum { disable, enable, only } = .disable;
        var c_callconv = false;
        var vfunc = false;
        inline for (fmt) |ch| {
            switch (ch) {
                'e' => type_annotation = .enable,
                'o' => type_annotation = .only,
                'c' => c_callconv = true,
                'v' => vfunc = true,
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        var first = true;
        try writer.writeAll("(");
        if (self.isMethod()) {
            if (first) {
                first = false;
            } else {
                try writer.writeAll(", ");
            }
            const container = self.into(BaseInfo).getContainer().?;
            switch (type_annotation) {
                .disable => try writer.writeAll("self"),
                .enable => try writer.print("self: *{s}", .{container.getName().?}),
                .only => try writer.print("*{s}", .{container.getName().?}),
            }
        }
        if (vfunc) {
            if (type_annotation == .enable) {
                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }
                try writer.writeAll("_gtype: core.Type");
            }
        }
        var iter = self.argsIter();
        while (iter.next()) |arg| {
            if (first) {
                first = false;
            } else {
                try writer.writeAll(", ");
            }
            switch (type_annotation) {
                .disable => try writer.print("_{s}", .{arg.into(BaseInfo).getName().?}),
                .enable => try writer.print("{}", .{arg}),
                .only => try writer.print("{t}", .{arg}),
            }
        }
        if (self.canThrowGerror()) {
            if (first) {
                first = false;
            } else {
                try writer.writeAll(", ");
            }
            switch (type_annotation) {
                .disable => {
                    if (!vfunc) {
                        try writer.writeAll("&"); // method wrapper
                    }
                    try writer.writeAll("_error");
                },
                .enable => try writer.writeAll("_error: *?*core.Error"),
                .only => try writer.writeAll("*?*core.Error"),
            }
        }
        try writer.writeAll(") ");
        if (type_annotation != .disable) {
            if (c_callconv) {
                try writer.writeAll("callconv(.C) ");
            }
            if (self.skipReturn()) {
                try writer.writeAll("void");
            } else {
                const return_type = self.getReturnType();
                var ctor = false;
                if (self.into(BaseInfo).getType() == .function) {
                    if (self.tryInto(FunctionInfo).?.getFlags().is_constructor) {
                        ctor = true;
                    }
                }
                if (ctor) {
                    const container = self.into(BaseInfo).getContainer().?;
                    if (self.mayReturnNull()) {
                        try writer.writeAll("?");
                    }
                    try writer.print("*{s}", .{container.getName().?});
                } else {
                    if (self.mayReturnNull() or return_type.getTag() == .glist or return_type.getTag() == .gslist) {
                        try writer.print("{mn}", .{return_type});
                    } else {
                        try writer.print("{m}", .{return_type});
                    }
                }
            }
        }
    }
};

pub const CallbackInfoExt = struct {
    pub fn format(self_immut: *CallbackInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *CallbackInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }
        try writer.writeAll("*const fn ");
        try writer.print("{ec}", .{self.into(CallableInfo)});
    }
};

pub const ConstantInfoExt = struct {
    pub fn freeValue(self: *ConstantInfo, value: *gi.Argument) void {
        const cFn = @extern(*const fn (*BaseInfo, *gi.Argument) callconv(.C) void, .{ .name = "g_constant_info_free_value" });
        _ = cFn(self.into(BaseInfo), value);
    }

    pub fn getValue(self: *ConstantInfo, value: *gi.Argument) c_int {
        const cFn = @extern(*const fn (*BaseInfo, *gi.Argument) callconv(.C) c_int, .{ .name = "g_constant_info_get_value" });
        const ret = cFn(self.into(BaseInfo), value);
        return ret;
    }

    pub fn format(self_immut: *const ConstantInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *ConstantInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        try root.generateDocs(.{ .constant = self }, writer);
        try writer.print("pub const {s} = ", .{self.into(BaseInfo).getName().?});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("if (core.config.disable_deprecated) core.Deprecated else ");
        }
        var value: gi.Argument = undefined;
        _ = self.getValue(&value);
        defer self.freeValue(&value);
        const value_type = self.getType();
        switch (value_type.getTag()) {
            .boolean => try writer.print("{}", .{value.v_boolean}),
            .int8 => try writer.print("{}", .{value.v_int8}),
            .uint8 => try writer.print("{}", .{value.v_uint8}),
            .int16 => try writer.print("{}", .{value.v_int16}),
            .uint16 => try writer.print("{}", .{value.v_uint16}),
            .int32 => try writer.print("{}", .{value.v_int32}),
            .uint32 => try writer.print("{}", .{value.v_uint32}),
            .int64 => try writer.print("{}", .{value.v_int64}),
            .uint64 => try writer.print("{}", .{value.v_uint64}),
            .float => try writer.print("{}", .{value.v_float}),
            .double => try writer.print("{}", .{value.v_double}),
            .utf8 => try writer.print("\"{s}\"", .{value.v_string.?}),
            .interface => {
                const value_namespace = self.into(BaseInfo).getNamespace().?;
                const value_name = self.into(BaseInfo).getName().?;
                try writer.writeAll("null");
                std.log.warn("[Guess] {s}.{s} is set to null", .{ value_namespace, value_name });
            },
            else => unreachable,
        }
        try writer.writeAll(";\n");
    }
};

pub const EnumInfoExt = struct {
    const ValueIter = Iterator(*EnumInfo, *ValueInfo);
    pub fn valueIter(self: *EnumInfo) ValueIter {
        return .{ .context = self, .capacity = self.getNValues(), .next_fn = EnumInfo.getValue };
    }

    const MethodIter = Iterator(*EnumInfo, *FunctionInfo);
    pub fn methodIter(self: *EnumInfo) MethodIter {
        return .{ .context = self, .capacity = self.getNMethods(), .next_fn = EnumInfo.getMethod };
    }

    pub fn format(self_immut: *const EnumInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *EnumInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        try root.generateDocs(.{ .@"enum" = self }, writer);
        const name = self.into(BaseInfo).getName().?;
        try writer.print("pub const {s} = ", .{name});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("if (core.config.disable_deprecated) core.Deprecated else ");
        }
        try writer.writeAll("enum");
        switch (self.getStorageType()) {
            .int32 => try writer.writeAll("(i32)"),
            .uint32 => try writer.writeAll("(u32)"),
            else => unreachable,
        }
        try writer.writeAll("{\n");
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();
        var values = std.AutoHashMap(i64, void).init(allocator);
        defer values.deinit();
        var iter = self.valueIter();
        while (iter.next()) |value| {
            if (values.contains(value.getValue())) {
                continue;
            }
            values.put(value.getValue(), {}) catch @panic("Out of Memory");
            switch (self.getStorageType()) {
                .int32 => try writer.print("{}", .{value}),
                .uint32 => try writer.print("{u}", .{value}),
                else => unreachable,
            }
            try writer.writeAll(",\n");
        }
        iter = self.valueIter();
        while (iter.next()) |value| {
            if (values.remove(value.getValue())) continue;
            try writer.writeAll("pub const ");
            switch (self.getStorageType()) {
                .int32 => try writer.print("{e}", .{value}),
                .uint32 => try writer.print("{ue}", .{value}),
                else => unreachable,
            }
            try writer.writeAll(";\n");
        }
        var m_iter = self.methodIter();
        while (m_iter.next()) |method| {
            try writer.print("\n{}", .{method});
        }
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("};\n");
    }
};

pub const FlagsInfoExt = struct {
    pub fn format(self_immut: *const FlagsInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *FlagsInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        try root.generateDocs(.{ .flags = self }, writer);
        const name = self.into(BaseInfo).getName().?;
        try writer.print("pub const {s} = ", .{name});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("if (core.config.disable_deprecated) core.Deprecated else ");
        }
        try writer.writeAll("packed struct");
        switch (self.into(EnumInfo).getStorageType()) {
            .int32 => try writer.writeAll("(i32)"),
            .uint32 => try writer.writeAll("(u32)"),
            else => unreachable,
        }
        try writer.writeAll("{\n");
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();
        var values = std.AutoHashMap(usize, []const u8).init(allocator);
        defer {
            var value_iter = values.valueIterator();
            while (value_iter.next()) |val| {
                allocator.free(val.*);
            }
            values.deinit();
        }
        var iter = self.into(EnumInfo).valueIter();
        while (iter.next()) |value| {
            const _value = value.getValue();
            if (_value <= 0 or !std.math.isPowerOfTwo(_value)) {
                continue;
            }
            const idx = std.math.log2_int(u32, @intCast(_value));
            if (values.contains(idx)) {
                continue;
            }
            var buf: [256]u8 = undefined;
            const name_v = camelToSnake(std.mem.span(value.into(BaseInfo).getName().?), buf[0..]);
            const name_dup = allocator.dupe(u8, name_v) catch @panic("Out of Memory");
            values.put(idx, name_dup) catch @panic("Out of Memory");
        }
        var padding_bits: usize = 0;
        for (0..32) |idx| {
            if (values.get(idx)) |name_v| {
                if (padding_bits != 0) {
                    try writer.print("_{d}: u{d} = 0,\n", .{ idx - padding_bits, padding_bits });
                    padding_bits = 0;
                }
                try writer.print("{}: bool = false,\n", .{Identifier{ .str = name_v }});
            } else {
                padding_bits += 1;
            }
        }
        if (padding_bits != 0) {
            try writer.print("_: u{d} = 0,\n", .{padding_bits});
        }
        iter = self.into(EnumInfo).valueIter();
        while (iter.next()) |value| {
            try writer.writeAll("pub const ");
            switch (self.into(EnumInfo).getStorageType()) {
                .int32 => try writer.print("{b}", .{value}),
                .uint32 => try writer.print("{ub}", .{value}),
                else => unreachable,
            }
            try writer.writeAll(";\n");
        }
        var m_iter = self.into(EnumInfo).methodIter();
        while (m_iter.next()) |method| {
            try writer.print("\n{}", .{method});
        }
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("};\n");
    }
};

pub const FieldInfoExt = struct {
    pub fn format(self_immut: *const FieldInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *FieldInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        const field_name = self.into(BaseInfo).getName().?;
        const field_type = self.getType();
        const field_size = self.getSize();
        if (field_size != 0) {
            const field_container_bits: usize = switch (field_type.getTag()) {
                .int32, .uint32 => 32,
                else => unreachable,
            };
            if (BitField.remaining == null) {
                try BitField.begin(field_container_bits, self.getOffset(), writer);
            } else {
                try BitField.ensure(field_size, field_container_bits, self.getOffset(), writer);
            }
            BitField.emit(field_size);
        } else if (BitField.remaining != null) {
            try BitField.end(writer);
        }
        try writer.print("{}", .{Identifier{ .str = std.mem.span(field_name) }});
        if (field_size == 0) {
            try writer.print(": {n},\n", .{field_type});
        } else if (field_size == 1) {
            try writer.writeAll(": bool,\n");
        } else {
            switch (field_type.getTag()) {
                .int32 => try writer.print(": i{d},\n", .{field_size}),
                .uint32 => try writer.print(": u{d},\n", .{field_size}),
                else => unreachable,
            }
        }
    }
};

pub const FunctionInfoExt = struct {
    pub fn format(self_immut: *const FunctionInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *FunctionInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        const SliceInfo = struct {
            is_slice_ptr: bool = false,
            slice_len: usize = undefined,
            is_slice_len: bool = false,
            slice_ptr: usize = undefined,
        };
        const ClosureInfo = struct {
            scope: gi.ScopeType = .invalid,
            is_func: bool = false,
            closure_data: usize = undefined,
            is_data: bool = false,
            closure_func: usize = undefined,
            is_destroy: bool = false,
            closure_destroy: usize = undefined,
        };

        var buffer: [4096]u8 = undefined;
        var fixed_buffer_allocator = std.heap.FixedBufferAllocator.init(buffer[0..]);
        const allocator = fixed_buffer_allocator.allocator();
        var buf: [256]u8 = undefined;
        const func_name = snakeToCamel(std.mem.span(self.into(BaseInfo).getName().?), buf[0..]);
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("pub usingnamespace if (core.config.disable_deprecated) struct{\n");
            try writer.print("pub const {}", .{Identifier{ .str = func_name }});
            try writer.writeAll(" = core.Deprecated;\n");
            try writer.writeAll("} else struct{\n");
        }
        try root.generateDocs(.{ .function = self }, writer);
        try writer.print("pub fn {}", .{Identifier{ .str = func_name }});
        const return_type = self.into(CallableInfo).getReturnType();
        const args = self.into(CallableInfo).argsAlloc(allocator) catch @panic("Out of Memory");
        var slice_info = allocator.alloc(SliceInfo, args.len) catch @panic("Out of Memory");
        @memset(slice_info[0..], .{});
        var closure_info = allocator.alloc(ClosureInfo, args.len) catch @panic("Out of Memory");
        @memset(closure_info[0..], .{});
        var n_out_param: usize = 0;
        for (args, 0..) |arg, idx| {
            if (arg.getDirection() == .out and !arg.isCallerAllocates()) {
                n_out_param += 1;
            }
            const arg_type = arg.getType();
            if (arg_type.getArrayLength() != -1) {
                const pos: usize = @intCast(arg_type.getArrayLength());
                slice_info[idx].is_slice_ptr = true;
                slice_info[idx].slice_len = pos;
                if (!slice_info[pos].is_slice_len) {
                    slice_info[pos].is_slice_len = true;
                    slice_info[pos].slice_ptr = idx;
                }
            }
            const arg_name = std.mem.span(arg.into(BaseInfo).getName().?);
            if (arg.getScope() != .invalid and arg.getClosure() != -1 and !std.mem.eql(u8, "data", arg_name[arg_name.len - 4 .. arg_name.len])) {
                closure_info[idx].scope = arg.getScope();
                closure_info[idx].is_func = true;
                if (arg.getClosure() != -1) {
                    const pos: usize = @intCast(arg.getClosure());
                    closure_info[idx].closure_data = pos;
                    closure_info[pos].is_data = true;
                    closure_info[pos].closure_func = idx;
                }
                if (arg.getDestroy() != -1) {
                    const pos: usize = @intCast(arg.getDestroy());
                    closure_info[idx].closure_destroy = pos;
                    closure_info[pos].is_destroy = true;
                    closure_info[pos].closure_func = idx;
                }
            }
        }
        const return_bool = return_type.getTag() == .boolean;
        const throw_bool = return_bool and (n_out_param > 0);
        const throw_error = self.into(CallableInfo).canThrowGerror();
        const skip_return = self.into(CallableInfo).skipReturn();
        const real_skip_return = skip_return or throw_bool;
        const n_out = n_out_param + @intFromBool(!real_skip_return);
        {
            try writer.writeAll("(");
            var first = true;
            if (self.into(CallableInfo).isMethod()) {
                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }
                const container = self.into(BaseInfo).getContainer().?;
                try writer.print("self: *{s}", .{container.getName().?});
            }
            for (args, 0..) |arg, idx| {
                if (arg.getDirection() == .out and !arg.isCallerAllocates()) continue;
                if (slice_info[idx].is_slice_len) continue;
                if (closure_info[idx].is_data) continue;
                if (closure_info[idx].is_destroy) continue;
                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }
                if (slice_info[idx].is_slice_ptr) {
                    try writer.print("_{s}s: ", .{arg.into(BaseInfo).getName().?});
                    if (arg.isOptional()) {
                        try writer.writeAll("?");
                    }
                    try writer.print("[]{}", .{arg.getType().getParamType(0)});
                } else if (closure_info[idx].is_func) {
                    try writer.print("{s}: anytype, {s}_args: anytype", .{ arg.into(BaseInfo).getName().?, arg.into(BaseInfo).getName().? });
                } else {
                    try writer.print("{}", .{arg});
                }
            }
            try writer.writeAll(") ");
            if (throw_error) {
                try writer.writeAll("error{GError}!");
            } else if (throw_bool) {
                try writer.writeAll("error{BooleanError}!");
            }
            if (n_out > 1) {
                try writer.writeAll("struct {\n");
            }
            if (!real_skip_return) {
                if (n_out > 1) {
                    try writer.writeAll("ret: ");
                }
                var ctor = false;
                if (self.getFlags().is_constructor) {
                    ctor = true;
                }
                if (return_bool) {
                    try writer.writeAll("bool");
                } else if (ctor) {
                    const container = self.into(BaseInfo).getContainer().?;
                    if (self.into(CallableInfo).mayReturnNull()) {
                        try writer.writeAll("?");
                    }
                    try writer.print("*{s}", .{container.getName().?});
                } else {
                    if (self.into(CallableInfo).mayReturnNull() or return_type.getTag() == .glist or return_type.getTag() == .gslist) {
                        try writer.print("{mn}", .{return_type});
                    } else {
                        try writer.print("{m}", .{return_type});
                    }
                }
                if (n_out > 1) {
                    try writer.writeAll(",\n");
                }
            }
            if (n_out_param > 0) {
                for (args, 0..) |arg, idx| {
                    if (arg.getDirection() != .out or arg.isCallerAllocates()) continue;
                    if (slice_info[idx].is_slice_len) continue;
                    if (n_out > 1) {
                        try writer.print("{s}: ", .{arg.into(BaseInfo).getName().?});
                    }
                    if (slice_info[idx].is_slice_ptr) {
                        if (arg.isOptional()) {
                            try writer.writeAll("?");
                        }
                        try writer.print("[]{}", .{arg.getType().getParamType(0)});
                    } else {
                        if (arg.mayBeNull()) {
                            try writer.print("{mn}", .{arg.getType()});
                        } else {
                            try writer.print("{m}", .{arg.getType()});
                        }
                    }
                    if (n_out > 1) {
                        try writer.writeAll(",\n");
                    }
                }
            }
            if (n_out > 1) {
                try writer.writeAll("}");
            }
        }
        try writer.writeAll(" {\n");
        // prepare error
        if (throw_error) {
            try writer.writeAll("var _error: ?*core.Error = null;\n");
        }
        // prepare input/inout
        for (args, 0..) |arg, idx| {
            if (arg.getDirection() == .out and !arg.isCallerAllocates()) continue;
            const arg_name = arg.into(BaseInfo).getName().?;
            if (slice_info[idx].is_slice_len) {
                const arg_type = arg.getType();
                const ptr_arg = args[slice_info[idx].slice_ptr];
                if (ptr_arg.isOptional()) {
                    try writer.print("const _{s}: {} = if (_{s}s) |some| @intCast(some.len) else 0;\n", .{ arg_name, arg_type, ptr_arg.into(BaseInfo).getName().? });
                } else {
                    try writer.print("const _{s}: {} = @intCast(_{s}s.len);\n", .{ arg_name, arg_type, ptr_arg.into(BaseInfo).getName().? });
                }
            }
            if (slice_info[idx].is_slice_ptr) {
                if (arg.isOptional()) {
                    try writer.print("const _{s} = if (_{s}s) |some| some.ptr else null;\n", .{ arg_name, arg_name });
                } else {
                    try writer.print("const _{s} = _{s}s.ptr;\n", .{ arg_name, arg_name });
                }
            }
            if (closure_info[idx].is_func) {
                try writer.print("var closure_{s} = core.zig_closure({s}, {s}_args, &.{{", .{ arg_name, arg_name, arg_name });
                const arg_type = arg.getType();
                if (arg_type.getInterface()) |interface| {
                    if (interface.getType() == .callback) {
                        const cb_return_type = interface.tryInto(CallableInfo).?.getReturnType();
                        if (interface.tryInto(CallableInfo).?.mayReturnNull() or cb_return_type.getTag() == .glist or cb_return_type.getTag() == .gslist) {
                            try writer.print("{mn}", .{cb_return_type});
                        } else {
                            try writer.print("{m}", .{cb_return_type});
                        }
                        var callback_args = interface.tryInto(CallableInfo).?.argsAlloc(allocator) catch @panic("Out of Memory");
                        if (callback_args.len > 0) {
                            for (callback_args[0 .. callback_args.len - 1]) |cb_arg| {
                                try writer.writeAll(", ");
                                try writer.print("{t}", .{cb_arg});
                            }
                        } else {
                            std.log.warn("[Generic Callback] {s}", .{self.getSymbol()});
                        }
                        assert(!interface.tryInto(CallableInfo).?.canThrowGerror());
                    } else {
                        try writer.writeAll("void");
                        std.log.warn("[Generic Callback] {s}", .{self.getSymbol()});
                    }
                } else {
                    try writer.writeAll("void");
                    std.log.warn("[Generic Callback] {s}", .{self.getSymbol()});
                }
                try writer.writeAll("});\n");
                switch (closure_info[idx].scope) {
                    .call => {
                        try writer.print("defer closure_{s}.deinit();\n", .{arg_name});
                    },
                    .@"async" => {
                        try writer.print("closure_{s}.setOnce();\n", .{arg_name});
                    },
                    .notified, .forever => {
                        //
                    },
                    else => unreachable,
                }
                try writer.print("const _{s}: {t} = @ptrCast(closure_{s}.c_closure());\n", .{ arg_name, arg, arg_name });
            }
            if (closure_info[idx].is_data) {
                const func_arg = args[closure_info[idx].closure_func];
                try writer.print("const _{s}: {t} = @ptrCast(closure_{s}.c_data());\n", .{ arg_name, arg, func_arg.into(BaseInfo).getName().? });
            }
            if (closure_info[idx].is_destroy) {
                const func_arg = args[closure_info[idx].closure_func];
                try writer.print("const _{s}: {t} = @ptrCast(closure_{s}.c_destroy());\n", .{ arg_name, arg, func_arg.into(BaseInfo).getName().? });
            }
        }
        // prepare output
        for (args) |arg| {
            if (arg.getDirection() != .out or arg.isCallerAllocates()) continue;
            const arg_name = arg.into(BaseInfo).getName().?;
            const arg_type = arg.getType();
            if (arg.mayBeNull()) {
                try writer.print("var {s}_out: {mn} = undefined;\n", .{ arg_name, arg_type });
            } else {
                try writer.print("var {s}_out: {m} = undefined;\n", .{ arg_name, arg_type });
            }
            try writer.print("const _{s} = &{s}_out;\n", .{ arg_name, arg_name });
        }
        try writer.writeAll("const cFn = @extern(*const fn");
        try writer.print("{oc}", .{self.into(CallableInfo)});
        try writer.print(", .{{ .name = \"{s}\"}});\n", .{self.getSymbol()});
        try writer.writeAll("const ret = cFn");
        try writer.print("{}", .{self.into(CallableInfo)});
        try writer.writeAll(";\n");
        if (skip_return) {
            try writer.writeAll("_ = ret;\n");
        }
        if (throw_error) {
            if (throw_bool) {
                try writer.writeAll("_ = ret;\n");
            }
            try writer.writeAll("if (_error) |some| {\n");
            try writer.writeAll("    core.setError(some);\n");
            try writer.writeAll("    return error.GError;\n");
            try writer.writeAll("}\n");
        } else if (throw_bool) {
            try writer.writeAll("if (ret) return error.BooleanError;\n");
        }
        try writer.writeAll("return ");
        var first = true;
        if (n_out > 1) {
            try writer.writeAll(".{ ");
        }
        if (!real_skip_return) {
            first = false;
            if (n_out > 1) {
                try writer.writeAll(".ret = ");
            }
            try writer.writeAll("ret");
        }
        if (n_out_param > 0) {
            for (args, 0..) |arg, idx| {
                if (arg.getDirection() != .out or arg.isCallerAllocates()) continue;
                if (slice_info[idx].is_slice_len) continue;
                if (n_out > 1) {
                    if (first) {
                        first = false;
                    } else {
                        try writer.writeAll(", ");
                    }
                }
                const arg_name = arg.into(BaseInfo).getName().?;
                if (n_out > 1) {
                    try writer.print(".{s} = ", .{arg_name});
                }
                try writer.print("{s}_out", .{arg_name});
                if (slice_info[idx].is_slice_ptr) {
                    const len_arg = args[slice_info[idx].slice_len];
                    try writer.writeAll("[0..@intCast(");
                    if (len_arg.getDirection() == .out and !len_arg.isCallerAllocates()) {
                        try writer.print("{s}_out", .{len_arg.into(BaseInfo).getName().?});
                    } else {
                        try writer.print("_{s}", .{len_arg.into(BaseInfo).getName().?});
                    }
                    try writer.writeAll(")]");
                }
            }
        }
        if (n_out > 1) {
            try writer.writeAll(" }");
        }
        try writer.writeAll(";\n");
        try writer.writeAll("}\n");
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("};\n");
        }
    }
};

pub const InterfaceInfoExt = struct {
    const PrerequisiteIter = Iterator(*InterfaceInfo, *BaseInfo);
    pub fn prerequisiteIter(self: *InterfaceInfo) PrerequisiteIter {
        return .{ .context = self, .capacity = self.getNPrerequisites(), .next_fn = InterfaceInfo.getPrerequisite };
    }

    const PropertyIter = Iterator(*InterfaceInfo, *PropertyInfo);
    pub fn propertyIter(self: *InterfaceInfo) PropertyIter {
        return .{ .context = self, .capacity = self.getNProperties(), .next_fn = InterfaceInfo.getProperty };
    }

    const MethodIter = Iterator(*InterfaceInfo, *FunctionInfo);
    pub fn methodIter(self: *InterfaceInfo) MethodIter {
        return .{ .context = self, .capacity = self.getNMethods(), .next_fn = InterfaceInfo.getMethod };
    }

    const SignalIter = Iterator(*InterfaceInfo, *SignalInfo);
    pub fn signalIter(self: *InterfaceInfo) SignalIter {
        return .{ .context = self, .capacity = self.getNSignals(), .next_fn = InterfaceInfo.getSignal };
    }

    const VFuncIter = Iterator(*InterfaceInfo, *VFuncInfo);
    pub fn vfuncIter(self: *InterfaceInfo) VFuncIter {
        return .{ .context = self, .capacity = self.getNVfuncs(), .next_fn = InterfaceInfo.getVfunc };
    }

    const ConstantIter = Iterator(*InterfaceInfo, *ConstantInfo);
    pub fn constantIter(self: *InterfaceInfo) ConstantIter {
        return .{ .context = self, .capacity = self.getNConstants(), .next_fn = InterfaceInfo.getConstant };
    }

    pub fn format(self_immut: *const InterfaceInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *InterfaceInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        try root.generateDocs(.{ .interface = self }, writer);
        var p_iter = self.propertyIter();
        while (p_iter.next()) |property| {
            try writer.print("{}", .{property});
        }
        const name = self.into(BaseInfo).getName().?;
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.print("pub const {s} = if (core.config.disable_deprecated) core.Deprecated else opaque {{\n", .{name});
        } else {
            try writer.print("pub const {s} = opaque {{\n", .{name});
        }
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
                try writer.print("{}.{s}", .{ Namespace{ .str = std.mem.span(prerequisite.into(BaseInfo).getNamespace().?) }, prerequisite.into(BaseInfo).getName().? });
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
        var s_iter = self.signalIter();
        while (s_iter.next()) |signal| {
            try writer.print("{}", .{signal});
        }
        try writer.writeAll("pub usingnamespace core.Extend(@This());\n");
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("};\n");
    }
};

pub const ObjectInfoExt = struct {
    const ConstantIter = Iterator(*ObjectInfo, *ConstantInfo);
    pub fn constantIter(self: *ObjectInfo) ConstantIter {
        return .{ .context = self, .capacity = self.getNConstants(), .next_fn = ObjectInfo.getConstant };
    }

    const FieldIter = Iterator(*ObjectInfo, *FieldInfo);
    pub fn fieldIter(self: *ObjectInfo) FieldIter {
        return .{ .context = self, .capacity = self.getNFields(), .next_fn = ObjectInfo.getField };
    }

    const InterfaceIter = Iterator(*ObjectInfo, *InterfaceInfo);
    pub fn interfaceIter(self: *ObjectInfo) InterfaceIter {
        return .{ .context = self, .capacity = self.getNInterfaces(), .next_fn = ObjectInfo.getInterface };
    }

    const MethodIter = Iterator(*ObjectInfo, *FunctionInfo);
    pub fn methodIter(self: *ObjectInfo) MethodIter {
        return .{ .context = self, .capacity = self.getNMethods(), .next_fn = ObjectInfo.getMethod };
    }

    const PropertyIter = Iterator(*ObjectInfo, *PropertyInfo);
    pub fn propertyIter(self: *ObjectInfo) PropertyIter {
        return .{ .context = self, .capacity = self.getNProperties(), .next_fn = ObjectInfo.getProperty };
    }

    const SignalIter = Iterator(*ObjectInfo, *SignalInfo);
    pub fn signalIter(self: *ObjectInfo) SignalIter {
        return .{ .context = self, .capacity = self.getNSignals(), .next_fn = ObjectInfo.getSignal };
    }

    const VFuncIter = Iterator(*ObjectInfo, *VFuncInfo);
    pub fn vfuncIter(self: *ObjectInfo) VFuncIter {
        return .{ .context = self, .capacity = self.getNVfuncs(), .next_fn = ObjectInfo.getVfunc };
    }

    pub fn format(self_immut: *const ObjectInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *ObjectInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        try root.generateDocs(.{ .object = self }, writer);
        var p_iter = self.propertyIter();
        while (p_iter.next()) |property| {
            try writer.print("{}", .{property});
        }
        const name = self.into(BaseInfo).getName().?;
        var iter = self.fieldIter();
        try writer.print("pub const {s} = ", .{name});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("if (core.config.disable_deprecated) core.Deprecated else ");
        }
        try writer.print("{s} {{\n", .{if (iter.capacity == 0) "opaque" else "extern struct"});
        BitField.reset();
        while (iter.next()) |field| {
            try writer.print("{}", .{field});
        }
        if (BitField.remaining != null) {
            try BitField.end(writer);
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
                try writer.print("{}.{s}", .{ Namespace{ .str = std.mem.span(interface.into(BaseInfo).getNamespace().?) }, interface.into(BaseInfo).getName().? });
            }
            try writer.writeAll("};\n");
        }
        if (self.getParent()) |_parent| {
            try writer.print("pub const Parent = {}.{s};\n", .{ Namespace{ .str = std.mem.span(_parent.into(BaseInfo).getNamespace().?) }, _parent.into(BaseInfo).getName().? });
        }
        if (self.getClassStruct()) |_class| {
            try writer.print("pub const Class = {}.{s};\n", .{ Namespace{ .str = std.mem.span(_class.into(BaseInfo).getNamespace().?) }, _class.into(BaseInfo).getName().? });
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
        var s_iter = self.signalIter();
        while (s_iter.next()) |signal| {
            try writer.print("{}", .{signal});
        }
        try writer.writeAll("pub usingnamespace core.Extend(@This());\n");
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("};\n");
    }
};

pub const PropertyInfoExt = struct {
    pub fn format(self_immut: *const PropertyInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *PropertyInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        try root.generateDocs(.{ .property = self }, writer);
    }
};

pub const RegisteredTypeInfoExt = struct {
    pub fn format(self_immut: *const RegisteredTypeInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *RegisteredTypeInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        if (self.getGType() != .none) {
            try writer.writeAll("pub fn gType() core.Type {\n");
            const init_fn = std.mem.span(self.getTypeInit());
            if (std.mem.eql(u8, "intern", init_fn)) {
                if (@intFromEnum(self.getGType()) < 256 * 4) {
                    try writer.print("return @enumFromInt({});", .{@intFromEnum(self.getGType())});
                } else {
                    try writer.writeAll("@panic(\"Internal type\");");
                }
            } else {
                try writer.print("const cFn = @extern(*const fn () callconv(.C) core.Type, .{{ .name = \"{s}\" }});\n", .{init_fn});
                try writer.writeAll("return cFn();\n");
            }
            try writer.writeAll("}\n");
        }
    }
};

pub const SignalInfoExt = struct {
    pub fn format(self_immut: *const SignalInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *SignalInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        const container_name = self.into(BaseInfo).getContainer().?.getName().?;
        var buf: [256]u8 = undefined;
        const raw_name = std.mem.span(self.into(BaseInfo).getName().?);
        const name = snakeToCamel(raw_name, buf[0..]);
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("pub usingnamespace if (core.config.disable_deprecated) struct {\n");
            try writer.print("pub const connect{c}{s} = core.Deprecated;\n", .{ std.ascii.toUpper(name[0]), name[1..] });
            try writer.writeAll("} else struct {\n");
        }
        try root.generateDocs(.{ .signal = self }, writer);
        try writer.print("pub fn connect{c}{s}(self: *{s}, handler: anytype, args: anytype, comptime flags: gobject.ConnectFlags) usize {{\n", .{ std.ascii.toUpper(name[0]), name[1..], container_name });
        try writer.print("return self.connect(\"{s}\", handler, args, flags, &.{{", .{raw_name});
        const return_type = self.into(CallableInfo).getReturnType();
        var interface_returned = false;
        if (return_type.getInterface()) |child_type| {
            switch (child_type.getType()) {
                .@"enum", .flags => {},
                else => interface_returned = true,
            }
        }
        if (self.into(CallableInfo).mayReturnNull() or interface_returned) {
            try writer.print("{mn}", .{return_type});
        } else {
            try writer.print("{m}", .{return_type});
        }
        try writer.print(", *{s}", .{container_name});
        var iter = self.into(CallableInfo).argsIter();
        while (iter.next()) |arg| {
            try writer.print(", {tp}", .{arg});
        }
        try writer.writeAll("});\n");
        try writer.writeAll("}\n");
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("};\n");
        }
    }
};

pub const StructInfoExt = struct {
    const FieldIter = Iterator(*StructInfo, *FieldInfo);
    pub fn fieldIter(self: *StructInfo) FieldIter {
        return .{ .context = self, .capacity = self.getNFields(), .next_fn = StructInfo.getField };
    }

    const MethodIter = Iterator(*StructInfo, *FunctionInfo);
    pub fn methodIter(self: *StructInfo) MethodIter {
        return .{ .context = self, .capacity = self.getNMethods(), .next_fn = StructInfo.getMethod };
    }

    pub fn format(self_immut: *const StructInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *StructInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        try root.generateDocs(.{ .@"struct" = self }, writer);
        const name = std.mem.span(self.into(BaseInfo).getName().?);
        const namespace = std.mem.span(self.into(BaseInfo).getNamespace().?);
        try writer.print("pub const {s} = ", .{name});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("if (core.config.disable_deprecated) core.Deprecated else ");
        }
        try writer.print("{s}{{\n", .{if (self.getSize() == 0) "opaque" else "extern struct"});
        BitField.reset();
        var iter = self.fieldIter();
        while (iter.next()) |field| {
            // TODO: https://github.com/ziglang/zig/issues/12325
            if (std.mem.eql(u8, namespace, "GObject") and std.mem.eql(u8, name, "Closure") and std.mem.eql(u8, std.mem.span(field.into(BaseInfo).getName().?), "notifiers")) {
                try writer.writeAll("notifiers: ?*anyopaque,\n");
                continue;
            }
            try writer.print("{}", .{field});
        }
        if (BitField.remaining != null) {
            try BitField.end(writer);
        }
        var m_iter = self.methodIter();
        while (m_iter.next()) |method| {
            try writer.print("\n{}", .{method});
        }
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("};\n");
    }
};

pub const TypeInfoExt = struct {
    pub fn format(self_immut: *const TypeInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *TypeInfo = @constCast(self_immut);
        var option_mut = false;
        var option_nullable = false;
        var option_out = false;
        var option_optional = false;
        inline for (fmt) |ch| {
            switch (ch) {
                'm' => option_mut = true,
                'n' => option_nullable = true,
                'o' => option_out = true,
                'p' => option_optional = true,
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        if (option_out) {
            if (option_optional) {
                try writer.writeAll("?");
            }
            try writer.writeAll("*");
        }
        switch (self.getTag()) {
            .void => {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*anyopaque");
                } else {
                    try writer.writeAll("void");
                }
            },
            .boolean, .int8, .uint8, .int16, .uint16, .int32, .uint32, .int64, .uint64, .float, .double, .glist, .gslist, .ghash, .gtype, .@"error", .unichar => |t| {
                if (self.isPointer()) {
                    if (option_nullable) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("*");
                }
                try writer.writeAll(switch (t) {
                    .boolean => "bool",
                    .int8 => "i8",
                    .uint8 => "u8",
                    .int16 => "i16",
                    .uint16 => "u16",
                    .int32 => "i32",
                    .uint32 => "u32",
                    .int64 => "i64",
                    .uint64 => "u64",
                    .float => "f32",
                    .double => "f64",
                    .glist => "core.List",
                    .gslist => "core.SList",
                    .ghash => "core.HashTable",
                    .gtype => "core.Type",
                    .@"error" => "core.Error",
                    .unichar => "core.Unichar",
                    else => unreachable,
                });
            },
            .utf8, .filename => {
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
            .array => {
                switch (self.getArrayType()) {
                    .c => {
                        const child_type = self.getParamType(0);
                        const size = self.getArrayFixedSize();
                        if (size != -1) {
                            if (self.isPointer()) {
                                if (option_nullable) {
                                    try writer.writeAll("?");
                                }
                                try writer.writeAll("*");
                            }
                            try writer.print("[{}]{n}", .{ size, child_type });
                        } else if (self.isZeroTerminated()) {
                            assert(self.isPointer());
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            if (child_type.isPointer()) {
                                try writer.print("[*:null]{n}", .{child_type});
                            } else {
                                switch (child_type.getTag()) {
                                    .int8, .uint8, .int16, .uint16, .int32, .uint32, .int64, .uint64, .float, .double, .unichar => {
                                        try writer.print("[*:0]{}", .{child_type});
                                    },
                                    else => {
                                        try writer.print("[*:std.mem.zeroes({n})]{n}", .{ child_type, child_type });
                                    },
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
                    .array, .ptr_array, .byte_array => |t| {
                        if (self.isPointer()) {
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            try writer.writeAll("*");
                        }
                        try writer.writeAll(switch (t) {
                            .array => "core.Array",
                            .ptr_array => "core.PtrArray",
                            .byte_array => "core.ByteArray",
                            else => unreachable,
                        });
                    },
                }
            },
            .interface => {
                const child_type = self.getInterface().?;
                switch (child_type.getType()) {
                    .callback => {
                        if (option_nullable) {
                            try writer.writeAll("?");
                        }
                        const callback_name = child_type.getName().?;
                        if (std.ascii.isUpper(callback_name[0])) {
                            try writer.print("{}.{s}", .{ Namespace{ .str = std.mem.span(child_type.getNamespace().?) }, child_type.getName().? });
                        } else {
                            try writer.print("{}", .{child_type.tryInto(CallbackInfo).?});
                        }
                    },
                    .@"struct", .boxed, .@"enum", .flags, .@"union" => {
                        if (self.isPointer()) {
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            try writer.writeAll("*");
                        }
                        try writer.print("{}.{s}", .{ Namespace{ .str = std.mem.span(child_type.getNamespace().?) }, child_type.getName().? });
                    },
                    .object, .interface => {
                        if (self.isPointer()) {
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            try writer.writeAll("*");
                        }
                        try writer.print("{}.{s}", .{ Namespace{ .str = std.mem.span(child_type.getNamespace().?) }, child_type.getName().? });
                    },
                    .invalid, .function, .constant, .invalid_0, .value, .signal, .vfunc, .property, .field, .arg, .type => unreachable,
                    .unresolved => {
                        try writer.print("{}.{s}", .{ Namespace{ .str = std.mem.span(child_type.getNamespace().?) }, child_type.getName().? });
                        std.log.warn("[Unresolved] {s}.{s}", .{ child_type.getNamespace().?, child_type.getName().? });
                    },
                }
            },
        }
    }
};

pub const UnionInfoExt = struct {
    const FieldIter = Iterator(*UnionInfo, *FieldInfo);
    pub fn fieldIter(self: *UnionInfo) FieldIter {
        return .{ .context = self, .capacity = self.getNFields(), .next_fn = UnionInfo.getField };
    }

    const MethodIter = Iterator(*UnionInfo, *FunctionInfo);
    pub fn methodIter(self: *UnionInfo) MethodIter {
        return .{ .context = self, .capacity = self.getNMethods(), .next_fn = UnionInfo.getMethod };
    }

    pub fn format(self_immut: *const UnionInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *UnionInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        try root.generateDocs(.{ .@"union" = self }, writer);
        try writer.print("pub const {s} = ", .{self.into(BaseInfo).getName().?});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("if (core.config.disable_deprecated) core.Deprecated else ");
        }
        try writer.writeAll("extern union{\n");
        var iter = self.fieldIter();
        while (iter.next()) |field| {
            try writer.print("{}", .{field});
        }
        var m_iter = self.methodIter();
        while (m_iter.next()) |method| {
            try writer.print("{}", .{method});
        }
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("};\n");
    }
};

pub const ValueInfoExt = struct {
    pub fn format(self_immut: *const ValueInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *ValueInfo = @constCast(self_immut);
        comptime var convert_func: ?[]const u8 = null;
        comptime var Storage: type = i32;
        inline for (fmt) |ch| {
            switch (ch) {
                'u' => Storage = u32,
                'e' => convert_func = "enumFromInt",
                'b' => convert_func = "bitCast",
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        const value_name = self.into(BaseInfo).getName().?;
        try writer.print("{}", .{Identifier{ .str = std.mem.span(value_name) }});
        if (convert_func) |func| {
            try writer.print(": @This() = @{s}(", .{func});
        } else {
            try writer.writeAll(" = ");
        }
        try writer.print("{d}", .{@as(Storage, @intCast(self.getValue()))});
        if (convert_func) |_| {
            try writer.writeAll(")");
        }
    }
};

pub const VFuncInfoExt = struct {
    pub fn format(self_immut: *const VFuncInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *VFuncInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        var buf: [256]u8 = undefined;
        const raw_vfunc_name = std.mem.span(self.into(BaseInfo).getName().?);
        const vfunc_name = snakeToCamel(raw_vfunc_name, buf[0..]);
        const container = self.into(BaseInfo).getContainer().?;
        const class = switch (container.getType()) {
            .object => container.tryInto(ObjectInfo).?.getClassStruct().?,
            .interface => container.tryInto(InterfaceInfo).?.getIfaceStruct(),
            else => unreachable,
        };
        const class_name = class.into(BaseInfo).getName().?;
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("pub usingnamespace struct {} else struct {\n");
        }
        try root.generateDocs(.{ .vfunc = self }, writer);
        try writer.print("pub fn {s}V", .{vfunc_name});
        try writer.print("{ev}", .{self.into(CallableInfo)});
        try writer.writeAll(" {\n");
        try writer.print("const vFn = @as(*{s}, @ptrCast(gobject.typeClassPeek(_gtype))).{s}.?;", .{ class_name, raw_vfunc_name });
        try writer.writeAll("const ret = vFn");
        try writer.print("{v}", .{self.into(CallableInfo)});
        try writer.writeAll(";\n");
        if (self.into(CallableInfo).skipReturn()) {
            try writer.writeAll("_ = ret;\n");
        }
        if (self.into(CallableInfo).skipReturn()) {
            try writer.writeAll("return {};\n");
        } else {
            try writer.writeAll("return ret;\n");
        }
        try writer.writeAll("}\n");
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("};\n");
        }
    }
};

const BitField = struct {
    var remaining: ?isize = null;

    pub fn reset() void {
        BitField.remaining = null;
    }

    pub fn begin(bits: isize, offset: isize, writer: anytype) !void {
        assert(BitField.remaining == null);
        BitField.remaining = bits;
        try writer.print("_{d} : packed struct(u{d}) {{\n", .{ offset, bits });
    }

    pub fn end(writer: anytype) !void {
        assert(BitField.remaining != null);
        if (BitField.remaining.? != 0) {
            try writer.print("_: u{d},\n", .{BitField.remaining.?});
        }
        BitField.remaining = null;
        try writer.writeAll("},\n");
    }

    pub fn ensure(bits: isize, alloc: isize, offset: isize, writer: anytype) !void {
        assert(BitField.remaining != null);
        if (BitField.remaining.? < bits) {
            try BitField.end(writer);
            try BitField.begin(alloc, offset, writer);
        }
    }

    pub fn emit(bits: isize) void {
        assert(BitField.remaining != null);
        BitField.remaining.? -= bits;
    }
};
