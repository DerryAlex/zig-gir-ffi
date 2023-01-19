### Custom Widget

```zig
const ExampleAppPrefsClass = extern struct {
    parent: Gtk.DialogClass,

    pub fn init(self: *ExampleAppPrefsClass) callconv(.C) void {
        var object_class = @ptrCast(*core.ObjectClass, self);
        object_class.dispose = &dispose;
        // ...
    }

    pub fn dispose(object: core.Object) callconv(.C) void {
        var prefs = object.tryInto(ExampleAppPrefs).?;
        prefs.disposeOverride();
    }
};

const ExampleAppPrefsImpl = extern struct {
    parent: Gtk.Dialog.cType(),
    settings: core.Settings,
    // ...
};

pub const ExampleAppPrefsNullable = packed struct {
    ptr: ?*ExampleAppPrefsImpl, // naming convention, should be called `ptr` do not break

    pub fn expect(self: ExampleAppPrefsNullable, message: []const u8) ExampleAppPrefs {
        if (self.ptr) |some| {
            return ExampleAppPrefs{ .instance = some };
        } else @panic(message);
    }

    pub fn wrap(self: ExampleAppPrefsNullable) ?ExampleAppPrefs {
        return if (self.ptr) |some| ExampleAppPrefs{ .instance = some } else null;
    }
};

pub const ExampleAppPrefs = packed struct {
    instance: *ExampleAppPrefsImpl, // naming convention, should be called `instance`, do not break
    traitExampleAppPrefs: void = {},

    pub const Parent = Gtk.Dialog;

    pub fn init(self: ExampleAppPrefs) callconv(.C) void {
        // ...
    }

    pub fn new(win: ExampleAppWindow) ExampleAppPrefs {
        // ...
        return core.newObject(gType(), property_names[0..], property_values[0..])).tryInto(ExampleAppPrefs).?;
    }

    pub fn disposeOverride(self: ExampleAppPrefs) void {
        self.instance.settings.callMethod("unref", .{});
        self.callMethod("disposeV", .{Parent.gType()}); // chain up
    }

    pub fn CallMethod(comptime method: []const u8) ?type {
        if (Parent.CallMethod(method)) |some| return some;
        return null;
    }

    pub fn callMethod(self: ExampleAppPrefs, comptime method: []const u8, args: anytype) gen_return_type: {
        if (CallMethod(method)) |some| {
            break :gen_return_type some;
        } else {
            @compileError(std.fmt.comptimePrint("No such method {s}", .{method}));
        }
    } {
        if (Parent.CallMethod(method)) |_| {
            return self.into(Parent).callMethod(method, args);
        } else {
            @compileError("No such method");
        }
    }

    pub fn cType() type {
        return ExampleAppPrefsImpl;
    }

    pub fn gType() core.GType {
        return core.registerType(ExampleAppPrefsClass, ExampleAppPrefs, "ExampleAppPrefs", .{ .final = true });
    }

    pub fn isAImpl(comptime T: type) bool {
        return meta.trait.hasField("traitExampleAppPrefs")(T);
    }

    pub fn into(self: ExampleAppPrefs, comptime T: type) T {
        return core.upCast(T, self);
    }

    pub fn tryInto(self: ExampleAppPrefs, comptime T: type) ?T {
        return core.downCast(T, self);
    }

    pub fn asSome(self: ExampleAppPrefs) ExampleAppPrefsNullable {
        return .{ .ptr = self.instance };
    }
};
```

To define a custom widget, we need to define a `Class` for our widget. The layout should be `extern`. The members should be `parent_class` followed by class virtual functions. (Paddings may be used so that we can add new virtual functions without break ABI.) Define `init` function if virtual functions need to be initialized or overrided. For example, `object_class.dispose = &dispose` overrides inherited virtual function `dispose` . Virtual functions can be called with `V` suffix. `Parent.gType()` is passed so that `disposeV` dispatches to `dialog_dispose` runtime.

```zig
// defined in GObject.Object
pub fn disposeV(self: Object, g_type: core.GType) void {
    const class = core.alignedCast(*ObjectClass, typeClassPeek(g_type));
    const dispose_fn = class.dispose.?;
    dispose_fn(self);
}
```

We define an `Impl` for our widget. The layout should be `extern`. The first member should be `parent`. `Nullable` is just nice to have as `?Instance` is preferred.

Now we define `Instance` to wrap `Impl`. `Instance` should have the same memory layout as `*anyopaque`.

- `Parent` should be defined and should be a wrapped type.
- Traits should be marked unless they can be inherited from parent. `isAImpl` should be defined.
- `cType()` should be defined. `gType()` should be defined. (Convenience wrapper `registerType` can be used. Or you can turn to `GObject.registerType{Static, Dynamic}`.)
- Define `init` function if instance needs to be initialized
- (Recommended) Define `into`, `tryInto`.
- (Recommended) Define `callMethod`.
- (Recommended) Define signal proxies, property proxies and vfunc proxies.
