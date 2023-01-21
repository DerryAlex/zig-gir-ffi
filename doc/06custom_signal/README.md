### Custom Signal

[custom_button.zig](../../../example/custom_button.zig)

> :warning **Warning**: Non GTK signal system may be adopted in the future
> gtkmm uses libsigc++ to implement its proxy wrappers for the GTK signal system, but for new, non-GTK signals, you can create pure C++ signals, using the sigc::signal<> template.
