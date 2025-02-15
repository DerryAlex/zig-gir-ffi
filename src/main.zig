const std = @import("std");
const config = @import("config");
const clap = @import("clap");
const gi = @import("girepository-2.0.zig");
const String = @import("string.zig").String;

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    // Declare cli options
    const params = comptime clap.parseParamsComptime(std.fmt.comptimePrint(
        \\-h, --help                      Display this help and exit
        \\--version                       Display version
        \\-N, --gi-namespaces <str>...    GI namespace to use (default: {s})
        \\-V, --gi-versions <str>...      Version of namespace
        \\--includedir <str>...           Include directories in GIR search path
        \\--outputdir <str>               Output directory (default: {s})
        \\--pkg-name <str>                Generated package name (default: $gi-namespace[0])
        \\--pkg-version <str>             Generated package version (default: $gi-version[0])
        \\--emit-abi                      Output ABI description
        \\--gi-ext                        Enable manual extensions for gi
        \\
    , .{ blk: {
        var string: []const u8 = "";
        for (config.gi_namespaces, 0..) |namespace, idx| {
            if (idx > 0) {
                string = string ++ ", ";
            }
            string = string ++ namespace;
        }
        break :blk string;
    }, config.outputdir }));
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
    var gi_namespaces = config.gi_namespaces;
    var gi_versions = config.gi_versions;
    if (res.args.@"gi-namespaces".len != 0) {
        gi_namespaces = res.args.@"gi-namespaces";
        gi_versions = null;
    }
    if (res.args.@"gi-versions".len != 0) {
        if (res.args.@"gi-versions".len != res.args.@"gi-namespaces".len) {
            std.log.err("Unmatched number of GI namespace and version", .{});
            return error.InvalidParameter;
        }
        gi_versions = res.args.@"gi-versions";
    }
    const includedir = res.args.includedir;
    var outputdir = config.outputdir;
    if (res.args.outputdir) |o| {
        outputdir = o;
    }
    var pkg_name = String.new_from("{s}", .{gi_namespaces[0]}).to_snake();
    if (res.args.@"pkg-name") |p| {
        pkg_name = String.new_from("{s}", .{p});
    }
    var pkg_version = String.new_from("{s}", .{if (gi_versions) |version| version[0] else "0.0.0"});
    if (res.args.@"pkg-version") |p| {
        pkg_version = String.new_from("{s}", .{p});
    }
    const emit_abi = res.args.@"emit-abi" != 0;
    const has_gi_ext = res.args.@"gi-ext" != 0;

    // Load GIR
    const repository = gi.Repository.new();
    for (includedir) |i| {
        const _i = String.new_from("{s}", .{i});
        repository.prependSearchPath(_i.slice());
    }
    for (gi_namespaces, 0..) |namespace, idx| {
        const n = String.new_from("{s}", .{namespace});
        const v = if (gi_versions) |versions| String.new_from("{s}", .{versions[idx]}) else String.new_from("null", .{});
        var err: ?*gi.core.Error = null;
        _ = repository.require(
            n.slice(),
            if (gi_versions == null) null else v.slice(),
            .{},
            &err,
        ) catch {
            std.log.err("{s}", .{err.?.message.?});
            return error.UnexpectedError;
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
        if (emit_abi) break;
        switch (e.kind) {
            .file => {
                const filename = try allocator.dupe(u8, e.basename);
                try manual_files.append(filename);
                const target = String.new_from("{s}/{s}", .{ manualdir_r, filename });
                const symlink = String.new_from("{s}/{s}", .{ outputdir_r, filename });
                manual_dir.symLink(target.slice(), symlink.slice(), .{}) catch |err| switch (err) {
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
        .emit_abi = emit_abi,
        .has_gi_ext = has_gi_ext,
    });
}

const PkgConfig = struct {
    name: String,
    version: String,
    extra_files: [][]const u8,
    emit_abi: bool,
    has_gi_ext: bool,
};

pub fn generateBindings(allocator: std.mem.Allocator, repository: *gi.Repository, output_dir: std.fs.Dir, pkg_config: PkgConfig) !void {
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
        const mod = std.mem.sliceTo(e, '.');
        try build_zig.writer().print(
            \\    var {s} = b.addModule("{s}", .{{ .root_source_file = b.path("{s}") }});
            \\
        , .{ mod, mod, e });
        try build_zig_zon.writer().print(
            \\        "{s}",
            \\
        , .{e});
    }

    const loaded_namespaces = repository.getLoadedNamespaces();
    for (loaded_namespaces.ret[0..loaded_namespaces.n_namespaces_out]) |namespaceZ| {
        const namespace = String.new_from("{s}", .{namespaceZ});
        const filename = String.new_from("{s}.zig", .{namespace.to_snake()});
        {
            const file = try output_dir.createFile(filename.slice(), .{});
            defer file.close();
            const writer = file.writer().any();
            try writer.writeAll("// This file is auto-generated by zig-gir-ffi\n");
            try writer.print("const {s} = @This();\n", .{namespace.to_snake()});

            const dependencies = repository.getDependencies(namespace.slice());
            for (dependencies.ret[0..dependencies.n_dependencies_out]) |dependencyZ| {
                const dependency = String.new_from("{s}", .{std.mem.sliceTo(dependencyZ, '-')}).to_snake();
                if (!pkg_config.emit_abi) {
                    try writer.print(
                        \\pub const {s} = @import("{s}");
                        \\
                    , .{ dependency, dependency });
                } else {
                    try writer.print(
                        \\pub const {s} = @import("{s}.zig");
                        \\
                    , .{ dependency, dependency });
                }
            }
            if (!pkg_config.emit_abi) {
                try writer.writeAll(
                    \\pub const core = @import("core");
                    \\
                );
            } else {
                try writer.writeAll(
                    \\pub const core = @import("core.zig");
                    \\
                );
            }
            if (std.mem.eql(u8, "Gtk", namespace.slice()) and !pkg_config.emit_abi) {
                try writer.writeAll(
                    \\pub const template = @import("template");
                    \\
                );
            }
            try writer.writeAll(
                \\const std = @import("std");
                \\
            );
            try writer.writeAll(
                \\const config = core.config;
                \\
            );
            if (pkg_config.emit_abi) {
                try writer.writeAll(
                    \\const c = @import("c");
                    \\const testing = @import("testing.zig");
                    \\const expect = testing.expect;
                    \\const isAbiCompatitable = testing.isAbiCompatitable;
                    \\
                );
            }
            if (pkg_config.has_gi_ext) {
                try writer.writeAll(
                    \\const ext = @import("gi-ext.zig");
                    \\
                );
            }

            const n = repository.getNInfos(namespace.slice());
            for (0..@intCast(n)) |i| {
                const info = repository.getInfo(namespace.slice(), @intCast(i));
                switch (info.getType()) {
                    .boxed => try writer.print(
                        \\pub const {s} = opaque {{}};
                        \\
                    , .{info.getName().?}),
                    .callback => {
                        try generateDocs(.{ .callback = info.tryInto(gi.CallbackInfo).? }, writer);
                        try writer.print("pub const {s} = ", .{info.getName().?});
                        if (info.isDeprecated()) {
                            try writer.writeAll("if (config.disable_deprecated) core.Deprecated else ");
                        }
                        try writer.print("{};\n", .{info.tryInto(gi.CallbackInfo).?});
                    },
                    .constant => try writer.print("{}", .{info.tryInto(gi.ConstantInfo).?}),
                    .@"enum" => {
                        if (pkg_config.emit_abi) {
                            try writer.print("{b}", .{info.tryInto(gi.EnumInfo).?});
                        } else {
                            try writer.print("{}", .{info.tryInto(gi.EnumInfo).?});
                        }
                    },
                    .flags => {
                        if (pkg_config.emit_abi) {
                            try writer.print("{b}", .{info.tryInto(gi.FlagsInfo).?});
                        } else {
                            try writer.print("{}", .{info.tryInto(gi.FlagsInfo).?});
                        }
                    },
                    .function => {
                        if (pkg_config.emit_abi) {
                            try writer.print("{bG}", .{info.tryInto(gi.FunctionInfo).?});
                        } else {
                            try writer.print("{}", .{info.tryInto(gi.FunctionInfo).?});
                        }
                    },
                    .interface => {
                        if (pkg_config.emit_abi) {
                            try writer.print("{b}", .{info.tryInto(gi.InterfaceInfo).?});
                        } else {
                            try writer.print("{}", .{info.tryInto(gi.InterfaceInfo).?});
                        }
                    },
                    .object => {
                        if (pkg_config.emit_abi) {
                            try writer.print("{b}", .{info.tryInto(gi.ObjectInfo).?});
                        } else if (pkg_config.has_gi_ext) {
                            try writer.print("{e}", .{info.tryInto(gi.ObjectInfo).?});
                        } else {
                            try writer.print("{}", .{info.tryInto(gi.ObjectInfo).?});
                        }
                    },
                    .@"struct" => {
                        if (pkg_config.emit_abi) {
                            try writer.print("{b}", .{info.tryInto(gi.StructInfo).?});
                        } else {
                            try writer.print("{}", .{info.tryInto(gi.StructInfo).?});
                        }
                    },
                    .@"union" => {
                        if (pkg_config.emit_abi) {
                            try writer.print("{b}", .{info.tryInto(gi.UnionInfo).?});
                        } else {
                            try writer.print("{}", .{info.tryInto(gi.UnionInfo).?});
                        }
                    },
                    else => unreachable,
                }
            }

            try writer.writeAll(
                \\test {
                \\    @setEvalBranchQuota(1_000_000);
                \\    std.testing.refAllDecls(@This());
                \\}
                \\
            );
        }

        const outputdir_r = try output_dir.realpathAlloc(allocator, ".");
        defer allocator.free(outputdir_r);
        const filename_r = try std.mem.concat(allocator, u8, &.{ outputdir_r, "/", filename.slice() });
        defer allocator.free(filename_r);
        const fmt_result = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = &[_][]const u8{ "zig", "fmt", filename_r },
        });
        defer allocator.free(fmt_result.stdout);
        defer allocator.free(fmt_result.stderr);
        std.debug.assert(fmt_result.stderr.len == 0);

        try build_zig.writer().print(
            \\    var {s} = b.addModule("{s}", .{{ .root_source_file = b.path("{s}") }});
            \\
        , .{ namespace.to_snake(), namespace.to_snake(), filename });
        try build_zig_zon.writer().print(
            \\        "{s}",
            \\
        , .{filename});
    }

    for (loaded_namespaces.ret[0..loaded_namespaces.n_namespaces_out]) |namespaceZ| {
        const namespace = String.new_from("{s}", .{namespaceZ});
        try build_zig.writer().writeAll("    inline for ([_]*std.Build.Module{ core");
        const dependencies = repository.getDependencies(namespace.slice());
        for (dependencies.ret[0..dependencies.n_dependencies_out]) |dependencyZ| {
            const dependency = String.new_from("{s}", .{std.mem.sliceTo(dependencyZ, '-')}).to_snake();
            try build_zig.writer().print(", {s}", .{dependency});
        }
        try build_zig.writer().writeAll(
            \\ }, [_][]const u8{ "core"
        );
        for (dependencies.ret[0..dependencies.n_dependencies_out]) |dependencyZ| {
            const dependency = String.new_from("{s}", .{std.mem.sliceTo(dependencyZ, '-')}).to_snake();
            try build_zig.writer().print(", \"{s}\"", .{dependency});
        }
        try build_zig.writer().writeAll(" }) |dep_mod, dep_name| {\n");
        try build_zig.writer().print("        {s}.addImport(dep_name, dep_mod);\n", .{namespace.to_snake()});
        try build_zig.writer().writeAll("    }\n");
        if (std.mem.eql(u8, namespace.slice(), "Gtk")) {
            try build_zig.writer().writeAll("    gtk.addImport(\"template\", template);\n");
        }
    }
    for (pkg_config.extra_files) |e| {
        const mod = std.mem.sliceTo(e, '.');
        if (std.mem.eql(u8, mod, "core")) {
            try build_zig.writer().writeAll("    core.addImport(\"glib\", glib);\n");
            try build_zig.writer().writeAll("    core.addImport(\"gobject\", gobject);\n");
        } else if (std.mem.eql(u8, mod, "template")) {
            try build_zig.writer().writeAll("    template.addImport(\"core\", core);\n");
            try build_zig.writer().writeAll("    template.addImport(\"gtk\", gtk);\n");
        } else {
            try build_zig.writer().print("    {s}.addImport(\"core\", core);\n", .{mod});
        }
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

    pub fn isDeprecated(self: Info) bool {
        return switch (self) {
            inline else => |info| info.into(gi.BaseInfo).isDeprecated(),
        };
    }
};

