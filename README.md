# Zig GIR FFI

GObject Introspection for zig. Generated [GTK4 binding](https://github.com/DerryAlex/zig-gir-ffi/releases) can be downloaded.

###### Zig compatibility

Before zig reaches 1.0,

1. Be compatible with zig stable, say 0.x

2. Try to be compatible with zig master, or 0.(x+1)+dev

> **Warning**
> Only pre-releases targeting zig 0.x and 0.(x-1) are guarenteed to be kept.

###### Table of Contents

- [Usage](#usage)

- [Usage of Bindings](#usage-of-bindings)

- [Contributing](#contributing)

## Usage

```bash
# generate bindings for Gtk
zig build run -- -N Gtk
# generate bindings for Gtk-3.0
zig build run -- -N Gtk -V 3.0
# display help
zig build run -- --help
```

## Usage of Bindings

Run `zig fetch --save=gtk4 https://url/to/bindings.tar.gz` and add the following lines to your `build.zig`. For more information, refer to [Zig Build System](https://ziglang.org/learn/build-system/).

```zig
const gtk = b.dependency("gtk4", .{});
exe.root_module.addImport("gtk", gtk.module("gtk"));
```

### Examples

- [application](examples/application) : Port of [Gtk - 4.0: Getting Started with GTK](https://docs.gtk.org/gtk4/getting_started.html), a relatively comprehensive example

- [hello](examples/hello) : A simple example  
  
  ```zig
  pub fn printHello() void {
    std.log.info("Hello World", .{});
  }
  pub fn activate(app: *GApplication) void {
    var window = ApplicationWindow.new(app.tryInto(Application).?).into(Window);
    window.setTitle("Window");
    window.setDefaultSize(200, 200);
    var box = Box.new(.vertical, 0);
    var box_as_widget = box.into(Widget);
    box_as_widget.setHalign(.center);
    box_as_widget.setValign(.center);
    window.setChild(box_as_widget);
    var button = Button.newWithLabel("Hello, World");
    _ = button.connectClicked(printHello, .{}, .{});
    _ = button.connectClicked(Window.destroy, .{window}, .{ .swapped = true });
    box.append(button.into(Widget));
    window.present();
  }
  pub fn main() u8 {
    var app = Application.new("org.gtk.example", .{}).into(GApplication);
    defer app.__call("unref", .{});
    _ = app.connectActivate(activate, .{}, .{});
    return @intCast(app.run(std.os.argv));
  }
  ```
  
  ![](examples/hello/screenshot.png)

- [clock](examples/clock) : (Implicit) use of the main context

- [custom](examples/custom) : Custom widget

- [interface](examples/interface) : Define interface

### Object Interface

```zig
pub fn into(*Self, T) *T; // comptime-checked upcast
pub fn tryInto(*Self, T) ?*T; // runtime-checked downcast
```

```zig
pub fn connect(*Self, signal, handler, args, flags, signature) signal_id; // type-safe connect
pub fn connectNotify(...) signal_id; // connect notify::$property
```

```zig
pub fn get(*Self, T, property) value; // get property
pub fn set(*Self, T, property, value) void; // set property
```

```zig
pub fn __call(*Self, method, args) result; // call inherited functions, desired function may be shadowed
box.__call("setHalign", .{.center}); // equivalent to box.into(Widget).setHalign(.center)
```

### GError handling

```zig
doSomething() catch {
  var err = core.getError();
  defer err.free();
  std.log.err("{s}", .{err.message.?});
  // ...
}
```

## Contributing

Read [docs/design.md](docs/design.md) and [docs/hacking.md](docs/hacking.md).

> **Note**
> 
> (Newly written) source code should follow [Tigerbeetle's Style](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md) while generated code should follow [Zig's Style](https://ziglang.org/documentation/master/#Style-Guide).
