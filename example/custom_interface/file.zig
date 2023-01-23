const std = @import("std");
const root = @import("root");
const Gtk = root.Gtk;
const core = Gtk.core;
const meta = std.meta;
const Editable = @import("editable.zig").Editable;

pub const FileClass = extern struct {
    parent: core.ObjectClass,
};

pub const FileImpl = extern struct {
    parent: core.Object.cType(),
};

pub const File = packed struct {
    instance: *FileImpl,
    traitFile: void = {},
    traitEditable: void = {},

    pub const Parent = core.Object;

    pub fn new() File {
        return core.objectNewWithProperties(gType(), null, null).tryInto(File).?;
    }

    fn saveFile(_: Editable) void {
        std.log.info("save file", .{});
    }

    fn initEditable(self: Editable) callconv(.C) void {
        self.instance.save = &saveFile;
    }

    fn register(type_id: core.GType) void {
        core.registerInterfaceImplementation(type_id, Editable, &initEditable);
    }

    pub fn CallMethod(comptime method: []const u8) ?type {
        if (Editable.CallMethod(method)) |some| return some;
        if (Parent.CallMethod(method)) |some| return some;
        return null;
    }

    pub fn callMethod(self: File, comptime method: []const u8, args: anytype) gen_return_type: {
        if (CallMethod(method)) |some| {
            break :gen_return_type some;
        } else {
            @compileError(std.fmt.comptimePrint("No such method {s}", .{method}));
        }
    } {
        if (Editable.CallMethod(method)) |_| {
            return self.into(Editable).callMethod(method, args);
        } else if (Parent.CallMethod(method)) |_| {
            return self.into(Parent).callMethod(method, args);
        } else {
            @compileError("No such method");
        }
    }

    pub fn cType() type {
        return FileImpl;
    }

    pub fn gType() core.GType {
        return core.registerType(FileClass, File, "File", .{ .extra_register_fn = &register });
    }

    pub fn isAImpl(comptime T: type) bool {
        return meta.trait.hasField("traitFile")(T);
    }

    pub fn into(self: File, comptime T: type) T {
        return core.upCast(T, self);
    }

    pub fn tryInto(self: File, comptime T: type) ?T {
        return core.downCast(T, self);
    }
};
