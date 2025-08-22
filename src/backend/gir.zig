const std = @import("std");
const options = @import("options");
const gi = @import("../gi.zig");
const Repository = gi.Repository;
const loadGir = @import("gir/load.zig").loadGir;

/// Load `namespace` if it isn't ready.
pub fn load(self: *Repository, namespace: []const u8, version: ?[]const u8) Repository.Error!void {
    if (!options.has_gir) return error.FileNotFound;

    const default_search_path = "/usr/share/gir-1.0/";
    try self._search_paths.append(self.allocator, default_search_path);
    defer _ = self._search_paths.pop();

    const namespace_ = try std.mem.concat(self.allocator, u8, &.{ namespace, "-" });
    defer self.allocator.free(namespace_);

    const cwd = std.fs.cwd();
    for (self._search_paths.items) |search_path| {
        var dir = cwd.openDir(search_path, .{ .iterate = true }) catch continue;
        defer dir.close();
        var version_buffer: [8]u8 = undefined;
        const version_: []const u8 = if (version) |v| v else version: {
            var iter = dir.iterate();
            var ver: f32 = -1.0;
            var ver_str: []const u8 = &.{};
            while (iter.next() catch null) |entry| {
                if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".gir") and std.mem.startsWith(u8, entry.name, namespace_)) {
                    const v_str = entry.name[namespace_.len .. entry.name.len - 4];
                    const v = std.fmt.parseFloat(f32, v_str) catch -1.0;
                    if (v > ver) {
                        ver = v;
                        ver_str = std.fmt.bufPrint(&version_buffer, "{s}", .{v_str}) catch unreachable;
                    }
                }
            }
            if (ver != -1) break :version ver_str;
            continue;
        };
        const filename = try std.mem.concat(self.allocator, u8, &.{ namespace_, version_, ".gir" });
        defer self.allocator.free(filename);
        const file = dir.openFile(filename, .{}) catch continue;
        loadGir(self, file) catch @panic("");
        return;
    }
    return error.FileNotFound;
}
