const std = @import("std");
pub const Gtk = @import("Gtk");
const core = Gtk.core;

pub fn main() u8 {
    var app = Gtk.Application.new("org.example.clock", .FlagsNone);
    defer app.__call("unref", .{});
    _ = app.__call("connectActivate", .{ buildUi, .{}, .{} });
    return @truncate(u8, @bitCast(u32, app.__call("run", .{std.os.argv})));
}

pub fn buildUi(arg_app: *core.Application) void {
    var app = arg_app.tryInto(Gtk.Application).?;
    var window = Gtk.ApplicationWindow.new(app);
    window.__call("setTitle", .{"Clock Example"});
    window.__call("setDefaultSize", .{ 260, 40 });
    var label = Gtk.Label.new(null);
    _ = tick(label);
    _ = core.timeoutAddSeconds(core.PRIORITY_DEFAULT, 1, tick, .{label});
    window.__call("setChild", .{label.into(Gtk.Widget)});
    window.__call("present", .{});
}

pub fn tick(label: *Gtk.Label) bool {
    var time = std.time.timestamp();
    const s: u6 = @intCast(u6, @mod(time, std.time.s_per_min));
    time = @divFloor(time, std.time.s_per_min);
    const min: u6 = @intCast(u6, @mod(time, 60));
    time = @divFloor(time, 60);
    const hour: u5 = @intCast(u5, @mod(time, 24));
    var buf: [13]u8 = undefined;
    const str = std.fmt.bufPrintZ(buf[0..], "{d:0>2}:{d:0>2}:{d:0>2}UTC", .{ hour, min, s }) catch @panic("No Space Left");
    label.setLabel(str);
    return true; // true to continue, false to stop
}
