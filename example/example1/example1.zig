const std = @import("std");
const Gtk = @import("Gtk");
const core = Gtk.core;

pub fn printHello() void {
    std.log.info("Hello World", .{});
}

pub fn activate(arg_app: *core.Application) void {
    var app = arg_app.tryInto(Gtk.Application).?;
    var window = Gtk.ApplicationWindow.new(app);
    window.callZ("setTitle", .{"Window"});
    window.callZ("setDefaultSize", .{ 200, 200 });
    var box = Gtk.Box.new(.Vertical, 0);
    box.callZ("setHalign", .{.Center});
    box.callZ("setValign", .{.Center});
    window.callZ("setChild", .{box.into(Gtk.Widget)});
    var button = Gtk.Button.newWithLabel("Hello, World");
    _ = button.signalClicked().connectSwap(printHello, .{}, .{});
    _ = button.signalClicked().connectSwap(Gtk.Window.destroy, .{window.into(Gtk.Window)}, .{});
    box.append(button.into(Gtk.Widget));
    window.callZ("show", .{});
}

pub fn main() !void {
    var app = Gtk.Application.new("org.gtk.example", .FlagsNone);
    defer app.callZ("unref", .{});
    _ = app.callZ("signalActivate", .{}).connect(activate, .{}, .{});
    _ = app.callZ("run", .{@intCast(i32, std.os.argv.len), std.os.argv.ptr});
}
