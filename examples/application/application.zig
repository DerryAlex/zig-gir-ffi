const std = @import("std");
const gi = @import("gi");
const core = gi.core;
const GLib = gi.GLib;
const Gio = gi.Gio;
const ExampleApp = @import("example_app.zig").ExampleApp;

pub fn main() u8 {
    _ = GLib.setenv("GSETTINGS_SCHEMA_DIR", ".", false);
    const _app: *ExampleApp = .new();
    const app = _app.into(Gio.Application);
    return @intCast(app.run(@ptrCast(std.os.argv)));
}
