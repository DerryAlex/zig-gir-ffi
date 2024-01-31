const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const meta = std.meta;
const assert = std.debug.assert;
const ExampleAppWindow = @import("example_app_window.zig").ExampleAppWindow;
const ExampleAppPrefs = @import("example_app_prefs.zig").ExampleAppPrefs;
const Action = core.Action;
const Application = gtk.Application;
const ApplicationClass = gtk.ApplicationClass;
const ApplicationFlags = core.ApplicationFlags;
const File = core.File;
const SimpleAction = core.SimpleAction;
const Value = core.Value;
const GApplication = core.Application;
const GApplicationClass = core.ApplicationClass;

pub const ExampleAppClass = extern struct {
    parent: ApplicationClass,

    pub fn activate_override(arg_app: *GApplication) callconv(.C) void {
        const self = arg_app.tryInto(ExampleApp).?;
        var win = ExampleAppWindow.new(self);
        win.__call("present", .{});
    }

    pub fn open_override(arg_app: *GApplication, arg_files: [*]*File, arg_n_files: i32, arg_hint: [*:0]const u8) callconv(.C) void {
        var self = arg_app.tryInto(ExampleApp).?;
        _ = arg_hint;
        const windows = self.__call("getWindows", .{});
        const win = if (windows) |some| core.dynamicCast(ExampleAppWindow, some.data.?).? else ExampleAppWindow.new(self);
        for (arg_files[0..@intCast(arg_n_files)]) |file| {
            win.__call("open", .{file});
        }
        win.__call("present", .{});
    }

    fn preferencesActivate(self: *ExampleApp) void {
        const win = self.__call("getActiveWindow", .{}).?.tryInto(ExampleAppWindow).?;
        var prefs = ExampleAppPrefs.new(win);
        prefs.__call("present", .{});
    }

    fn quitActivate(self: *ExampleApp) void {
        self.__call("quit", .{});
    }

    pub fn startup_override(arg_app: *GApplication) callconv(.C) void {
        var self = arg_app.tryInto(ExampleApp).?;
        var action_preferences = SimpleAction.new("preferences", null);
        defer action_preferences.__call("unref", .{});
        _ = action_preferences.connectActivate(preferencesActivate, .{self}, .{ .swapped = true });
        self.__call("addAction", .{action_preferences.into(Action)});
        var action_quit = SimpleAction.new("quit", null);
        defer action_quit.__call("unref", .{});
        _ = action_quit.connectActivate(quitActivate, .{self}, .{ .swapped = true });
        self.__call("addAction", .{action_quit.into(Action)});
        var quit_accels = [_:null]?[*:0]const u8{"<Ctrl>Q"};
        self.__call("setAccelsForAction", .{ "app.quit", &quit_accels });
        self.__call("startupV", .{ExampleApp.Parent.gType()});
    }
};

pub const ExampleApp = extern struct {
    parent: Parent,

    pub const Parent = Application;
    pub const Class = ExampleAppClass;
    pub usingnamespace core.Extend(ExampleApp);

    pub fn new() *ExampleApp {
        return core.newObject(ExampleApp, .{
            .@"application-id" = "org.gtk.example",
            .flags = core.ApplicationFlags{ .handles_open = true },
        });
    }

    pub fn gType() core.Type {
        return core.registerType(ExampleApp, "ExampleApp", .{ .final = true });
    }
};
