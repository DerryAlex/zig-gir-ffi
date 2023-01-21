const std = @import("std");
pub const Gtk = @import("Gtk");
const core = Gtk.core;
const CustomButton = @import("custom_button.zig").CustomButton;

pub fn main() void {
    var app = Gtk.Application.new("org.zig_gir.custom_button", .FlagsNone);
    _ = app.callMethod("signalActivate", .{}).connect(buildUi, .{}, .{});
    _ = app.callMethod("run", .{std.os.argv});
}

pub fn buildUi(arg_app: core.Application) void {
    var app = arg_app.tryInto(Gtk.Application).?;
    var button = CustomButton.new();
    _ = button.signalZeroReached().connect(numberReset, .{}, .{});
    var box = Gtk.Box.new(.Vertical, 12);
    box.append(button.into(Gtk.Widget));
    var window = Gtk.ApplicationWindow.new(app);
    window.callMethod("setChild", .{box.into(Gtk.Widget).asSome()});
    window.callMethod("present", .{});
}

pub fn numberReset(button: CustomButton) void {
    button.propertyNumber().set(10);
}
