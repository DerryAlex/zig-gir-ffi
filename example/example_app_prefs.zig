const std = @import("std");
const root = @import("root");
const Gtk = root.Gtk;
const core = root.core;
const meta = std.meta;
const assert = std.debug.assert;
const ExampleAppWindow = @import("example_app_window.zig").ExampleAppWindow;

const Static = struct {
    var type_id: core.GType = core.GType.Invalid;
    var parent_class: ?Gtk.DialogClass = null;
};

const ExampleAppPrefsClassImpl = extern struct {
    parent: Gtk.DialogClass.cType(),
};

pub const ExampleAppPrefsClass = packed struct {
    instance: *ExampleAppPrefsClassImpl,

    pub fn init(self: ExampleAppPrefsClass) callconv(.C) void {
        Static.parent_class = core.unsafeCast(Gtk.DialogClass, core.typeClassPeek(Gtk.Dialog.gType()));
        core.unsafeCast(core.ObjectClass, self).instance.Dispose = &dispose;
        core.unsafeCast(Gtk.WidgetClass, self).setTemplateFromResource("/org/gtk/exampleapp/prefs.ui");
        core.unsafeCast(Gtk.WidgetClass, self).bindTemplateChildFull("font", core.Boolean.new(false), @offsetOf(ExampleAppPrefsImpl, "font"));
        core.unsafeCast(Gtk.WidgetClass, self).bindTemplateChildFull("transition", core.Boolean.new(false), @offsetOf(ExampleAppPrefsImpl, "transition"));
    }

    pub fn dispose(object: core.Object) callconv(.C) void {
        var prefs = core.downCast(ExampleAppPrefs, object).?;
        prefs.callMethod("dispose", .{});
    }
};

const ExampleAppPrefsImpl = extern struct {
    parent: Gtk.Dialog.cType(),
    settings: core.Settings,
    font: Gtk.FontButton,
    transition: Gtk.ComboBoxText,
};

pub const ExampleAppPrefsNullable = packed struct {
    instance: ?*ExampleAppPrefsImpl,

    pub fn new(self: ?ExampleAppPrefs) ExampleAppPrefsNullable {
        return .{ .instance = if (self) |some| some.instance else null };
    }

    pub fn get(self: ExampleAppPrefsNullable) ?ExampleAppPrefs {
        return if (self.instance) |some| ExampleAppPrefs{ .instance = some } else null;
    }
};

pub const ExampleAppPrefs = packed struct {
    instance: *ExampleAppPrefsImpl,
    classGObjectObject: void = {},
    classGObjectInitiallyUnowned: void = {},
    classGtkWidget: void = {},
    classGtkWindow: void = {},
    classGtkDialog: void = {},
    classExampleAppPrefs: void = {},

    pub fn init(self: ExampleAppPrefs) callconv(.C) void {
        self.callMethod("initTemplate", .{});
        self.instance.settings = core.Settings.new("org.gtk.exampleapp");
        self.instance.settings.callMethod("bind", .{ "font", core.upCast(core.Object, self.instance.font), "font", .Default });
        self.instance.settings.callMethod("bind", .{ "transition", core.upCast(core.Object, self.instance.transition), "active-id", .Default });
    }

    pub fn new(win: ExampleAppWindow) ExampleAppPrefs {
        var property_names = [_][*:0]const u8{ "transient-for", "use-header-bar" };
        var property_values = std.mem.zeroes([2]core.Value.cType());
        var transient_for = core.unsafeCastPtr(core.Value, &property_values[0]);
        _ = transient_for.init(core.GType.Object);
        transient_for.setObject(core.ObjectNullable.new(core.upCast(core.Object, win)));
        var use_header_bar = core.unsafeCastPtr(core.Value, &property_values[1]);
        _ = use_header_bar.init(core.GType.Boolean);
        use_header_bar.setBoolean(core.Boolean.new(true));
        return core.downCast(ExampleAppPrefs, core.newObject(gType(), property_names[0..], property_values[0..])).?;
    }

    pub fn dispose(self: ExampleAppPrefs) void {
        self.instance.settings.callMethod("unref", .{});
        const dispose_fn = core.unsafeCast(core.ObjectClass, Static.parent_class.?).instance.Dispose.?;
        dispose_fn(core.upCast(core.Object, self));
    }

    pub fn CallMethod(comptime method: []const u8) ?type {
        if (std.mem.eql(u8, method, "dispose")) return void;
        if (Gtk.Dialog.CallMethod(method)) |some| return some;
        return null;
    }

    pub fn callMethod(self: ExampleAppPrefs, comptime method: []const u8, args: anytype) gen_return_type: {
        if (CallMethod(method)) |some| {
            break :gen_return_type some;
        } else {
            @compileError(std.fmt.comptimePrint("No such method {s}", .{method}));
        }
    } {
        if (comptime std.mem.eql(u8, method, "dispose")) {
            return @call(.auto, dispose, .{self} ++ args);
        } else if (Gtk.Dialog.CallMethod(method)) |_| {
            return core.upCast(Gtk.Dialog, self).callMethod(method, args);
        } else {
            @compileError("No such method");
        }
    }

    pub fn cType() type {
        return ExampleAppPrefsImpl;
    }

    pub fn gType() core.GType {
        if (core.onceInitEnter(&Static.type_id).get()) {
            // zig fmt: off
            var type_id = core.typeRegisterStaticSimple(
                Gtk.Dialog.gType(),
                "ExampleAppPrefs",
                @sizeOf(ExampleAppPrefsClassImpl), @ptrCast(core.ClassInitFunc, &ExampleAppPrefsClass.init),
                @sizeOf(ExampleAppPrefsImpl), @ptrCast(core.InstanceInitFunc, &ExampleAppPrefs.init),
                .None
            );
            // zig fmt: on
            defer core.onceInitLeave(&Static.type_id, type_id.value);
        }
        return Static.type_id;
    }

    pub fn isAImpl(comptime T: type) bool {
        return meta.trait.hasField("classExampleAppPrefs")(T);
    }
};
