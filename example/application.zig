const std = @import("std");
pub const Gtk = @import("Gtk");
pub const core = @import("core");
const ExampleApp = @import("example_app.zig").ExampleApp;

pub fn main() void {
    _ = core.setenv("GSETTINGS_SCHEMA_DIR", ".", core.Boolean.False);
    var app = ExampleApp.new();
    _ = app.callMethod("run", .{std.os.argv});
}
