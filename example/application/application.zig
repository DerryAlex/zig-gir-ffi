const std = @import("std");
pub const Gtk = @import("Gtk");
const core = Gtk.core;
const ExampleApp = @import("example_app.zig").ExampleApp;

pub fn main() u8 {
    _ = core.setenv("GSETTINGS_SCHEMA_DIR", ".", false);
    var app = ExampleApp.new();
    return @intCast(app.__call("run", .{std.os.argv}));
}
