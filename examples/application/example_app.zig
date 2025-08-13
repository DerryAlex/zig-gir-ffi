const std = @import("std");
const gi = @import("gi");
const core = gi.core;
const GObject = gi.GObject;
const Gio = gi.Gio;
const Gtk = gi.Gtk;
const ExampleAppWindow = @import("example_app_window.zig").ExampleAppWindow;
const ExampleAppPrefs = @import("example_app_prefs.zig").ExampleAppPrefs;
const Action = Gio.Action;
const ActionMap = Gio.ActionMap;
const Application = Gtk.Application;
const File = Gio.File;
const Object = GObject.Object;
const SimpleAction = Gio.SimpleAction;
const Window = Gtk.Window;

pub const ExampleAppClass = extern struct {
    parent_class: Application.Class,
};

pub const ExampleApp = extern struct {
    parent: Parent,

    pub const Parent = Application;
    pub const Class = ExampleAppClass;

    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub const getParentClass = Ext.getParentClass;

    pub const Override = struct {
        pub fn activate(app: *Gio.Application) callconv(.c) void {
            const self = app.tryInto(ExampleApp).?;
            const win: *ExampleAppWindow = .new(self);
            win.into(Gtk.Window).present();
        }

        pub fn open(app: *Gio.Application, files: [*]*File, n_files: i32, hint: [*:0]const u8) callconv(.c) void {
            _ = hint;
            const self = app.tryInto(ExampleApp).?;
            const windows = app.tryInto(Application).?.getWindows();
            const win = if (windows) |some| core.dynamicCast(ExampleAppWindow, some.data.?).? else ExampleAppWindow.new(self);
            for (files[0..@intCast(n_files)]) |file| {
                win.open(file);
            }
            win.into(Gtk.Window).present();
        }

        pub fn startup(app: *Gio.Application) callconv(.c) void {
            const self = app.tryInto(ExampleApp).?;
            const act_pref: *SimpleAction = .new("preferences", null);
            defer act_pref.into(Object).unref();
            _ = act_pref._signals.activate.connect(.init(preferencesActivate, .{self}), .{});
            self.into(ActionMap).addAction(act_pref.into(Action));
            const act_quit: *SimpleAction = .new("quit", null);
            defer act_quit.into(Object).unref();
            _ = act_quit._signals.activate.connect(.init(quitActivate, .{self}), .{});
            self.into(ActionMap).addAction(act_quit.into(Action));
            var quit_accels = [_:null]?[*:0]const u8{"<Ctrl>Q"};
            self.into(Application).setAccelsForAction("app.quit", &quit_accels);
            const p_class = self.getParentClass(Gio.Application);
            p_class.startup.?(app);
        }
    };

    pub fn new() *ExampleApp {
        const self = core.newObject(ExampleApp);
        self.into(Gio.Application)._props.@"application-id".set("org.gtk.example");
        self.into(Gio.Application)._props.flags.set(.{ .handles_open = true });
        return self;
    }

    fn preferencesActivate(self: *ExampleApp) void {
        const win = self.into(Application).getActiveWindow().?.tryInto(ExampleAppWindow).?;
        const prefs: *ExampleAppPrefs = .new(win);
        prefs.into(Window).present();
    }

    fn quitActivate(self: *ExampleApp) void {
        self.into(Gio.Application).quit();
    }

    pub fn gType() core.Type {
        return core.registerType(ExampleApp, "ExampleApp", .{ .final = true });
    }
};
