const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const Button = gtk.Button;
const ButtonClass = gtk.ButtonClass;
const gobject = gtk.gobject;
const ParamSpec = gobject.ParamSpec;
const Object = gobject.Object;
const Value = gobject.Value;

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

    var parent_class: ?*ButtonClass = null;

    pub fn init(class: *CustomButtonClass) void {
        parent_class = @ptrCast(gobject.TypeClass.peekParent(@ptrCast(class)));
    }

    pub fn properties() []*ParamSpec {
        @memcpy(_properties[1..], &[_]*ParamSpec{
            gobject.paramSpecInt("number", null, null, 0, 10, 10, .{ .readable = true, .writable = true }),
        });
        return _properties[0..];
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

    pub const ObjectClassOverride = struct {
        pub fn set_property(arg_object: *Object, arg_property_id: u32, arg_value: *Value, _: *ParamSpec) callconv(.C) void {
            var self = arg_object.tryInto(CustomButton).?;
            switch (@as(Properties, @enumFromInt(arg_property_id))) {
                .Number => {
                    self.setNumber(arg_value.getInt());
                },
            }
        }

        pub fn get_property(arg_object: *Object, arg_property_id: u32, arg_value: *Value, _: *ParamSpec) callconv(.C) void {
            var self = arg_object.tryInto(CustomButton).?;
            switch (@as(Properties, @enumFromInt(arg_property_id))) {
                .Number => {
                    arg_value.setInt(self.getNumber());
                },
            }
        }

        pub fn constructed(arg_object: *Object) callconv(.C) void {
            var self = arg_object.tryInto(CustomButton).?;
            const p_class: *gobject.ObjectClass = @ptrCast(parent_class);
            p_class.constructed.?(arg_object);
            _ = self.__method__().invoke("bindProperty", .{ "number", self.into(Object), "label", .{ .sync_create = true } });
        }
    };

    pub const ButtonClassOverride = struct {
        pub fn clicked(arg_button: *Button) callconv(.C) void {
            var self = arg_button.tryInto(CustomButton).?;
            const decremented_number = self.private.number - 1;
            self.setNumber(decremented_number);
        }
    };
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
            var instance = std.mem.zeroes(gobject.Value);
            defer instance.unset();
            _ = instance.init(CustomButton.gType());
            instance.setObject(self.into(gobject.Object));
            var params = [_]Value{instance};
            _ = gobject.signalEmitv(&params, _signals[@intFromEnum(Signals.ZeroReached)], 0, null);
        }
        self.__method__().invoke("notifyByPspec", .{_properties[@intFromEnum(Properties.Number)]});
    }

    pub fn connectZeroReached(self: *CustomButton, comptime handler: anytype, args: anytype, comptime flags: gobject.ConnectFlags) usize {
        return self.__signal__().connect("zero-reached", handler, args, flags, &[_]type{ void, *CustomButton });
    }

    pub fn into(self: *CustomButton, comptime T: type) *T {
        return core.upCast(T, self);
    }

    pub fn tryInto(self: *CustomButton, comptime T: type) ?*T {
        return core.downCast(T, self);
    }

    pub fn __method__(self: *CustomButton) core.MethodMixin(CustomButton) {
        return .{ .self = self };
    }

    pub fn __property__(self: *CustomButton) core.PropertyMixin(CustomButton) {
        return .{ .self = self };
    }

    pub fn __signal__(self: *CustomButton) core.SignalMixin(CustomButton) {
        return .{ .self = self };
    }

    pub fn gType() core.Type {
        return core.registerType(CustomButton, "CustomButton", .{});
    }
};
