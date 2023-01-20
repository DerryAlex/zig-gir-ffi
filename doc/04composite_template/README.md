### Composite Template

[example_app_prefs.zig](../../../example/application/example_app_prefs.zig)

Call `WidgetClass.setTemplateFromResource` from the class initialization. You will typically declare a pointer in the instance private data structure of your type using the same name as the widget in the template definition, and call `WidgetClass.bindTemplateChildFull`.
Template child should be named `"TC" ++ name` or `"TI" ++ name`(internal child) when using convenience function `template.bindChild`.

You will also need to call `Widget.initTemplate` from the instance initialization function.
as well as calling `Widget.disposeTemplate` from the dispose function.

You can also use `WidgetClass.bindTemplateCallbackFull` to connect a signal callback defined in the template with a function visible in the scope of the class.
Template callback should be named `"TC" ++ name` when using convenience function `template.bindCallback`.
