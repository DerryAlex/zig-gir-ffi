const std = @import("std");
const gir = @import("gir.zig");
const BaseInfo = gir.BaseInfo;
const FieldInfo = gir.FieldInfo;

pub fn emit(info: BaseInfo, writer: anytype) !void {
    const info_type = info.type();
    switch (info_type) {
        .Function => {
            const namespace = info.namespace();
            if (docPrefix(namespace)) |prefix| {
                try writer.print("/// func [{s}]({s}/func.{s}.html)\n", .{ info.name().?, prefix, info.name().? });
            }
            try writer.print("{}", .{info.asCallable().asFunction()});
        },
        .Callback => {
            const namespace = info.namespace();
            if (docPrefix(namespace)) |prefix| {
                try writer.print("/// callback [{s}]({s}/callback.{s}.html)\n", .{ info.name().?, prefix, info.name().? });
            }
            if (info.isDeprecated()) {
                try writer.print("pub const {s} = if (core.config.disable_deprecated) core.Deprecated else {};\n", .{ info.name().?, info.asCallable().asCallback() });
            } else {
                try writer.print("pub const {s} = {};\n", .{ info.name().?, info.asCallable().asCallback() });
            }
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

pub fn camelToSnake(src: []const u8, buf: []u8) []u8 {
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

pub fn docPrefix(namespace: []const u8) ?[]const u8 {
    const data = std.ComptimeStringMap([]const u8, .{
        .{ "Gtk", "https://docs.gtk.org/gtk4" },
        .{ "Gdk", "https://docs.gtk.org/gdk4" },
        .{ "GdkPixbuf", "https://docs.gtk.org/gdk-pixbuf" },
        .{ "Gsk", "https://docs.gtk.org/gsk4" },
        .{ "GObject", "https://docs.gtk.org/gobject" },
        .{ "Gio", "https://docs.gtk.org/gio" },
        .{ "GLib", "https://docs.gtk.org/glib" },
        .{ "Pango", "https://docs.gtk.org/Pango" },
        .{ "PangoCario", "https://docs.gtk.org/PangoCairo" },
    });
    return data.get(namespace);
}

pub const NamespaceString = struct {
    str: []const u8,

    pub fn format(self: NamespaceString, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        for (self.str, 0..) |c, i| {
            if (std.ascii.isUpper(c)) {
                if (i != 0 and (i != 1 or self.str[0] != 'G')) {
                    try writer.print("_{c}", .{std.ascii.toLower(c)});
                } else {
                    try writer.print("{c}", .{std.ascii.toLower(c)});
                }
            } else {
                try writer.print("{c}", .{c});
            }
        }
    }
};
