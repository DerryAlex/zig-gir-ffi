const std = @import("std");
const gir = @import("gir.zig");
const BaseInfo = gir.BaseInfo;
const FieldInfo = gir.FieldInfo;
const xml = @import("xml");
const c = @import("root").c;

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

// TODO: https://gitlab.gnome.org/GNOME/gobject-introspection/-/issues/246
// For xml parser, see https://github.com/ianprime0509/zig-gobject/
pub fn fieldInfoGetSize(field_info: FieldInfo) !usize {
    const xml_reader_option: xml.ReaderOptions = .{
        .DecoderType = xml.encoding.Utf8Decoder,
        .enable_normalization = false,
    };
    const XmlReader = xml.Reader(std.fs.File.Reader, xml_reader_option);
    const Cache = struct {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        var namespace: ?[]const u8 = null;
        var success: bool = false;
        var file: std.fs.File = undefined;
        var reader: XmlReader = undefined;
        const XmlChildrenReader = @TypeOf(reader.children());
        var repository: XmlChildrenReader = undefined;

        var record_success: bool = false;
        var record_name: ?[]const u8 = null;
        var record: XmlChildrenReader = undefined;
    };
    const allocator = Cache.gpa.allocator();
    const ns = "http://www.gtk.org/introspection/core/1.0";

    const namespace = field_info.asBase().namespace();
    const record_name = field_info.asBase().container().name().?;
    const field_name = field_info.asBase().name().?;
    if (Cache.namespace != null and std.mem.eql(u8, Cache.namespace.?, namespace)) {
        // do nothing
    } else {
        if (Cache.namespace != null) {
            allocator.free(Cache.namespace.?);
            Cache.namespace = null;
        }
        if (Cache.success) {
            Cache.file.close();
        }
        Cache.success = false;
        Cache.record_success = false;
        Cache.record_name = null;

        Cache.namespace = try allocator.dupe(u8, namespace);
        const prefix = "gir-files/";
        const version = std.mem.span(c.g_irepository_get_version(null, namespace));
        const path = try std.mem.concat(allocator, u8, &[_][]const u8{ prefix, namespace, "-", version, ".gir" });
        defer allocator.free(path);

        Cache.file = std.fs.cwd().openFile(path, .{}) catch |err| switch (err) {
            error.FileNotFound => {
                std.log.warn("[File Not Found] {s}", .{path});
                return 0;
            },
            else => return err,
        };
        Cache.reader = xml.reader(allocator, Cache.file.reader(), xml_reader_option);
        while (try Cache.reader.next()) |event| {
            switch (event) {
                .element_start => |e| if (e.name.is(ns, "repository")) {
                    var children = Cache.reader.children();
                    while (try children.next()) |child_event| {
                        switch (child_event) {
                            .element_start => |child| if (child.name.is(ns, "namespace")) {
                                Cache.repository = children.children();
                                Cache.success = true;
                                break;
                            } else {
                                try children.children().skip();
                            },
                            else => {},
                        }
                    }
                } else {
                    try Cache.reader.children().skip();
                },
                else => {},
            }
            if (Cache.success) break;
        }
    }
    if (!Cache.success) {
        return 0;
    } else {
        if (Cache.record_success and std.mem.eql(u8, Cache.record_name.?, record_name)) {
            return try fieldBitSizeHelper(&Cache.record, field_name);
        }
        Cache.record_success = false;
        if (Cache.record_name != null) {
            allocator.free(Cache.record_name.?);
            Cache.record_name = null;
        }
        while (try Cache.repository.next()) |event| {
            switch (event) {
                .element_start => |child| if (child.name.is(ns, "record")) {
                    for (child.attributes) |attr| {
                        if (attr.name.is(null, "name")) {
                            if (std.mem.eql(u8, attr.value, record_name)) {
                                Cache.record_success = true;
                                Cache.record_name = try allocator.dupe(u8, record_name);
                            }
                        }
                    }
                    if (!Cache.record_success) continue;
                    Cache.record = Cache.repository.children();
                    return try fieldBitSizeHelper(&Cache.record, field_name);
                } else {
                    try Cache.repository.children().skip();
                },
                else => {},
            }
            if (Cache.record_success) break;
        }
        return 0;
    }
}

fn fieldBitSizeHelper(reader: anytype, field_name: []const u8) !usize {
    const ns = "http://www.gtk.org/introspection/core/1.0";
    while (try reader.next()) |event| {
        switch (event) {
            .element_start => |child| if (child.name.is(ns, "field")) {
                var field_matched = false;
                var field_bits: usize = 0;
                for (child.attributes) |attr| {
                    if (attr.name.is(null, "name")) {
                        if (std.mem.eql(u8, attr.value, field_name)) {
                            field_matched = true;
                        }
                    } else if (attr.name.is(null, "bits")) {
                        field_bits = try std.fmt.parseInt(usize, attr.value, 10);
                    }
                }
                if (field_matched) {
                    return field_bits;
                }
            } else {
                try reader.children().skip();
            },
            else => {},
        }
    }
    return 0;
}
