const std = @import("std");
const gi = @import("gi");
const Gio = gi.Gio;
const Gtk = gi.Gtk;
const Application = Gtk.Application;
const ApplicationWindow = Gtk.ApplicationWindow;
const Box = Gtk.Box;
const Button = Gtk.Button;
const Object = gi.GObject.Object;
const Widget = Gtk.Widget;
const Window = Gtk.Window;

pub fn printHello() void {
    std.log.info("Hello World", .{});
}

pub fn activate(app: *Gio.Application) void {
    const _window: *ApplicationWindow = .new(app.tryInto(Application).?);
    const window = _window.into(Window);
    window.setTitle("Window");
    window.setDefaultSize(200, 200);
    const box: *Box = .new(.vertical, 0);
    box.into(Widget).setHalign(.center);
    box.into(Widget).setValign(.center);
    window.setChild(box.into(Widget));
    const button = Button.newWithLabel("Hello, World");
    _ = button._signals.clicked.connect(.init(printHello, .{}), .{});
    _ = button._signals.clicked.connect(.init(Window.destroy, .{window}), .{});
    box.append(button.into(Widget));
    window.present();
}

pub fn main() u8 {
    const _app: *Application = .new("org.gtk.example", .{});
    const app = _app.into(Gio.Application);
    defer app.into(Object).unref();
    _ = app._signals.activate.connect(.init(activate, .{}), .{});
    return @intCast(app.run(@ptrCast(std.os.argv)));
}
