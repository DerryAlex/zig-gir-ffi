const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const CustomButton = @import("custom_button.zig").CustomButton;
const Application = gtk.Application;
const ApplicationWindow = gtk.ApplicationWindow;
const Box = gtk.Box;
const Widget = gtk.Widget;
const GApplication = core.Application;

pub fn main() u8 {
    var app = Application.new("org.example.custom_button", .FlagsNone);
    defer app.__call("unref", .{});
    _ = app.__call("connectActivate", .{ activate, .{}, .{} });
    return @intCast(app.__call("run", .{std.os.argv}));
}

pub fn activate(arg_app: *GApplication) void {
    var app = arg_app.tryInto(Application).?;
    var window = ApplicationWindow.new(app);
    var box = Box.new(.Vertical, 12);
    window.__call("setChild", .{box.into(Widget)});
    var button = CustomButton.new();
    _ = button.connectZeroReached(CustomButton.setNumber, .{10}, .{});
    box.append(button.into(Widget));
    window.__call("present", .{});
}