pub fn generateDocs(info: Info, writer: std.io.AnyWriter) anyerror!void {
    const urlmap = std.StaticStringMap([]const u8).initComptime(.{
        .{ "GIRepository", "https://docs.gtk.org/girepository" },
        .{ "GLib", "https://docs.gtk.org/glib" },
        .{ "GLibUnix", "https://docs.gtk.org/glib-unix" },
        .{ "GLibWin32", "https://docs.gtk.org/glib-win32" },
        .{ "GModule", "https://docs.gtk.org/gmodule" },
        .{ "GObject", "https://docs.gtk.org/gobject" },
        .{ "Gio", "https://docs.gtk.org/gio" },
        .{ "GioUnix", "https://docs.gtk.org/gio-unix" },
        .{ "GioWin32", "https://docs.gtk.org/gio-win32" },
        .{ "Gdk", "https://docs.gtk.org/gdk4" },
        .{ "GdkWayland", "https://docs.gtk.org/gdk4-wayland" },
        .{ "GdkX11", "https://docs.gtk.org/gdk4-x11" },
        .{ "Gsk", "https://docs.gtk.org/gsk4" },
        .{ "GdkPixbuf", "https://docs.gtk.org/gdk-pixbuf" },
        .{ "Gtk", "https://docs.gtk.org/gtk4" },
        .{ "Pango", "https://docs.gtk.org/Pango" },
        .{ "PangoCairo", "https://docs.gtk.org/PangoCairo" },
    });
    const namespace = info.getNamespace().?;
    if (urlmap.get(namespace)) |prefix| {
        if (info.isDeprecated()) {
            try writer.writeAll("/// Deprecated:\n");
        }
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
                try writer.print("({c}{c}) `{}`\n", .{ @as(u8, if (flags.readable) 'r' else '-'), @as(u8, if (flags.writable and !flags.construct_only) 'w' else '-'), p.getTypeInfo() });
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
