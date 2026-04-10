const std = @import("std");
pub const options = @import("options");
const assert = std.debug.assert;
const fatal = std.process.fatal;
const Io = std.Io;
const CliOptions = @import("CliOptions.zig");
const gi = @import("gi.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const arena = init.arena.allocator();
    const io = init.io;

    const args = try init.minimal.args.toSlice(arena);
    const cli_options: CliOptions = try .parse(io, arena, args);

    if (cli_options.help) {
        try CliOptions.printUsage(io, args[0]);
        return;
    }
    if (cli_options.version) {
        try CliOptions.printVersion(io, options.version);
        return;
    }
    if (cli_options.namespaces.len == 0) fatal("no namespace specified", .{});

    var repository: gi.Repository = .init(allocator, .chain(.debug(.gir), .debug(.typelib)));
    defer repository.deinit();
    for (cli_options.include_dirs) |dir| {
        try repository.appendSearchPath(dir);
    }
    for (cli_options.namespaces) |ns| {
        repository.load(io, ns.name, ns.version) catch |err| {
            std.log.err("{t}", .{err});
        };
    }
    if (repository.namespaces.count() == 0) fatal("no namespace loaded", .{});

    const cwd = Io.Dir.cwd();
    var output_dir = cwd.openDir(io, cli_options.output_dir, .{}) catch |err| switch (err) {
        error.FileNotFound => blk: {
            try cwd.createDir(io, cli_options.output_dir, .default_dir);
            break :blk try cwd.openDir(io, cli_options.output_dir, .{});
        },
        else => return err,
    };
    defer output_dir.close(io);
    var binding_dir = output_dir.openDir(io, "binding", .{}) catch |err| switch (err) {
        error.FileNotFound => blk: {
            try output_dir.createDir(io, "binding", .default_dir);
            break :blk try output_dir.openDir(io, "binding", .{});
        },
        else => return err,
    };
    defer binding_dir.close(io);

    var buffer: [4096]u8 = undefined;
    const namespaces = repository.namespaces.values();
    for (namespaces) |*ns| {
        const file_name = try std.mem.concat(allocator, u8, &.{ ns.name, ".zig" });
        defer allocator.free(file_name);
        const file = try binding_dir.createFile(io, file_name, .{});
        defer file.close(io);
        std.log.info("[Start] {s}", .{file_name});
        var writer = file.writer(io, &buffer);
        try writer.interface.writeAll("const std = @import(\"std\");\n");
        try writer.interface.writeAll("const core = @import(\"core.zig\");\n");
        for (ns.dependencies.items) |dep| try writer.interface.print("const {s} = @import(\"{s}.zig\");\n", .{ dep, dep });
        try writer.interface.print("const {s} = @This();\n", .{ns.name});
        for (ns.infos.items) |*info| try writer.interface.print("{f}", .{info});
        try writer.interface.flush();
        std.log.info("[Done] {s}", .{file_name});
    }
    // core.zig
    {
        const file = try binding_dir.createFile(io, "core.zig", .{});
        defer file.close(io);
        var writer = file.writer(io, &buffer);
        try writer.interface.writeAll(@embedFile("manual/core.zig"));
        try writer.interface.flush();
    }
    // gi.zig
    {
        const file = try output_dir.createFile(io, "gi.zig", .{});
        defer file.close(io);
        var writer = file.writer(io, &buffer);
        try writer.interface.writeAll("pub const core = @import(\"binding/core.zig\");\n");
        for (namespaces) |ns| try writer.interface.print("pub const {s} = @import(\"binding/{s}.zig\");\n", .{ ns.name, ns.name });
        try writer.interface.flush();
    }
    // build.zig
    {
        const file = try output_dir.createFile(io, "build.zig", .{});
        defer file.close(io);
        var writer = file.writer(io, &buffer);
        try writer.interface.writeAll(@embedFile("build/build.zig"));
        try writer.interface.flush();
    }
    // build.zig.zon
    {
        const file = try output_dir.createFile(io, "build.zig.zon", .{});
        defer file.close(io);
        var writer = file.writer(io, &buffer);
        try writer.interface.writeAll(@embedFile("build/build.zig.zon"));
        try writer.interface.flush();
    }

    var fmt_argv: std.ArrayList([]const u8) = try .initCapacity(allocator, 2);
    fmt_argv.appendSliceAssumeCapacity(&.{ "zig", "fmt" });
    defer {
        for (fmt_argv.items[2..]) |arg| allocator.free(arg);
        fmt_argv.deinit(allocator);
    }
    for (namespaces) |ns| {
        const file_name = try std.mem.concat(allocator, u8, &.{ ns.name, ".zig" });
        try fmt_argv.append(allocator, file_name);
    }
    var fmt_process = try std.process.spawn(io, .{
        .argv = fmt_argv.items,
        .cwd = .{ .dir = binding_dir },
        .stdout = .ignore,
    });
    const term = try fmt_process.wait(io);
    assert(term.exited == 0);
}
