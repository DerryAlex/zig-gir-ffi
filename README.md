# Zig GIR FFI

GObject Introspection for zig. Generated [GTK4 binding](https://github.com/DerryAlex/zig-gir-ffi/releases) can be downloaded.

## Documentation

- [Custom Widget](./doc/custom_widget/)
- WIP
- [GTK Documentation](https://docs.gtk.org/)
- [Zig Language Reference](https://ziglang.org/documentation/master/)

## Example

![example.png](./example/example/screenshot.png)

```zig
pub fn printHello() void {
    std.log.info("Hello World", .{});
}

pub fn activate(arg_app: *GApplication) void {
    // `into` and `tryInto` are one-line wrappers for `downCast` and `upCast`
    var app = arg_app.tryInto(Application).?;
    var window = ApplicationWindow.new(app);
    // Set property `Gtk.Window:title`
    window.__call("setTitle", .{"Window"});
    window.__call("setDefaultSize", .{ 200, 200 });
    var box = Box.new(.Vertical, 0);
    box.__call("setHalign", .{.Center});
    box.__call("setValign", .{.Center});
    window.__call("setChild", .{box.into(Widget)});
    var button = Button.newWithLabel("Hello, World");
    _ = button.connectClicked(printHello, .{}, .{});
    // Swapped connect allows callback of `fn (args...) void` for any signal
    // No need to write a wrapper `fn (*Button, *Window) void`
    _ = button.connectClickedSwap(Window.destroy, .{window.into(Window)}, .{});
    box.append(button.into(Widget));
    window.__call("show", .{});
}

pub fn main() u8 {
    var app = Application.new("org.gtk.example", .FlagsNone);
    // `__call` is a comptime dispatcher, `GObject.unref` will be called runtime
    defer app.__call("unref", .{});
    // Connect callback `activate` to signal `GApplication::activate`
    // Type-safety of callback will be checked
    // e.g. signature of signal `activate` is `fn (*GApplication) void`
    // callback must be `fn () void`, `fn (*GApplication) void`
    // or `fn (*GApplication, args...) void`
    _ = app.__call("connectActivate", .{activate, .{}, .{}});
    return @truncate(u8, @bitCast(u32, app.__call("run", .{std.os.argv})));
}
```
