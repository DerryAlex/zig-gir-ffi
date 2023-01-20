### Basics

[example1.zig](../../../example/example1/example1.zig)

`Application.new` creates an application. `tryInto` downcasts `Gio.Application` to `Application`. (`tryInto` may fail. User should check whether return value is `null`.) `callMethod` dispatches `setChild` to `Window.setChild(self, child: WidgetNullable) void` comptime. `WigdetNullable` is a wrapper of `?*WidgetImpl` for C ABI compatibility. `into` upcasts `Box` to `Widget` and `asSome` converts `Widget` to `WidgetNullable`.

`signalActivate` creates an proxy for signal `activate` (of object `app`). `connect` connects the signal to a type-safe handler `activate`. (Set `swapped` flag to `true` if the handler takes only custom arguments. Set `after` flag to `true` if the handler should be called after the default handler.) NOTE: memory allocation is done implicity without asking an allocator, which is anti-pattern in zig. The allocated memory will be freed automatically once the object is destroyed.
