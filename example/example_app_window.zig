const std = @import("std");
const root = @import("root");
const Gtk = root.Gtk;
const core = root.core;
const meta = std.meta;
const ExampleApp = @import("example_app.zig").ExampleApp;

const Static = struct {
    var type_id: core.GType = core.GType.Invalid;
};

const ExampleAppWindowClassImpl = extern struct {
    parent: Gtk.ApplicationWindowClass.cType(),
};

pub const ExampleAppWindowClass = packed struct {
    instance: *ExampleAppWindowClassImpl,

    pub fn init(self: ExampleAppWindowClass) callconv(.C) void {
        core.unsafeCast(Gtk.WidgetClass, self).setTemplateFromResource("/org/gtk/exampleapp/window.ui");
        core.unsafeCast(Gtk.WidgetClass, self).bindTemplateChildFull("stack", core.Boolean.new(false), @offsetOf(ExampleAppWindowImpl, "stack"));
    }
};

const ExampleAppWindowImpl = extern struct {
    parent: Gtk.ApplicationWindow.cType(),
    stack: Gtk.Stack,
};

pub const ExampleAppWindowNullable = packed struct {
    instance: ?*ExampleAppWindowImpl,

    pub fn new(self: ?ExampleAppWindow) ExampleAppWindowNullable {
        return .{ .instance = if (self) |some| some.instance else null };
    }

    pub fn get(self: ExampleAppWindowNullable) ?ExampleAppWindow {
        return if (self.instance) |some| ExampleAppWindow{ .instance = some } else null;
    }
};

pub const ExampleAppWindow = packed struct {
    instance: *ExampleAppWindowImpl,
    classGObjectObject: void = {},
    classGObjectInitiallyUnowned: void = {},
    classGtkWidget: void = {},
    classGtkWindow: void = {},
    classGtkApplicationWindow: void = {},
    classExampleAppWindow: void = {},

    pub fn init(self: ExampleAppWindow) callconv(.C) void {
        self.callMethod("initTemplate", .{});
    }

    pub fn new(arg_app: ExampleApp) ExampleAppWindow {
        var property_names = [_][*:0]const u8{"application"};
        var property_values = std.mem.zeroes([1]core.Value.cType());
        var application = core.unsafeCastPtr(core.Value, &property_values[0]);
        _ = application.init(core.GType.Object);
        application.setObject(core.ObjectNullable.new(core.upCast(core.Object, arg_app)));
        return core.downCast(ExampleAppWindow, core.newObject(gType(), property_names[0..], property_values[0..])).?;
    }

    pub fn open(self: ExampleAppWindow, file: core.File) void {
        var basename = file.getBasename().?;
        defer core.freeDiscardConst(basename);
        var scrolled = core.downCast(Gtk.ScrolledWindow, Gtk.ScrolledWindow.new()).?;
        scrolled.callMethod("setHexpand", .{core.Boolean.new(true)});
        scrolled.callMethod("setVexpand", .{core.Boolean.new(true)});
        var view = core.downCast(Gtk.TextView, Gtk.TextView.new()).?;
        view.callMethod("setEditable", .{core.Boolean.new(false)});
        view.callMethod("setCursorVisible", .{core.Boolean.new(false)});
        scrolled.callMethod("setChild", .{Gtk.WidgetNullable.new(core.upCast(Gtk.Widget, view))});
        _ = self.instance.stack.callMethod("addTitled", .{ core.upCast(Gtk.Widget, scrolled), basename, basename });
        var result = file.loadContents(core.CancellableNullable.new(null));
        switch (result) {
            .Ok => |ok| {
                defer core.free(ok.contents.ptr);
                defer core.freeDiscardConst(ok.etag_out);
                var buffer = view.callMethod("getBuffer", .{});
                buffer.setText(@ptrCast([*:0]const u8, ok.contents.ptr), @intCast(i32, ok.contents.len));
            },
            .Err => |err| {
                defer err.free();
                std.log.warn("{s}", .{err.instance.Message.?});
                return;
            },
        }
    }

    pub fn CallMethod(comptime method: []const u8) ?type {
        if (std.mem.eql(u8, method, "open")) return void;
        if (Gtk.ApplicationWindow.CallMethod(method)) |some| return some;
        return null;
    }

    pub fn callMethod(self: ExampleAppWindow, comptime method: []const u8, args: anytype) gen_return_type: {
        if (CallMethod(method)) |some| {
            break :gen_return_type some;
        } else {
            @compileError(std.fmt.comptimePrintf("No such method {s}", .{method}));
        }
    } {
        if (comptime std.mem.eql(u8, method, "open")) {
            return @call(.auto, open, .{self} ++ args);
        } else if (Gtk.ApplicationWindow.CallMethod(method)) |_| {
            return core.upCast(Gtk.ApplicationWindow, self).callMethod(method, args);
        } else {
            @compileError("No such method");
        }
    }

    pub fn cType() type {
        return ExampleAppWindowImpl;
    }

    pub fn gType() core.GType {
        if (core.onceInitEnter(&Static.type_id).get()) {
            // zig fmt: off
            var type_id = core.typeRegisterStaticSimple(
                Gtk.ApplicationWindow.gType(),
                "ExampleAppWindow",
                @sizeOf(ExampleAppWindowClassImpl), @ptrCast(core.ClassInitFunc, &ExampleAppWindowClass.init),
                @sizeOf(ExampleAppWindowImpl), @ptrCast(core.InstanceInitFunc, &ExampleAppWindow.init),
                .None
            );
            // zig fmt: on
            defer core.onceInitLeave(&Static.type_id, type_id.value);
        }
        return Static.type_id;
    }

    pub fn isAImpl(comptime T: type) bool {
        return meta.trait.hasField("classExampleAppWindow")(T);
    }
};
