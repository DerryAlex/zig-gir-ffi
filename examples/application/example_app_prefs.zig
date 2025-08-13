const std = @import("std");
const gi = @import("gi");
const core = gi.core;
const GLib = gi.GLib;
const GObject = gi.GObject;
const Gio = gi.Gio;
const Gtk = gi.Gtk;
const Pango = gi.Pango;
const ExampleAppWindow = @import("example_app_window.zig").ExampleAppWindow;
const DropDown = Gtk.DropDown;
const FontDialogButton = Gtk.FontDialogButton;
const FontDescription = Pango.FontDescription;
const Object = GObject.Object;
const Settings = Gio.Settings;
const Value = GObject.Value;
const Variant = GLib.Variant;
const VariantType = GLib.VariantType;
const Widget = Gtk.Widget;
const Window = Gtk.Window;

const ExampleAppPrefsClass = extern struct {
    parent_class: Window.Class,

    pub fn init(class: *ExampleAppPrefsClass) void {
        const widget_class: *Widget.Class = @ptrCast(class);
        widget_class.setTemplateFromResource("/org/gtk/exampleapp/prefs.ui");
        const private_offset = core.typeTag(ExampleAppPrefs).private_offset;
        widget_class.bindTemplateChildFull("font", false, @offsetOf(ExampleAppPrefsPrivate, "font") + private_offset);
        widget_class.bindTemplateChildFull("transition", false, @offsetOf(ExampleAppPrefsPrivate, "transition") + private_offset);
    }
};

const ExampleAppPrefsPrivate = struct {
    settings: *Settings,
    font: *FontDialogButton, // template child
    transition: *DropDown, // template child
};

fn stringToFontDesc(value: *Value, variant: *Variant, _: ?*anyopaque) callconv(.c) bool {
    const s = variant.getString().ret;
    const desc = FontDescription.fromString(s);
    value.takeBoxed(desc);
    return true;
}

fn fontDescToString(value: *Value, _: *VariantType, _: ?*anyopaque) callconv(.c) *Variant {
    const Static = struct {
        var desc_str: ?[*:0]u8 = null;
    };
    const desc: *FontDescription = @ptrCast(value.getBoxed());
    const s = desc.toString();
    if (Static.desc_str) |str| {
        GLib.free(str);
    }
    Static.desc_str = GLib.strdup(s);
    return .newString(Static.desc_str.?);
}

fn transitionToPos(value: *Value, variant: *Variant, _: ?*anyopaque) callconv(.c) bool {
    const ret = variant.getString();
    const s = ret.ret[0..ret.length];
    if (std.mem.eql(u8, "none", s)) {
        value.setUint(0);
    } else if (std.mem.eql(u8, "crossfade", s)) {
        value.setUint(1);
    } else {
        value.setUint(2);
    }
    return true;
}

fn posToTransition(value: *Value, _: *VariantType, _: ?*anyopaque) callconv(.c) *Variant {
    return switch (value.getUint()) {
        0 => .newString("none"),
        1 => .newString("crossfade"),
        2 => .newString("slide-left-right"),
        else => unreachable,
    };
}

pub const ExampleAppPrefs = extern struct {
    parent: Parent,
    private: *Private,

    pub const Parent = Window;
    pub const Private = ExampleAppPrefsPrivate;
    pub const Class = ExampleAppPrefsClass;

    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub const getParentClass = Ext.getParentClass;

    pub const Override = struct {
        pub fn dispose(object: *Object) callconv(.c) void {
            const self = object.tryInto(ExampleAppPrefs).?;
            self.private.settings.into(Object).unref();
            self.into(Widget).disposeTemplate(gType());
            const p_class = self.getParentClass(Object);
            p_class.dispose.?(object);
        }
    };

    pub fn init(self: *ExampleAppPrefs) void {
        self.into(Widget).initTemplate();
        self.private.settings = Settings.new("org.gtk.exampleapp");
        // FIXME: g_settings_bind_with_mapping_closures does not work
        const g_settings_bind_with_mapping = struct {
            extern fn g_settings_bind_with_mapping(settings: *Settings, key: [*c]const u8, object: *anyopaque, property: [*c]const u8, flags: Gio.SettingsBindFlags, get_mapping: Gio.SettingsBindGetMapping, set_mapping: Gio.SettingsBindSetMapping, user_data: ?*anyopaque, destroy: ?GLib.DestroyNotify) void;
        }.g_settings_bind_with_mapping;
        g_settings_bind_with_mapping(self.private.settings, "font", self.private.font, "font-desc", .{}, stringToFontDesc, fontDescToString, null, null);
        g_settings_bind_with_mapping(self.private.settings, "transition", self.private.transition, "selected", .{}, transitionToPos, posToTransition, null, null);
    }

    pub fn new(win: *ExampleAppWindow) *ExampleAppPrefs {
        const self = core.newObject(ExampleAppPrefs);
        self.into(Window)._props.@"transient-for".set(win.into(Window));
        return self;
    }

    pub fn gType() core.Type {
        return core.registerType(ExampleAppPrefs, "ExampleAppPrefs", .{});
    }
};
