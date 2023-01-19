const std = @import("std");
const root = @import("root");
const Gtk = root.Gtk;
const core = Gtk.core;
const meta = std.meta;
const assert = std.debug.assert;
const ExampleAppWindow = @import("example_app_window.zig").ExampleAppWindow;
const ExampleAppPrefs = @import("example_app_prefs.zig").ExampleAppPrefs;

pub const ExampleAppClass = extern struct {
    parent: Gtk.ApplicationClass,

    pub fn init(self: *ExampleAppClass) callconv(.C) void {
        var application_class = @ptrCast(*core.ApplicationClass, self);
        application_class.activate = &activate;
        application_class.open = &open;
        application_class.startup = &startup;
    }

    pub fn activate(arg_app: core.Application) callconv(.C) void {
        var app = arg_app.tryInto(ExampleApp).?;
        app.activateOverride();
    }

    pub fn open(arg_app: core.Application, files: [*]core.File, n_file: i32, hint: [*:0]const u8) callconv(.C) void {
        var app = arg_app.tryInto(ExampleApp).?;
        app.openOverride(files[0..@intCast(usize, n_file)], hint);
    }

    pub fn startup(arg_app: core.Application) callconv(.C) void {
        var app = arg_app.tryInto(ExampleApp).?;
        app.startupOverride();
    }
};

const ExampleAppImpl = extern struct {
    parent: Gtk.Application.cType(),
};

pub const ExampleAppNullable = packed struct {
    ptr: ?*ExampleAppImpl,

    pub fn expect(self: ExampleAppNullable, message: []const u8) ExampleApp {
        if (self.ptr) |some| {
            return ExampleApp{ .instance = some };
        } else @panic(message);
    }

    pub fn wrap(self: ExampleAppNullable) ?ExampleApp {
        return if (self.ptr) |some| ExampleApp{ .instance = some } else null;
    }
};

pub const ExampleApp = packed struct {
    instance: *ExampleAppImpl,
    traitExampleApp: void = {},

    pub const Parent = Gtk.Application;

    fn preferenceActivate(_: core.SimpleAction, _: *core.Variant, self: ExampleApp) void {
        var win = self.callMethod("getActiveWindow", .{}).expect("active window").tryInto(ExampleAppWindow).?;
        var prefs = ExampleAppPrefs.new(win);
        prefs.callMethod("present", .{});
    }

    fn quitActivate(_: core.SimpleAction, _: *core.Variant, self: ExampleApp) void {
        self.callMethod("quit", .{});
    }

    pub fn new() ExampleApp {
        var property_names = [_][*:0]const u8{ "application-id", "flags" };
        var property_values = std.mem.zeroes([2]core.Value);
        var application_id = property_values[0].init(core.GType.String);
        defer application_id.unset();
        application_id.setStaticString("org.gtk.example");
        var flags = property_values[1].init(core.GType.Flags);
        defer flags.unset();
        flags.setFlags(@enumToInt(core.ApplicationFlags.HandlesOpen));
        return core.newObject(gType(), property_names[0..], property_values[0..]).tryInto(ExampleApp).?;
    }

    pub fn activateOverride(self: ExampleApp) void {
        var win = ExampleAppWindow.new(self);
        win.callMethod("present", .{});
    }

    pub fn openOverride(self: ExampleApp, files: []core.File, hint: [*:0]const u8) void {
        _ = hint;
        var windows = self.callMethod("getWindows", .{});
        var win = if (windows) |some| core.dynamicCast(ExampleAppWindow, some.data.?).? else ExampleAppWindow.new(self);
        for (files) |file| {
            win.open(file);
        }
        win.callMethod("present", .{});
    }

    pub fn startupOverride(self: ExampleApp) void {
        var action_preference = core.createClosure(preferenceActivate, .{self}, false, &[_]type{ void, core.SimpleAction, *core.Variant }); // Memery leak, we don't call `closure.deinit` or ask glib to destroy it
        var action_quit = core.createClosure(quitActivate, .{self}, false, &[_]type{ void, core.SimpleAction, *core.Variant });
        // zig fmt: off
        var app_entries = [_]core.ActionEntry{
            .{ .name = "preferences", .activate = action_preference.invoke_fn(), .parameter_type = null, .state = null, .change_state = null, .padding = undefined },
            .{ .name = "quit", .activate = action_quit.invoke_fn(), .parameter_type = null, .state = null, .change_state = null, .padding = undefined },
        };
        // zig fmt: on
        self.callMethod("startupV", .{Parent.gType()});
        self.callMethod("addActionEntries", .{ app_entries[0..1], action_preference });
        self.callMethod("addActionEntries", .{ app_entries[1..2], action_quit });
        var quit_accels = [_:null]?[*:0]const u8{"<Ctrl>Q"};
        self.callMethod("setAccelsForAction", .{ "app.quit", &quit_accels });
    }

    pub fn CallMethod(comptime method: []const u8) ?type {
        if (Parent.CallMethod(method)) |some| return some;
        return null;
    }

    pub fn callMethod(self: ExampleApp, comptime method: []const u8, args: anytype) gen_return_type: {
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
        return ExampleAppImpl;
    }

    pub fn gType() core.GType {
        return core.registerType(ExampleAppClass, ExampleApp, "ExampleApp", .{ .final = true });
    }

    pub fn isAImpl(comptime T: type) bool {
        return meta.trait.hasField("traitExampleApp")(T);
    }

    pub fn into(self: ExampleApp, comptime T: type) T {
        return core.upCast(T, self);
    }

    pub fn tryInto(self: ExampleApp, comptime T: type) ?T {
        return core.downCast(T, self);
    }

    pub fn asSome(self: ExampleApp) ExampleAppNullable {
        return .{ .ptr = self.instance };
    }
};
