const std = @import("std");
const root = @import("root");
const Gtk = root.Gtk;
const core = Gtk.core;
const template = Gtk.template;
const meta = std.meta;
const assert = std.debug.assert;
const ExampleAppWindow = @import("example_app_window.zig").ExampleAppWindow;

const ExampleAppPrefsClass = extern struct {
    parent: Gtk.DialogClass,

    pub fn init(self: *ExampleAppPrefsClass) void {
        var object_class = @ptrCast(*core.ObjectClass, self);
        object_class.dispose = &dispose;
        var widget_class = @ptrCast(*Gtk.WidgetClass, self);
        widget_class.setTemplateFromResource("/org/gtk/exampleapp/prefs.ui");
        template.bindChild(widget_class, ExampleAppPrefs);
    }

    pub fn dispose(object: core.Object) callconv(.C) void {
        var prefs = object.tryInto(ExampleAppPrefs).?;
        prefs.disposeOverride();
    }
};

const ExampleAppPrefsImpl = extern struct {
    parent: Gtk.Dialog.cType(),
    private: *Private,

    pub const Private = ExampleAppPrefsPrivateImpl;
};

const ExampleAppPrefsPrivateImpl = struct {
    settings: core.Settings,
    TCfont: Gtk.FontButton,
    TCtransition: Gtk.ComboBoxText,
};

pub const ExampleAppPrefsNullable = core.Nullable(ExampleAppPrefs);

pub const ExampleAppPrefs = packed struct {
    instance: *ExampleAppPrefsImpl,
    traitExampleAppPrefs: void = {},

    pub const Parent = Gtk.Dialog;

    pub fn init(self: ExampleAppPrefs) void {
        self.callMethod("initTemplate", .{});
        self.instance.private.settings = core.Settings.new("org.gtk.exampleapp");
        self.instance.private.settings.callMethod("bind", .{ "font", self.instance.private.TCfont.into(core.Object), "font", .Default });
        self.instance.private.settings.callMethod("bind", .{ "transition", self.instance.private.TCtransition.into(core.Object), "active-id", .Default });
    }

    pub fn new(win: ExampleAppWindow) ExampleAppPrefs {
        var transient_for = core.GValue(Gtk.Window).new();
        defer transient_for.deinit();
        transient_for.set(win.into(Gtk.Window));
        var use_header_bar = core.GValue(core.Boolean).new();
        defer use_header_bar.deinit();
        use_header_bar.set(.True);
        var property_names = [_][*:0]const u8{ "transient-for", "use-header-bar" };
        var property_values: [2]core.Value = undefined;
        property_values[0] = transient_for.asValue().*;
        property_values[1] = use_header_bar.asValue().*;
        return core.objectNewWithProperties(gType(), property_names[0..], property_values[0..]).tryInto(ExampleAppPrefs).?;
    }

    pub fn disposeOverride(self: ExampleAppPrefs) void {
        self.instance.private.settings.callMethod("unref", .{}); // TODO: g_clear_object
        self.callMethod("disposeTemplate", .{gType()});
        self.callMethod("disposeV", .{Parent.gType()});
    }

    pub fn CallMethod(comptime method: []const u8) ?type {
        if (Parent.CallMethod(method)) |some| return some;
        return null;
    }

    pub fn callMethod(self: ExampleAppPrefs, comptime method: []const u8, args: anytype) gen_return_type: {
        if (CallMethod(method)) |some| {
            break :gen_return_type some;
        } else {
            @compileError(std.fmt.comptimePrint("No such method {s}", .{method}));
        }
    } {
        if (Parent.CallMethod(method)) |_| {
            return self.into(Parent).callMethod(method, args);
        } else {
            @compileError("No such method");
        }
    }

    pub fn cType() type {
        return ExampleAppPrefsImpl;
    }

    pub fn gType() core.GType {
        return core.registerType(ExampleAppPrefsClass, ExampleAppPrefs, "ExampleAppPrefs", .{});
    }

    pub fn isAImpl(comptime T: type) bool {
        return meta.trait.hasField("traitExampleAppPrefs")(T);
    }

    pub fn into(self: ExampleAppPrefs, comptime T: type) T {
        return core.upCast(T, self);
    }

    pub fn tryInto(self: ExampleAppPrefs, comptime T: type) ?T {
        return core.downCast(T, self);
    }

    pub fn asSome(self: ExampleAppPrefs) ExampleAppPrefsNullable {
        return .{ .ptr = self.instance };
    }
};
