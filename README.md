# Zig GIR FFI

GObject Introspection for zig. Generated [GTK4 binding](https://github.com/DerryAlex/zig-gir-ffi/releases) can be downloaded.

- [Usage](#usage)

- [Usage of Bindings](#usage-of-bindings)
  
  ## Usage

```bash
# generate bindings for Gtk
zig build run -- -N Gtk
# generate bindings for Gtk-3.0
zig build run -- -N Gtk -V 3.0
# display help
zig build run -- --help
```

Typelibs need to be patched as bitfield info is currently not embedded.

```bash
cd lib/tools
# build patched g-ir-compiler
./fetch-compiler.sh
# generate patched typelib
./generate.sh
```

`--includedir lib/girepository-1.0` can be passed to binding generator to use patched typelibs.

## Usage of Bindings

Run `zig fetch --save=gtk4 https://url/to/bindings.tar.gz` and add the following lines to your `build.zig`. For more information, refer to [Zig Build System](https://ziglang.org/learn/build-system/).

```zig
const gtk = b.dependency("gtk4", .{});
exe.root_module.addImport("gtk", gtk.module("gtk4"));
```

### Examples

- [application](examples/application) : Port of [Gtk - 4.0: Getting Started with GTK](https://docs.gtk.org/gtk4/getting_started.html), a relatively comprehensive example
- [hello](examples/hello) : A simple example
  ![](examples/example/screenshot.png)
- [clock](examples/clock) : (Implicit) use of the main context
- [custom](examples/custom) : custom widget

### Object Interface

```zig
pub fn into(*Self, T) *T; // comptime-checked upcast
pub fn tryInto(*Self, T) ?*T; // runtime-checked downcast
```

```zig
pub fn connect(*Self, signal, handler, args, flags, signature) signal_id; // type-safe connect, used by methods like connectClicked
pub fn connectNotify(...) signal_id; // connect notify::$property
```

```zig
pub fn get(*Self, T, property) value; // get property
pub fn set(*Self, T, property, value) void; // set property
```

```zig
pub fn __call(*Self, method, args) result; // call inherited functions, interface methods are preferred
// Explict cast may be needed in case desired function is shadowed
box.__call("setHalign", .{.center}); // box.into(Widget).setHalign(.center)
```
