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
    const output_dir = try openDirCreate(cwd, io, cli_options.output_dir, .{});
    defer output_dir.close(io);
    const binding_dir = try openDirCreate(output_dir, io, "binding", .{ .iterate = true });
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

    // copy manual files
    const manual_dir = try cwd.openDir(io, cli_options.manual_dir, .{ .iterate = true });
    defer manual_dir.close(io);
    try copyDir(manual_dir, output_dir, io);

    // gi.zig
    {
        const file = try output_dir.createFile(io, "gi.zig", .{});
        defer file.close(io);
        var writer = file.writer(io, &buffer);
        var binding_iter = binding_dir.iterate();
        while (binding_iter.next(io)) |_entry| {
            if (_entry == null) break;
            const entry = _entry.?;
            if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".zig")) {
                const name = entry.name[0 .. entry.name.len - 4];
                try writer.interface.print("pub const {s} = @import(\"binding/{s}.zig\");\n", .{ name, name });
            }
        } else |err| {
            return err;
        }
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

fn openDirCreate(dir: Io.Dir, io: Io, sub_path: []const u8, open_options: Io.Dir.OpenOptions) !Io.Dir {
    return dir.openDir(io, sub_path, open_options) catch |err| switch (err) {
        error.FileNotFound => blk: {
            try dir.createDir(io, sub_path, .default_dir);
            break :blk try dir.openDir(io, sub_path, open_options);
        },
        else => return err,
    };
}

fn copyDir(source_dir: Io.Dir, dest_dir: Io.Dir, io: Io) !void {
    var iter = source_dir.iterate();
    while (iter.next(io)) |_entry| {
        if (_entry == null) break;
        const entry = _entry.?;
        switch (entry.kind) {
            .file => {
                try source_dir.copyFile(entry.name, dest_dir, entry.name, io, .{});
            },
            .directory => {
                dest_dir.createDir(io, entry.name, .default_dir) catch {};
                const sub_dest_dir = try dest_dir.openDir(io, entry.name, .{});
                const sub_source_dir = try source_dir.openDir(io, entry.name, .{ .iterate = true });
                try copyDir(sub_source_dir, sub_dest_dir, io);
            },
            else => {
                std.log.debug("copyDir: unhandled file {s} of type {}", .{ entry.name, entry.kind });
            },
        }
    } else |err| {
        return err;
    }
}
