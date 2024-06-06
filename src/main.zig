const std = @import("std");
const config = @import("config");
const clap = @import("clap");
pub const c = @cImport({
    @cInclude("girepository.h");
});
const emit = @import("helper.zig").emit;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Declare cli options
    const params = comptime clap.parseParamsComptime(
        \\-h, --help                 Display this help and exit
        \\--version                  Display version
        \\-N, --gi-namespace <str>   GI namespace to use (default: Gtk)
        \\-V, --gi-version <str>     Version of namespace (default: null)
        \\--includedir <str>...      Include directories in GIR search path
        \\--outputdir <str>          Output directory (default: output)
        \\--pkg-name <str>           Generated package name (default: ${gi-namespace})
        \\--pkg-version <str>        Generated package version (default: ${gi-version})
        \\
    );
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
    const repository: *c.GIRepository = c.g_irepository_get_default();
    for (includedir) |i| {
        c.g_irepository_prepend_search_path(i.ptr);
    }
    var gerror: ?*c.GError = null;
    _ = c.g_irepository_require(repository, gi_namespace.ptr, if (gi_version) |v| v.ptr else null, 0, &gerror);
    if (gerror) |err| {
        std.log.warn("{s}", .{err.message});
        return error.UnexpectedError;
    }

    // Create output directory
    const cwd = std.fs.cwd();
    cwd.makeDir(outputdir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    var output_dir = try cwd.openDir(outputdir, .{});
    defer output_dir.close();
    const outputdir_realpath = try output_dir.realpathAlloc(allocator, ".");
    defer allocator.free(outputdir_realpath);

    var manual_dir = try cwd.openDir("manual", .{ .iterate = true });
    defer manual_dir.close();
    const manualdir_realpath = try manual_dir.realpathAlloc(allocator, ".");
    defer allocator.free(manualdir_realpath);
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
                const target = try std.mem.concat(allocator, u8, &.{ manualdir_realpath, "/", filename });
                defer allocator.free(target);
                const symlink = try std.mem.concat(allocator, u8, &.{ outputdir_realpath, "/", filename });
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
        .enable_deprecated = false,
    });
}

pub fn generateBindings(allocator: std.mem.Allocator, repository: *c.GIRepository, output_dir: std.fs.Dir, pkg_config: struct {
    name: []const u8,
    version: []const u8,
    extra_files: [][]const u8,
    enable_deprecated: bool,
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

    const namespaces: [*:null]?[*:0]const u8 = c.g_irepository_get_loaded_namespaces(repository);
    for (std.mem.span(namespaces)) |namespaceZ| {
        const namespace = std.mem.span(namespaceZ.?);
        const file_name = try std.mem.concat(allocator, u8, &[_][]const u8{ namespace, ".zig" });
        defer allocator.free(file_name);
        const file = try output_dir.createFile(file_name, .{});
        const writer = file.writer();
        try writer.print("// This file is generated by zig-gir-ffi\n", .{});
        try writer.print("const {s} = @This();\n", .{namespace});
        const dependencies: [*:null]?[*:0]const u8 = c.g_irepository_get_dependencies(repository, namespace.ptr);
        for (std.mem.span(dependencies)) |dependencyZ| {
            const dependency = std.mem.sliceTo(dependencyZ.?, '-');
            // import dependency
            try writer.print("pub const {s} = @import(\"{s}.zig\");\n", .{ dependency, dependency });
            if (std.mem.eql(u8, dependency, "Gtk")) {
                // import 'template' module
                try writer.print("pub const template = @import(\"template.zig\");\n", .{});
            }
        }
        if (std.mem.eql(u8, namespace, "Gtk")) {
            // import 'template' module
            try writer.print("pub const template = @import(\"template.zig\");\n", .{});
        }
        if (std.mem.eql(u8, namespace, "GLib") or std.mem.eql(u8, namespace, "GObject") or std.mem.eql(u8, namespace, "Gio")) {
            // part of 'core' module
            try writer.print("const core = @import(\"core.zig\");\n", .{});
        } else {
            // import 'core' module
            try writer.print("pub const core = @import(\"core.zig\");\n", .{});
        }
        // import 'std'
        try writer.print("const std = @import(\"std\");\n", .{});
        try writer.print("const assert = std.debug.assert;\n", .{});
        const n = c.g_irepository_get_n_infos(repository, namespace.ptr);
        for (0..@intCast(n)) |i| {
            const info: *c.GIBaseInfo = c.g_irepository_get_info(repository, namespace.ptr, @intCast(i));
            defer c.g_base_info_unref(info);
            try emit(.{ .info = info }, writer);
        }
        file.close();
        const outputdir = try output_dir.realpathAlloc(allocator, ".");
        defer allocator.free(outputdir);
        const longer_file_name = try std.mem.concat(allocator, u8, &.{ outputdir, "/", file_name });
        defer allocator.free(longer_file_name);
        const fmt_result = try std.ChildProcess.run(.{
            .allocator = allocator,
            .argv = &[_][]const u8{ "zig", "fmt", longer_file_name },
        });
        defer allocator.free(fmt_result.stdout);
        defer allocator.free(fmt_result.stderr);
        std.debug.assert(fmt_result.stderr.len == 0);

        try build_zig.writer().print("    _ = b.addModule(\"{c}{s}\", .{{ .root_source_file = b.path(\"{s}.zig\") }});\n", .{ std.ascii.toLower(namespace[0]), namespace[1..], namespace });
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
