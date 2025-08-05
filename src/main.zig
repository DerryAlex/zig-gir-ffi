const std = @import("std");
pub const options = @import("options");
const fatal = std.process.fatal;
const CliOptions = @import("CliOptions.zig");
const gi = @import("gi.zig");

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const cli_options: CliOptions = try .parse(allocator, args);
    defer cli_options.deinit(allocator);

    if (cli_options.help) {
        try CliOptions.printUsage(args[0]);
        return;
    }
    if (cli_options.version) {
        try CliOptions.printVersion(options.version);
        return;
    }
    if (cli_options.namespaces.len == 0) fatal("no namespace specified", .{});

    var repository: gi.Repository = .init(allocator, .chain(.gir, .typelib));
    for (cli_options.include_dirs) |dir| {
        try repository.appendSearchPath(dir);
    }
    for (cli_options.namespaces) |ns| {
        try repository.load(ns.name, ns.version);
    }

    const cwd = std.fs.cwd();
    var output_dir = cwd.openDir(cli_options.output_dir, .{}) catch |err| switch (err) {
        error.FileNotFound => blk: {
            try cwd.makeDir(cli_options.output_dir);
            break :blk try cwd.openDir(cli_options.output_dir, .{});
        },
        else => return err,
    };
    defer output_dir.close();

    var buffer: [4096]u8 = undefined;
    const namespaces = repository.namespaces.values();
    for (namespaces) |*ns| {
        const file_name = try std.mem.concat(allocator, u8, &.{ ns.name, ".zig" });
        defer allocator.free(file_name);
        var file = try output_dir.createFile(file_name, .{});
        defer file.close();
        var writer = file.writer(&buffer);
        try writer.interface.writeAll("const core = @import(\"core.zig\");\n");
        for (ns.dependencies.items) |dep| try writer.interface.print("const {s} = @import(\"{s}.zig\");\n", .{ dep, dep });
        try writer.interface.print("const {s} = @This();\n", .{ns.name});
        for (ns.infos.items) |*info| try writer.interface.print("{f}", .{info});
        try writer.interface.flush();
    }
}
