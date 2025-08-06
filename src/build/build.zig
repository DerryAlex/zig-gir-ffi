const std = @import("std");

pub fn build(b: *std.Build) !void {
    const gi_mod = b.addModule("gi", .{ .root_source_file = b.path("gi.zig") });
    _ = gi_mod;
}
