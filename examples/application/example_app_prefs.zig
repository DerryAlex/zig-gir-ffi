const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const gobject = gtk.gobject;
const gio = gtk.gio;
const template = gtk.template;
const meta = std.meta;
const assert = std.debug.assert;
const ExampleAppWindow = @import("example_app_window.zig").ExampleAppWindow;
const ComboBoxText = gtk.ComboBoxText;
const Dialog = gtk.Dialog;
const DialogClass = gtk.DialogClass;
const FontButton = gtk.FontButton;
const Object = gobject.Object;
const ObjectClass = gobject.ObjectClass;
const Settings = gio.Settings;
const WidgetClass = gtk.WidgetClass;
const Window = gtk.Window;

const ExampleAppPrefsClass = extern struct {
    parent_class: DialogClass,

    pub var parent_class: ?*DialogClass = null;

    pub fn init(class: *ExampleAppPrefsClass) void {
        parent_class = @ptrCast(gobject.TypeClass.peekParent(@ptrCast(class)));
        var widget_class: *WidgetClass = @ptrCast(class);
        widget_class.setTemplateFromResource("/org/gtk/exampleapp/prefs.ui");
        template.bindChild(widget_class, ExampleAppPrefs, null, &[_]template.BindingZ{
            .{ .name = "font" },
            .{ .name = "transition" },
        });
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

    const Ext = core.Extend(@This());
    pub const __call = Ext.__call;
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub const property = Ext.property;
    pub const signalConnect = Ext.signalConnect;

    pub const Override = struct {
        pub fn dispose(arg_object: *Object) callconv(.C) void {
            var self = arg_object.tryInto(ExampleAppPrefs).?;
            self.private.settings.__call("unref", .{});
            self.__call("disposeTemplate", .{ExampleAppPrefs.gType()});
            const p_class: *ObjectClass = @ptrCast(Class.parent_class.?);
            p_class.dispose.?(arg_object);
        }
    };

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
