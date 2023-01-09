const std = @import("std");
const root = @import("root");
const Gtk = root.Gtk;
const core = root.core;
const meta = std.meta;
const assert = std.debug.assert;
const ExampleAppWindow = @import("example_app_window.zig").ExampleAppWindow;
const ExampleAppPrefs = @import("example_app_prefs.zig").ExampleAppPrefs;

const Static = struct {
    var type_id: core.GType = core.GType.Invalid;
    var parent_class: ?*Gtk.ApplicationClass = null;
};

pub const ExampleAppClass = extern struct {
    parent: Gtk.ApplicationClass,

    pub fn init(self: *ExampleAppClass) callconv(.C) void {
        Static.parent_class = @ptrCast(*Gtk.ApplicationClass, core.typeClassPeek(Gtk.Application.gType()));
        var application_class = @ptrCast(*core.ApplicationClass, self);
        application_class.activate = &activate;
        application_class.open = &open;
        application_class.startup = &startup;
    }

    pub fn activate(arg_app: core.Application) callconv(.C) void {
        var app = arg_app.tryInto(ExampleApp).?;
        app.activate();
    }

    pub fn open(arg_app: core.Application, files: [*]core.File, n_file: i32, hint: [*:0]const u8) callconv(.C) void {
        var app = arg_app.tryInto(ExampleApp).?;
        app.open(files[0..@intCast(usize, n_file)], hint);
    }

    pub fn startup(arg_app: core.Application) callconv(.C) void {
        var app = arg_app.tryInto(ExampleApp).?;
        app.startup();
    }
};

const ExampleAppImpl = extern struct {
    parent: Gtk.Application.cType(),
};

pub const ExampleAppNullable = packed struct {
    ptr: ?*ExampleAppImpl,

    pub const Nil = ExampleAppNullable{ .ptr = null };

    pub fn from(that: ?ExampleApp) ExampleAppNullable {
        return .{ .ptr = if (that) |some| some.instance else null };
    }

    pub fn tryInto(self: ExampleAppNullable) ?ExampleApp {
        return if (self.ptr) |some| ExampleApp{ .instance = some } else null;
    }
};

pub const ExampleApp = packed struct {
    instance: *ExampleAppImpl,
    traitGObjectObject: void = {},
    traitGioApplication: void = {},
    traitGtkApplication: void = {},
    traitExampleApp: void = {},

    fn preferenceActivate(_: core.SimpleAction, _: *core.Variant, self: ExampleApp) void {
        var win = self.callMethod("getActiveWindow", .{}).tryInto().?.tryInto(ExampleAppWindow).?;
        var prefs = ExampleAppPrefs.new(win);
        prefs.callMethod("present", .{});
    }

    fn quitActivate(_: core.SimpleAction, _: *core.Variant, self: ExampleApp) void {
        self.callMethod("quit", .{});
    }

    pub fn init() callconv(.C) void {}

    pub fn new() ExampleApp {
        var property_names = [_][*:0]const u8{ "application-id", "flags" };
        var property_values = std.mem.zeroes([2]core.Value);
        var application_id = &property_values[0];
        _ = application_id.init(core.GType.String);
        application_id.setStaticString("org.gtk.example");
        var flags = &property_values[1];
        _ = flags.init(core.GType.Flags);
        flags.setFlags(@enumToInt(core.ApplicationFlags.HandlesOpen));
        return core.newObject(gType(), property_names[0..], property_values[0..]).tryInto(ExampleApp).?;
    }

    pub fn activate(self: ExampleApp) void {
        var win = ExampleAppWindow.new(self);
        win.callMethod("present", .{});
    }

    pub fn open(self: ExampleApp, files: []core.File, hint: [*:0]const u8) void {
        _ = hint;
        var windows = self.callMethod("getWindows", .{});
        var win = if (windows) |some| core.unsafeCastPtr(ExampleAppWindow, some.data.?) else ExampleAppWindow.new(self);
        for (files) |file| {
            win.open(file);
        }
        win.callMethod("present", .{});
    }

    pub fn startup(self: ExampleApp) void {
        var action_preference = core.createClosure(preferenceActivate, .{self}, false, .{ void, core.SimpleAction, *core.Variant }); // Memery leak, we don't call `closure.deinit` or ask glib to destroy it
        var action_quit = core.createClosure(quitActivate, .{self}, false, .{ void, core.SimpleAction, *core.Variant });
        // zig fmt: off
        var app_entries = [_]core.ActionEntry{
            .{ .name = "preferences", .activate = action_preference.invoke_fn(), .parameter_type = null, .state = null, .change_state = null, .padding = undefined },
            .{ .name = "quit", .activate = action_quit.invoke_fn(), .parameter_type = null, .state = null, .change_state = null, .padding = undefined },
        };
        // zig fmt: on
        const startup_fn = @ptrCast(*core.ApplicationClass, Static.parent_class.?).startup.?;
        startup_fn(self.into(core.Application));
        self.callMethod("addActionEntries", .{ app_entries[0..1], action_preference });
        self.callMethod("addActionEntries", .{ app_entries[1..2], action_quit });
        var quit_accels = [_:null]?[*:0]const u8{"<Ctrl>Q"};
        self.callMethod("setAccelsForAction", .{ "app.quit", &quit_accels });
    }

    pub fn CallMethod(comptime method: []const u8) ?type {
        if (std.mem.eql(u8, method, "activate")) return void;
        if (std.mem.eql(u8, method, "open")) return void;
        if (std.mem.eql(u8, method, "startup")) return void;
        if (Gtk.Application.CallMethod(method)) |some| return some;
        return null;
    }

    pub fn callMethod(self: ExampleApp, comptime method: []const u8, args: anytype) gen_return_type: {
        if (CallMethod(method)) |some| {
            break :gen_return_type some;
        } else {
            @compileError(std.fmt.comptimePrint("No such method {s}", .{method}));
        }
    } {
        if (comptime std.mem.eql(u8, method, "activate")) {
            return @call(.auto, activate, .{self} ++ args);
        } else if (comptime std.mem.eql(u8, method, "open")) {
            return @call(.auto, open, .{self} ++ args);
        } else if (comptime std.mem.eql(u8, method, "startup")) {
            return @call(.auto, startup, .{self} ++ args);
        } else if (Gtk.Application.CallMethod(method)) |_| {
            return self.into(Gtk.Application).callMethod(method, args);
        } else {
            @compileError("No such method");
        }
    }

    pub fn cType() type {
        return ExampleAppImpl;
    }

    pub fn gType() core.GType {
        if (core.onceInitEnter(&Static.type_id).into()) {
            // zig fmt: off
            var type_id = core.typeRegisterStaticSimple(
                Gtk.Application.gType(),
                "ExampleApp",
                @sizeOf(ExampleAppClass), @ptrCast(core.ClassInitFunc, &ExampleAppClass.init),
                @sizeOf(ExampleAppImpl), @ptrCast(core.InstanceInitFunc, &ExampleApp.init),
                .None
            );
            // zig fmt: on
            defer core.onceInitLeave(&Static.type_id, type_id.value);
        }
        return Static.type_id;
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
