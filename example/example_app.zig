const std = @import("std");
const root = @import("root");
const Gtk = root.Gtk;
const core = root.core;
const meta = std.meta;
const ExampleAppWindow = @import("example_app_window.zig").ExampleAppWindow;

const Static = struct {
    var type_id: core.GType = core.GType.Invalid;
};

const ExampleAppClassImpl = extern struct {
    parent: Gtk.ApplicationClass.cType(),
};

pub const ExampleAppClass = packed struct {
    instance: *ExampleAppClassImpl,

    pub fn init(self: ExampleAppClass) callconv(.C) void {
        core.unsafeCast(core.ApplicationClass, self).instance.Activate = &activate;
        core.unsafeCast(core.ApplicationClass, self).instance.Open = &open;
    }

    pub fn activate(arg_app: core.Application) callconv(.C) void {
        var app = core.downCast(ExampleApp, arg_app).?;
        app.activate();
    }

    pub fn open(arg_app: core.Application, files: [*]core.File, n_file: i32, hint: [*:0]const u8) callconv(.C) void {
        var app = core.downCast(ExampleApp, arg_app).?;
        app.open(files[0..@intCast(usize, n_file)], hint);
    }
};

const ExampleAppImpl = extern struct {
    parent: Gtk.Application.cType(),
};

pub const ExampleAppNullable = packed struct {
    instance: ?*ExampleAppImpl,

    pub fn new(self: ?ExampleApp) ExampleAppNullable {
        return .{ .instance = if (self) |some| some.instance else null };
    }

    pub fn get(self: ExampleAppNullable) ?ExampleApp {
        return if (self.instance) |some| ExampleApp{ .instance = some } else null;
    }
};

pub const ExampleApp = packed struct {
    instance: *ExampleAppImpl,
    classGObjectObject: void = {},
    classGioApplication: void = {},
    classGtkApplication: void = {},
    classExampleApp: void = {},

    pub fn init() callconv(.C) void {}

    pub fn new() ExampleApp {
        var property_names = [_][*:0]const u8{ "application-id", "flags" };
        var property_values = std.mem.zeroes([2]core.Value.cType());
        var application_id = core.unsafeCastPtr(core.Value, &property_values[0]);
        _ = application_id.init(core.GType.String);
        application_id.setStaticString("org.gtk.example");
        var flags = core.unsafeCastPtr(core.Value, &property_values[1]);
        _ = flags.init(core.GType.Flags);
        flags.setFlags(@enumToInt(core.ApplicationFlags.HandlesOpen));
        return core.downCast(ExampleApp, core.newObject(gType(), property_names[0..], property_values[0..])).?;
    }

    pub fn activate(self: ExampleApp) void {
        var win = ExampleAppWindow.new(self);
        win.callMethod("present", .{});
    }

    pub fn open(self: ExampleApp, files: []core.File, hint: [*:0]const u8) void {
        _ = hint;
        var windows = self.callMethod("getWindows", .{});
        var win = if (windows.get()) |some| core.unsafeCastPtr(ExampleAppWindow, some.instance.Data.?) else ExampleAppWindow.new(self);
        for (files) |file| {
            win.callMethod("open", .{file});
        }
        win.callMethod("present", .{});
    }

    pub fn CallMethod(comptime method: []const u8) ?type {
        if (std.mem.eql(u8, method, "activate")) return void;
        if (std.mem.eql(u8, method, "open")) return void;
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
        } else if (Gtk.Application.CallMethod(method)) |_| {
            return core.upCast(Gtk.Application, self).callMethod(method, args);
        } else {
            @compileError("No such method");
        }
    }

    pub fn cType() type {
        return ExampleAppImpl;
    }

    pub fn gType() core.GType {
        if (core.onceInitEnter(&Static.type_id).get()) {
            // zig fmt: off
            var type_id = core.typeRegisterStaticSimple(
                Gtk.Application.gType(),
                "ExampleApp",
                @sizeOf(ExampleAppClassImpl), @ptrCast(core.ClassInitFunc, &ExampleAppClass.init),
                @sizeOf(ExampleAppImpl), @ptrCast(core.InstanceInitFunc, &ExampleApp.init),
                .None
            );
            // zig fmt: on
            defer core.onceInitLeave(&Static.type_id, type_id.value);
        }
        return Static.type_id;
    }

    pub fn isAImpl(comptime T: type) bool {
        return meta.trait.hasField("classExampleApp")(T);
    }
};
