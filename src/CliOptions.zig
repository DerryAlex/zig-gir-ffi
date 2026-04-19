const CliOptions = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const fatal = std.process.fatal;

help: bool = false,
version: bool = false,
namespaces: []const Namespace = &.{},
output_dir: []const u8 = "gi",
include_dirs: []const []const u8 = &.{},
manual_dir: []const u8 = "src/manual",

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
    \\  -m, --manual <dir>    Add manual files from <dir>.
    \\
;

pub fn printUsage(io: Io, arg0: [:0]const u8) !void {
    const stderr = try io.lockStderr(&.{}, null);
    defer io.unlockStderr();
    var writer = &stderr.file_writer.interface;
    try writer.print(usage, .{arg0});
}

pub fn printVersion(io: Io, version: std.SemanticVersion) !void {
    const stderr = try io.lockStderr(&.{}, null);
    defer io.unlockStderr();
    var writer = &stderr.file_writer.interface;
    try writer.print("{f}\n", .{version});
}

fn isValidDir(io: Io, path: []const u8) bool {
    const cwd = Io.Dir.cwd();
    var dir = cwd.openDir(io, path, .{}) catch |err| {
        std.log.warn("Invalid path `{s}`: {t}", .{ path, err });
        return false;
    };
    defer dir.close(io);
    return true;
}

pub fn parse(io: Io, allocator: Allocator, args: []const [:0]const u8) !CliOptions {
    var options: CliOptions = .{};
    var namespaces: std.ArrayList(Namespace) = .empty;
    errdefer namespaces.deinit(allocator);
    var include_dirs: std.ArrayList([]const u8) = .empty;
    errdefer include_dirs.deinit(allocator);

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
                if (isValidDir(io, dir)) try include_dirs.append(allocator, dir);
            } else if (std.mem.eql(u8, arg, "-m") or std.mem.eql(u8, arg, "--manual")) {
                if (i + 1 >= args.len) fatal("expected argument after '{s}'", .{arg});
                i += 1;
                options.manual_dir = args[i];
            } else {
                fatal("unknown option: '{s}'", .{arg});
            }
        } else {
            if (std.mem.indexOfScalar(u8, arg, '-')) |pos| {
                try namespaces.append(allocator, .{
                    .name = arg[0..pos],
                    .version = arg[pos + 1 ..],
                });
            } else {
                try namespaces.append(allocator, .{
                    .name = arg,
                });
            }
        }
    }

    options.namespaces = try namespaces.toOwnedSlice(allocator);
    options.include_dirs = try include_dirs.toOwnedSlice(allocator);
    return options;
}

pub fn deinit(self: CliOptions, allocator: Allocator) void {
    allocator.free(self.namespaces);
    allocator.free(self.include_dirs);
}
