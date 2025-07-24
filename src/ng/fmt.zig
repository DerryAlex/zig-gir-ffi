const std = @import("std");
const AutoHashMap = std.AutoHashMap;
const assert = std.debug.assert;
const Writer = std.Io.Writer;
const gi = @import("gi.zig");

fn formatTypeTag(tag: gi.TypeTag) []const u8 {
    return switch (tag) {
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
    };
}

fn formatArrayType(tag: gi.ArrayType) []const u8 {
    return switch (tag) {
        .array => "core.Array",
        .ptr_array => "core.PtrArray",
        .byte_array => "core.ByteArray",
        else => unreachable,
    };
}

// --- Type ---
pub const TypeFormatter = struct {
    type: *gi.Type,
    mutable: bool = false,
    nullable: bool = false,
    out: bool = false,
    optional: bool = false,

    pub fn format(self: TypeFormatter, writer: *Writer) Writer.Error!void {
        if (self.out) {
            if (self.optional) try writer.writeAll("?");
            try writer.writeAll("*");
        }
        switch (self.type.tag) {
            .void => {
                if (self.type.pointer) {
                    if (!self.out) {
                        if (self.nullable) try writer.writeAll("?");
                        try writer.writeAll("*");
                    }
                    try writer.writeAll("anyopaque");
                } else {
                    try writer.writeAll("void");
                }
            },
            .boolean, .int8, .uint8, .int16, .uint16, .int32, .uint32, .int64, .uint64, .float, .double, .glist, .gslist, .ghash, .gtype, .@"error", .unichar => {
                if (self.type.pointer) {
                    if (self.nullable) try writer.writeAll("?");
                    try writer.writeAll("*");
                }
                const tag = formatTypeTag(self.type.tag);
                try writer.writeAll(tag);
            },
            .utf8, .filename => {
                assert(self.type.pointer);
                if (self.nullable) try writer.writeAll("?");
                try writer.writeAll("[*:0]");
                if (!self.mutable) try writer.writeAll("const ");
                try writer.writeAll("u8");
            },
            .array => {
                switch (self.type.array_type) {
                    .c => {
                        const child_type = self.type.param_type.?;
                        var child_nullable = true;
                        if (self.type.array_fixed_size) |size| {
                            if (self.type.pointer) {
                                if (self.optional) try writer.writeAll("?");
                                try writer.writeAll("*");
                            }
                            try writer.print("[{}]", .{size});
                        } else {
                            assert(self.type.pointer);
                            if (self.nullable) try writer.writeAll("?");
                            try writer.writeAll("[*");
                            if (self.type.zero_terminated) {
                                switch (child_type.tag) {
                                    .int8, .uint8, .int16, .uint16, .int32, .uint32, .int64, .uint64, .float, .double, .unichar => try writer.writeAll(":0"),
                                    // FIXME: interface == .@"struct" and interface.@"struct".size == 0
                                    .interface => if (child_type.pointer) try writer.writeAll(":null"),
                                    else => {},
                                }
                            } else {
                                child_nullable = false;
                            }
                            try writer.writeAll("]");
                        }
                        try writer.print("{f}", .{TypeFormatter{
                            .type = child_type,
                            .nullable = child_nullable,
                        }});
                    },
                    .array, .ptr_array, .byte_array => {
                        if (!self.out) {
                            if (self.type.pointer) {
                                if (self.nullable) try writer.writeAll("?");
                                try writer.writeAll("*");
                            }
                        }
                    },
                }
            },
            .interface => {
                const child_type = self.type.interface.?;
                const base = child_type.getBase();
                switch (child_type.*) {
                    .callback => {
                        if (self.nullable) try writer.writeAll("?");
                        if (std.ascii.isUpper(base.name[0])) {
                            try writer.print("{f}", .{base});
                        } else {
                            // expand
                            try writer.print("{f}", .{CallbackFormatter{ .callback = &child_type.callback }});
                        }
                    },
                    .@"enum", .flags, .interface, .object, .@"struct", .@"union" => {
                        if (self.type.pointer) {
                            if (self.nullable) try writer.writeAll("?");
                            try writer.writeAll("*");
                        }
                        try writer.print("{f}", .{base});
                    },
                    .unresolved => {
                        try writer.writeAll("*anyopaque");
                        std.log.warn("Unresolved: {f}", .{base});
                    },
                    else => unreachable,
                }
            },
        }
    }
};

