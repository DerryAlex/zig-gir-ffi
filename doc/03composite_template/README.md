### Composite Template

Call `WidgetClass.setTemplateFromResource` from the class initialization. You can access widgets defined in the template using the `Widget.getTemplateChild` function, but you will typically declare a pointer in the instance private data structure of your type using the same name as the widget in the template definition, and call `WidgetClass.bindTemplateChildFull`.

> **WARNING**: `template.bindChild` does NOT support private or internal child currently. Template child should be named `"TC" ++ name` when using convenience function `template.bindChild`.

```zig
const ExampleAppPrefsClass = extern struct {
	// ...

    pub fn init(self: *ExampleAppPrefsClass) callconv(.C) void {
    	// ...
        var widget_class = @ptrCast(*Gtk.WidgetClass, self);
        widget_class.setTemplateFromResource("/org/gtk/exampleapp/prefs.ui");
        template.bindChild(widget_class, ExampleAppPrefsImpl);
    }
};
```

You will also need to call `Widget.initTemplate` from the instance initialization function.

```zig
pub const ExampleAppPrefs = packed struct {
    // ...

    pub fn init(self: ExampleAppPrefs) callconv(.C) void {
        self.callMethod("initTemplate", .{});
        // ...
    }
};
```

as well as calling `Widget.disposeTemplate` from the dispose function.

```zig
pub const ExampleAppPrefs = packed struct {
    // ...

    pub fn disposeOverride(self: ExampleAppPrefs) void {
        self.instance.settings.callMethod("unref", .{});
        self.callMethod("disposeTemplate", .{gType()});
        self.callMethod("disposeV", .{Parent.gType()});
    }
};
```

You can also use `WidgetClass.bindTemplateCallbackFull` to connect a signal callback defined in the template with a function visible in the scope of the class. Template callback should be named `"TC" ++ name` when using convenience function `template.bindCallback`.

```zig
pub const ExampleAppWindowClass = extern struct {
    // ...

    pub fn init(self: *ExampleAppWindowClass) callconv(.C) void {
        // ...
        template.bindCallback(widget_class, ExampleAppWindowClass);
    }

    pub fn TCsearch_text_changed(entry: Gtk.Entry, win: ExampleAppWindow) callconv(.C) void {
        // ...
    }

    pub fn TCvisible_child_changed(stack: Gtk.Stack, _: core.ParamSpec, win: ExampleAppWindow) callconv(.C) void {
        // ...
    }
};
```
