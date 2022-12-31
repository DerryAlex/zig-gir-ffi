const std = @import("std");
pub const Gtk = @import("Gtk");
pub const core = @import("core");
const ExampleApp = @import("example_app.zig").ExampleApp;

pub fn main() void {
    var app = ExampleApp.new();
    _ = app.callMethod("run", .{std.os.argv});
}