// --- Arg, Callable and Callback ---
pub const ArgFormatter = struct {
    arg: *gi.Arg,
    arg_name: bool = true,

    pub fn format(self: ArgFormatter, writer: *Writer) Writer.Error!void {
        if (self.arg_name) try writer.print("arg_{s}: ", .{self.arg.getBase().name});
        const arg_type = self.arg.type_info.?;
        var formatter: TypeFormatter = .{ .type = arg_type };
        if (self.arg.direction != .in and !(self.arg.caller_allocates and arg_type.tag == .array and arg_type.array_type == .c)) {
            formatter.out = true;
            formatter.mutable = true;
            if (self.arg.optional) formatter.optional = true;
        }
        if (self.arg.may_be_null) formatter.nullable = true;
        try writer.print("{f}", .{formatter});
    }
};

/// Helper to print `(arg_names...: arg_types...) return_type`
pub const CallableFormatter = struct {
    callable: *gi.Callable,
    container: ?*gi.Info = null,
    arg_name: bool = true,
    arg_type: bool = false,
    c_callconv: bool = false,
    constructor: bool = false,

    pub fn format(self: CallableFormatter, writer: *Writer) Writer.Error!void {
        var first = true;
        try writer.writeAll("(");
        if (self.callable.is_method) {
            if (!first) try writer.writeAll(", ") else first = false;
            if (self.arg_name) try writer.writeAll("self");
            if (self.arg_name and self.arg_type) try writer.writeAll(": ");
            if (self.arg_type) try writer.print("*{s}", .{self.container.?.getBase().name});
        }
        for (self.callable.args.items) |*arg| {
            if (!first) try writer.writeAll(", ") else first = false;
            if (self.arg_type) try writer.print("{f}", .{ArgFormatter{ .arg = arg, .arg_name = self.arg_name }});
            if (!self.arg_type and self.arg_name) {
                const arg_type = arg.type_info.?;
                if (arg_type.tag == .void and arg_type.pointer) try writer.writeAll("@ptrCast(");
                try writer.print("arg_{s}", .{arg.getBase().name});
                if (arg_type.tag == .void and arg_type.pointer) try writer.writeAll(")");
            }
        }
        if (self.callable.can_throw_gerror) {
            if (!first) try writer.writeAll(", ") else first = false;
            if (self.arg_name) try writer.writeAll("arg_error");
            if (self.arg_name and self.arg_type) try writer.writeAll(": ");
            if (self.arg_type) try writer.writeAll("*?*core.Error");
        }
        try writer.writeAll(")");

        if (self.arg_type) {
            if (self.c_callconv) try writer.writeAll(" callconv(.c)");
            if (self.callable.skip_return) {
                try writer.writeAll("void");
            } else {
                const return_type = self.callable.return_type.?;
                if (self.constructor) {
                    if (self.callable.may_return_null) try writer.writeAll("?");
                    try writer.print("*{s}", .{self.container.?.getBase().name});
                } else {
                    try writer.print("{f}", .{TypeFormatter{
                        .type = return_type,
                        .mutable = true,
                        .nullable = self.callable.may_return_null, // FIXME: glist, gslist
                    }});
                }
            }
        }
    }
};

pub const CallbackFormatter = struct {
    callback: *gi.Callback,

    pub fn format(self: CallbackFormatter, writer: *Writer) Writer.Error!void {
        try writer.print("*const fn {f}", .{CallableFormatter{
            .callable = &self.callback.callable,
            .arg_type = true,
            .c_callconv = true,
        }});
    }
};

// --- Constant and Value ---
pub const ConstantFormatter = struct {
    constant: *gi.Constant,

    pub fn format(self: ConstantFormatter, writer: *Writer) Writer.Error!void {
        switch (self.constant.value.?) {
            .string => |s| try writer.print("\"{s}\"", .{s}),
            .pointer => |p| try writer.print("{?}", .{p}),
            inline else => |v| try writer.print("{}", .{v}),
        }
    }
};

