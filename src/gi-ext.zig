const gi = @import("girepository-2.0.zig");
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
    const UInt = @Type(@typeInfo(c_uint));

    return struct {
        context: Context,
        index: UInt = 0,
        capacity: UInt,
        next_fn: *const fn (Context, UInt) Item,

        const Self = @This();

        pub fn next(self: *Self) ?Item {
            if (self.index >= self.capacity) return null;
            defer self.index += 1;
            return self.next_fn(self.context, self.index);
        }
    };
}

const std = @import("std");
const root = @import("root");
const String = @import("string.zig").String;

// extensions
pub const BaseInfoExt = struct {
    /// Legacy `GIInfoType`
    pub const InfoType = enum(u32) {
        invalid = 0,
        function = 1,
        callback = 2,
        @"struct" = 3,
        boxed = 4,
        @"enum" = 5,
        flags = 6,
        object = 7,
        interface = 8,
        constant = 9,
        invalid_0 = 10,
        @"union" = 11,
        value = 12,
        signal = 13,
        vfunc = 14,
        property = 15,
        field = 16,
        arg = 17,
        type = 18,
        unresolved = 19,
    };

    /// Legacy `g_base_info_get_type`
    pub fn getType(self: *BaseInfo) InfoType {
        if (self.tryInto(ArgInfo)) |_| return .arg;
        if (self.tryInto(CallbackInfo)) |_| return .callback;
        if (self.tryInto(FunctionInfo)) |_| return .function;
        if (self.tryInto(SignalInfo)) |_| return .signal;
        if (self.tryInto(VFuncInfo)) |_| return .vfunc;
        if (self.tryInto(ConstantInfo)) |_| return .constant;
        if (self.tryInto(FlagsInfo)) |_| return .flags;
        if (self.tryInto(EnumInfo)) |_| return .@"enum";
        if (self.tryInto(InterfaceInfo)) |_| return .interface;
        if (self.tryInto(ObjectInfo)) |_| return .object;
        if (self.tryInto(StructInfo)) |_| return .@"struct";
        if (self.tryInto(UnionInfo)) |_| return .@"union";
        if (self.tryInto(FieldInfo)) |_| return .field;
        if (self.tryInto(PropertyInfo)) |_| return .property;
        if (self.tryInto(TypeInfo)) |_| return .type;
        if (self.tryInto(UnresolvedInfo)) |_| return .unresolved;
        if (self.tryInto(ValueInfo)) |_| return .value;
        return .invalid;
    }

    pub fn name_string(self: *BaseInfo) String {
        return String.new_from("{s}", .{self.getName().?});
    }

    pub fn namespace_string(self: *BaseInfo) String {
        return String.new_from("{s}", .{self.getNamespace().?}).to_snake();
    }
};

