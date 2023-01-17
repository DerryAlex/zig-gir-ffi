const std = @import("std");
const Gtk = @import("Gtk");
const core = Gtk.core;

pub fn printHello() void {
    std.log.info("Hello World", .{});
}

pub fn activate(arg_app: core.Application) void {
    var app = arg_app.tryInto(Gtk.Application).?;
    var builder = Gtk.Builder.new();
    defer builder.callMethod("unref", .{});
    switch (builder.addFromFile("builder.ui")) {
        .Ok => |_| {},
        .Err => |err| {
            defer err.free();
            std.log.warn("{s}", .{err.message.?});
            return;
        },
    }
    var window = builder.getObject("window").expect("window").tryInto(Gtk.Window).?;
    window.setApplication(app.asSome());
    var button1 = builder.getObject("button1").expect("button1").tryInto(Gtk.Button).?;
    _ = button1.signalClicked().connect(printHello, .{}, .{ .swapped = true });
    var button2 = builder.getObject("button2").expect("button2").tryInto(Gtk.Button).?;
    _ = button2.signalClicked().connect(printHello, .{}, .{ .swapped = true });
    var quit = builder.getObject("quit").expect("quit").tryInto(Gtk.Button).?;
    _ = quit.signalClicked().connect(Gtk.Window.destroy, .{window}, .{ .swapped = true });
    window.callMethod("show", .{});
}

pub fn main() !void {
    var app = Gtk.Application.new("org.gtk.example", .FlagsNone);
    defer app.callMethod("unref", .{});
    _ = app.callMethod("signalActivate", .{}).connect(activate, .{}, .{});
    _ = app.callMethod("run", .{std.os.argv});
}
