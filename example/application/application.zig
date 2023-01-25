const std = @import("std");
pub const Gtk = @import("Gtk");
const core = Gtk.core;
const ExampleApp = @import("example_app.zig").ExampleApp;

pub fn main() void {
    _ = core.setenv("GSETTINGS_SCHEMA_DIR", ".", .False);
    var app = ExampleApp.new();
    _ = app.callMethod("run", .{std.os.argv});
}