pub const ValueFormatter = struct {
    value: *gi.Value,
    storage: gi.TypeTag,
    convert: ?[]const u8 = null,

    pub fn format(self: ValueFormatter, writer: *Writer) Writer.Error!void {
        try writer.print("{s}", .{self.value.getBase().name});
        if (self.convert) |_| try writer.writeAll(": @This()");
        try writer.writeAll(" = ");
        if (self.convert) |c| try writer.print("{s}(@as({s}, ", .{ c, formatTypeTag(self.storage) });
        try writer.print("{}", .{self.value.value});
        if (self.convert) |_| try writer.writeAll("))");
    }
};

// --- Field ---
const BitField = struct {
    var remaining: ?usize = null;

    pub fn consume(writer: *Writer, bits: usize, container_size: usize, container_offset: usize) Writer.Error!void {
        if ((remaining orelse 0) < bits) {
            try end(writer);
            remaining = container_size;
            try writer.print("_{}: packed struct(u{}) {{\n", .{ container_offset, container_size });
        }
        remaining.? -= bits;
    }

    pub fn end(writer: *Writer) Writer.Error!void {
        if (remaining) |r| {
            try writer.print("_: u{},\n", .{r});
            try writer.writeAll("},\n");
        }
        remaining = null;
    }
};

pub const FieldFormatter = struct {
    field: *gi.Field,

    pub fn format(self: FieldFormatter, writer: *Writer) Writer.Error!void {
        const field_type = self.field.type_info.?;
        const field_size = self.field.size;
        const field_offset = self.field.offset;
        if (field_size != 0) {
            const container_size = switch (field_type.tag) {
                .int32, .uint32 => 32,
                else => unreachable,
            };
            try BitField.consume(writer, field_size, container_size, field_offset);
        } else {
            try BitField.end(writer);
        }
        try writer.print("{s}: ", .{self.field.getBase().name});
        if (field_size == 0) {
            // FIXME: simd4f alignment
            try writer.print("{f}", .{TypeFormatter{
                .type = field_type,
                .nullable = true,
            }});
        } else if (field_size == 1) {
            try writer.writeAll("bool");
        } else {
            const prefix = switch (field_type.tag) {
                .int32 => "i",
                .uint32 => "u",
                else => unreachable,
            };
            try writer.print("{s}{}", .{ prefix, field_size });
        }
        try writer.writeAll(",\n");
    }
};

// --- Property, Signal and VFunc ---
pub const PropertyFormatter = struct {
    property: *gi.Property,

    pub fn format(self: PropertyFormatter, writer: *Writer) Writer.Error!void {
        const name = self.property.getBase().name;
        const type_info = self.property.type_info.?;
        try writer.print("{s}: core.Property({f}, \"{s}\") = .{{}},\n", .{ name, TypeFormatter{ .type = type_info }, name });
    }
};

pub const SignalFormatter = struct {
    signal: *gi.Signal,
    container: ?*gi.Info = null,

    pub fn format(self: SignalFormatter, writer: *Writer) Writer.Error!void {
        const name = self.signal.getBase().name;
        const callable = &self.signal.callable;
        // FIXME: patch for signal param
        try writer.print("{s}: core.Signal(fn {f}, \"{s}\") = .{{}},\n", .{ name, CallableFormatter{
            .callable = callable,
            .container = self.container,
            .arg_name = false,
            .arg_type = true,
        }, name });
    }
};

pub const VFuncFormatter = struct {
    vfunc: *gi.VFunc,
    container: ?*gi.Info = null,

    pub fn format(self: VFuncFormatter, writer: *Writer) Writer.Error!void {
        const name = self.vfunc.getBase().name;
        const callable = &self.vfunc.callable;
        try writer.print("{s}: core.VFunc(fn {f}, \"{s}\") = .{{}},\n", .{ name, CallableFormatter{
            .callable = callable,
            .container = self.container,
            .arg_name = false,
            .arg_type = true,
        }, name });
    }
};

