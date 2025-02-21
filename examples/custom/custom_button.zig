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
    parent_class: ButtonClass,
    zero_reached: ?*const fn (self: *CustomButton) callconv(.c) void,

    pub var parent_class_ptr: ?*ButtonClass = null;

    pub fn init(class: *CustomButtonClass) void {
        parent_class_ptr = @ptrCast(gobject.TypeClass.peekParent(@ptrCast(class)));
    }

    pub fn properties() []*ParamSpec {
        @memcpy(_properties[1..], &[_]*ParamSpec{
            gobject.paramSpecInt("number", null, null, 0, 10, 10, .readwrite),
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

    const Ext = core.Extend(@This());
    pub const __call = Ext.__call;
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub const property = Ext.property;
    pub const signalConnect = Ext.signalConnect;

    pub const Override = struct {
        pub fn set_property(arg_object: *Object, arg_property_id: u32, arg_value: *Value, _: *ParamSpec) callconv(.c) void {
            var self = arg_object.tryInto(CustomButton).?;
            switch (@as(Properties, @enumFromInt(arg_property_id))) {
                .Number => {
                    self.setNumber(arg_value.getInt());
                },
            }
        }

        pub fn get_property(arg_object: *Object, arg_property_id: u32, arg_value: *Value, _: *ParamSpec) callconv(.c) void {
            var self = arg_object.tryInto(CustomButton).?;
            switch (@as(Properties, @enumFromInt(arg_property_id))) {
                .Number => {
                    arg_value.setInt(self.getNumber());
                },
            }
        }

        pub fn constructed(arg_object: *Object) callconv(.c) void {
            var self = arg_object.tryInto(CustomButton).?;
            const p_class: *gobject.ObjectClass = @ptrCast(Class.parent_class_ptr);
            p_class.constructed.?(arg_object);
            _ = self.__call("bindProperty", .{ "number", self.into(Object), "label", gobject.BindingFlags{ .sync_create = true } });
        }

        pub fn clicked(arg_button: *Button) callconv(.c) void {
            var self = arg_button.tryInto(CustomButton).?;
            const decremented_number = self.private.number - 1;
            self.setNumber(decremented_number);
        }
    };

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
        self.__call("notifyByPspec", .{_properties[@intFromEnum(Properties.Number)]});
    }

    pub fn connectZeroReached(self: *CustomButton, handler: anytype, args: anytype, flags: gobject.ConnectFlags) usize {
        return self.signalConnect("zero-reached", handler, args, flags, fn (*CustomButton) void);
    }

    pub fn gType() core.Type {
        return core.registerType(CustomButton, "CustomButton", .{});
    }
};
