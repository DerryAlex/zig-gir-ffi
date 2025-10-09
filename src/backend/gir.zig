const std = @import("std");
const StringArrayHashMap = std.StringArrayHashMapUnmanaged;
const options = @import("options");
const gi = @import("../gi.zig");
const Repository = gi.Repository;
const Scanner = @import("gir/Scanner.zig");
const Parser = @import("gir/Parser.zig");

/// Load `namespace` if it isn't ready.
pub fn load(self: *Repository, namespace: []const u8, version: ?[]const u8) Repository.Error!void {
    if (!options.has_gir) return error.FileNotFound;

    const default_search_path = "/usr/share/gir-1.0/";
    var search_paths = try self.search_paths.clone(self.allocator);
    defer search_paths.deinit(self.allocator);
    try search_paths.append(self.allocator, default_search_path);

    const namespace_ = try std.mem.concat(self.allocator, u8, &.{ namespace, "-" });
    defer self.allocator.free(namespace_);

    const cwd = std.fs.cwd();
    for (search_paths.items) |search_path| {
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
        std.log.debug("gir backend: loading {s}", .{namespace});
        var buffer: [4096]u8 = undefined;
        var reader = file.reader(&buffer);
        var scanner: Scanner = .init(&reader.interface);
        var parser: Parser = .init(&scanner);
        const loaded_namespace = parser.parse(self.allocator) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => {
                std.log.debug("gir backend: fail to load {s}", .{namespace});
                return error.FileNotFound;
            },
        };
        try self.namespaces.put(self.allocator, namespace, loaded_namespace);
        std.log.debug("gir backend: loaded {s}", .{namespace});
        for (loaded_namespace.dependencies.items) |dep| try self.load(dep, null);
        // transive dependency
        var dependencies: StringArrayHashMap(void) = try .init(self.allocator, loaded_namespace.dependencies.items, &.{});
        defer dependencies.deinit(self.allocator);
        var idx: usize = 0;
        while (idx < dependencies.count()) : (idx += 1) {
            const dep = dependencies.keys()[idx];
            const dep_ns = self.namespaces.get(dep).?;
            for (dep_ns.dependencies.items) |d| {
                if (!dependencies.contains(d)) try dependencies.put(self.allocator, d, {});
            }
        }
        var namespace_ptr = self.namespaces.getPtr(namespace).?;
        try namespace_ptr.dependencies.appendSlice(self.allocator, dependencies.keys()[namespace_ptr.dependencies.items.len..]);
        return;
    }
    std.log.debug("gir backend: fail to load {s}", .{namespace});
    return error.FileNotFound;
}
