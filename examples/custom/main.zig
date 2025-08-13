const std = @import("std");
const gi = @import("gi");
const core = gi.core;
const Gio = gi.Gio;
const Gtk = gi.Gtk;
const CustomButton = @import("custom_button.zig").CustomButton;
const Application = Gtk.Application;
const ApplicationWindow = Gtk.ApplicationWindow;
const Box = Gtk.Box;
const Button = Gtk.Button;
const Object = gi.GObject.Object;
const Widget = Gtk.Widget;
const Window = Gtk.Window;

pub fn main() u8 {
    const _app: *Application = .new("org.example.custom_button", .{});
    const app = _app.into(Gio.Application);
    defer app.into(Object).unref();
    _ = app._signals.activate.connect(.init(activate, .{}), .{});
    return @intCast(app.run(@ptrCast(std.os.argv)));
}

pub fn activate(arg_app: *Gio.Application) void {
    const app = arg_app.tryInto(Application).?;
    const _window: *ApplicationWindow = .new(app);
    const window = _window.into(Window);
    const box: *Box = .new(.vertical, 12);
    window.setChild(box.into(Widget));
    const button: *CustomButton = .new();
    _ = button.zero_reached.connect(.init(CustomButton.setNumber, .{10}), .{});
    box.append(button.into(Widget));
    window.present();
}
