const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const meta = std.meta;
const Button = gtk.Button;
const ButtonClass = gtk.ButtonClass;
const ParamSpec = core.ParamSpec;
const Object = core.Object;
const Value = core.Value;

const Properties = enum(u32) {
    Number = 1,
};

const Signals = enum {
    ZeroReached,
};

var _properties: [2]*ParamSpec = undefined;
var _signals: [1]u32 = undefined;

pub const CustomButtonClass = extern struct {
    parent: ButtonClass,
    zero_reached: ?*const fn (self: *CustomButton) callconv(.C) void,

    pub fn properties() []*ParamSpec {
        @memcpy(_properties[1..], &[_]*ParamSpec{
            core.paramSpecInt("number", null, null, 0, 10, 10, .{ .readable = true, .writable = true }),
        });
        return _properties[0..];
    }

    pub fn set_property_override(arg_object: *Object, arg_property_id: u32, arg_value: *Value, _: *ParamSpec) callconv(.C) void {
        var self = arg_object.tryInto(CustomButton).?;
        switch (@as(Properties, @enumFromInt(arg_property_id))) {
            .Number => {
                self.setNumber(arg_value.getInt());
            },
        }
    }

    pub fn get_property_override(arg_object: *Object, arg_property_id: u32, arg_value: *Value, _: *ParamSpec) callconv(.C) void {
        var self = arg_object.tryInto(CustomButton).?;
        switch (@as(Properties, @enumFromInt(arg_property_id))) {
            .Number => {
                arg_value.setInt(self.getNumber());
            },
        }
    }

    pub fn signals() []u32 {
        @memcpy(_signals[0..], &[_]u32{
            core.newSignal(CustomButton, "zero-reached", .{
                .run_last = true,
                .no_recurse = true,
                .no_hooks = true,
            }, {}, .{}),
        });
        return _signals[0..];
    }

    pub fn constructed_override(arg_object: *Object) callconv(.C) void {
        var self = arg_object.tryInto(CustomButton).?;
        self.__call("constructedV", .{CustomButton.Parent.gType()});
        _ = self.__call("bindProperty", .{ "number", self.into(Object), "label", .{ .sync_create = true } });
    }

    pub fn clicked_override(arg_button: *Button) callconv(.C) void {
        var self = arg_button.tryInto(CustomButton).?;
        const decremented_number = self.private.number - 1;
        self.setNumber(decremented_number);
    }
};

pub const CustomButtonPrivate = struct {
    number: i32 = 10,
};

pub const CustomButton = extern struct {
    parent: Button,
    private: *Private,

    pub const Parent = Button;
    pub const Private = CustomButtonPrivate;
    pub const Class = CustomButtonClass;
    pub usingnamespace core.Extend(CustomButton);

    pub fn new() *CustomButton {
        return core.newObject(CustomButton, .{});
    }

    pub fn getNumber(self: *CustomButton) i32 {
        return self.private.number;
    }

    pub fn setNumber(self: *CustomButton, number: i32) void {
        if (number < 0 or number > 10) {
            std.log.warn("{} is out of range for property number", .{number});
            return;
        }
        self.private.number = number;
        if (number == 0) {
            var instance = core.ValueZ(CustomButton).init();
            defer instance.deinit();
            instance.set(self);
            var params = [_]Value{instance.value};
            _ = core.signalEmitv(&params, _signals[@intFromEnum(Signals.ZeroReached)], 0, null);
        }
        self.__call("notifyByPspec", .{_properties[@intFromEnum(Properties.Number)]});
    }

    pub fn connectZeroReached(self: *CustomButton, comptime handler: anytype, args: anytype, comptime flags: core.ConnectFlags) usize {
        return self.connect("zero-reached", handler, args, flags, &[_]type{ void, *CustomButton });
    }

    pub fn gType() core.Type {
        return core.registerType(CustomButton, "CustomButton", .{});
    }
};
