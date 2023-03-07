const std = @import("std");
const BaseInfo = @import("gir.zig").BaseInfo;

pub const enable_deprecated = false;

pub fn emit(info: BaseInfo, writer: anytype) !void {
    if (info.isDeprecated() and !enable_deprecated) return;
    const info_type = info.type();
    switch (info_type) {
        .Function => {
            try writer.print("{}", .{info.asCallable().asFunction()});
        },
        .Callback => {
            try writer.print("pub const {s} = {};\n", .{ info.name().?, info.asCallable().asCallback() });
        },
        .Struct => {
            try writer.print("{}", .{info.asRegisteredType().asStruct()});
        },
        .Boxed => {
            try writer.print("pub const {s} = opaque{{}};\n", .{info.name().?});
        },
        .Enum => {
            try writer.print("{}", .{info.asRegisteredType().asEnum()});
        },
        .Flags => {
            try writer.print("{_}", .{info.asRegisteredType().asEnum()});
        },
        .Object => {
            try writer.print("{}", .{info.asRegisteredType().asObject()});
        },
        .Interface => {
            try writer.print("{}", .{info.asRegisteredType().asInterface()});
        },
        .Constant => {
            try writer.print("{}", .{info.asConstant()});
        },
        .Union => {
            try writer.print("{}", .{info.asRegisteredType().asUnion()});
        },
        else => unreachable,
    }
}

