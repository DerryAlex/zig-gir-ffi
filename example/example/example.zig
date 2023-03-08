const std = @import("std");
const Gtk = @import("Gtk");
const core = Gtk.core;
const Application = Gtk.Application;
const ApplicationWindow = Gtk.ApplicationWindow;
const Box = Gtk.Box;
const Button = Gtk.Button;
const Widget = Gtk.Widget;
const Window = Gtk.Window;
const GApplication = core.Application;

pub fn printHello() void {
    std.log.info("Hello World", .{});
}

pub fn activate(arg_app: *GApplication) void {
    var app = arg_app.tryInto(Application).?;
    var window = ApplicationWindow.new(app);
    window.__call("setTitle", .{"Window"});
    window.__call("setDefaultSize", .{ 200, 200 });
    var box = Box.new(.Vertical, 0);
    box.__call("setHalign", .{.Center});
    box.__call("setValign", .{.Center});
    window.__call("setChild", .{box.into(Widget)});
    var button = Button.newWithLabel("Hello, World");
    _ = button.connectClicked(printHello, .{}, .{});
    _ = button.connectClickedSwap(Window.destroy, .{window.into(Window)}, .{});
    box.append(button.into(Widget));
    window.__call("show", .{});
}

pub fn main() !void {
    var app = Application.new("org.gtk.example", .FlagsNone);
    defer app.__call("unref", .{});
    _ = app.__call("connectActivate", .{activate, .{}, .{}});
    _ = app.__call("run", .{std.os.argv});
}
