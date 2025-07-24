const std = @import("std");
const gi = @import("../gi.zig");
const Repository = gi.Repository;

/// Load `namespace` if it isn't ready.
pub fn load(self: *Repository, namespace: []const u8, version: ?[]const u8) Repository.Error!void {
    _ = self;
    _ = namespace;
    _ = version;
    return error.FileNotFound;
}
