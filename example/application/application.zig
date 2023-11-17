const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const ExampleApp = @import("example_app.zig").ExampleApp;

pub fn main() u8 {
    _ = core.setenv("GSETTINGS_SCHEMA_DIR", ".", false);
    var app = ExampleApp.new();
    return @intCast(app.__call("run", .{std.os.argv}));
}
