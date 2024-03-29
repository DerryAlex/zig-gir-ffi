const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const template = gtk.template;
const meta = std.meta;
const assert = std.debug.assert;
const ExampleAppWindow = @import("example_app_window.zig").ExampleAppWindow;
const ComboBoxText = gtk.ComboBoxText;
const Dialog = gtk.Dialog;
const DialogClass = gtk.DialogClass;
const FontButton = gtk.FontButton;
const Object = core.Object;
const ObjectClass = core.ObjectClass;
const Settings = core.Settings;
const WidgetClass = gtk.WidgetClass;
const Window = gtk.Window;

const ExampleAppPrefsClass = extern struct {
    parent: DialogClass,

    pub fn init(class: *ExampleAppPrefsClass) void {
        var widget_class: *WidgetClass = @ptrCast(class);
        widget_class.setTemplateFromResource("/org/gtk/exampleapp/prefs.ui");
        template.bindChild(widget_class, ExampleAppPrefs, null, &[_]template.BindingZ{
            .{ .name = "font" },
            .{ .name = "transition" },
        });
    }

    fn dispose_override(arg_object: *Object) callconv(.C) void {
        var self = arg_object.tryInto(ExampleAppPrefs).?;
        self.private.settings.__call("unref", .{});
        self.__call("disposeTemplate", .{ExampleAppPrefs.type()});
        self.__call("disposeV", .{ExampleAppPrefs.Parent.type()});
    }
};

const ExampleAppPrefsPrivate = struct {
    settings: *Settings,
    font: *FontButton, // template child
    transition: *ComboBoxText, // template child
};

pub const ExampleAppPrefs = extern struct {
    parent: Parent,
    private: *Private,

    pub const Parent = Dialog;
    pub const Private = ExampleAppPrefsPrivate;
    pub const Class = ExampleAppPrefsClass;
    pub usingnamespace core.Extend(ExampleAppPrefs);

    pub fn init(self: *ExampleAppPrefs) void {
        self.__call("initTemplate", .{});
        self.private.settings = Settings.new("org.gtk.exampleapp");
        self.private.settings.__call("bind", .{ "font", self.private.font.into(Object), "font", .{} });
        self.private.settings.__call("bind", .{ "transition", self.private.transition.into(Object), "active-id", .{} });
    }

    pub fn new(win: *ExampleAppWindow) *ExampleAppPrefs {
        return core.newObject(ExampleAppPrefs, .{
            .@"transient-for" = win.into(Window),
            .@"use-header-bar" = true,
        });
    }

    pub fn gType() core.Type {
        return core.registerType(ExampleAppPrefs, "ExampleAppPrefs", .{});
    }
};
