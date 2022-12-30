const std = @import("std");
const Gtk = @import("Gtk");
const core = @import("core");

pub fn printHello() void {
    std.log.info("Hello World", .{});
}

pub fn activate(arg_app: core.Application) void {
    var app = core.downCast(Gtk.Application, arg_app).?;
    var builder = Gtk.Builder.new();
    defer builder.callMethod("unref", .{});
    switch (builder.callMethod("addFromFile", .{"builder.ui"})) {
        .Ok => |_| {},
        .Err => |err| {
            defer err.free();
            std.log.warn("{s}", .{err.instance.Message});
            return;
        },
    }
    var window = core.downCast(Gtk.Window, builder.callMethod("getObject", .{"window"}).get().?).?;
    window.callMethod("setApplication", .{Gtk.ApplicationNullable.new(app)});
    var button1 = core.downCast(Gtk.Button, builder.callMethod("getObject", .{"button1"}).get().?).?;
    button1.callMethod("signalClicked", .{}).connect(printHello, .{}, .{ .swapped = true });
    var button2 = core.downCast(Gtk.Button, builder.callMethod("getObject", .{"button2"}).get().?).?;
    button2.callMethod("signalClicked", .{}).connect(printHello, .{}, .{ .swapped = true });
    var quit = core.downCast(Gtk.Button, builder.callMethod("getObject", .{"quit"}).get().?).?;
    quit.callMethod("signalClicked", .{}).connect(Gtk.Window.destroy, .{window}, .{ .swapped = true });
    window.callMethod("show", .{});
}

pub fn main() !void {
    var app = Gtk.Application.new("org.gtk.example", .FlagsNone);
    defer app.callMethod("unref", .{});
    app.callMethod("signalActivate", .{}).connect(activate, .{}, .{});
    _ = app.callMethod("run", .{std.os.argv});
}
