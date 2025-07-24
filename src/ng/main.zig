const std = @import("std");
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
        try CliOptions.printVersion(.{
            .major = 0,
            .minor = 0,
            .patch = 0,
        });
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

    var iter = repository.namespaces.iterator();
    while (iter.next()) |entry| {
        std.log.debug("{s}", .{entry.key_ptr.*});
        for (entry.value_ptr.infos.items) |*info| std.log.debug("{f}", .{info});
    }
}
