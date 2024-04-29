const std = @import("std");
const gir = @import("gir.zig");
const BaseInfo = gir.BaseInfo;
const FieldInfo = gir.FieldInfo;
const xml = @import("xml");
const c = @import("root").c;
const StringHashMap = std.StringHashMap;

pub const enable_deprecated = false;

pub fn emit(info: BaseInfo, writer: anytype) !void {
    if (info.isDeprecated() and !enable_deprecated) return;
    const info_type = info.type();
    switch (info_type) {
        .Function => {
            try writer.print("{}", .{info.asCallable().asFunction()});
        },
        .Callback => {
            const namespace = info.namespace();
            if (docPrefix(namespace)) |prefix| {
                try writer.print("/// {s}/callback.{s}.html\n", .{ prefix, info.name().? });
            }
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
        .{ "GLib", "https://doc.gtk.org/glib" },
        .{ "Pango", "https://docs.gtk.org/pango" },
        .{ "PangoCario", "https://docs.gtk.org/PangoCairo" },
    });
    return data.get(namespace);
}

// TODO: https://gitlab.gnome.org/GNOME/gobject-introspection/-/issues/246
pub fn fieldInfoGetSize(field_info: FieldInfo) !usize {
    const xml_reader_option: xml.ReaderOptions = .{
        .DecoderType = xml.encoding.Utf8Decoder,
        .enable_normalization = false,
    };
    const ns = "http://www.gtk.org/introspection/core/1.0";
    const Static = struct {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        var table = StringHashMap(*StringHashMap(*StringHashMap(usize))).init(gpa.allocator());
    };
    const allocator = Static.gpa.allocator();

    const namespace = field_info.asBase().namespace();
    const query_record_name = field_info.asBase().container().?.name().?;
    const query_field_name = field_info.asBase().name().?;
    if (Static.table.get(namespace)) |subtable| {
        if (subtable.get(query_record_name)) |subsubtable| {
            if (subsubtable.get(query_field_name)) |bits| {
                return bits;
            }
            return 0;
        }
        return 0;
    }

    const namespace_dup = try allocator.dupe(u8, namespace); // DO NOT free
    const new_subtable = try allocator.create(StringHashMap(*StringHashMap(usize)));
    new_subtable.* = StringHashMap(*StringHashMap(usize)).init(allocator);
    try Static.table.put(namespace_dup, new_subtable);
    const version = std.mem.span(c.g_irepository_get_version(null, namespace));
    const path = try std.mem.concat(allocator, u8, &[_][]const u8{ "gir-files/", namespace, "-", version, ".gir" });
    defer allocator.free(path);
    const file = std.fs.cwd().openFile(path, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            std.log.warn("[File Not Found] {s}", .{path});
            return 0;
        },
        else => return err,
    };
    defer file.close();
    var reader = xml.reader(allocator, file.reader(), xml_reader_option);

    while (try reader.next()) |event| switch (event) {
        .element_start => |e| if (e.name.is(ns, "repository")) {
            var repository_reader = reader.children();
            while (try repository_reader.next()) |repository_event| switch (repository_event) {
                .element_start => |re| if (re.name.is(ns, "namespace")) {
                    for (re.attributes) |attr| {
                        if (attr.name.is(null, "name")) {
                            std.debug.assert(std.mem.eql(u8, attr.value, namespace));
                        }
                    }
                    var namespace_reader = repository_reader.children();
                    while (try namespace_reader.next()) |namespace_event| switch (namespace_event) {
                        .element_start => |ne| if (ne.name.is(ns, "record")) {
                            for (ne.attributes) |attr| {
                                if (attr.name.is(null, "name")) {
                                    const record_name = try allocator.dupe(u8, attr.value); // DO NOT free
                                    var record_reader = repository_reader.children();
                                    while (try record_reader.next()) |record_event| switch (record_event) {
                                        .element_start => |rece| if (rece.name.is(ns, "field")) {
                                            var bits: usize = 0;
                                            var name: []const u8 = ""; // DO NOT free
                                            for (rece.attributes) |field_attr| {
                                                if (field_attr.name.is(null, "name")) {
                                                    name = try allocator.dupe(u8, field_attr.value);
                                                } else if (field_attr.name.is(null, "bits")) {
                                                    bits = try std.fmt.parseInt(usize, field_attr.value, 10);
                                                }
                                            }
                                            std.debug.assert(!std.mem.eql(u8, name, ""));
                                            if (bits != 0) {
                                                var subtable = Static.table.get(namespace).?;
                                                if (!subtable.contains(record_name)) {
                                                    const new_subsubtable = try allocator.create(StringHashMap(usize));
                                                    new_subsubtable.* = StringHashMap(usize).init(allocator);
                                                    try subtable.put(record_name, new_subsubtable);
                                                }
                                                var subsubtable = subtable.get(record_name).?;
                                                try subsubtable.putNoClobber(name, bits);
                                            }
                                        } else {
                                            try record_reader.children().skip();
                                        },
                                        else => {},
                                    };
                                }
                            }
                        } else {
                            try namespace_reader.children().skip();
                        },
                        else => {},
                    };
                } else {
                    try repository_reader.children().skip();
                },
                else => {},
            };
        } else {
            try reader.children().skip();
        },
        else => {},
    };

    if (Static.table.get(namespace)) |subtable| {
        if (subtable.get(query_record_name)) |subsubtable| {
            if (subsubtable.get(query_field_name)) |bits| {
                return bits;
            }
            return 0;
        }
        return 0;
    }
    return 0;
}
