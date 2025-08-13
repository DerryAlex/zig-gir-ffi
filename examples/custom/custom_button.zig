const std = @import("std");
const gi = @import("gi");
const core = gi.core;
const Gtk = gi.Gtk;
const Button = Gtk.Button;

pub const CustomButtonClass = extern struct {
    parent_class: Button.Class,
};

pub const CustomButtonPrivate = struct {
    number: i32,
};

pub const CustomButton = extern struct {
    parent: Button,
    private: *Private,
    zero_reached: core.SimpleSignal(fn (*CustomButton) void) = .{},

    pub const Parent = Button;
    pub const Private = CustomButtonPrivate;
    pub const Class = CustomButtonClass;

    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;

    pub const Override = struct {
        pub fn clicked(button: *Button) callconv(.c) void {
            const self = button.tryInto(CustomButton).?;
            self.setNumber(self.getNumber() - 1);
        }
    };

    pub fn new() *CustomButton {
        return core.newObject(CustomButton);
    }

    pub fn init(self: *CustomButton) void {
        self.setNumber(10);
    }

    pub fn getNumber(self: *CustomButton) i32 {
        return self.private.number;
    }

    pub fn setNumber(self: *CustomButton, number: i32) void {
        if (number < 0 or number > 10) {
            std.log.warn("{} is out of range for property 'number'", .{number});
            return;
        }
        self.private.number = number;
        var buffer: [11]u8 = undefined;
        const label = std.fmt.bufPrintZ(&buffer, "{}", .{number}) catch unreachable;
        self.into(Button).setLabel(label);
        if (number == 0) {
            self.zero_reached.emit(.{self});
        }
    }

    pub fn gType() core.Type {
        return core.registerType(CustomButton, "CustomButton", .{});
    }
};