pub fn snakeToCamel(src: []const u8, buf: []u8) []u8 {
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

pub fn isZigKeyword(str: []const u8) bool {
    const keywords = [_][]const u8{ "addrspace", "align", "allowzero", "and", "anyframe", "anytype", "asm", "async", "await", "break", "callconv", "catch", "comptime", "const", "continue", "defer", "else", "enum", "errdefer", "error", "export", "extern", "fn", "for", "if", "inline", "linksection", "noalias", "noinline", "nosuspend", "opaque", "or", "orelse", "packed", "pub", "resume", "return", "struct", "suspend", "switch", "test", "threadlocal", "try", "union", "unreachable", "usingnamespace", "var", "volatile", "while" };
    for (keywords) |keyword| {
        if (std.mem.eql(u8, keyword, str)) {
            return true;
        }
    }
    const primitives = [_][]const u8{ "anyerror", "anyframe", "anyopaque", "bool", "comptime_float", "comptime_int", "false", "isize", "noreturn", "null", "true", "type", "undefined", "usize", "void" };
    for (primitives) |keyword| {
        if (std.mem.eql(u8, keyword, str)) {
            return true;
        }
    }
    return false;
}

pub fn emitCall(self: anytype, writer: anytype) !void {
    // part 1
    const name = self.asRegisteredType().asBase().name().?;
    try writer.writeAll("pub fn CallZ(comptime method: []const u8) ?type {\n");
    var m_iter = self.methodIter();
    while (m_iter.next()) |method| {
        if (method.asCallable().asBase().isDeprecated() and !enable_deprecated) continue;
        var buf: [256]u8 = undefined;
        var m_name: []const u8 = snakeToCamel(method.asCallable().asBase().name().?, buf[0..]);
        if (std.mem.eql(u8, "self", m_name)) {
            m_name = "getSelf";
        }
        if (method.asCallable().isMethod()) {
            try writer.print("if (comptime std.mem.eql(u8, \"{s}\", method))", .{m_name});
            if (method.asCallable().mayReturnNull()) {
                try writer.print(" return {&?};\n", .{method.asCallable().returnType()});
            } else {
                try writer.print(" return {&};\n", .{method.asCallable().returnType()});
            }
        }
    }
    var v_iter = self.vfuncIter();
    while (v_iter.next()) |vfunc| {
        if (vfunc.asCallable().asBase().isDeprecated() and !enable_deprecated) continue;
        var buf: [256]u8 = undefined;
        const v_name = snakeToCamel(vfunc.asCallable().asBase().name().?, buf[0..]);
        try writer.print("if (comptime std.mem.eql(u8, \"{s}V\", method))", .{v_name});
        if (vfunc.asCallable().mayReturnNull()) {
            try writer.print(" return {&?};\n", .{vfunc.asCallable().returnType()});
        } else {
            try writer.print(" return {&};\n", .{vfunc.asCallable().returnType()});
        }
    }
    var p_iter = self.propertyIter();
    while (p_iter.next()) |property| {
        if (property.asBase().isDeprecated() and !enable_deprecated) continue;
        var buf: [256]u8 = undefined;
        const p_name = snakeToCamel(property.asBase().name().?, buf[0..]);
        try writer.print("if (comptime std.mem.eql(u8, \"property{c}{s}\", method)) return Property{c}{s}Z;\n", .{ std.ascii.toUpper(p_name[0]), p_name[1..], std.ascii.toUpper(p_name[0]), p_name[1..] });
    }
    var s_iter = self.signalIter();
    while (s_iter.next()) |signal| {
        if (signal.asCallable().asBase().isDeprecated() and !enable_deprecated) continue;
        var buf: [256]u8 = undefined;
        const s_name = snakeToCamel(signal.asCallable().asBase().name().?, buf[0..]);
        try writer.print("if (comptime std.mem.eql(u8, \"signal{c}{s}\", method)) return Signal{c}{s}Z;\n", .{ std.ascii.toUpper(s_name[0]), s_name[1..], std.ascii.toUpper(s_name[0]), s_name[1..] });
    }
    try writer.writeAll("return core.DispatchZ(@This(), method);\n");
    try writer.writeAll("}\n");
    // part 2
    try writer.print("pub fn callZ(self: *{s}, comptime method: []const u8, args: anytype)", .{name});
    try writer.writeAll(" if (CallZ(method)) |some| some else @compileError(std.fmt.comptimePrint(\"No such method {s}\", .{method})) {\n");
    m_iter = self.methodIter();
    while (m_iter.next()) |method| {
        if (method.asCallable().asBase().isDeprecated() and !enable_deprecated) continue;
        var buf: [256]u8 = undefined;
        var m_name: []const u8 = snakeToCamel(method.asCallable().asBase().name().?, buf[0..]);
        if (std.mem.eql(u8, "self", m_name)) {
            m_name = "getSelf";
        }
        if (method.asCallable().isMethod()) {
            if (isZigKeyword(m_name)) {
                try writer.print("if (comptime std.mem.eql(u8, \"{s}\", method)) return @call(.auto, @This().@\"{s}\", .{{self}} ++ args);", .{ m_name, m_name });
            } else {
                try writer.print("if (comptime std.mem.eql(u8, \"{s}\", method)) return @call(.auto, @This().{s}, .{{self}} ++ args);", .{ m_name, m_name });
            }
        }
    }
    v_iter = self.vfuncIter();
    while (v_iter.next()) |vfunc| {
        if (vfunc.asCallable().asBase().isDeprecated() and !enable_deprecated) continue;
        var buf: [256]u8 = undefined;
        const v_name = snakeToCamel(vfunc.asCallable().asBase().name().?, buf[0..]);
        try writer.print("if (comptime std.mem.eql(u8, \"{s}V\", method)) return @call(.auto, {s}V, .{{self}} ++ args);", .{ v_name, v_name });
    }
    p_iter = self.propertyIter();
    while (p_iter.next()) |property| {
        if (property.asBase().isDeprecated() and !enable_deprecated) continue;
        var buf: [256]u8 = undefined;
        const p_name = snakeToCamel(property.asBase().name().?, buf[0..]);
        try writer.print("if (comptime std.mem.eql(u8, \"property{c}{s}\", method)) return @call(.auto, property{c}{s}, .{{self}} ++ args);\n", .{ std.ascii.toUpper(p_name[0]), p_name[1..], std.ascii.toUpper(p_name[0]), p_name[1..] });
    }
    s_iter = self.signalIter();
    while (s_iter.next()) |signal| {
        if (signal.asCallable().asBase().isDeprecated() and !enable_deprecated) continue;
        var buf: [256]u8 = undefined;
        const s_name = snakeToCamel(signal.asCallable().asBase().name().?, buf[0..]);
        try writer.print("if (comptime std.mem.eql(u8, \"signal{c}{s}\", method)) return @call(.auto, signal{c}{s}, .{{self}} ++ args);\n", .{ std.ascii.toUpper(s_name[0]), s_name[1..], std.ascii.toUpper(s_name[0]), s_name[1..] });
    }
    try writer.writeAll("return core.dispatchZ(self, method, args);\n");
    try writer.writeAll("}\n");
}
