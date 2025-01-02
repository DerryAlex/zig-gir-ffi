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
const Dialog = gtk.Dialog;
const DialogClass = gtk.DialogClass;
const DropDown = gtk.DropDown;
const FontDialogButton = gtk.FontDialogButton;
const FontDescription = pango.FontDescription;
const Object = gobject.Object;
const ObjectClass = gobject.ObjectClass;
const Settings = gio.Settings;
const Value = gobject.Value;
const Variant = glib.Variant;
const VariantType = gobject.VariantType;
const WidgetClass = gtk.WidgetClass;
const Window = gtk.Window;

const ExampleAppPrefsClass = extern struct {
    parent_class: DialogClass,

    pub var parent_class_ptr: ?*DialogClass = null;

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

fn stringToFontDesc(value: *Value, variant: *Variant) bool {
    const s = variant.getString().ret;
    const desc = FontDescription.fromString(s);
    value.takeBoxed(desc);
    return true;
}

fn fontDescToString(value: *Value, _: *VariantType) *Variant {
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

fn transitionToPos(value: *Value, variant: *Variant) bool {
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

fn posToTransition(value: *Value, _: *VariantType) *Variant {
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
        const font_get_mapping = core.zig_closure(stringToFontDesc, .{}, &.{ bool, *Value, *Variant });
        const font_set_mapping = core.zig_closure(fontDescToString, .{}, &.{ *Variant, *Value, *VariantType });
        self.private.settings.bindWithMapping("font", self.private.font.into(Object), "font-desc", @bitCast(@as(u32, 0)), font_get_mapping.g_closure(), font_set_mapping.g_closure());
        const transition_get_mapping = core.zig_closure(transitionToPos, .{}, &.{ bool, *Value, *Variant });
        const transition_set_mapping = core.zig_closure(posToTransition, .{}, &.{ *Variant, *Value, *VariantType });
        self.private.settings.bindWithMapping("transition", self.private.transition.into(Object), "selected", @bitCast(@as(u32, 0)), transition_get_mapping.g_closure(), transition_set_mapping.g_closure());
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
