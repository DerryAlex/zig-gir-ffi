const std = @import("std");
pub const c = @cImport({
    @cInclude("girepository.h");
});
const config = @import("config");
const emit = @import("helper.zig").emit;

const output_path = "gtk4/";

pub fn main() !void {
    const version = config.version;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const cwd = std.fs.cwd();

    const repository: *c.GIRepository = c.g_irepository_get_default();
    var gerror: ?*c.GError = null;
    _ = c.g_irepository_require(repository, "Gtk", null, 0, &gerror);
    if (gerror) |err| {
        std.log.warn("{s}", .{err.message});
        return error.UnexpectedError;
    }

    cwd.makeDir(output_path) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    var output_dir = try cwd.openDir(output_path, .{});
    defer output_dir.close();
    inline for ([_][]const u8{ "core.zig", "template.zig" }) |filename| {
        output_dir.symLink("../manual/" ++ filename, filename, .{}) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
    }
    var build_zig = try output_dir.createFile("build.zig", .{});
    defer build_zig.close();
    var build_zig_zon = try output_dir.createFile("build.zig.zon", .{});
    defer build_zig_zon.close();
    try build_zig.writer().writeAll(
        \\const std = @import("std");
        \\const LazyPath = std.Build.LazyPath;
        \\
        \\pub fn build(b: *std.Build) !void{
        \\
    );
    try build_zig_zon.writer().print(
        \\.{{
        \\    .name = "gtk4",
        \\    .version = "{s}",
        \\    .paths = .{{
        \\        "build.zig",
        \\        "build.zig.zon",
        \\
    , .{version});

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
        const longer_file_name = try std.mem.concat(allocator, u8, &[_][]const u8{ output_path, file_name });
        defer allocator.free(longer_file_name);
        const fmt_result = try std.ChildProcess.run(.{
            .allocator = allocator,
            .argv = &[_][]const u8{ "zig", "fmt", longer_file_name },
        });
        std.debug.assert(fmt_result.stderr.len == 0);

        try build_zig.writer().print("    _ = b.addModule(\"{c}{s}\", .{{ .root_source_file = LazyPath{{ .path = \"{s}.zig\" }} }});\n", .{ std.ascii.toLower(namespace[0]), namespace[1..], namespace });
        try build_zig_zon.writer().print("        \"{s}.zig\",\n", .{namespace});
    }

    try build_zig.writer().writeAll(
        \\}
    );
    try build_zig_zon.writer().writeAll(
        \\    },
        \\    .dependencies = .{},
        \\}
    );
}
