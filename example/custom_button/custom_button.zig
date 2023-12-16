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

    pub fn init(class: *CustomButtonClass) void {
        var button_class: *ButtonClass = @ptrCast(class);
        button_class.clicked = &clicked;
    }

    pub fn properties() []*ParamSpec {
        _properties[@intFromEnum(Properties.Number)] = core.paramSpecInt("number", null, null, 0, 10, 10, .{ .readable = true, .writable = true });
        return _properties[0..];
    }

    // @override
    pub fn set_property(arg_object: *Object, arg_property_id: u32, arg_value: *Value, _: *ParamSpec) callconv(.C) void {
        var self = arg_object.tryInto(CustomButton).?;
        switch (@as(Properties, @enumFromInt(arg_property_id))) {
            .Number => {
                self.setNumber(arg_value.getInt());
            },
        }
    }

    // @override
    pub fn get_property(arg_object: *Object, arg_property_id: u32, arg_value: *Value, _: *ParamSpec) callconv(.C) void {
        var self = arg_object.tryInto(CustomButton).?;
        switch (@as(Properties, @enumFromInt(arg_property_id))) {
            .Number => {
                arg_value.setInt(self.getNumber());
            },
        }
    }

    pub fn signals() []u32 {
        _signals[@intFromEnum(Signals.ZeroReached)] = core.newSignal(CustomButtonClass, CustomButton, "zero-reached", .{
            .run_last = true,
            .no_recurse = true,
            .no_hooks = true,
        }, {}, .{});
        return _signals[0..];
    }

    // @override
    pub fn constructed(arg_object: *Object) callconv(.C) void {
        var self = arg_object.tryInto(CustomButton).?;
        self.__call("constructedV", .{CustomButton.Parent.gType()});
        _ = self.__call("bindProperty", .{ "number", self.into(Object), "label", .{ .sync_create = true } });
    }

    // @override
    pub fn clicked(arg_button: *Button) callconv(.C) void {
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
    pub usingnamespace core.Extend(CustomButton);

    pub fn new() *CustomButton {
        return core.newObject(CustomButton, null, null);
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

    pub fn connectNumberNotify(self: *CustomButton, comptime handler: anytype, args: anytype, comptime flags: core.ConnectFlags) usize {
        return core.connect(self.into(core.Object), "notify::number", handler, args, flags, &[_]type{ void, *CustomButton, *ParamSpec });
    }

    pub fn connectZeroReached(self: *CustomButton, comptime handler: anytype, args: anytype, comptime flags: core.ConnectFlags) usize {
        return core.connect(self.into(core.Object), "zero-reached", handler, args, flags, &[_]type{ void, *CustomButton });
    }

    pub fn gType() core.Type {
        return core.registerType(CustomButtonClass, CustomButton, "CustomButton", .{});
    }
};
