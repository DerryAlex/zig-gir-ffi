### Custom Signal

#### non-GTK Signal

[custom_button2.zig](../../../example/custom_button/custom_button2.zig)

Use `core.signalZ(Types...).init` to register signal in `instance_init`. Call `signalZ.overrideDefault` to set default handler. Call `signalZ.connect` to connect slots. Call `signalZ.emit` to emit signal. You need to call `signalZ.deinit` from the dispose function.

#### GTK Signal

[custom_button1.zig](../../../example/custom_button/custom_button1.zig)

Use `core.signalNewv` to register signal in `class_init`. (GObject provides two built-in accumulators `signalAccumulatorFirstWins` and `signalAccumulatorTrueHandled`)

```zig
var flags = core.FlagsBuilder(core.SignalFlags){};
signals[@enumToInt(Signals.ZeroReached)] = core.signalNewv("zero-reached", CustomButton.gType(), flags.set(.RunLast).set(.NoRecurse).set(.NoHooks).build(), core.signalTypeCclosureNew(CustomButton.gType(), @offsetOf(CustomButtonClass, "zeroReached")), null, null, null, .None, null);
```

And call `GObject.signalEmitv` to emit signal.
