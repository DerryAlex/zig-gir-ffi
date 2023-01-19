### Basics

```zig
const std = @import("std");
const Gtk = @import("Gtk");
const core = Gtk.core;

pub fn printHello() void {
    std.log.info("Hello World", .{});
}

pub fn activate(arg_app: core.Application) void {
    var app = arg_app.tryInto(Gtk.Application).?;
    var window = Gtk.ApplicationWindow.new(app);
    window.callMethod("setTitle", .{"Window"});
    window.callMethod("setDefaultSize", .{ 200, 200 });
    var box = Gtk.Box.new(.Vertical, 0);
    box.callMethod("setHalign", .{.Center});
    box.callMethod("setValign", .{.Center});
    window.callMethod("setChild", .{box.into(Gtk.Widget).asSome()});
    var button = Gtk.Button.newWithLabel("Hello, World");
    _ = button.signalClicked().connect(printHello, .{}, .{ .swapped = true });
    _ = button.signalClicked().connect(Gtk.Window.destroy, .{window.into(Gtk.Window)}, .{ .swapped = true });
    box.append(button.into(Gtk.Widget));
    window.callMethod("show", .{});
}

pub fn main() !void {
    var app = Gtk.Application.new("org.gtk.example", .FlagsNone);
    defer app.callMethod("unref", .{});
    _ = app.callMethod("signalActivate", .{}).connect(activate, .{}, .{});
    _ = app.callMethod("run", .{std.os.argv});
}
```

`Application.new` creates an application. `tryInto` downcasts `Gio.Application` to `Application`. (`tryInto` may fail. User should check whether return value is `null`.) `callMethod` dispatches `setChild` to `Window.setChild(self, child: WidgetNullable) void` comptime. `WigdetNullable` is a wrapper of `?*WidgetImpl` for C ABI compatibility. `into` upcasts `Box` to `Widget` and `asSome` converts `Widget` to `WidgetNullable`. (`wrap` converts `WidgetNullable` to `?Widget`. If app should panic when wrapping `null`, use `expect` instead.)

`signalActivate` creates an proxy for signal `activate` (of object `app`). `connect` connects the signal to a type-safe handler `activate`. (Set `swapped` flag to `true` if the handler takes only custom arguments. Set `after` flag to `true` if the handler should be called after the default handler.) NOTE: memory allocation is done implicity without asking an allocator, which is anti-pattern in zig. The allocated memory will be freed automatically once the object is destroyed.
