const std = @import("std");
pub const Gtk = @import("Gtk");
const core = Gtk.core;
const CustomButton = @import("custom_button2.zig").CustomButton;

pub fn main() void {
    var app = Gtk.Application.new("org.zig_gir.custom_button", .FlagsNone);
    defer app.callMethod("unref", .{});
    _ = app.callMethod("signalActivate", .{}).connect(buildUi, .{}, .{});
    _ = app.callMethod("run", .{std.os.argv});
}

pub fn buildUi(arg_app: core.Application) void {
    var app = arg_app.tryInto(Gtk.Application).?;
    var window = Gtk.ApplicationWindow.new(app);
    var box = Gtk.Box.new(.Vertical, 12);
    window.callMethod("setChild", .{box.into(Gtk.Widget).asSome()});
    var button = CustomButton.new();
    box.append(button.into(Gtk.Widget));
    _ = button.signalZeroReached().connect(numberReset, .{}, .{});
    window.callMethod("present", .{});
}

pub fn numberReset(button: CustomButton) void {
    button.propertyNumber().set(10);
}
