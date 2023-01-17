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
    window.callMethod("setDefaultSize", .{ 200, 200 });
    var box = Gtk.Box.new(.Vertical, 0);
    box.callMethod("setHalign", .{.Center});
    box.callMethod("setValign", .{.Center});
    window.callMethod("setChild", .{box.into(Gtk.Widget).asSome()});
    var button = Gtk.Button.newWithLabel("Hello, World");
    _ = button.signalClicked().connect(printHello, .{}, .{ .swapped = true });
    _ = button.signalClicked().connect(Gtk.Window.destroy, .{window.into(Gtk.Window)}, .{ .swapped = true });
    box.append(button.into(Gtk.Widget));
    window.callMethod("show", .{});
}

pub fn main() !void {
    var app = Gtk.Application.new("org.gtk.example", .FlagsNone);
    defer app.callMethod("unref", .{});
    _ = app.callMethod("signalActivate", .{}).connect(activate, .{}, .{});
    _ = app.callMethod("run", .{std.os.argv});
}
