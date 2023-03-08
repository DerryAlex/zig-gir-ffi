# Zig GIR

GObject Introspection Repository binding for zig

Generated [GTK4 binding](https://github.com/DerryAlex/zig-gir-ffi/releases) can be downloaded.

**Note**: We are migrating to new generator written in zig.

Major changes:

- Wrapper for callback. `CellArea.foreach(self, CellCallback, ?*anyopaque)` becomes `CellArea.foreach(self, func, args)`. `func` can be `fn () void`, `fn (*CellRender) void` or `fn (*CellRender, args...) void`(Checked at comptime for signal type safety).
- Drop awkward `WidgetNullable` wrapper. `*Widget` and `?*Widget` is used.
- Generator is written in zig instead of C.
- (WIP) Better custom widget.
- (WIP) Better signal. (Partially done) You can ignore part of parameters in signal signatures. (Custom signal coming back soon)

## Documentation

- Docs and Examples(Coming back soon)
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

pub fn main() !void {
    var app = Application.new("org.gtk.example", .FlagsNone);
    defer app.__call("unref", .{});
    _ = app.__call("connectActivate", .{activate, .{}, .{}});
    _ = app.__call("run", .{std.os.argv});
}
```
