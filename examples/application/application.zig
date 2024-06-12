const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const glib = gtk.glib;
const ExampleApp = @import("example_app.zig").ExampleApp;

pub const gi_configs: core.Configs = .{
    .disable_deprecated = false,
};

pub fn main() u8 {
    _ = glib.setenv("GSETTINGS_SCHEMA_DIR", ".", false);
    var app = ExampleApp.new();
    return @intCast(app.__call("run", .{std.os.argv}));
}
