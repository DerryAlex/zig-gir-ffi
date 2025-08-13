const std = @import("std");
const gi = @import("gi");
const GLib = gi.GLib;
const GObject = gi.GObject;
const Gio = gi.Gio;
const Gtk = gi.Gtk;

pub fn main() u8 {
    const _app: *Gtk.Application = .new("org.example.clock", .{});
    const app = _app.into(Gio.Application);
    defer app.into(GObject.Object).unref();
    _ = app._signals.activate.connect(.init(buildUi, .{}), .{});
    return @intCast(app.run(@ptrCast(std.os.argv)));
}

pub fn buildUi(arg_app: *Gio.Application) void {
    const app = arg_app.tryInto(Gtk.Application).?;
    const _window: *Gtk.ApplicationWindow = .new(app);
    const window = _window.into(Gtk.Window);
    window.setTitle("Clock Example");
    window.setDefaultSize(260, 40);
    var label: *Gtk.Label = .new(null);
    _ = tick(label);
    _ = GLib.timeoutAddSeconds(GLib.PRIORITY_DEFAULT, 1, .init(tick, .{label}));
    window.setChild(label.into(Gtk.Widget));
    window.present();
}

pub fn tick(label: *Gtk.Label) bool {
    var time = std.time.timestamp();
    const s: u6 = @intCast(@mod(time, std.time.s_per_min));
    time = @divFloor(time, std.time.s_per_min);
    const min: u6 = @intCast(@mod(time, 60));
    time = @divFloor(time, 60);
    const hour: u5 = @intCast(@mod(time, 24));
    var buf: [13]u8 = undefined;
    const str = std.fmt.bufPrintZ(buf[0..], "{d:0>2}:{d:0>2}:{d:0>2}UTC", .{ hour, min, s }) catch unreachable;
    label.setLabel(str);
    return true; // true to continue, false to stop
}
