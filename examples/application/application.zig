const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const glib = gtk.glib;
const ExampleApp = @import("example_app.zig").ExampleApp;

pub fn main() u8 {
    _ = glib.setenv("GSETTINGS_SCHEMA_DIR", ".", false);
    var app = ExampleApp.new();
    return @intCast(app.__call("run", .{@as([][*:0]const u8, @ptrCast(std.os.argv))}));
}