pub const ArgInfoExt = struct {
    /// Print `arg_name: arg_type`
    ///
    /// Specifiers
    /// - t: only print `arg_name`
    /// - p: convert `arg_type` to pointer aggressively (patch for signal param)
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
        const arg_type = self.getTypeInfo();
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
        {
            const func = self.into(BaseInfo).getContainer().?;
            if (func.getType() == .function) {
                const func_symbol = std.mem.span(func.tryInto(FunctionInfo).?.getSymbol());
                const arg_name = std.mem.span(self.into(BaseInfo).getName().?);
                // PATCH: utf8 is char**
                if (std.mem.eql(u8, "g_variant_parse", func_symbol) and std.mem.eql(u8, "endptr", arg_name)) {
                    try writer.writeAll("?*[*:0]const u8");
                    return;
                }
                if (std.mem.eql(u8, "g_assertion_message_cmpstrv", func_symbol) and std.mem.eql(u8, "arg1", arg_name)) {
                    try writer.writeAll("*const [*:0]const u8");
                    return;
                }
                if (std.mem.eql(u8, "g_assertion_message_cmpstrv", func_symbol) and std.mem.eql(u8, "arg2", arg_name)) {
                    try writer.writeAll("*const [*:0]const u8");
                    return;
                }
                if (std.mem.eql(u8, "g_log_writer_default_set_debug_domains", func_symbol) and std.mem.eql(u8, "domains", arg_name)) {
                    try writer.writeAll("*const [*:0]const u8");
                    return;
                }
                // PATCH: out buf
                if (std.mem.eql(u8, "g_base64_decode_inplace", func_symbol) and std.mem.eql(u8, "text", arg_name)) {
                    try writer.writeAll("[*]u8");
                    return;
                }
                if (std.mem.eql(u8, "g_base64_encode_close", func_symbol) and std.mem.eql(u8, "out", arg_name)) {
                    try writer.writeAll("[*]u8");
                    return;
                }
                if (std.mem.eql(u8, "g_base64_encode_step", func_symbol) and std.mem.eql(u8, "out", arg_name)) {
                    try writer.writeAll("[*]u8");
                    return;
                }
                if (std.mem.eql(u8, "g_unichar_to_utf8", func_symbol) and std.mem.eql(u8, "outbuf", arg_name)) {
                    try writer.writeAll("[*]u8");
                    return;
                }
                // PATCH: g_list_store_splice
                if (std.mem.eql(u8, "g_list_store_splice", func_symbol) and std.mem.eql(u8, "additions", arg_name)) {
                    try writer.writeAll("[*]*gobject.Object");
                    return;
                }
                // PATCH: text list
                if (std.mem.eql(u8, "gdk_x11_display_text_property_to_text_list", func_symbol) and std.mem.eql(u8, "list", arg_name)) {
                    try writer.writeAll("*?[*:null]?[*:0]u8");
                    return;
                }
                if (std.mem.eql(u8, "gdk_x11_free_text_list", func_symbol) and std.mem.eql(u8, "list", arg_name)) {
                    try writer.writeAll("[*:null]?[*:0]u8");
                    return;
                }
            }
        }
        if ((self.getDirection() != .in and !(self.isCallerAllocates() and arg_type.getTag() == .array and arg_type.getArrayType() == .c)) or option_signal_param) {
            if (self.isOptional()) {
                if (self.mayBeNull()) {
                    try writer.print("{mnop}", .{arg_type});
                } else {
                    try writer.print("{mop}", .{arg_type});
                }
            } else {
                if (self.mayBeNull()) {
                    try writer.print("{mno}", .{arg_type});
                } else {
                    try writer.print("{mo}", .{arg_type});
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
    /// Collect all `ArgInfo`
    pub fn argsAlloc(self: *CallableInfo, allocator: std.mem.Allocator) ![]*ArgInfo {
        const args = try allocator.alloc(*ArgInfo, @intCast(self.getNArgs()));
        for (args, 0..) |*arg, index| {
            arg.* = self.getArg(@intCast(index));
        }
        return args;
    }

    const ArgsIter = Iterator(*CallableInfo, *ArgInfo);
    pub fn args_iter(self: *CallableInfo) ArgsIter {
        return .{ .context = self, .capacity = self.getNArgs(), .next_fn = CallableInfo.getArg };
    }

    /// Print `(arg_names...) return_type`
    ///
    /// Specifiers:
    /// - e: print `(arg_names...: arg_types...) return_type`
    /// - o: print `(arg_types...) return_type`
    /// - c: addtionally print `callconv(.c)`
    pub fn format(self_immut: *const CallableInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *CallableInfo = @constCast(self_immut);
        var type_annotation: enum { disable, enable, only } = .disable;
        var c_callconv = false;
        var emit_abi = false;
        inline for (fmt) |ch| {
            switch (ch) {
                'e' => type_annotation = .enable,
                'o' => type_annotation = .only,
                'c' => c_callconv = true,
                'b' => emit_abi = true,
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

        var iter = args_iter(self);
        while (iter.next()) |arg| {
            if (first) {
                first = false;
            } else {
                try writer.writeAll(", ");
            }
            switch (type_annotation) {
                .disable => {
                    const type_info = arg.getTypeInfo();
                    if (type_info.getTag() == .void and type_info.isPointer()) {
                        try writer.writeAll("@ptrCast(");
                    }
                    try writer.print("_{s}", .{arg.into(BaseInfo).getName().?});
                    if (type_info.getTag() == .void and type_info.isPointer()) {
                        try writer.writeAll(")");
                    }
                },
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
                .disable => try writer.writeAll("_error"),
                .enable => try writer.writeAll("_error: *?*core.Error"),
                .only => try writer.writeAll("*?*core.Error"),
            }
        }
        try writer.writeAll(") ");
        if (type_annotation != .disable) {
            if (c_callconv) {
                try writer.writeAll("callconv(.c) ");
            }
            if (self.skipReturn() and !emit_abi) {
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
    /// Print `*const fn(arg_names...: arg_types...) callconv(.c) return_type`
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
        const cFn = @extern(*const fn (*BaseInfo, *gi.Argument) callconv(.c) void, .{ .name = "gi_constant_info_free_value" });
        _ = cFn(self.into(BaseInfo), value);
    }

    pub fn getValue(self: *ConstantInfo, value: *gi.Argument) c_int {
        const cFn = @extern(*const fn (*BaseInfo, *gi.Argument) callconv(.c) c_int, .{ .name = "gi_constant_info_get_value" });
        const ret = cFn(self.into(BaseInfo), value);
        return ret;
    }

    /// Print `pub const name = value;`
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
            try writer.writeAll("core.deprecated(");
        }
        var value: gi.Argument = undefined;
        _ = self.getValue(&value);
        defer self.freeValue(&value);
        const value_type = self.getTypeInfo();
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
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll(")");
        }
        try writer.writeAll(";\n");
    }
};

pub const EnumInfoExt = struct {
    const ValueIter = Iterator(*EnumInfo, *ValueInfo);
    pub fn value_iter(self: *EnumInfo) ValueIter {
        return .{ .context = self, .capacity = self.getNValues(), .next_fn = EnumInfo.getValue };
    }

    const MethodIter = Iterator(*EnumInfo, *FunctionInfo);
    pub fn method_iter(self: *EnumInfo) MethodIter {
        return .{ .context = self, .capacity = self.getNMethods(), .next_fn = EnumInfo.getMethod };
    }

    /// Print `pub const name = enum(backing_int) {...}`
    pub fn format(self_immut: *const EnumInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *EnumInfo = @constCast(self_immut);
        var emit_abi = false;
        inline for (fmt) |ch| {
            switch (ch) {
                'b' => emit_abi = true,
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        try root.generateDocs(.{ .@"enum" = self }, writer);
        const name = self.into(BaseInfo).getName().?;
        try writer.print("pub const {s} = ", .{name});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("core.deprecated(");
        }
        try writer.writeAll("enum");
        switch (self.getStorageType()) {
            .int32 => try writer.writeAll("(i32)"),
            .uint32 => try writer.writeAll("(u32)"),
            else => unreachable,
        }
        try writer.writeAll("{\n");
        const allocator = std.heap.smp_allocator;
        var values = std.AutoHashMap(i64, void).init(allocator);
        defer values.deinit();
        var iter = value_iter(self);
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
        iter = value_iter(self);
        while (iter.next()) |value| {
            if (values.remove(value.getValue())) continue;
            // emit alias
            try writer.writeAll("pub const ");
            switch (self.getStorageType()) {
                .int32 => try writer.print("{e}", .{value}),
                .uint32 => try writer.print("{ue}", .{value}),
                else => unreachable,
            }
            try writer.writeAll(";\n");
        }
        if (emit_abi) {
            try writer.writeAll("}");
            if (self.into(BaseInfo).isDeprecated()) {
                try writer.writeAll(")");
            }
            try writer.writeAll(";\n");
            var m_iter = method_iter(self);
            while (m_iter.next()) |method| {
                try writer.print("{b}", .{method});
            }
            return;
        }
        var m_iter = method_iter(self);
        while (m_iter.next()) |method| {
            try writer.print("\n{}", .{method});
        }
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("}");
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll(")");
        }
        try writer.writeAll(";\n");
    }
};

pub const FlagsInfoExt = struct {
    /// Print `pub const name = packed struct(backing_int) {...}`
    pub fn format(self_immut: *const FlagsInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *FlagsInfo = @constCast(self_immut);
        var emit_abi = false;
        inline for (fmt) |ch| {
            switch (ch) {
                'b' => emit_abi = true,
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        try root.generateDocs(.{ .flags = self }, writer);
        const name = self.into(BaseInfo).getName().?;
        try writer.print("pub const {s} = ", .{name});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("core.deprecated(");
        }
        try writer.writeAll("packed struct");
        switch (self.into(EnumInfo).getStorageType()) {
            .int32 => try writer.writeAll("(i32)"),
            .uint32 => try writer.writeAll("(u32)"),
            else => unreachable,
        }
        try writer.writeAll("{\n");
        const allocator = std.heap.smp_allocator;
        var values = std.AutoHashMap(usize, []const u8).init(allocator);
        defer {
            var value_iter = values.valueIterator();
            while (value_iter.next()) |val| {
                allocator.free(val.*);
            }
            values.deinit();
        }
        var iter = EnumInfoExt.value_iter(self.into(EnumInfo));
        while (iter.next()) |value| {
            const _value = value.getValue();
            if (_value <= 0 or !std.math.isPowerOfTwo(_value)) {
                continue;
            }
            const idx = std.math.log2_int(u32, @intCast(_value));
            if (values.contains(idx)) {
                continue;
            }
            const name_v = value.into(BaseInfo).name_string().to_identifier();
            const name_dup = allocator.dupe(u8, name_v.slice()) catch @panic("Out of Memory");
            values.put(idx, name_dup) catch @panic("Out of Memory");
        }
        var padding_bits: usize = 0;
        for (0..32) |idx| {
            if (values.get(idx)) |name_v| {
                if (padding_bits != 0) {
                    try writer.print("_{d}: u{d} = 0,\n", .{ idx - padding_bits, padding_bits });
                    padding_bits = 0;
                }
                try writer.print("{s}: bool = false,\n", .{name_v});
            } else {
                padding_bits += 1;
            }
        }
        if (padding_bits != 0) {
            try writer.print("_: u{d} = 0,\n", .{padding_bits});
        }
        iter = EnumInfoExt.value_iter(self.into(EnumInfo));
        while (iter.next()) |value| {
            const _value = value.getValue();
            if (_value == 0 or (_value > 0 and std.math.isPowerOfTwo(_value))) {
                continue;
            }
            // emit multi-bit flags
            try writer.writeAll("pub const ");
            switch (self.into(EnumInfo).getStorageType()) {
                .int32 => try writer.print("{b}", .{value}),
                .uint32 => try writer.print("{ub}", .{value}),
                else => unreachable,
            }
            try writer.writeAll(";\n");
        }
        if (emit_abi) {
            try writer.writeAll("}");
            if (self.into(BaseInfo).isDeprecated()) {
                try writer.writeAll(")");
            }
            try writer.writeAll(";\n");
            var m_iter = EnumInfoExt.method_iter(self.into(EnumInfo));
            while (m_iter.next()) |method| {
                try writer.print("{b}", .{method});
            }
            return;
        }
        var m_iter = EnumInfoExt.method_iter(self.into(EnumInfo));
        while (m_iter.next()) |method| {
            try writer.print("\n{}", .{method});
        }
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("}");
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll(")");
        }
        try writer.writeAll(";\n");
    }
};

pub const FieldInfoExt = struct {
    /// Print `field_name: field_type,`
    pub fn format(self_immut: *const FieldInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *FieldInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        const field_name = self.into(BaseInfo).name_string().to_identifier();
        const field_type = self.getTypeInfo();
        const field_size = self.getSize();
        if (field_size != 0) {
            const field_container_bits: usize = switch (field_type.getTag()) {
                .int32, .uint32 => 32,
                else => unreachable,
            };
            try BitField._emit(writer, field_size, field_container_bits, self.getOffset());
        } else {
            try BitField._end(writer);
        }
        try writer.print("{s}", .{field_name});
        if (field_size == 0) {
            try writer.print(": {nw}", .{field_type});
            // PATCH: simd4f alignment
            if (field_type.getTag() == .interface) {
                const interface = field_type.getInterface().?;
                if (interface.getType() == .@"struct") {
                    const type_namespace = std.mem.span(interface.getNamespace().?);
                    const type_name = std.mem.span(interface.getName().?);
                    if (std.mem.eql(u8, type_namespace, "Graphene") and std.mem.eql(u8, type_name, "Simd4F")) {
                        try writer.writeAll(" align(16)");
                    }
                }
            }
            try writer.writeAll(",\n");
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
    /// Infomation to convert `[*]T, usize` to `[]T`
    const SliceInfo = struct {
        is_slice_ptr: bool = false,
        slice_len: usize = undefined,
        is_slice_len: bool = false,
        slice_ptr: usize = undefined,
    };

    /// Infomation to convert `void (*)(void), void*` to `handler, args`
    const ClosureInfo = struct {
        scope: gi.ScopeType = .invalid,
        is_func: bool = false,
        closure_data: usize = undefined,
        is_data: bool = false,
        closure_func: usize = undefined,
        is_destroy: bool = false,
        closure_destroy: usize = undefined,
    };

    /// Print `pub fn name(...) ...`
    pub fn format(self_immut: *const FunctionInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *FunctionInfo = @constCast(self_immut);
        var emit_abi = false;
        var global_namespace = false;
        inline for (fmt) |ch| {
            switch (ch) {
                'b' => emit_abi = true,
                'G' => global_namespace = true,
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        if (emit_abi) {
            if (self.into(BaseInfo).isDeprecated()) return;
            try writer.print(
                \\test "{s}{s}" {{
                \\    if (comptime @hasDecl(c, "{s}")) {{
                \\        try expect(comptime isAbiCompatitable(@TypeOf(c.{s}), fn{ocb}));
                \\    }} else {{
                \\        return error.SkipZigTest;
                \\    }}
                \\}}
                \\
            , .{
                if (global_namespace) "GLOBAL_" else "",
                self.getSymbol(),
                self.getSymbol(),
                self.getSymbol(),
                self.into(CallableInfo),
            });
            return;
        }

        // create a `FixedBufferAllocator` to alloc `ArgInfo`s on stack
        var buffer: [4096]u8 = undefined;
        var fixed_buffer_allocator = std.heap.FixedBufferAllocator.init(buffer[0..]);
        const allocator = fixed_buffer_allocator.allocator();
        // obtain infomation about parameters
        const args = CallableInfoExt.argsAlloc(self.into(CallableInfo), allocator) catch @panic("Out of Memory");
        // initialize slice info and closure info
        var slice_info = allocator.alloc(SliceInfo, args.len) catch @panic("Out of Memory");
        @memset(slice_info[0..], .{});
        var closure_info = allocator.alloc(ClosureInfo, args.len) catch @panic("Out of Memory");
        @memset(closure_info[0..], .{});

        // print function name
        var func_name = self.into(BaseInfo).name_string().to_camel();
        {
            // PATCH: duplicate name
            if (std.mem.eql(u8, "g_hook_destroy", std.mem.span(self.getSymbol()))) {
                func_name = String.new_from("{s}", .{"destroyID"});
            }
        }
        try root.generateDocs(.{ .function = self }, writer);
        try writer.print("pub fn {s}", .{func_name.to_identifier()});

        {
            // PATCH: out len
            const func_symbol = std.mem.span(self.getSymbol());
            if (std.mem.eql(u8, "g_base64_decode_inplace", func_symbol)) {
                try writer.writeAll(
                    \\(_texts: []u8) []u8 {
                    \\    const _text = _texts.ptr;
                    \\    var _out_len: u64 = @intCast(_texts.len);
                    \\    const cFn = @extern(*const fn ([*]u8, *u64) callconv(.c) [*]u8, .{ .name = "g_base64_decode_inplace" });
                    \\    const ret = cFn(_text, &_out_len);
                    \\    return ret[0.._out_len];
                    \\}
                    \\
                );
                return;
            }
            // PATCH: out buf
            if (std.mem.eql(u8, "g_base64_encode_close", func_symbol)) {
                try writer.writeAll(
                    \\(_break_lines: bool, _out: [*]u8, _state: *i32, _save: *i32) u64 {
                    \\    const cFn = @extern(*const fn (bool, [*]u8, *i32, *i32) callconv(.c) u64, .{ .name = "g_base64_encode_close" });
                    \\    const ret = cFn(_break_lines, _out, _state, _save);
                    \\    return ret;
                    \\}
                    \\
                );
                return;
            }
            if (std.mem.eql(u8, "g_base64_encode_step", func_symbol)) {
                try writer.writeAll(
                    \\(_ins: []u8, _break_lines: bool, _out: [*]u8, _state: *i32, _save: *i32) u64 {
                    \\    const _in = _ins.ptr;
                    \\    const _len: u64 = @intCast(_ins.len);
                    \\    const cFn = @extern(*const fn ([*]u8, u64, bool, [*]u8, *i32, *i32) callconv(.c) u64, .{ .name = "g_base64_encode_step" });
                    \\    const ret = cFn(_in, _len, _break_lines, _out, _state, _save);
                    \\    return ret;
                    \\}
                    \\
                );
                return;
            }
            // PATCH: g_list_store_splice
            if (std.mem.eql(u8, "g_list_store_splice", func_symbol)) {
                try writer.writeAll(
                    \\(self: *ListStore, _position: u32, _n_removals: u32, _additionss: []*gobject.Object) void {
                    \\    const _additions = _additionss.ptr;
                    \\    const _n_additions: u32 = @intCast(_additionss.len);
                    \\    const cFn = @extern(*const fn (*ListStore, u32, u32, [*]*gobject.Object, u32) callconv(.c) void, .{ .name = "g_list_store_splice" });
                    \\    const ret = cFn(self, _position, _n_removals, _additions, _n_additions);
                    \\    return ret;
                    \\}
                );
                return;
            }
        }

        // analyse parameters
        var n_out_param: usize = 0;
        for (args, 0..) |arg, idx| {
            // collect out parameter info
            if (arg.getDirection() == .out and !arg.isCallerAllocates()) {
                n_out_param += 1;
            }
            // collect slice info
            const arg_type = arg.getTypeInfo();
            if (arg_type.getArrayLengthIndex()) |pos| {
                slice_info[idx].is_slice_ptr = true;
                slice_info[idx].slice_len = pos;
                if (!slice_info[pos].is_slice_len) {
                    slice_info[pos].is_slice_len = true;
                    slice_info[pos].slice_ptr = idx;
                }
            }
            // collect closure info
            const arg_name = std.mem.span(arg.into(BaseInfo).getName().?);
            if (arg.getScope() != .invalid and arg.getClosureIndex() != null and !std.mem.eql(u8, "data", arg_name[arg_name.len - 4 .. arg_name.len])) {
                closure_info[idx].scope = arg.getScope();
                closure_info[idx].is_func = true;
                if (arg.getClosureIndex()) |pos| {
                    closure_info[idx].closure_data = pos;
                    closure_info[pos].is_data = true;
                    closure_info[pos].closure_func = idx;
                }
                if (arg.getDestroyIndex()) |pos| {
                    closure_info[idx].closure_destroy = pos;
                    closure_info[pos].is_destroy = true;
                    closure_info[pos].closure_func = idx;
                }
            }
        }

        // analyse return type
        const return_type = self.into(CallableInfo).getReturnType();
        const return_bool = return_type.getTag() == .boolean;
        // some function returns true if out parameters are valid
        const throw_bool = return_bool and (n_out_param > 0) and (self.into(CallableInfo).isMethod() and func_name.len >= 3 and std.mem.eql(u8, "get", func_name.slice()[0..3]));
        const throw_error = self.into(CallableInfo).canThrowGerror();
        const skip_return = self.into(CallableInfo).skipReturn();
        const real_skip_return = skip_return or throw_bool;
        const n_out = n_out_param + @intFromBool(!real_skip_return);

        {
            // parameters
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
                // skip out parameter
                if (arg.getDirection() == .out and !arg.isCallerAllocates()) continue;
                // skip slice len
                if (slice_info[idx].is_slice_len) continue;
                // skip closure data
                if (closure_info[idx].is_data) continue;
                // skip closure destroy
                if (closure_info[idx].is_destroy) continue;

                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }

                if (slice_info[idx].is_slice_ptr) {
                    // slice
                    try writer.print("_{s}s: ", .{arg.into(BaseInfo).getName().?});
                    if (arg.isOptional()) {
                        try writer.writeAll("?");
                    }
                    try writer.writeAll("[]");
                    if (arg.getTypeInfo().isZeroTerminated()) {
                        try writer.writeAll("?");
                    }
                    try writer.print("{}", .{arg.getTypeInfo().getParamType(0).?});
                } else if (closure_info[idx].is_func) {
                    // closure
                    try writer.print("{s}: anytype, {s}_args: anytype", .{ arg.into(BaseInfo).getName().?, arg.into(BaseInfo).getName().? });
                } else {
                    try writer.print("{}", .{arg});
                }
            }

            if (throw_error) {
                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }
                try writer.writeAll("_error: *?*core.Error");
            }

            try writer.writeAll(") ");

            // return type
            if (throw_error) {
                try writer.writeAll("error{GError}!");
            }
            if (throw_bool) {
                try writer.writeAll("?");
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
                        try writer.writeAll("[]");
                        if (arg.getTypeInfo().isZeroTerminated()) {
                            try writer.writeAll("?");
                        }
                        try writer.print("{}", .{arg.getTypeInfo().getParamType(0).?});
                    } else {
                        if (arg.mayBeNull()) {
                            try writer.print("{mn}", .{arg.getTypeInfo()});
                        } else {
                            try writer.print("{m}", .{arg.getTypeInfo()});
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

        // function body
        try writer.writeAll(" {\n");
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("core.deprecated({});\n");
        }
        // prepare input/inout
        for (args, 0..) |arg, idx| {
            if (arg.getDirection() == .out and !arg.isCallerAllocates()) continue;
            const arg_name = arg.into(BaseInfo).getName().?;
            if (slice_info[idx].is_slice_len) {
                const arg_type = arg.getTypeInfo();
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
                try writer.print("var closure_{s} = core.ZigClosure.newWithContract({s}, {s}_args, fn (", .{ arg_name, arg_name, arg_name });
                const arg_type = arg.getTypeInfo();
                if (arg_type.getInterface()) |interface| {
                    if (interface.getType() == .callback) {
                        var callback_args = CallableInfoExt.argsAlloc(interface.tryInto(CallableInfo).?, allocator) catch @panic("Out of Memory");
                        if (callback_args.len > 0) {
                            var first_cb_arg = true;
                            for (callback_args[0 .. callback_args.len - 1]) |cb_arg| {
                                if (!first_cb_arg) {
                                    try writer.writeAll(", ");
                                } else {
                                    first_cb_arg = false;
                                }
                                try writer.print("{t}", .{cb_arg});
                            }
                        } else {
                            std.log.warn("[Generic Callback] {s}", .{self.getSymbol()});
                        }
                        const cb_return_type = interface.tryInto(CallableInfo).?.getReturnType();
                        if (interface.tryInto(CallableInfo).?.mayReturnNull() or cb_return_type.getTag() == .glist or cb_return_type.getTag() == .gslist) {
                            try writer.print(") {mn}", .{cb_return_type});
                        } else {
                            try writer.print(") {m}", .{cb_return_type});
                        }
                        std.debug.assert(!interface.tryInto(CallableInfo).?.canThrowGerror());
                    } else {
                        try writer.writeAll(") void");
                        std.log.warn("[Generic Callback] {s}", .{self.getSymbol()});
                    }
                } else {
                    try writer.writeAll(") void");
                    std.log.warn("[Generic Callback] {s}", .{self.getSymbol()});
                }
                try writer.writeAll(");\n");
                switch (closure_info[idx].scope) {
                    .call => {
                        try writer.print("defer closure_{s}.deinit();\n", .{arg_name});
                    },
                    .@"async" => {
                        try writer.print("closure_{s}.once = true;\n", .{arg_name});
                    },
                    .notified, .forever => {
                        //
                    },
                    else => unreachable,
                }
                try writer.print("const _{s}: {t} = @ptrCast(closure_{s}.cCallback());\n", .{ arg_name, arg, arg_name });
            }
            if (closure_info[idx].is_data) {
                const func_arg = args[closure_info[idx].closure_func];
                try writer.print("const _{s}: {t} = @ptrCast(closure_{s}.cData());\n", .{ arg_name, arg, func_arg.into(BaseInfo).getName().? });
            }
            if (closure_info[idx].is_destroy) {
                const func_arg = args[closure_info[idx].closure_func];
                try writer.print("const _{s}: {t} = @ptrCast(closure_{s}.cDestroy());\n", .{ arg_name, arg, func_arg.into(BaseInfo).getName().? });
            }
        }
        // prepare output
        for (args) |arg| {
            if (arg.getDirection() != .out or arg.isCallerAllocates()) continue;
            const arg_name = arg.into(BaseInfo).getName().?;
            const arg_type = arg.getTypeInfo();
            if (arg.mayBeNull()) {
                try writer.print("var {s}_out: {mn} = undefined;\n", .{ arg_name, arg_type });
            } else {
                try writer.print("var {s}_out: {m} = undefined;\n", .{ arg_name, arg_type });
            }
            try writer.print("const _{s} = &{s}_out;\n", .{ arg_name, arg_name });
        }
        // call C function
        try writer.writeAll("const cFn = @extern(*const fn");
        try writer.print("{oc}", .{self.into(CallableInfo)});
        try writer.print(", .{{ .name = \"{s}\"}});\n", .{self.getSymbol()});
        try writer.writeAll("const ret = cFn");
        try writer.print("{}", .{self.into(CallableInfo)});
        try writer.writeAll(";\n");
        // return
        if (skip_return) {
            try writer.writeAll("_ = ret;\n");
        }
        if (throw_error) {
            try writer.writeAll("if (_error.* != null) return error.GError;\n");
        }
        if (throw_bool) {
            try writer.writeAll("if (!ret) return null;\n");
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
    }
};

pub const InterfaceInfoExt = struct {
    const PrerequisiteIter = Iterator(*InterfaceInfo, *BaseInfo);
    pub fn prerequisite_iter(self: *InterfaceInfo) PrerequisiteIter {
        return .{ .context = self, .capacity = self.getNPrerequisites(), .next_fn = InterfaceInfo.getPrerequisite };
    }

    const PropertyIter = Iterator(*InterfaceInfo, *PropertyInfo);
    pub fn property_iter(self: *InterfaceInfo) PropertyIter {
        return .{ .context = self, .capacity = self.getNProperties(), .next_fn = InterfaceInfo.getProperty };
    }

    const MethodIter = Iterator(*InterfaceInfo, *FunctionInfo);
    pub fn method_iter(self: *InterfaceInfo) MethodIter {
        return .{ .context = self, .capacity = self.getNMethods(), .next_fn = InterfaceInfo.getMethod };
    }

    const SignalIter = Iterator(*InterfaceInfo, *SignalInfo);
    pub fn signal_iter(self: *InterfaceInfo) SignalIter {
        return .{ .context = self, .capacity = self.getNSignals(), .next_fn = InterfaceInfo.getSignal };
    }

    const VFuncIter = Iterator(*InterfaceInfo, *VFuncInfo);
    pub fn vfunc_iter(self: *InterfaceInfo) VFuncIter {
        return .{ .context = self, .capacity = self.getNVfuncs(), .next_fn = InterfaceInfo.getVfunc };
    }

    const ConstantIter = Iterator(*InterfaceInfo, *ConstantInfo);
    pub fn constant_iter(self: *InterfaceInfo) ConstantIter {
        return .{ .context = self, .capacity = self.getNConstants(), .next_fn = InterfaceInfo.getConstant };
    }

    /// Print `pub const name = opaque {...}`
    pub fn format(self_immut: *const InterfaceInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *InterfaceInfo = @constCast(self_immut);
        var emit_abi = false;
        inline for (fmt) |ch| {
            switch (ch) {
                'b' => emit_abi = true,
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        try root.generateDocs(.{ .interface = self }, writer);
        var p_iter = property_iter(self);
        while (p_iter.next()) |property| {
            try writer.print("{}", .{property});
        }
        const name = self.into(BaseInfo).getName().?;
        try writer.print("pub const {s} = ", .{name});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("core.deprecated(");
        }
        try writer.writeAll("opaque {\n");
        var pre_iter = prerequisite_iter(self);
        if (pre_iter.capacity > 0) {
            var first = true;
            try writer.writeAll("pub const Prerequisites = [_]type{");
            while (pre_iter.next()) |prerequisite| {
                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }
                try writer.print("{s}.{s}", .{ prerequisite.into(BaseInfo).namespace_string(), prerequisite.into(BaseInfo).getName().? });
            }
            try writer.writeAll("};\n");
        }
        var c_iter = constant_iter(self);
        while (c_iter.next()) |constant| {
            try writer.print("{}", .{constant});
        }
        if (emit_abi) {
            try writer.writeAll("}");
            if (self.into(BaseInfo).isDeprecated()) {
                try writer.writeAll(")");
            }
            try writer.writeAll(";\n");
            var m_iter = method_iter(self);
            while (m_iter.next()) |method| {
                try writer.print("{b}\n", .{method});
            }
            return;
        }
        var m_iter = method_iter(self);
        while (m_iter.next()) |method| {
            try writer.print("{}", .{method});
        }
        var v_iter = vfunc_iter(self);
        while (v_iter.next()) |vfunc| {
            try writer.print("{}", .{vfunc});
        }
        var s_iter = signal_iter(self);
        while (s_iter.next()) |signal| {
            try writer.print("{}", .{signal});
        }
        try writer.writeAll(
            \\const Ext = core.Extend(@This());
            \\pub const __call = Ext.__call;
            \\pub const into = Ext.into;
            \\pub const tryInto = Ext.tryInto;
            \\
        );
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("}");
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll(")");
        }
        try writer.writeAll(";\n");
    }
};

pub const ObjectInfoExt = struct {
    const ConstantIter = Iterator(*ObjectInfo, *ConstantInfo);
    pub fn constant_iter(self: *ObjectInfo) ConstantIter {
        return .{ .context = self, .capacity = self.getNConstants(), .next_fn = ObjectInfo.getConstant };
    }

    const FieldIter = Iterator(*ObjectInfo, *FieldInfo);
    pub fn field_iter(self: *ObjectInfo) FieldIter {
        return .{ .context = self, .capacity = self.getNFields(), .next_fn = ObjectInfo.getField };
    }

    const InterfaceIter = Iterator(*ObjectInfo, *InterfaceInfo);
    pub fn interface_iter(self: *ObjectInfo) InterfaceIter {
        return .{ .context = self, .capacity = self.getNInterfaces(), .next_fn = ObjectInfo.getInterface };
    }

    const MethodIter = Iterator(*ObjectInfo, *FunctionInfo);
    pub fn method_iter(self: *ObjectInfo) MethodIter {
        return .{ .context = self, .capacity = self.getNMethods(), .next_fn = ObjectInfo.getMethod };
    }

    const PropertyIter = Iterator(*ObjectInfo, *PropertyInfo);
    pub fn property_iter(self: *ObjectInfo) PropertyIter {
        return .{ .context = self, .capacity = self.getNProperties(), .next_fn = ObjectInfo.getProperty };
    }

    const SignalIter = Iterator(*ObjectInfo, *SignalInfo);
    pub fn signal_iter(self: *ObjectInfo) SignalIter {
        return .{ .context = self, .capacity = self.getNSignals(), .next_fn = ObjectInfo.getSignal };
    }

    const VFuncIter = Iterator(*ObjectInfo, *VFuncInfo);
    pub fn vfunc_iter(self: *ObjectInfo) VFuncIter {
        return .{ .context = self, .capacity = self.getNVfuncs(), .next_fn = ObjectInfo.getVfunc };
    }

    /// Print `pub const name = extern struct {...}`
    pub fn format(self_immut: *const ObjectInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *ObjectInfo = @constCast(self_immut);
        var emit_abi = false;
        var has_gi_ext = false;
        inline for (fmt) |ch| {
            switch (ch) {
                'b' => emit_abi = true,
                'e' => has_gi_ext = true,
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        try root.generateDocs(.{ .object = self }, writer);
        var p_iter = property_iter(self);
        while (p_iter.next()) |property| {
            try writer.print("{}", .{property});
        }
        const name = self.into(BaseInfo).getName().?;
        var iter = field_iter(self);
        try writer.print("pub const {s} = ", .{name});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("core.deprecated(");
        }
        try writer.print("{s} {{\n", .{if (iter.capacity == 0) "opaque" else "extern struct"});
        while (iter.next()) |field| {
            try writer.print("{}", .{field});
        }
        try BitField._end(writer);
        var i_iter = interface_iter(self);
        if (i_iter.capacity > 0) {
            var first = true;
            try writer.writeAll("pub const Interfaces = [_]type{");
            while (i_iter.next()) |interface| {
                if (!self.into(BaseInfo).isDeprecated() and interface.into(BaseInfo).isDeprecated()) {
                    continue;
                }
                if (first) {
                    first = false;
                } else {
                    try writer.writeAll(", ");
                }
                try writer.print("{s}.{s}", .{ interface.into(BaseInfo).namespace_string(), interface.into(BaseInfo).getName().? });
            }
            try writer.writeAll("};\n");
        }
        if (self.getParent()) |_parent| {
            try writer.print("pub const Parent = {s}.{s};\n", .{ _parent.into(BaseInfo).namespace_string(), _parent.into(BaseInfo).getName().? });
        }
        if (self.getClassStruct()) |_class| {
            try writer.print("pub const Class = {s}.{s};\n", .{ _class.into(BaseInfo).namespace_string(), _class.into(BaseInfo).getName().? });
        }
        var c_iter = constant_iter(self);
        while (c_iter.next()) |constant| {
            try writer.print("{}", .{constant});
        }
        if (emit_abi) {
            try writer.writeAll("}");
            if (self.into(BaseInfo).isDeprecated()) {
                try writer.writeAll(")");
            }
            try writer.writeAll(";\n");
            var m_iter = method_iter(self);
            while (m_iter.next()) |method| {
                try writer.print("{b}", .{method});
            }
            return;
        }
        var m_iter = method_iter(self);
        while (m_iter.next()) |method| {
            try writer.print("{}", .{method});
        }
        var v_iter = vfunc_iter(self);
        while (v_iter.next()) |vfunc| {
            try writer.print("{}", .{vfunc});
        }
        var s_iter = signal_iter(self);
        while (s_iter.next()) |signal| {
            try writer.print("{}", .{signal});
        }
        try writer.writeAll(
            \\const Ext = core.Extend(@This());
            \\pub const __call = Ext.__call;
            \\pub const into = Ext.into;
            \\pub const tryInto = Ext.tryInto;
            \\pub const property = Ext.property;
            \\pub const signalConnect = Ext.signalConnect;
            \\
        );
        if (has_gi_ext) {
            try writer.print(
                \\const ManualExt = ext.{s}Ext;
                \\pub const format = ManualExt.format;
                \\
            , .{name});
            if (std.mem.eql(u8, "BaseInfo", std.mem.span(name))) {
                try writer.writeAll(
                    \\pub const getType = ManualExt.getType;
                    \\
                );
            }
            if (std.mem.eql(u8, "ConstantInfo", std.mem.span(name))) {
                try writer.writeAll(
                    \\pub const getValue = ManualExt.getValue;
                    \\pub const freeValue = ManualExt.freeValue;
                    \\
                );
            }
        }
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("}");
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll(")");
        }
        try writer.writeAll(";\n");
    }
};

pub const PropertyInfoExt = struct {
    /// Print nothing (except docs)
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
    /// Print `pub fn gType() core.Type {...}`
    pub fn format(self_immut: *const RegisteredTypeInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *RegisteredTypeInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        if (self.getTypeInitFunctionName()) |init_fn| {
            try writer.writeAll("pub fn gType() core.Type {\n");
            if (std.mem.eql(u8, "intern", std.mem.span(init_fn))) {
                if (@intFromEnum(self.getGType()) < 256 * 4) {
                    try writer.print("return @enumFromInt({});", .{@intFromEnum(self.getGType())});
                } else {
                    const g_param_spec_types = std.StaticStringMap(usize).initComptime(.{
                        .{ "GParamChar", 0 },
                        .{ "GParamUChar", 1 },
                        .{ "GParamBoolean", 2 },
                        .{ "GParamInt", 3 },
                        .{ "GParamUInt", 4 },
                        .{ "GParamLong", 5 },
                        .{ "GParamULong", 6 },
                        .{ "GParamInt64", 7 },
                        .{ "GParamUInt64", 8 },
                        .{ "GParamUnichar", 9 },
                        .{ "GParamEnum", 10 },
                        .{ "GParamFlags", 11 },
                        .{ "GParamFloat", 12 },
                        .{ "GParamDouble", 13 },
                        .{ "GParamString", 14 },
                        .{ "GParamParam", 15 },
                        .{ "GParamBoxed", 16 },
                        .{ "GParamPointer", 17 },
                        .{ "GParamValueArray", 18 },
                        .{ "GParamObject", 19 },
                        .{ "GParamOverride", 20 },
                        .{ "GParamGType", 21 },
                        .{ "GParamVariant", 22 },
                    });
                    const typename = self.getTypeName().?;
                    if (g_param_spec_types.get(std.mem.span(typename))) |idx| {
                        try writer.writeAll("const g_param_spec_types = @extern([*]core.Type, .{.name = \"g_param_spec_types\"});\n");
                        try writer.print("return g_param_spec_types[{}];\n", .{idx});
                    } else {
                        std.log.info("{s}: {}", .{ self.getTypeName().?, self.getGType() });
                        try writer.writeAll("@panic(\"intern\");");
                    }
                }
            } else {
                try writer.print("const cFn = @extern(*const fn () callconv(.c) core.Type, .{{ .name = \"{s}\" }});\n", .{init_fn});
                try writer.writeAll("return cFn();\n");
            }
            try writer.writeAll("}\n");
        }
    }
};

pub const SignalInfoExt = struct {
    /// Print `pub fn connectSignal(self, handler, args, flags) usize {...}`
    pub fn format(self_immut: *const SignalInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *SignalInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        const container_name = self.into(BaseInfo).getContainer().?.getName().?;
        const raw_name = self.into(BaseInfo).name_string();
        const name = raw_name.to_camel();
        try root.generateDocs(.{ .signal = self }, writer);
        try writer.print("pub fn connect{c}{s}(self: *{s}, callback_func: anytype, user_data: anytype, flags: gobject.ConnectFlags) usize {{\n", .{ std.ascii.toUpper(name.slice()[0]), name.slice()[1..], container_name });
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("core.deprecated({});\n");
        }
        try writer.print("return self.signalConnect(\"{s}\", callback_func, user_data, flags, fn (", .{raw_name});
        try writer.print("*{s}", .{container_name});
        var iter = CallableInfoExt.args_iter(self.into(CallableInfo));
        while (iter.next()) |arg| {
            try writer.print(", {tp}", .{arg});
        }
        try writer.writeAll(") ");
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
        try writer.writeAll(");\n");
        try writer.writeAll("}\n");
    }
};

pub const StructInfoExt = struct {
    const FieldIter = Iterator(*StructInfo, *FieldInfo);
    pub fn field_iter(self: *StructInfo) FieldIter {
        return .{ .context = self, .capacity = self.getNFields(), .next_fn = StructInfo.getField };
    }

    const MethodIter = Iterator(*StructInfo, *FunctionInfo);
    pub fn method_iter(self: *StructInfo) MethodIter {
        return .{ .context = self, .capacity = self.getNMethods(), .next_fn = StructInfo.getMethod };
    }

    /// Print `pub const name = extern struct {...}`
    pub fn format(self_immut: *const StructInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *StructInfo = @constCast(self_immut);
        var emit_abi = false;
        inline for (fmt) |ch| {
            switch (ch) {
                'b' => emit_abi = true,
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        try root.generateDocs(.{ .@"struct" = self }, writer);
        const name = std.mem.span(self.into(BaseInfo).getName().?);
        try writer.print("pub const {s} = ", .{name});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("core.deprecated(");
        }
        try writer.print("{s}{{\n", .{if (self.getSize() == 0) "opaque" else "extern struct"});
        var iter = field_iter(self);
        while (iter.next()) |field| {
            try writer.print("{}", .{field});
        }
        try BitField._end(writer);
        if (emit_abi) {
            try writer.writeAll("}");
            if (self.into(BaseInfo).isDeprecated()) {
                try writer.writeAll(")");
            }
            try writer.writeAll(";\n");
            var m_iter = method_iter(self);
            while (m_iter.next()) |method| {
                try writer.print("{b}", .{method});
            }
            return;
        }
        var m_iter = method_iter(self);
        while (m_iter.next()) |method| {
            try writer.print("{}", .{method});
        }
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("}");
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll(")");
        }
        try writer.writeAll(";\n");
    }
};

pub const TypeInfoExt = struct {
    /// Print type
    ///
    /// Specifiers:
    /// - m: muttable
    /// - n: nullable
    /// - o: out
    /// - p: optional
    /// - w: expand callback to workaround zig compiler bug
    pub fn format(self_immut: *const TypeInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *TypeInfo = @constCast(self_immut);
        var option_mut = false;
        var option_nullable = false;
        var option_out = false;
        var option_optional = false;
        var option_expand_callback = false;
        inline for (fmt) |ch| {
            switch (ch) {
                'm' => option_mut = true,
                'n' => option_nullable = true,
                'o' => option_out = true,
                'p' => option_optional = true,
                'w' => option_expand_callback = true,
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
                    if (!option_out) {
                        if (option_nullable) {
                            try writer.writeAll("?");
                        }
                        try writer.writeAll("*anyopaque");
                    } else {
                        try writer.writeAll("anyopaque");
                    }
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
                std.debug.assert(self.isPointer());
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
                        const child_type = self.getParamType(0).?;
                        if (self.getArrayFixedSize()) |size| {
                            if (self.isPointer()) {
                                if (option_nullable) {
                                    try writer.writeAll("?");
                                }
                                try writer.writeAll("*");
                            }
                            try writer.print("[{}]{n}", .{ size, child_type });
                        } else if (self.isZeroTerminated()) {
                            std.debug.assert(self.isPointer());
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
                                    .interface => {
                                        const interface = child_type.getInterface().?;
                                        if (interface.getType() == .@"struct" and interface.tryInto(StructInfo).?.getSize() == 0) {
                                            try writer.print("[*:null]?*{n}", .{child_type});
                                        } else {
                                            // https://github.com/ziglang/zig/pull/21509
                                            try writer.print("[*]{n}", .{child_type});
                                        }
                                    },
                                    else => {
                                        // https://github.com/ziglang/zig/pull/21509
                                        try writer.print("[*]{n}", .{child_type});
                                    },
                                }
                            }
                        } else {
                            std.debug.assert(self.isPointer());
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            try writer.print("[*]{}", .{child_type});
                        }
                    },
                    .array, .ptr_array, .byte_array => |t| {
                        if (!option_out) {
                            if (self.isPointer()) {
                                if (option_nullable) {
                                    try writer.writeAll("?");
                                }
                                try writer.writeAll("*");
                            }
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
                            // TODO: https://github.com/ziglang/zig/issues/12325
                            if (option_expand_callback) {
                                try writer.print("{}", .{child_type.tryInto(CallbackInfo).?});
                            } else {
                                try writer.print("{s}.{s}", .{ child_type.namespace_string(), child_type.getName().? });
                            }
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
                        try writer.print("{s}.{s}", .{ child_type.namespace_string(), child_type.getName().? });
                    },
                    .object, .interface => {
                        if (self.isPointer()) {
                            if (option_nullable) {
                                try writer.writeAll("?");
                            }
                            try writer.writeAll("*");
                        }
                        try writer.print("{s}.{s}", .{ child_type.namespace_string(), child_type.getName().? });
                    },
                    .invalid, .function, .constant, .invalid_0, .value, .signal, .vfunc, .property, .field, .arg, .type => unreachable,
                    .unresolved => {
                        // try writer.print("{s}.{s}", .{ child_type.namespace_string(), child_type.getName().? });
                        try writer.writeAll("*anyopaque");
                        std.log.warn("[Unresolved] {s}.{s}", .{ child_type.getNamespace().?, child_type.getName().? });
                    },
                }
            },
        }
    }
};

pub const UnionInfoExt = struct {
    const FieldIter = Iterator(*UnionInfo, *FieldInfo);
    pub fn field_iter(self: *UnionInfo) FieldIter {
        return .{ .context = self, .capacity = self.getNFields(), .next_fn = UnionInfo.getField };
    }

    const MethodIter = Iterator(*UnionInfo, *FunctionInfo);
    pub fn method_iter(self: *UnionInfo) MethodIter {
        return .{ .context = self, .capacity = self.getNMethods(), .next_fn = UnionInfo.getMethod };
    }

    /// Print `pub const name = extern union {...}`
    pub fn format(self_immut: *const UnionInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *UnionInfo = @constCast(self_immut);
        var emit_abi = false;
        inline for (fmt) |ch| {
            switch (ch) {
                'b' => emit_abi = true,
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        try root.generateDocs(.{ .@"union" = self }, writer);
        try writer.print("pub const {s} = ", .{self.into(BaseInfo).getName().?});
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("core.deprecated(");
        }
        try writer.writeAll("extern union{\n");
        var iter = field_iter(self);
        while (iter.next()) |field| {
            try writer.print("{}", .{field});
        }
        if (emit_abi) {
            try writer.writeAll("}");
            if (self.into(BaseInfo).isDeprecated()) {
                try writer.writeAll(")");
            }
            try writer.writeAll(";\n");
            var m_iter = method_iter(self);
            while (m_iter.next()) |method| {
                try writer.print("{b}", .{method});
            }
            return;
        }
        var m_iter = method_iter(self);
        while (m_iter.next()) |method| {
            try writer.print("{}", .{method});
        }
        try writer.print("{}", .{self.into(RegisteredTypeInfo)});
        try writer.writeAll("}");
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll(")");
        }
        try writer.writeAll(";\n");
    }
};

pub const ValueInfoExt = struct {
    /// Print value
    ///
    /// Specifiers:
    /// - u: unsigned
    /// - e: @enumFromInt
    /// - b: @bitCast
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

        const value_name = self.into(BaseInfo).name_string();
        try writer.print("{s}", .{value_name.to_identifier()});
        if (convert_func) |func| {
            try writer.print(": @This() = @{s}(", .{func});
            if (func[0] == 'b') {
                try writer.print("@as({s}, ", .{@typeName(Storage)});
            }
        } else {
            try writer.writeAll(" = ");
        }
        try writer.print("{d}", .{@as(Storage, @intCast(self.getValue()))});
        if (convert_func) |func| {
            if (func[0] == 'b') {
                try writer.writeAll(")");
            }
            try writer.writeAll(")");
        }
    }
};

pub const VFuncInfoExt = struct {
    /// Print `pub fn nameV(...) ...`
    pub fn format(self_immut: *const VFuncInfo, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = options;
        const self: *VFuncInfo = @constCast(self_immut);
        inline for (fmt) |ch| {
            switch (ch) {
                else => @compileError(std.fmt.comptimePrint("Invalid format string '{c}' for type {s}", .{ ch, @typeName(@This()) })),
            }
        }

        const raw_vfunc_name = self.into(BaseInfo).name_string();
        const vfunc_name = raw_vfunc_name.to_camel();
        const container = self.into(BaseInfo).getContainer().?;
        const class = switch (container.getType()) {
            .object => container.tryInto(ObjectInfo).?.getClassStruct().?,
            .interface => container.tryInto(InterfaceInfo).?.getIfaceStruct().?,
            else => unreachable,
        };
        const class_name = class.into(BaseInfo).getName().?;
        try root.generateDocs(.{ .vfunc = self }, writer);
        try writer.print("pub fn {s}V", .{vfunc_name});
        try writer.print("{e}", .{self.into(CallableInfo)});
        try writer.writeAll(" {\n");
        if (self.into(BaseInfo).isDeprecated()) {
            try writer.writeAll("core.deprecated({});\n");
        }
        try writer.print("const class: *{s} = @ptrCast(core.unsafeCast(gobject.TypeInstance, self).g_class.?);\n", .{class_name});
        try writer.print("const vFn = class.{s}.?;", .{raw_vfunc_name});
        try writer.writeAll("const ret = vFn");
        try writer.print("{}", .{self.into(CallableInfo)});
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
    }
};

pub const UnresolvedInfoExt = struct {};

const BitField = struct {
    var remaining: ?usize = null;

    /// Make sure bitfield ends
    pub fn _end(writer: std.io.AnyWriter) anyerror!void {
        if (remaining != null) {
            try writer.print("_: u{d},\n", .{BitField.remaining.?});
            try writer.writeAll("},\n");
            remaining = null;
        }
    }

    /// Alloc `bits`. If failed, create a new container of `container_size` and retry.
    pub fn _emit(writer: std.io.AnyWriter, bits: usize, container_size: usize, container_name: usize) anyerror!void {
        if ((remaining orelse 0) < bits) {
            try _end(writer);
            remaining = container_size;
            try writer.print("_{d}: packed struct(u{d}) {{\n", .{ container_name, container_size });
        }
        remaining.? -= bits;
    }
};
