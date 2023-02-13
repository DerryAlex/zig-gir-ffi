# Zig GIR FFI

GObject binding for ziglang using Introspection Repository

You may download pre-generated code for GTK4 [here](https://github.com/DerryAlex/zig-gir-ffi/releases).

## Documentation

- [Examples](./example/)
- [Docs](./docs/)
- [GTK Documentation](https://docs.gtk.org/)
- [Zig Language Reference](https://ziglang.org/documentation/master/)

## Example

![example.png](./doc/img/example.png)

```zig
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
```
