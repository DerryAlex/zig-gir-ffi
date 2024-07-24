const std = @import("std");
const gtk = @import("gtk");
const glib = gtk.glib;
const gio = gtk.gio;

pub fn main() u8 {
    var app = gtk.Application.new("org.example.clock", .{});
    defer app.__call("unref", .{});
    _ = app.__call("connectActivate", .{ buildUi, .{}, .{} });
    return @intCast(app.__call("run", .{std.os.argv}));
}

pub fn buildUi(arg_app: *gio.Application) void {
    const app = arg_app.tryInto(gtk.Application).?;
    var window = gtk.ApplicationWindow.new(app);
    window.__call("setTitle", .{"Clock Example"});
    window.__call("setDefaultSize", .{ 260, 40 });
    var label = gtk.Label.new(null);
    _ = tick(label);
    _ = glib.timeoutAddSeconds(glib.PRIORITY_DEFAULT, 1, tick, .{label});
    window.__call("setChild", .{label.into(gtk.Widget)});
    window.__call("present", .{});
}

pub fn tick(label: *gtk.Label) bool {
    var time = std.time.timestamp();
    const s: u6 = @intCast(@mod(time, std.time.s_per_min));
    time = @divFloor(time, std.time.s_per_min);
    const min: u6 = @intCast(@mod(time, 60));
    time = @divFloor(time, 60);
    const hour: u5 = @intCast(@mod(time, 24));
    var buf: [13]u8 = undefined;
    const str = std.fmt.bufPrintZ(buf[0..], "{d:0>2}:{d:0>2}:{d:0>2}UTC", .{ hour, min, s }) catch @panic("No Space Left");
    label.setLabel(str);
    return true; // true to continue, false to stop
}
