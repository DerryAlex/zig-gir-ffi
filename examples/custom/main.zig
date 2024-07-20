const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const CustomButton = @import("custom_button.zig").CustomButton;
const Application = gtk.Application;
const ApplicationWindow = gtk.ApplicationWindow;
const Box = gtk.Box;
const Widget = gtk.Widget;
const gio = gtk.gio;
const GApplication = gio.Application;

pub fn main() u8 {
    var app = Application.new("org.example.custom_button", .{});
    defer app.__method__().invoke("unref", .{});
    _ = app.__method__().invoke("connectActivate", .{ activate, .{}, .{} });
    return @intCast(app.__method__().invoke("run", .{std.os.argv}));
}

pub fn activate(arg_app: *GApplication) void {
    const app = arg_app.tryInto(Application).?;
    var window = ApplicationWindow.new(app);
    var box = Box.new(.vertical, 12);
    window.__method__().invoke("setChild", .{box.into(Widget)});
    var button = CustomButton.new();
    _ = button.connectZeroReached(CustomButton.setNumber, .{10}, .{});
    box.append(button.into(Widget));
    window.__method__().invoke("present", .{});
}
