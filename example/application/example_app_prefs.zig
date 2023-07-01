const std = @import("std");
const root = @import("root");
const Gtk = root.Gtk;
const core = Gtk.core;
const template = Gtk.template;
const meta = std.meta;
const assert = std.debug.assert;
const ExampleAppWindow = @import("example_app_window.zig").ExampleAppWindow;
const ComboBoxText = Gtk.ComboBoxText;
const Dialog = Gtk.Dialog;
const DialogClass = Gtk.DialogClass;
const FontButton = Gtk.FontButton;
const Object = core.Object;
const ObjectClass = core.ObjectClass;
const Settings = core.Settings;
const WidgetClass = Gtk.WidgetClass;
const Window = Gtk.Window;

const ExampleAppPrefsClass = extern struct {
    parent: DialogClass,

    pub fn init(class: *ExampleAppPrefsClass) void {
        var widget_class: *WidgetClass = @ptrCast(class);
        widget_class.setTemplateFromResource("/org/gtk/exampleapp/prefs.ui");
        template.bindChild(widget_class, ExampleAppPrefs);
    }

    // @override
    fn dispose(arg_object: *Object) callconv(.C) void {
        var self = arg_object.tryInto(ExampleAppPrefs).?;
        self.private.settings.__call("unref", .{});
        self.__call("disposeTemplate", .{ExampleAppPrefs.type()});
        self.__call("disposeV", .{ExampleAppPrefs.Parent.type()});
    }
};

const ExampleAppPrefsPrivate = struct {
    settings: *Settings,
    tc_font: *FontButton, // template child
    tc_transition: *ComboBoxText, // template child
};

pub const ExampleAppPrefs = extern struct {
    parent: Parent,
    private: *Private,

    pub const Parent = Dialog;
    pub const Private = ExampleAppPrefsPrivate;
    pub usingnamespace core.Extend(ExampleAppPrefs);

    pub fn init(self: *ExampleAppPrefs) void {
        self.__call("initTemplate", .{});
        self.private.settings = Settings.new("org.gtk.exampleapp");
        self.private.settings.__call("bind", .{ "font", self.private.tc_font.into(Object), "font", .Default });
        self.private.settings.__call("bind", .{ "transition", self.private.tc_transition.into(Object), "active-id", .Default });
    }

    pub fn new(win: *ExampleAppWindow) *ExampleAppPrefs {
        var transient_for = core.ValueZ(Window).init();
        defer transient_for.deinit();
        transient_for.set(win.into(Window));
        var use_header_bar = core.ValueZ(bool).init();
        defer use_header_bar.deinit();
        use_header_bar.set(true);
        var property_names = [_][*:0]const u8{ "transient-for", "use-header-bar" };
        var property_values = [_]core.Value{ transient_for.value, use_header_bar.value };
        return core.newObject(ExampleAppPrefs, property_names[0..], property_values[0..]);
    }

    pub fn @"type"() core.Type {
        return core.registerType(ExampleAppPrefsClass, ExampleAppPrefs, "ExampleAppPrefs", .{});
    }
};
