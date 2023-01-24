const std = @import("std");
pub const Gtk = @import("Gtk");
const core = Gtk.core;

pub fn main() void {
    var app = Gtk.Application.new("org.zig_gir.clock", .FlagsNone);
    defer app.callMethod("unref", .{});
    _ = app.callMethod("signalActivate", .{}).connect(buildUi, .{}, .{});
    _ = app.callMethod("run", .{std.os.argv});
}

pub fn buildUi(arg_app: core.Application) void {
    var app = arg_app.tryInto(Gtk.Application).?;
    var window = Gtk.ApplicationWindow.new(app);
    window.callMethod("setTitle", .{"Clock Example"});
    window.callMethod("setDefaultSize", .{ 260, 40 });
    var label = Gtk.Label.new(null);
    _ = tick(label);
    var closure = core.createClosure(&tick, .{label}, false, &[_]type{core.Boolean});
    _ = core.timeoutAddSeconds(core.PRIORITY_DEFAULT, 1, closure.invoke_fn(), closure, closure.deinit_fn());
    window.callMethod("setChild", .{label.into(Gtk.Widget).asSome()});
    window.callMethod("present", .{});
}

pub fn tick(label: Gtk.Label) core.Boolean {
    var time = core.DateTime.newNowLocal().?;
    defer time.unref();
    var str = time.formatIso8601().?;
    defer core.freeDiscardConst(str);
    label.setLabel(str);
    return .True; // true to continue, false to stop
}
