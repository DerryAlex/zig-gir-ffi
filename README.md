# Zig GIR FFI

GObject Introspection for zig. Generated [GTK4 binding](https://github.com/DerryAlex/zig-gir-ffi/releases) can be downloaded.

> **Warning**
> Before zig 1.0 is released, only pre-releases targeting latest zig stable are guarenteed to be kept.

###### Table of Contents

- [Usage](#usage)

- [Usage of Bindings](#usage-of-bindings)

- [Contributing](#contributing)

## Usage

```bash
# generate bindings for Gtk
zig build run -- Gtk
# generate bindings for Gtk-3.0
zig build run -- Gtk-3.0
# display help
zig build run -- --help
```

*Note*: The typelib backend relies on `field_info_get_size` to work properly.
Due to an [issue](https://gitlab.gnome.org/GNOME/gobject-introspection/-/issues/5) in gobject-introspection, a patched version of `g-ir-compiler` (or `gi-compile-repository`) may be required.
As bitfields are not commonly found in GIR files, users can use typelibs from their package manager (e.g., `apt`, `msys2`) without recompiling.
For notable exceptions (`GLib`, `GObject` and `Pango`), this project ships patched typelibs (for LP64 model), which can be enabled by `-I data/typelib` option.
For example, `zig build run -- Adw -I data/typelib` should work perfectly if you have installed `gir1.2-adw-1` package or its equivalent.

## Usage of Bindings

Run `zig fetch --save https://url/to/bindings.tar.gz` and add the following lines to your `build.zig`. For more information, refer to [Zig Build System](https://ziglang.org/learn/build-system/).

```zig
const gi = b.dependency("gi", .{});
exe.root_module.addImport("gi", gi.module("gi"));
```

### Examples

- [application](examples/application) : Port of [Gtk - 4.0: Getting Started with GTK](https://docs.gtk.org/gtk4/getting_started.html), a relatively comprehensive example

- [hello](examples/hello) : A simple example

  ```zig
  const std = @import("std");
  const gi = @import("gi");
  const Gio = gi.Gio;
  const Gtk = gi.Gtk;
  // ...

  pub fn printHello() void {
      std.log.info("Hello World", .{});
  }

  pub fn activate(app: *Gio.Application) void {
      const _window: *ApplicationWindow = .new(app.tryInto(Application).?);
      const window = _window.into(Window);
      window.setTitle("Window");
      window.setDefaultSize(200, 200);
      const box: *Box = .new(.vertical, 0);
      box.into(Widget).setHalign(.center);
      box.into(Widget).setValign(.center);
      window.setChild(box.into(Widget));
      const button = Button.newWithLabel("Hello, World");
      _ = button._signals.clicked.connect(.init(printHello, .{}), .{});
      _ = button._signals.clicked.connect(.init(Window.destroy, .{window}), .{});
      box.append(button.into(Widget));
      window.present();
  }

  pub fn main() u8 {
      const _app: *Application = .new("org.gtk.example", .{});
      const app = _app.into(Gio.Application);
      defer app.into(Object).unref();
      _ = app._signals.activate.connect(.init(activate, .{}), .{});
      return @intCast(app.run(@ptrCast(std.os.argv)));
  }
  ```

  ![](examples/hello/screenshot.png)

- [clock](examples/clock) : (Implicit) use of the main context

- [custom](examples/custom) : Custom widget

- [interface](examples/interface) : Define interface
