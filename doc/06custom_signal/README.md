### Custom Signal

[custom_button.zig](../../../example/custom_buttoncustom_button.zig)

#### non-GTK Signal

> gtkmm uses libsigc++ to implement its proxy wrappers for the GTK signal system, but for new, non-GTK signals, you can create pure C++ signals, using the sigc::signal<> template.

#### GTK Signal

Use `core.signalNewv` to register signal in `class_init`. (GObject provides two built-in accumulators `signalAccumulatorFirstWins` and `signalAccumulatorTrueHandled`)

```zig
var flags = core.FlagsBuilder(core.SignalFlags){};
signals[@enumToInt(Signals.ZeroReached)] = core.signalNewv("zero-reached", CustomButton.gType(), flags.set(.RunLast).set(.NoRecurse).set(.NoHooks).build(), core.signalTypeCclosureNew(CustomButton.gType(), @offsetOf(CustomButtonClass, "zeroReached")), null, null, null, .None, null);
```

And use `GObject.signalEmitv` to emit signal.
