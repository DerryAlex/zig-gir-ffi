### Custom Widget

#### Define `Class`

```zig
const ExampleAppPrefsClass = extern struct {
    parent: DialogClass,

    pub fn init(class: *ExampleAppPrefsClass) void {
        var object_class = @ptrCast(*ObjectClass, class);
        object_class.dispose = &dispose;
        // ...
    }

    // @override
    fn dispose(arg_object: *Object) callconv(.C) void {
        var self = arg_object.tryInto(ExampleAppPrefs).?;
        // ...
        self.__call("disposeV", .{ExampleAppPrefs.Parent.type()});
    }
};

// defined in GObject.Object
pub fn disposeV(self: *Object, _type: core.Type) void {
    const class = @ptrCast(*ObjectClass, typeClassPeek(_type));
    const vfunc_fn = class.dispose.?;
    vfunc_fn(self);
}
```

The layout should be `extern`. The first member should be `parent`.
Implement `init` function if virtual functions need to be overrided. Virtual functions can be called with `V` suffix. (Usually `Parent.type()` is passed to chain up.)

#### Define `Impl`

```zig
const ExampleAppPrefsPrivate = struct {
    settings: *Settings,
    // ...
};

pub const ExampleAppPrefs = extern struct {
    parent: Parent,
    private: *Private,

    pub const Parent = Dialog;
    pub const Private = ExampleAppPrefsPrivate;
    pub usingnamespace core.Extend(ExampleAppPrefs);

    pub fn init(self: *ExampleAppPrefs) void {
        self.private.settings = Settings.new("org.gtk.exampleapp");
        // ...
    }

    pub fn new(win: *ExampleAppWindow) *ExampleAppPrefs {
        // ...
        return core.objectNewWithProperties(@"type"(), property_names[0..], property_values[0..]).tryInto(ExampleAppPrefs).?;
    }

    pub fn @"type"() core.Type {
        return core.registerType(ExampleAppPrefsClass, ExampleAppPrefs, "ExampleAppPrefs", .{});
    }
};
```

The layout should be `extern`. The first member should be `parent`. We may have a `PrivateImpl`.

- `@"type"` should be defined.
- `Parent` should be declared.
- `Private` may be declared.

