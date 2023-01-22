### Custom Widget

[example_app_prefs.zig](../../../example/application/example_app_prefs.zig)

To define a custom widget, we need to define a `Class` for our widget. The layout should be `extern`. The members should be `parent` followed by class virtual functions. (Paddings may be used so that we can add new virtual functions without breaking ABI.)
Implement `init` function if virtual functions need to be initialized or overrided. Virtual functions can be called with `V` suffix. `Parent.gType()` is passed so that `disposeV` dispatches to `Dialog.dispose` runtime.

```zig
// defined in GObject.Object
pub fn disposeV(self: Object, g_type: core.GType) void {
    const class = core.alignedCast(*ObjectClass, typeClassPeek(g_type));
    const dispose_fn = class.dispose.?;
    dispose_fn(self);
}
```

We define an `Impl` for our widget. The layout should be `extern`. The first member should be `parent`. (For derivable type, `PrivateImpl` may be used to attain a stable ABI for `Impl`. If so, the member `private` should be defined and `Private` should be declared. All fields of `Impl` and `PrivateImpl` except `parent` will be zero-initialized.)

Now we define `Instance` to wrap `Impl`. `Instance` should have the same memory layout as `*anyopaque`.

- `Parent` should be declared.
- Traits should be marked unless they can be inherited from parent. `isAImpl` should be implemented.
- `cType()` should be implemented. `gType()` should be implemented. (Convenience function `registerType` can be used which will handle `PrivateImpl`. Or you can turn to `GObject.typeRegisterStatic`.)
- Implement `init` function if instance needs to be initialized.
- (Recommended) Implement `into`, `tryInto`.
- (Recommended) Implement `callMethod`.
- (Recommended) Implement signal proxies, property proxies and vfunc proxies.

`Nullable` is just nice to have as `?Instance` is preferred.

Addtional infomation: 

| -\|private_offset\| |                   | offset 0   |      |
| :-----------------: | :---------------: | :--------: | :--: |
| PrivateImpl         | ParentPrivateImpl | ParentImpl | Impl |
