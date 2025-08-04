const CliOptions = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const fatal = std.process.fatal;

help: bool = false,
version: bool = false,
namespaces: []const Namespace = &.{},
output_dir: []const u8 = &.{},
include_dirs: []const []const u8 = &.{},

pub const Namespace = struct {
    name: []const u8,
    version: ?[]const u8 = null,
};

const usage =
    \\Usage: {s} [option...] namespace...
    \\Options:
    \\  -h, --help            Display this information.
    \\  --version             Display version information.
    \\  -o, --output <dir>    Place output into <dir>.
    \\  -I, --include <dir>   Add <dir> to search path.
    \\
;

pub fn printUsage(arg0: [:0]const u8) !void {
    var writer = std.Progress.lockStderrWriter(&.{});
    defer std.Progress.unlockStderrWriter();
    try writer.print(usage, .{arg0});
}

pub fn printVersion(version: std.SemanticVersion) !void {
    var writer = std.Progress.lockStderrWriter(&.{});
    defer std.Progress.unlockStderrWriter();
    try writer.print("{f}\n", .{version});
}

fn isValidDir(path: []const u8) bool {
    const cwd = std.fs.cwd();
    var dir = cwd.openDir(path, .{}) catch |err| {
        std.log.warn("Invalid path `{s}`: {t}", .{ path, err });
        return false;
    };
    defer dir.close();
    return true;
}

pub fn parse(allocator: Allocator, args: []const [:0]const u8) !CliOptions {
    var options: CliOptions = .{};
    var namespaces: std.ArrayList(Namespace) = .init(allocator);
    errdefer namespaces.deinit();
    var include_dirs: std.ArrayList([]const u8) = .init(allocator);
    errdefer include_dirs.deinit();

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.startsWith(u8, arg, "-")) {
            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                options.help = true;
            } else if (std.mem.eql(u8, arg, "--version")) {
                options.version = true;
            } else if (std.mem.eql(u8, arg, "-o") or std.mem.eql(u8, arg, "--output")) {
                if (i + 1 >= args.len) fatal("expected argument after '{s}'", .{arg});
                i += 1;
                options.output_dir = args[i];
            } else if (std.mem.eql(u8, arg, "-I") or std.mem.eql(u8, arg, "--include")) {
                if (i + 1 >= args.len) fatal("expected argument after '{s}'", .{arg});
                i += 1;
                const dir = args[i];
                if (isValidDir(dir)) try include_dirs.append(dir);
            } else {
                fatal("unknown option: '{s}'", .{arg});
            }
        } else {
            if (std.mem.indexOfScalar(u8, arg, '-')) |pos| {
                try namespaces.append(.{
                    .name = arg[0..pos],
                    .version = arg[pos + 1 ..],
                });
            } else {
                try namespaces.append(.{
                    .name = arg,
                });
            }
        }
    }

    options.namespaces = try namespaces.toOwnedSlice();
    options.include_dirs = try include_dirs.toOwnedSlice();
    return options;
}

pub fn deinit(self: CliOptions, allocator: Allocator) void {
    allocator.free(self.namespaces);
    allocator.free(self.include_dirs);
}
