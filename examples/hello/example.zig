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

pub fn activate(app: *GApplication) void {
    var window = ApplicationWindow.new(app.tryInto(Application).?).into(Window);
    window.setTitle("Window");
    window.setDefaultSize(200, 200);
    var box = Box.new(.vertical, 0);
    var box_as_widget = box.into(Widget);
    box_as_widget.setHalign(.center);
    box_as_widget.setValign(.center);
    window.setChild(box_as_widget);
    var button = Button.newWithLabel("Hello, World");
    _ = button.connectClicked(printHello, .{}, .{});
    _ = button.connectClicked(Window.destroy, .{window}, .{ .swapped = true });
    box.append(button.into(Widget));
    window.present();
}

pub fn main() u8 {
    var app = Application.new("org.gtk.example", .{}).into(GApplication);
    defer app.__method__().invoke("unref", .{});
    _ = app.connectActivate(activate, .{}, .{});
    return @intCast(app.run(std.os.argv));
}
