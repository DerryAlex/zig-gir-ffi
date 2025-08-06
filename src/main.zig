const std = @import("std");
pub const options = @import("options");
const assert = std.debug.assert;
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
    var binding_dir = output_dir.openDir("binding", .{}) catch |err| switch (err) {
        error.FileNotFound => blk: {
            try output_dir.makeDir("binding");
            break :blk try output_dir.openDir("binding", .{});
        },
        else => return err,
    };
    defer binding_dir.close();

    var buffer: [4096]u8 = undefined;
    const namespaces = repository.namespaces.values();
    for (namespaces) |*ns| {
        const file_name = try std.mem.concat(allocator, u8, &.{ ns.name, ".zig" });
        defer allocator.free(file_name);
        const file = try binding_dir.createFile(file_name, .{});
        defer file.close();
        std.log.info("[Start] {s}", .{file_name});
        var writer = file.writer(&buffer);
        try writer.interface.writeAll("const core = @import(\"core.zig\");\n");
        for (ns.dependencies.items) |dep| try writer.interface.print("const {s} = @import(\"{s}.zig\");\n", .{ dep, dep });
        try writer.interface.print("const {s} = @This();\n", .{ns.name});
        for (ns.infos.items) |*info| try writer.interface.print("{f}", .{info});
        try writer.interface.flush();
        std.log.info("[Done] {s}", .{file_name});
    }
    // core.zig
    {
        const file = try binding_dir.createFile("core.zig", .{});
        defer file.close();
        var writer = file.writer(&buffer);
        try writer.interface.writeAll(@embedFile("manual/core.zig"));
        try writer.interface.flush();
    }
    // gi.zig
    {
        const file = try output_dir.createFile("gi.zig", .{});
        defer file.close();
        var writer = file.writer(&buffer);
        try writer.interface.writeAll("pub const core = @import(\"binding/core.zig\");\n");
        for (namespaces) |ns| try writer.interface.print("pub const {s} = @import(\"binding/{s}.zig\");\n", .{ ns.name, ns.name });
        try writer.interface.flush();
    }
    // build.zig
    {
        const file = try output_dir.createFile("build.zig", .{});
        defer file.close();
        var writer = file.writer(&buffer);
        try writer.interface.writeAll(@embedFile("build/build.zig"));
        try writer.interface.flush();
    }
    // build.zig.zon
    {
        const file = try output_dir.createFile("build.zig.zon", .{});
        defer file.close();
        var writer = file.writer(&buffer);
        try writer.interface.writeAll(@embedFile("build/build.zig.zon"));
        try writer.interface.flush();
    }

    var fmt_argv: std.ArrayList([]const u8) = try .initCapacity(allocator, 2);
    fmt_argv.appendSliceAssumeCapacity(&.{ "zig", "fmt" });
    defer {
        for (fmt_argv.items[2..]) |arg| allocator.free(arg);
        fmt_argv.deinit();
    }
    for (namespaces) |ns| {
        const file_name = try std.mem.concat(allocator, u8, &.{ ns.name, ".zig" });
        try fmt_argv.append(file_name);
    }
    var fmt_process: std.process.Child = .init(fmt_argv.items, allocator);
    fmt_process.cwd_dir = binding_dir;
    fmt_process.stdout_behavior = .Ignore;
    const term = try fmt_process.spawnAndWait();
    assert(term.Exited == 0);
}
