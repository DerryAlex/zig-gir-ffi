const std = @import("std");
const gi = @import("gi");
const GObject = gi.GObject;
const Gio = gi.Gio;
const Gtk = gi.Gtk;
const Application = Gtk.Application;
const ApplicationWindow = Gtk.ApplicationWindow;
const Box = Gtk.Box;
const Button = Gtk.Button;
const Object = GObject.Object;
const Widget = Gtk.Widget;
const Window = Gtk.Window;

pub fn printHello() void {
    std.log.info("Hello World", .{});
}

pub fn activate(app: *Gio.Application) void {
    var _window: *ApplicationWindow = .new(app.tryInto(Application).?);
    var window = _window.into(Window);
    window.setTitle("Window");
    window.setDefaultSize(200, 200);
    var box: *Box = .new(.vertical, 0);
    box.into(Widget).setHalign(.center);
    box.into(Widget).setValign(.center);
    window.setChild(box.into(Widget));
    var button = Button.newWithLabel("Hello, World");
    _ = button._signals.clicked.connect(.init(printHello, .{}), .{});
    _ = button._signals.clicked.connect(.init(Window.destroy, .{window}), .{ .swapped = true });
    box.append(button.into(Widget));
    window.present();
}

pub fn main() u8 {
    var _app: *Application = .new("org.gtk.example", .{});
    var app = _app.into(Gio.Application);
    defer app.into(Object).unref();
    _ = app._signals.activate.connect(.init(activate, .{}), .{});
    return @intCast(app.run(@ptrCast(std.os.argv)));
}
