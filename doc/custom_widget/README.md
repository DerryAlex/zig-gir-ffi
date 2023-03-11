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

    pub fn init(self: *ExampleAppPrefs) void {
        self.private.settings = Settings.new("org.gtk.exampleapp");
        // ...
    }

    pub fn new(win: *ExampleAppWindow) *ExampleAppPrefs {
        // ...
        return core.objectNewWithProperties(@"type"(), property_names[0..], property_values[0..]).tryInto(ExampleAppPrefs).?;
    }

    // ...

    pub fn into(self: *ExampleAppPrefs, comptime T: type) *T {
        return core.upCast(T, self);
    }

    pub fn tryInto(self: *ExampleAppPrefs, comptime T: type) ?*T {
        return core.downCast(T, self);
    }

    pub fn @"type"() core.Type {
        return core.registerType(ExampleAppPrefsClass, ExampleAppPrefs, "ExampleAppPrefs", .{});
    }
};
```

The layout should be `extern`. The first member should be `parent`. We may have a `PrivateImpl`. All fields of `Impl` and `PrivateImpl` except `parent` will be zero-initialized.

- `Parent` should be declared.
- `Private` may be declared.
- `Interfaces` may be declared. (e.g. `Interfaces = [_]type{ A.IFx, B.IFy };` and override interface virtual functions in `initIFx(*IFx), initIFy(*IFy)`)
- `@"type"` should be defined. `core.RegisterType` can be used, which will set `private` and register interface overrides.
- `into` and `tryInto` may be defined.
- `__call` and its helper `__Call` may be defined.
```zig
    pub fn __Call(comptime method: []const u8) ?type {
        if (std.mem.eql(u8, method, "open")) return void;
        return core.CallInherited(@This(), method);
    }

    pub fn __call(self: *ExampleAppWindow, comptime method: []const u8, args: anytype) core.CallReturnType(@This(), method) {
        if (comptime std.mem.eql(u8, method, "open")) return @call(.auto, open, .{self} ++ args);
        return core.callInherited(self, method, args);
    }
```

