const std = @import("std");
const config = @import("config");
const clap = @import("clap");
const gi = @import("girepository-2.0.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Declare cli options
    const params = comptime clap.parseParamsComptime(std.fmt.comptimePrint(
        \\-h, --help                 Display this help and exit
        \\--version                  Display version
        \\-N, --gi-namespace <str>   GI namespace to use (default: {s})
        \\-V, --gi-version <str>     Version of namespace
        \\--includedir <str>...      Include directories in GIR search path
        \\--outputdir <str>          Output directory (default: {s})
        \\--pkg-name <str>           Generated package name (default: $gi-namespace)
        \\--pkg-version <str>        Generated package version (default: $gi-version)
        \\
    , .{ config.gi_namespace, config.outputdir }));
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = allocator,
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    // Process cli options
    if (res.args.help != 0) {
        return clap.help(std.io.getStdOut().writer(), clap.Help, &params, .{});
    }
    if (res.args.version != 0) {
        try std.io.getStdOut().writeAll(config.version ++ "\n");
        return;
    }
    var gi_namespace = config.gi_namespace;
    var gi_version = config.gi_version;
    if (res.args.@"gi-namespace") |n| {
        gi_namespace = n;
        gi_version = null;
    }
    if (res.args.@"gi-version") |v| {
        if (res.args.@"gi-namespace" == null) {
            try std.io.getStdErr().writeAll("GI namespace unspecified\n");
            return error.InvalidParameter;
        }
        gi_version = v;
    }
    const includedir = res.args.includedir;
    var outputdir = config.outputdir;
    if (res.args.outputdir) |o| {
        outputdir = o;
    }
    var pkg_name = gi_namespace;
    if (res.args.@"pkg-name") |p| {
        pkg_name = p;
    }
    var pkg_version = gi_version orelse "0.0.0";
    if (res.args.@"pkg-version") |p| {
        pkg_version = p;
    }

    // Load GIR
    const repository = gi.Repository.new();
    for (includedir) |i| {
        const p = try allocator.dupeZ(u8, i);
        defer allocator.free(p);
        repository.prependSearchPath(p);
    }
    {
        const n = try allocator.dupeZ(u8, gi_namespace);
        defer allocator.free(n);
        const v_dupe: ?[:0]u8 = if (gi_version) |version| try allocator.dupeZ(u8, version) else null;
        defer if (v_dupe) |version| allocator.free(version);
        const v: ?[*:0]u8 = if (v_dupe) |v| v.ptr else null;
        _ = repository.require(n, v, .{}) catch |err| switch (err) {
            error.GError => {
                std.log.warn("{s}", .{gi.core.getError().message.?});
                return error.UnexpectedError;
            },
        };
    }

    // Create output directory
    const cwd = std.fs.cwd();
    cwd.makeDir(outputdir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    var output_dir = try cwd.openDir(outputdir, .{});
    defer output_dir.close();
    const outputdir_r = try output_dir.realpathAlloc(allocator, ".");
    defer allocator.free(outputdir_r);

    var manual_dir = try cwd.openDir("manual", .{ .iterate = true });
    defer manual_dir.close();
    const manualdir_r = try manual_dir.realpathAlloc(allocator, ".");
    defer allocator.free(manualdir_r);
    // Symlink files in manual directory
    var manual_files = std.ArrayList([]const u8).init(allocator);
    defer {
        for (manual_files.items) |i| {
            allocator.free(i);
        }
        manual_files.deinit();
    }
    var manual_dir_walker = try manual_dir.walk(allocator);
    defer manual_dir_walker.deinit();
    while (try manual_dir_walker.next()) |e| {
        switch (e.kind) {
            .file => {
                const filename = try allocator.dupe(u8, e.basename);
                try manual_files.append(filename);
                const target = try std.mem.concat(allocator, u8, &.{ manualdir_r, "/", filename });
                defer allocator.free(target);
                const symlink = try std.mem.concat(allocator, u8, &.{ outputdir_r, "/", filename });
                defer allocator.free(symlink);
                manual_dir.symLink(target, symlink, .{}) catch |err| switch (err) {
                    error.PathAlreadyExists => {},
                    else => return err,
                };
            },
            else => {},
        }
    }

    try generateBindings(allocator, repository, output_dir, .{
        .name = pkg_name,
        .version = pkg_version,
        .extra_files = manual_files.items,
    });
}

pub fn generateBindings(allocator: std.mem.Allocator, repository: *gi.Repository, output_dir: std.fs.Dir, pkg_config: struct {
    name: []const u8,
    version: []const u8,
    extra_files: [][]const u8,
}) !void {
    var build_zig = try output_dir.createFile("build.zig", .{});
    defer build_zig.close();
    var build_zig_zon = try output_dir.createFile("build.zig.zon", .{});
    defer build_zig_zon.close();
    try build_zig.writer().writeAll(
        \\const std = @import("std");
        \\
        \\pub fn build(b: *std.Build) !void{
        \\
    );
    try build_zig_zon.writer().print(
        \\.{{
        \\    .name = "{s}",
        \\    .version = "{s}",
        \\    .minimum_zig_version = "{s}",
        \\
    , .{ pkg_config.name, pkg_config.version, @import("builtin").zig_version_string });
    try build_zig_zon.writer().writeAll(
        \\    .dependencies = .{},
        \\    .paths = .{
        \\        "build.zig",
        \\        "build.zig.zon",
        \\
    );
    for (pkg_config.extra_files) |e| {
        try build_zig_zon.writer().print(
            \\        "{s}",
            \\
        , .{e});
    }

    const loaded_namespaces = repository.getLoadedNamespaces();
    for (loaded_namespaces.ret[0..loaded_namespaces.n_namespaces_out]) |namespaceZ| {
        const namespace: [:0]const u8 = std.mem.span(namespaceZ);
        const filename = try std.mem.concat(allocator, u8, &.{ namespace, ".zig" });
        defer allocator.free(filename);
        {
            const file = try output_dir.createFile(filename, .{});
            defer file.close();
            const writer = file.writer().any();
            try writer.writeAll("// This file is auto-generated by zig-gir-ffi\n");
            try writer.print("const {} = @This();\n", .{Namespace{ .str = namespace }});

            const dependencies = repository.getDependencies(namespace);
            for (dependencies.ret[0..dependencies.n_dependencies_out]) |dependencyZ| {
                const dependency: []const u8 = std.mem.sliceTo(dependencyZ, '-');
                try writer.print("pub const {} = @import(\"{s}.zig\");\n", .{ Namespace{ .str = dependency }, dependency });
            }
            try writer.writeAll("pub const core = @import(\"core.zig\");\n");
            if (std.mem.eql(u8, namespace, "Gtk")) {
                try writer.writeAll("pub const template = @import(\"template.zig\");\n");
            }
            try writer.writeAll("const std = @import(\"std\");\n");

            const n = repository.getNInfos(namespace);
            for (0..@intCast(n)) |i| {
                const info = repository.getInfo(namespace, @intCast(i));
                switch (info.getType()) {
                    .boxed => try writer.print("pub const {s} = opaque {{}};\n", .{info.getName().?}),
                    .callback => {
                        try generateDocs(.{ .callback = info.tryInto(gi.CallbackInfo).? }, writer);
                        try writer.print("pub const {s} = ", .{info.getName().?});
                        if (info.isDeprecated()) {
                            try writer.writeAll("if (core.config.disable_deprecated) core.Deprecated else ");
                        }
                        try writer.print("{};\n", .{info.tryInto(gi.CallbackInfo).?});
                    },
                    .constant => try writer.print("{}", .{info.tryInto(gi.ConstantInfo).?}),
                    .@"enum" => try writer.print("{}", .{info.tryInto(gi.EnumInfo).?}),
                    .flags => try writer.print("{}", .{info.tryInto(gi.FlagsInfo).?}),
                    .function => {
                        try writer.print("{}", .{info.tryInto(gi.FunctionInfo).?});
                    },
                    .interface => try writer.print("{}", .{info.tryInto(gi.InterfaceInfo).?}),
                    .object => try writer.print("{}", .{info.tryInto(gi.ObjectInfo).?}),
                    .@"struct" => try writer.print("{}", .{info.tryInto(gi.StructInfo).?}),
                    .@"union" => try writer.print("{}", .{info.tryInto(gi.UnionInfo).?}),
                    else => unreachable,
                }
            }
        }

        const outputdir_r = try output_dir.realpathAlloc(allocator, ".");
        defer allocator.free(outputdir_r);
        const filename_r = try std.mem.concat(allocator, u8, &.{ outputdir_r, "/", filename });
        defer allocator.free(filename_r);
        const fmt_result = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = &[_][]const u8{ "zig", "fmt", filename_r },
        });
        defer allocator.free(fmt_result.stdout);
        defer allocator.free(fmt_result.stderr);
        std.debug.assert(fmt_result.stderr.len == 0);

        try build_zig.writer().print("    _ = b.addModule(\"{}\", .{{ .root_source_file = b.path(\"{s}.zig\") }});\n", .{ Namespace{ .str = namespace }, namespace });
        try build_zig_zon.writer().print("        \"{s}.zig\",\n", .{namespace});
    }

    try build_zig.writer().writeAll(
        \\}
    );
    try build_zig_zon.writer().writeAll(
        \\    },
        \\}
    );
}

