# Zig GIR FFI

GObject Introspection for zig. Generated [GTK4 binding](https://github.com/DerryAlex/zig-gir-ffi/releases) can be downloaded.

## Documentation

- [GTK Documentation](https://docs.gtk.org/)
- [Zig Language Reference](https://ziglang.org/documentation/master/)
- [Zig Build System](https://ziglang.org/learn/build-system/)

### Basics

Zig container enables shorter code.

```zig
// GtkBox *box = GTK_BOX(gtk_box_new(GTK_ORIENTATIOON_VERTICAL, 0));
// gtk_box_append(box, GTK_WIDGET(button));
var box = Box.new(.Vertical, 0);
box.append(button.into(Widget));
```

The binding also makes use of zig's richer type system.

```zig
pub const Orientation = enum(u32) {
    Horizontal = 0,
    Vertical = 1,
};

pub const ApplicationFlags = packed struct(u32) {
    is_service: bool = false,
    // ...
    replace: bool = false,
    _padding: u23 = 0,
};

// int g_application_run (GApplication* application, int argc, char** argv);
pub fn run(*Application, [][*:0]const u8) i32 {
    // ...
}

// gboolean g_file_load_contents (GFile* file, GCancellable* cancellable,
//                                char** contents, gsize* length,
//                                char** etag_out, GError** error);
pub fn loadContents(*File, ?*Gio.Cancellable) error{GError}!struct {
    // boolean return value indicating error is ignored
    contents: []u8,
    etag_out: ?[*:0]u8,
} {
    // ...
}
// handle GError
const result = file.loadContents(null) catch {
    var err = core.getError();
    defer err.free();
    std.log.warn("{s}", .{err.message.?});
    return;
};
```

### Object

Two cast functions are provided.

```zig
pub fn into(*Self, T) *T; // comptime-checked upcast
pub fn tryInto(*Self, T) ?*T; // runtime-checked downcast
```

Users can use `__call` convinience function to call inherited functions. It will check self-owned methods, interface methods and finally ancestors' method.

```zig
// You may need explict cast in case desired function is shadowed
box.__call("setHalign", .{.Center}); // box.into(Widget).setHalign(.Center)
```

A nice type-safe wrapper for `connect` is created so that one does not need to provide a C callback.

```zig
pub fn printHello() void {
    std.log.info("Hello World", .{});
}

// id = object.connectSignal(handler, extra_args, comptime_flags)
_ = button.connectClicked(printHello, .{}, .{});
_ = button.connectClicked(Window.destroy, .{window.into(Window)}, .{ .swapped = true });
```

### Custom Widget

Custom widget and its class should be `extern struct` to provide a stable ABI. The first field should be `parent`. Custom widget may have a `private` field, which can be `struct` . Except `parent` and `private`, fields may have a default value.

Class may have `init` function to do initializing stuff. (You don't need to overide virtual functions manually.) For signals and properties, refer to [example/custom_button](./example/custom_button/custom_button.zig). For template, refer to [example/application](./example/application/example_app_prefs.zig).

Widget should have `new` and `gType` function and may have `init` function. You should use `Extend(Self)` to enable `into`, `tryInto` and `__call`.

```zig
pub const CustomButtonClass = extern struct {
    parent: ButtonClass,
    // ...

    pub fn clicked_override(arg_button: *Button) callconv(.C) void {
        // ...
    }

    // ...
};

pub const CustomButtonPrivate = struct {
    number: i32 = 10,
};

pub const CustomButton = extern struct {
    parent: Parent,
    private: *Private,

    pub const Parent = Button;
    pub const Private = CustomButtonPrivate;
    pub const Class = CustomButtonClass;
    pub usingnamespace core.Extend(CustomButton);

    pub fn new() *CustomButton {
        return core.newObject(CustomButton, null, null);
    }

    pub fn gType() core.Type {
        return core.registerType(CustomButton, "CustomButton", .{});
    }

    // ...
};
```

### Custom Interface

Refer to [example/custom_interface](./example/custom_interface).
