const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const gobject = gtk.gobject;
const gio = gtk.gio;
const glib = gtk.glib;
const pango = gtk.pango;
const template = gtk.template;
const meta = std.meta;
const assert = std.debug.assert;
const ExampleAppWindow = @import("example_app_window.zig").ExampleAppWindow;
const DropDown = gtk.DropDown;
const FontDialogButton = gtk.FontDialogButton;
const FontDescription = pango.FontDescription;
const Object = gobject.Object;
const ObjectClass = gobject.ObjectClass;
const Settings = gio.Settings;
const Value = gobject.Value;
const Variant = glib.Variant;
const VariantType = glib.VariantType;
const WidgetClass = gtk.WidgetClass;
const Window = gtk.Window;

const ExampleAppPrefsClass = extern struct {
    parent_class: Window.Class,

    pub var parent_class_ptr: ?*Window.Class = null;

    pub fn init(class: *ExampleAppPrefsClass) void {
        parent_class_ptr = @ptrCast(gobject.TypeClass.peekParent(@ptrCast(class)));
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
        glib.free(str);
    }
    Static.desc_str = glib.strdup(s);
    return Variant.newString(Static.desc_str.?);
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
    switch (value.getUint()) {
        0 => return Variant.newString("none"),
        1 => return Variant.newString("crossfade"),
        2 => return Variant.newString("slide-left-right"),
        else => unreachable,
    }
}

pub const ExampleAppPrefs = extern struct {
    parent: Parent,
    private: *Private,

    pub const Parent = Window;
    pub const Private = ExampleAppPrefsPrivate;
    pub const Class = ExampleAppPrefsClass;

    const Ext = core.Extend(@This());
    pub const __call = Ext.__call;
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub const property = Ext.property;
    pub const signalConnect = Ext.signalConnect;

    pub const Override = struct {
        pub fn dispose(arg_object: *Object) callconv(.c) void {
            var self = arg_object.tryInto(ExampleAppPrefs).?;
            self.private.settings.__call("unref", .{});
            self.__call("disposeTemplate", .{ExampleAppPrefs.gType()});
            const p_class: *ObjectClass = @ptrCast(Class.parent_class_ptr.?);
            p_class.dispose.?(arg_object);
        }
    };

    pub fn init(self: *ExampleAppPrefs) void {
        self.__call("initTemplate", .{});
        self.private.settings = Settings.new("org.gtk.exampleapp");
        // FIXME: g_settings_bind_with_mapping_closures does not work
        const g_settings_bind_with_mapping = struct {
            extern fn g_settings_bind_with_mapping(settings: *Settings, key: [*c]const u8, object: *anyopaque, property: [*c]const u8, flags: gio.SettingsBindFlags, get_mapping: gio.SettingsBindGetMapping, set_mapping: gio.SettingsBindSetMapping, user_data: ?*anyopaque, destroy: ?glib.DestroyNotify) void;
        }.g_settings_bind_with_mapping;
        g_settings_bind_with_mapping(self.private.settings, "font", self.private.font, "font-desc", @bitCast(@as(u32, 0)), stringToFontDesc, fontDescToString, null, null);
        g_settings_bind_with_mapping(self.private.settings, "transition", self.private.transition, "selected", @bitCast(@as(u32, 0)), transitionToPos, posToTransition, null, null);
    }

    pub fn new(win: *ExampleAppWindow) *ExampleAppPrefs {
        return core.newObject(ExampleAppPrefs, .{
            .@"transient-for" = win.into(Window),
        });
    }

    pub fn gType() core.Type {
        return core.registerType(ExampleAppPrefs, "ExampleAppPrefs", .{});
    }
};
