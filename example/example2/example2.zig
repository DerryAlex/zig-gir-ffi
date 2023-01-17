const std = @import("std");
const Gtk = @import("Gtk");
const core = Gtk.core;

pub fn printHello() void {
    std.log.info("Hello World", .{});
}

pub fn activate(arg_app: core.Application) void {
    var app = arg_app.tryInto(Gtk.Application).?;
    var window = Gtk.ApplicationWindow.new(app);
    window.callMethod("setTitle", .{"Window"});
    var grid = Gtk.Grid.new();
    window.callMethod("setChild", .{grid.into(Gtk.Widget).asSome()});
    var button1 = Gtk.Button.newWithLabel("Button 1");
    _ = button1.signalClicked().connect(printHello, .{}, .{ .swapped = true });
    grid.attach(button1.into(Gtk.Widget), 0, 0, 1, 1);
    var button2 = Gtk.Button.newWithLabel("Button 2");
    _ = button2.signalClicked().connect(printHello, .{}, .{ .swapped = true });
    grid.attach(button2.into(Gtk.Widget), 1, 0, 1, 1);
    var quit = Gtk.Button.newWithLabel("Quit");
    _ = quit.signalClicked().connect(Gtk.Window.destroy, .{window.into(Gtk.Window)}, .{ .swapped = true });
    grid.attach(quit.into(Gtk.Widget), 0, 1, 2, 1);
    window.callMethod("show", .{});
}

pub fn main() !void {
    var app = Gtk.Application.new("org.gtk.example", .FlagsNone);
    defer app.callMethod("unref", .{});
    _ = app.callMethod("signalActivate", .{}).connect(activate, .{}, .{});
    _ = app.callMethod("run", .{std.os.argv});
}
