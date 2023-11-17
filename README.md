# Zig GIR FFI

GObject Introspection for zig. Generated [GTK4 binding](https://github.com/DerryAlex/zig-gir-ffi/releases) can be downloaded.

## Documentation

- [Examples](./example)
- [GTK Documentation](https://docs.gtk.org/)
- [Zig Language Reference](https://ziglang.org/documentation/master/)

## Example

![example.png](./example/example/screenshot.png)

```zig
pub fn printHello() void {
    std.log.info("Hello World", .{});
}

pub fn activate(arg_app: *GApplication) void {
    var app = arg_app.tryInto(Application).?;
    var window = ApplicationWindow.new(app);
    window.__call("setTitle", .{"Window"});
    window.__call("setDefaultSize", .{ 200, 200 });
    var box = Box.new(.Vertical, 0);
    box.__call("setHalign", .{.Center});
    box.__call("setValign", .{.Center});
    window.__call("setChild", .{box.into(Widget)});
    var button = Button.newWithLabel("Hello, World");
    _ = button.connectClicked(printHello, .{}, .{});
    _ = button.connectClickedSwap(Window.destroy, .{window.into(Window)}, .{});
    box.append(button.into(Widget));
    window.__call("show", .{});
}

pub fn main() u8 {
    var app = Application.new("org.gtk.example", .FlagsNone);
    defer app.__call("unref", .{});
    _ = app.__call("connectActivate", .{activate, .{}, .{}});
    return @intCast(app.__call("run", .{std.os.argv}));
}
```
