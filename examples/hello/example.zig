const std = @import("std");
const gtk = @import("gtk");
const Application = gtk.Application;
const ApplicationWindow = gtk.ApplicationWindow;
const Box = gtk.Box;
const Button = gtk.Button;
const Widget = gtk.Widget;
const Window = gtk.Window;
const gio = gtk.gio;
const GApplication = gio.Application;

pub fn printHello() void {
    std.log.info("Hello World", .{});
}

pub fn activate(arg_app: *GApplication) void {
    const app = arg_app.tryInto(Application).?;
    var window = ApplicationWindow.new(app);
    window.__call("setTitle", .{"Window"});
    window.__call("setDefaultSize", .{ 200, 200 });
    var box = Box.new(.vertical, 0);
    box.__call("setHalign", .{.center});
    box.__call("setValign", .{.center});
    window.__call("setChild", .{box.into(Widget)});
    var button = Button.newWithLabel("Hello, World");
    _ = button.connectClicked(printHello, .{}, .{});
    _ = button.connectClicked(Window.destroy, .{window.into(Window)}, .{ .swapped = true });
    box.append(button.into(Widget));
    window.__call("setVisible", .{true});
}

pub fn main() u8 {
    var app = Application.new("org.gtk.example", .{});
    defer app.__call("unref", .{});
    _ = app.__call("connectActivate", .{ activate, .{}, .{} });
    return @intCast(app.__call("run", .{std.os.argv}));
}