// --- Enum, Flags, Struct, Union ---
pub const EnumFormatter = struct {
    context: *gi.Enum,

    pub fn format(self: EnumFormatter, writer: *Writer) Writer.Error!void {
        const storage_type = self.context.storage_type;
        try writer.print("pub const {s} = enum({s}) {{\n", .{ self.context.getBase().name, formatTypeTag(storage_type) });

        var arena: std.heap.ArenaAllocator = .init(std.heap.smp_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        var values: AutoHashMap(i64, void) = .init(allocator);

        for (self.context.values.items) |*value| {
            if (values.contains(value.value)) continue;
            values.put(value.value, {}) catch @panic("Out of Memory");
            try writer.print("{f},\n", .{ValueFormatter{
                .value = value,
                .storage = storage_type,
            }});
        }
        for (self.context.values.items) |*value| {
            if (values.remove(value.value)) continue;
            // alias
            try writer.print("pub const {f};\n", .{ValueFormatter{
                .value = value,
                .storage = storage_type,
                .convert = "@enumFromInt",
            }});
        }

        for (self.context.methods.items) |*method| try writer.print("{f}", .{FunctionFormatter{
            .function = method,
            .container = @constCast(&gi.Info{ .@"enum" = self.context.* }),
        }});

        try writer.writeAll("};\n");
    }
};

pub const FlagsFormatter = struct {
    context: *gi.Flags,

    pub fn format(self: FlagsFormatter, writer: *Writer) Writer.Error!void {
        const storage_type = self.context.base.storage_type;
        try writer.print("pub const {s} = packed struct({s}) {{\n", .{ self.context.getBase().name, formatTypeTag(storage_type) });

        var arena: std.heap.ArenaAllocator = .init(std.heap.smp_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        var values: AutoHashMap(usize, []const u8) = .init(allocator);

        for (self.context.base.values.items) |*value| {
            if (value.value < 0 or !std.math.isPowerOfTwo(value.value)) continue;
            const idx = std.math.log2_int(usize, @intCast(value.value));
            if (values.contains(idx)) continue;
            values.put(idx, value.getBase().name) catch @panic("Out of Memory");
        }
        var padding_bits: usize = 0;
        for (0..32) |idx| {
            if (values.get(idx)) |name| {
                if (padding_bits != 0) try writer.print("_{}: u{} = 0,\n", .{ idx - padding_bits, padding_bits });
                padding_bits = 0;
                try writer.print("{s}: bool = false,\n", .{name});
            } else {
                padding_bits += 1;
            }
        }
        if (padding_bits != 0) try writer.print("_: u{} = 0,\n", .{padding_bits});
        for (self.context.base.values.items) |*value| {
            if (value.value == 0 or (value.value > 0 and std.math.isPowerOfTwo(value.value))) continue;
            try writer.print("pub const {f};", .{ValueFormatter{
                .value = value,
                .storage = storage_type,
                .convert = "@bitCast",
            }});
        }

        for (self.context.base.methods.items) |*method| try writer.print("{f}", .{FunctionFormatter{
            .function = method,
            .container = @constCast(&gi.Info{ .flags = self.context.* }),
        }});

        try writer.writeAll("};\n");
    }
};

pub const StructFormatter = struct {
    context: *gi.Struct,

    pub fn format(self: StructFormatter, writer: *Writer) Writer.Error!void {
        try writer.print("pub const {s} = {s}{{\n", .{ self.context.getBase().name, if (self.context.size != 0) "extern struct" else "opaque" });
        for (self.context.fields.items) |*field| try writer.print("{f}", .{FieldFormatter{ .field = field }});
        try BitField.end(writer);
        for (self.context.methods.items) |*method| try writer.print("{f}", .{FunctionFormatter{
            .function = method,
            .container = @constCast(&gi.Info{ .@"struct" = self.context.* }),
        }});
        try writer.writeAll("};\n");
    }
};

pub const UnionFormatter = struct {
    context: *gi.Union,

    pub fn format(self: UnionFormatter, writer: *Writer) Writer.Error!void {
        try writer.print("pub const {s} = extern union{{\n", .{self.context.getBase().name});
        for (self.context.fields.items) |*field| try writer.print("{f}", .{FieldFormatter{ .field = field }});
        for (self.context.methods.items) |*method| try writer.print("{f}", .{FunctionFormatter{
            .function = method,
            .container = @constCast(&gi.Info{ .@"union" = self.context.* }),
        }});
        try writer.writeAll("};\n");
    }
};

// --- Interface and Object ---
pub const InterfaceFormatter = struct {
    context: *gi.Interface,

    pub fn format(self: InterfaceFormatter, writer: *Writer) Writer.Error!void {
        // FIXME: opaque?
        try writer.print("pub const {s} = struct{{\n", .{self.context.getBase().name});
        try writer.writeAll("pub const Prerequistes = [_]type{");
        var first = true;
        for (self.context.prerequisites.items) |*preq| {
            if (!first) try writer.writeAll(", ") else first = false;
            try writer.print("{f}", .{preq.getBase()});
        }
        try writer.writeAll("};\n");
        for (self.context.properties.items) |*prop| try writer.print("{f}", .{PropertyFormatter{ .property = prop }});
        for (self.context.signals.items) |*signal| try writer.print("{f}", .{SignalFormatter{
            .signal = signal,
            .container = @constCast(&gi.Info{ .interface = self.context.* }),
        }});
        for (self.context.vfuncs.items) |*vfunc| try writer.print("{f}", .{VFuncFormatter{
            .vfunc = vfunc,
            .container = @constCast(&gi.Info{ .interface = self.context.* }),
        }});
        for (self.context.constants.items) |*constant| try writer.print("{f}", .{ConstantFormatter{ .constant = constant }});
        for (self.context.methods.items) |*method| try writer.print("{f}", .{FunctionFormatter{
            .function = method,
            .container = @constCast(&gi.Info{ .interface = self.context.* }),
        }});
        try writer.writeAll("};\n");
    }
};

pub const ObjectFormatter = struct {
    context: *gi.Object,

    pub fn format(self: ObjectFormatter, writer: *Writer) Writer.Error!void {
        try writer.print("pub const {s} = {s}{{\n", .{ self.context.getBase().name, if (self.context.fields.items.len != 0) "extern struct" else "opaque" });
        try writer.writeAll("pub const Interfaces = [_]type{");
        var first = true;
        for (self.context.interfaces.items) |*interface| {
            if (!first) try writer.writeAll(", ") else first = false;
            try writer.print("{f}", .{interface.getBase()});
        }
        try writer.writeAll("};\n");
        if (self.context.parent) |parent| try writer.print("pub const Parent = {f};\n", .{parent.getBase()});
        if (self.context.class_struct) |class| try writer.print("pub const Class = {f};\n", .{class.getBase()});
        for (self.context.fields.items) |*field| try writer.print("{f}", .{FieldFormatter{ .field = field }});
        try BitField.end(writer);
        for (self.context.properties.items) |*prop| try writer.print("{f}", .{PropertyFormatter{ .property = prop }});
        for (self.context.signals.items) |*signal| try writer.print("{f}", .{SignalFormatter{
            .signal = signal,
            .container = @constCast(&gi.Info{ .object = self.context.* }),
        }});
        for (self.context.vfuncs.items) |*vfunc| try writer.print("{f}", .{VFuncFormatter{
            .vfunc = vfunc,
            .container = @constCast(&gi.Info{ .object = self.context.* }),
        }});
        for (self.context.constants.items) |*constant| try writer.print("{f}", .{ConstantFormatter{ .constant = constant }});
        for (self.context.methods.items) |*method| try writer.print("{f}", .{FunctionFormatter{
            .function = method,
            .container = @constCast(&gi.Info{ .object = self.context.* }),
        }});
        try writer.writeAll("};\n");
    }
};

// --- Function ---
pub const FunctionFormatter = struct {
    function: *gi.Function,
    container: ?*gi.Info = null,

    pub fn format(self: FunctionFormatter, writer: *Writer) Writer.Error!void {
        _ = self;
        _ = writer;
        @panic("TODO");
    }
};
