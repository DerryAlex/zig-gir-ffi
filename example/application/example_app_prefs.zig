const std = @import("std");
const root = @import("root");
const Gtk = root.Gtk;
const core = Gtk.core;
const meta = std.meta;
const assert = std.debug.assert;
const ExampleAppWindow = @import("example_app_window.zig").ExampleAppWindow;

const Static = struct {
    var type_id: core.GType = core.GType.Invalid;
    var parent_class: ?*Gtk.DialogClass = null;
};

const ExampleAppPrefsClass = extern struct {
    parent: Gtk.DialogClass,

    pub fn init(self: *ExampleAppPrefsClass) callconv(.C) void {
        Static.parent_class = @ptrCast(*Gtk.DialogClass, core.typeClassPeek(Gtk.Dialog.gType()));
        var object_class = @ptrCast(*core.ObjectClass, self);
        object_class.dispose = &dispose;
        var widget_class = @ptrCast(*Gtk.WidgetClass, self);
        widget_class.setTemplateFromResource("/org/gtk/exampleapp/prefs.ui");
        widget_class.bindTemplateChildFull("font", core.Boolean.False, @offsetOf(ExampleAppPrefsImpl, "font"));
        widget_class.bindTemplateChildFull("transition", core.Boolean.False, @offsetOf(ExampleAppPrefsImpl, "transition"));
    }

    pub fn dispose(object: core.Object) callconv(.C) void {
        var prefs = object.tryInto(ExampleAppPrefs).?;
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
    ptr: ?*ExampleAppPrefsImpl,

    pub fn expect(self: ExampleAppPrefsNullable, message: []const u8) ExampleAppPrefs {
        if (self.ptr) |some| {
            return ExampleAppPrefs{ .instance = some };
        } else @panic(message);
    }

    pub fn tryUnwrap(self: ExampleAppPrefsNullable) ?ExampleAppPrefs {
        return if (self.ptr) |some| ExampleAppPrefs{ .instance = some } else null;
    }
};

pub const ExampleAppPrefs = packed struct {
    instance: *ExampleAppPrefsImpl,
    traitExampleAppPrefs: void = {},

    pub const Parent = Gtk.Dialog;

    pub fn init(self: ExampleAppPrefs) callconv(.C) void {
        self.callMethod("initTemplate", .{});
        self.instance.settings = core.Settings.new("org.gtk.exampleapp");
        self.instance.settings.callMethod("bind", .{ "font", self.instance.font.into(core.Object), self.instance.font.callMethod("propertyFont", .{}).name(), .Default });
        self.instance.settings.callMethod("bind", .{ "transition", self.instance.transition.into(core.Object), self.instance.transition.callMethod("propertyActiveId", .{}).name(), .Default });
    }

    pub fn new(win: ExampleAppWindow) ExampleAppPrefs {
        var property_names = [_][*:0]const u8{ "transient-for", "use-header-bar" };
        var property_values = std.mem.zeroes([2]core.Value);
        var transient_for = &property_values[0];
        _ = transient_for.init(core.GType.Object);
        transient_for.setObject(win.into(core.Object).asSome());
        var use_header_bar = &property_values[1];
        _ = use_header_bar.init(core.GType.Boolean);
        use_header_bar.setBoolean(core.Boolean.True);
        return core.downCast(ExampleAppPrefs, core.newObject(gType(), property_names[0..], property_values[0..])).?;
    }

    pub fn dispose(self: ExampleAppPrefs) void {
        self.instance.settings.callMethod("unref", .{});
        const dispose_fn = @ptrCast(*core.ObjectClass, Static.parent_class.?).dispose.?;
        dispose_fn(self.into(core.Object));
    }

    pub fn CallMethod(comptime method: []const u8) ?type {
        if (std.mem.eql(u8, method, "dispose")) return void;
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
        if (comptime std.mem.eql(u8, method, "dispose")) {
            return @call(.auto, dispose, .{self} ++ args);
        } else if (Parent.CallMethod(method)) |_| {
            return self.into(Parent).callMethod(method, args);
        } else {
            @compileError("No such method");
        }
    }

    pub fn cType() type {
        return ExampleAppPrefsImpl;
    }

    pub fn gType() core.GType {
        if (core.onceInitEnter(&Static.type_id).toBool()) {
            // zig fmt: off
            var type_id = core.typeRegisterStaticSimple(
                Gtk.Dialog.gType(),
                "ExampleAppPrefs",
                @sizeOf(ExampleAppPrefsClass), @ptrCast(core.ClassInitFunc, &ExampleAppPrefsClass.init),
                @sizeOf(ExampleAppPrefsImpl), @ptrCast(core.InstanceInitFunc, &ExampleAppPrefs.init),
                .None
            );
            // zig fmt: on
            defer core.onceInitLeave(&Static.type_id, type_id.value);
        }
        return Static.type_id;
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
