const std = @import("std");
const root = @import("root");
const Gtk = root.Gtk;
const core = Gtk.core;
const meta = std.meta;

pub const EditableInterface = extern struct {
    parent: core.TypeInterface,
    save: ?*const fn (Editable) void,
};

pub const Editable = packed struct {
    instance: *EditableInterface,
    traitEditable: void = {},

    pub fn init(self: Editable) void {
        self.instance.save = &saveDefault;
    }

    pub fn save(self: Editable) void {
        const interface = core.typeInstanceGetInterface(Editable, self);
        const save_fn = interface.save.?;
        save_fn(self);
    }

    fn saveDefault(_: Editable) void {
        std.log.warn("save method unimplemented", .{});
    }

    pub fn CallMethod(comptime method: []const u8) ?type {
        if (comptime std.mem.eql(u8, method, "save")) return void;
        return null;
    }

    pub fn callMethod(self: Editable, comptime method: []const u8, args: anytype) gen_return_type: {
        if (CallMethod(method)) |some| {
            break :gen_return_type some;
        } else {
            @compileError(std.fmt.comptimePrint("No such method {s}", .{method}));
        }
    } {
        if (comptime std.mem.eql(u8, method, "save")) {
            return @call(.auto, save, .{self} ++ args);
        } else {
            @compileError("No such method");
        }
    }

    pub fn cType() type {
        return EditableInterface;
    }

    pub fn gType() core.GType {
        return core.registerInterface(Editable, null, "Editable", .{});
    }

    pub fn isAImpl(comptime T: type) bool {
        return meta.trait.hasField("traitEditable")(T);
    }
};