pub const Info = union(enum) {
    callback: *gi.CallbackInfo,
    constant: *gi.ConstantInfo,
    @"enum": *gi.EnumInfo,
    flags: *gi.FlagsInfo,
    function: *gi.FunctionInfo,
    interface: *gi.InterfaceInfo,
    object: *gi.ObjectInfo,
    property: *gi.PropertyInfo,
    signal: *gi.SignalInfo,
    @"struct": *gi.StructInfo,
    @"union": *gi.UnionInfo,
    vfunc: *gi.VFuncInfo,

    pub fn getName(self: Info) ?[:0]const u8 {
        const name = switch (self) {
            inline else => |info| info.into(gi.BaseInfo).getName(),
        };
        return if (name) |n| std.mem.span(n) else null;
    }

    pub fn getNamespace(self: Info) ?[:0]const u8 {
        const namespace = switch (self) {
            inline else => |info| info.into(gi.BaseInfo).getNamespace(),
        };
        return if (namespace) |n| std.mem.span(n) else null;
    }

    pub fn getContainer(self: Info) ?*gi.BaseInfo {
        return switch (self) {
            inline else => |info| info.into(gi.BaseInfo).getContainer(),
        };
    }
};

pub fn generateDocs(info: Info, writer: std.io.AnyWriter) anyerror!void {
    const data = std.StaticStringMap([]const u8).initComptime(.{
        .{ "Gtk", "https://docs.gtk.org/gtk4" },
        .{ "Gsk", "https://docs.gtk.org/gsk4" },
        .{ "Gdk", "https://docs.gtk.org/gdk4" },
        .{ "Pango", "https://docs.gtk.org/Pango" },
        .{ "GdkPixbuf", "https://docs.gtk.org/gdk-pixbuf" },
        .{ "GLib", "https://docs.gtk.org/glib" },
        .{ "GObject", "https://docs.gtk.org/gobject" },
        .{ "Gio", "https://docs.gtk.org/gio" },
        .{ "GIRepository", "https://docs.gtk.org/girepository" },
    });
    const namespace = info.getNamespace().?;
    if (data.get(namespace)) |prefix| {
        const name = info.getName().?;
        switch (info) {
            .callback => try writer.print("/// callback [{s}]({s}/callback.{s}.html)\n", .{ name, prefix, name }),
            .constant => try writer.print("/// const [{s}]({s}/const.{s}.html)\n", .{ name, prefix, name }),
            .@"enum" => {
                if (name.len >= 5 and std.mem.eql(u8, "Error", name[name.len - 5 ..])) {
                    try writer.print("/// Error [{s}]({s}/error.{s}.html)\n", .{ name, prefix, name });
                } else {
                    try writer.print("/// Enum [{s}]({s}/enum.{s}.html)\n", .{ name, prefix, name });
                }
            },
            .flags => try writer.print("/// Flags [{s}]({s}/flags.{s}.html)\n", .{ name, prefix, name }),
            .function => |i| {
                if (info.getContainer()) |container| {
                    const container_name = std.mem.span(container.getName().?);
                    if (i.into(gi.CallableInfo).isMethod()) {
                        if (container_name.len >= 5 and std.mem.eql(u8, "Class", container_name[container_name.len - 5 ..]) and container.tryInto(gi.StructInfo).?.isGtypeStruct()) {
                            try writer.print("/// class method [{s}]({s}/class_method.{s}.{s}.html)\n", .{ name, prefix, container_name, name });
                        } else {
                            try writer.print("/// method [{s}]({s}/method.{s}.{s}.html)\n", .{ name, prefix, container_name, name });
                        }
                    } else {
                        if (i.getFlags().is_constructor) {
                            try writer.print("/// ctor [{s}]({s}/ctor.{s}.{s}.html)\n", .{ name, prefix, container_name, name });
                        } else {
                            try writer.print("/// type func [{s}]({s}/type_func.{s}.{s}.html)\n", .{ name, prefix, container_name, name });
                        }
                    }
                } else {
                    try writer.print("/// func [{s}]({s}/func.{s}.html)\n", .{ name, prefix, name });
                }
            },
            .interface => try writer.print("/// Iface [{s}]({s}/iface.{s}.html)\n", .{ name, prefix, name }),
            .object => try writer.print("/// Class [{s}]({s}/class.{s}.html)\n", .{ name, prefix, name }),
            .property => |p| {
                const container = info.getContainer().?;
                const container_name = std.mem.span(container.getName().?);
                try writer.print("/// - property [{s}]({s}/property.{s}.{s}.html): ", .{ name, prefix, container_name, name });
                const flags = p.getFlags();
                try writer.print("({c}{c}) {}\n", .{ @as(u8, if (flags.readable) 'r' else '-'), @as(u8, if (flags.writable and !flags.construct_only) 'w' else '-'), p.getTypeInfo() });
            },
            .signal => {
                const container = info.getContainer().?;
                const container_name = std.mem.span(container.getName().?);
                try writer.print("/// signal [{s}]({s}/signal.{s}.{s}.html)\n", .{ name, prefix, container_name, name });
            },
            .@"struct" => |s| {
                if (s.isGtypeStruct() and name.len >= 5 and std.mem.eql(u8, "Class", name[name.len - 5 ..])) {
                    //
                } else if (s.isGtypeStruct() and name.len >= 9 and std.mem.eql(u8, "Interface", name[name.len - 9 ..])) {
                    //
                } else if (name.len >= 7 and std.mem.eql(u8, "Private", name[name.len - 7 ..])) {
                    //
                } else {
                    try writer.print("/// Struct [{s}]({s}/struct.{s}.html)\n", .{ name, prefix, name });
                }
            },
            .@"union" => try writer.print("/// Union [{s}]({s}/union.{s}.html)\n", .{ name, prefix, name }),
            .vfunc => {
                const container = info.getContainer().?;
                const container_name = std.mem.span(container.getName().?);
                try writer.print("/// vfunc [{s}]({s}/vfunc.{s}.{s}.html)\n", .{ name, prefix, container_name, name });
            },
        }
    }
}

pub const Namespace = struct {
    str: []const u8,

    pub fn format(self: Namespace, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
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

pub const Identifier = struct {
    str: []const u8,

    pub fn format(self: Identifier, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.io.AnyWriter) anyerror!void {
        _ = fmt;
        _ = options;
        if (std.zig.isValidId(self.str)) {
            if (std.mem.eql(u8, self.str, "self")) {
                try writer.writeAll("getSelf");
            } else {
                try writer.print("{s}", .{self.str});
            }
        } else {
            try writer.print("@\"{s}\"", .{self.str});
        }
    }
};
