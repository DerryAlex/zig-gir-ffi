const std = @import("std");
const root = @import("root");
const Gtk = root.Gtk;
const core = Gtk.core;
const meta = std.meta;
const assert = std.debug.assert;
const ExampleAppWindow = @import("example_app_window.zig").ExampleAppWindow;
const ExampleAppPrefs = @import("example_app_prefs.zig").ExampleAppPrefs;
const Action = core.Action;
const Application = Gtk.Application;
const ApplicationClass = Gtk.ApplicationClass;
const ApplicationFlags = core.ApplicationFlags;
const File = core.File;
const SimpleAction = core.SimpleAction;
const Value = core.Value;
const GApplication = core.Application;
const GApplicationClass = core.ApplicationClass;

pub const ExampleAppClass = extern struct {
    parent: ApplicationClass,

    pub fn init(class: *ExampleAppClass) void {
        var gapplication_class = @ptrCast(*GApplicationClass, class);
        gapplication_class.activate = &activate;
        gapplication_class.open = &open;
        gapplication_class.startup = &startup;
    }

    // @override
    fn activate(arg_app: *GApplication) callconv(.C) void {
        var self = arg_app.tryInto(ExampleApp).?;
        var win = ExampleAppWindow.new(self);
        win.__call("present", .{});
    }

    // @override
    fn open(arg_app: *GApplication, arg_files: [*]*File, arg_n_files: i32, arg_hint: [*:0]const u8) callconv(.C) void {
        var self = arg_app.tryInto(ExampleApp).?;
        _ = arg_hint;
        var windows = self.__call("getWindows", .{});
        var win = if (windows) |some| core.dynamicCast(ExampleAppWindow, some.data.?).? else ExampleAppWindow.new(self);
        for (arg_files[0..@intCast(usize, arg_n_files)]) |file| {
            win.__call("open", .{file});
        }
        win.__call("present", .{});
    }

    fn preferencesActivate(self: *ExampleApp) void {
        var win = self.__call("getActiveWindow", .{}).?.tryInto(ExampleAppWindow).?;
        var prefs = ExampleAppPrefs.new(win);
        prefs.__call("present", .{});
    }

    fn quitActivate(self: *ExampleApp) void {
        self.__call("quit", .{});
    }

    // @override
    fn startup(arg_app: *GApplication) callconv(.C) void {
        var self = arg_app.tryInto(ExampleApp).?;
        var action_preferences = SimpleAction.new("preferences", null);
        defer action_preferences.__call("unref", .{});
        _ = action_preferences.connectActivateSwap(preferencesActivate, .{self}, .{});
        self.__call("addAction", .{action_preferences.into(Action)});
        var action_quit = SimpleAction.new("quit", null);
        defer action_quit.__call("unref", .{});
        _ = action_quit.connectActivateSwap(quitActivate, .{self}, .{});
        self.__call("addAction", .{action_quit.into(Action)});
        var quit_accels = [_:null]?[*:0]const u8{"<Ctrl>Q"};
        self.__call("setAccelsForAction", .{ "app.quit", &quit_accels });
        self.__call("startupV", .{ExampleApp.Parent.type()});
    }
};

pub const ExampleApp = extern struct {
    parent: Parent,

    pub const Parent = Application;
    pub usingnamespace core.Extend(ExampleApp);

    pub fn new() *ExampleApp {
        var application_id = core.ValueZ([*:0]const u8).init();
        defer application_id.deinit();
        application_id.set("org.gtk.example");
        var flags = core.ValueZ(core.ApplicationFlags).init();
        defer flags.deinit();
        flags.set(.HandlesOpen);
        var property_names = [_][*:0]const u8{ "application-id", "flags" };
        var property_values = [_]Value{ application_id.value, flags.value };
        return core.newObject(ExampleApp, property_names[0..], property_values[0..]);
    }

    pub fn @"type"() core.Type {
        return core.registerType(ExampleAppClass, ExampleApp, "ExampleApp", .{ .final = true });
    }
};
