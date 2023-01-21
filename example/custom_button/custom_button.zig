const std = @import("std");
const root = @import("root");
const Gtk = root.Gtk;
const core = Gtk.core;
const meta = std.meta;

const Properties = enum(u32) {
    Number = 1,
};

const Signals = enum {
    ZeroReached,
};

var properties: [@enumToInt(Properties.Number) + 1]core.ParamSpec = undefined;
var signals: [@as(usize, @enumToInt(Signals.ZeroReached)) + 1]u32 = undefined;

pub const CustomButtonClass = extern struct {
    parent: Gtk.ButtonClass,
    zeroReached: ?*const fn (CustomButton) void,

    pub fn init(self: *CustomButtonClass) void {
        var object_class = @ptrCast(*core.ObjectClass, self);
        // custom properties
        object_class.set_property = &set_property;
        object_class.get_property = &get_property;
        properties[@enumToInt(Properties.Number)] = core.paramSpecInt("number", null, null, 0, 10, 10, .Readwrite);
        object_class.installProperties(properties[0..]);
        // custom signals
        var flags = core.FlagsBuilder(core.SignalFlags){};
        signals[@enumToInt(Signals.ZeroReached)] = core.signalNewv("zero-reached", CustomButton.gType(), flags.set(.RunLast).set(.NoRecurse).set(.NoHooks).build(), core.signalTypeCclosureNew(CustomButton.gType(), @offsetOf(CustomButtonClass, "zeroReached")), null, null, null, .None, null);
        // overrides
        object_class.constructed = &constructed;
        var button_class = @ptrCast(*Gtk.ButtonClass, self);
        button_class.clicked = &clicked;
    }

    pub fn constructed(object: core.Object) callconv(.C) void {
        var button = object.tryInto(CustomButton).?;
        button.constructedOverride();
    }

    pub fn set_property(object: core.Object, property_id: u32, value: *core.Value, _: core.ParamSpec) callconv(.C) void {
        var button = object.tryInto(CustomButton).?;
        switch (@intToEnum(Properties, property_id)) {
            .Number => {
                button.setNumber(value.getInt());
            },
        }
    }

    pub fn get_property(object: core.Object, property_id: u32, value: *core.Value, _: core.ParamSpec) callconv(.C) void {
        var button = object.tryInto(CustomButton).?;
        switch (@intToEnum(Properties, property_id)) {
            .Number => {
                value.setInt(button.getNumber());
            },
        }
    }

    pub fn clicked(arg_button: Gtk.Button) callconv(.C) void {
        var button = arg_button.tryInto(CustomButton).?;
        button.clickedOverride();
    }
};

pub const CustomButtonImpl = extern struct {
    parent: Gtk.Button.cType(),
    private: *Private,

    pub const Private = CustomButtonPrivateImpl;
};

pub const CustomButtonPrivateImpl = extern struct {
    number: i32,
};

pub const CustomButton = packed struct {
    instance: *CustomButtonImpl,
    traitCustomButton: void = {},

    pub const Parent = Gtk.Button;

    pub fn new() CustomButton {
        return core.objectNewWithProperties(gType(), null, null).tryInto(CustomButton).?;
    }

    pub fn constructedOverride(self: CustomButton) void {
        self.callMethod("constructedV", .{Parent.gType()});
        self.instance.private.number = 10;
        _ = self.callMethod("bindProperty", .{ "number", self.into(core.Object), "label", .SyncCreate });
    }

    pub fn clickedOverride(self: CustomButton) void {
        const decremented_number = self.instance.private.number - 1;
        self.setNumber(decremented_number);
    }

    pub fn setNumber(self: CustomButton, number: i32) void {
        if (number < 0 or number > 10) {
            std.log.warn("{} is out of range for property number", .{number});
            return;
        }
        self.instance.private.number = number;
        if (number == 0) {
            var params = std.mem.zeroes([1]core.Value);
            _ = params[0].init(.Object);
            params[0].setObject(self.into(core.Object).asSome());
            defer params[0].unset();
            _ = core.signalEmitv(&params, signals[@enumToInt(Signals.ZeroReached)], 0, std.mem.zeroes(core.Value));
        }
        self.callMethod("notifyByPspec", .{properties[@enumToInt(Properties.Number)]});
    }

    pub fn getNumber(self: CustomButton) i32 {
        return self.instance.private.number;
    }

    const PropertyProxyNumber = struct {
        object: CustomButton,

        pub fn connectNotify(self: PropertyProxyNumber, comptime handler: anytype, args: anytype, comptime flags: core.ConnectFlagsZ) usize {
            core.connect(self.object.into(core.Object), "notify::number", handler, args, flags, &[_]type{ void, CustomButton, core.ParamSpec });
        }

        pub fn set(self: PropertyProxyNumber, number: i32) void {
            self.object.setNumber(number);
        }

        pub fn get(self: PropertyProxyNumber) i32 {
            return self.object.getNumber();
        }
    };

    pub fn propertyNumber(self: CustomButton) PropertyProxyNumber {
        return .{ .object = self };
    }

    const SignalProxyZeroReached = struct {
        object: CustomButton,

        pub fn connect(self: SignalProxyZeroReached, comptime handler: anytype, args: anytype, comptime flags: core.ConnectFlagsZ) usize {
            return core.connect(self.object.into(core.Object), "zero-reached", handler, args, flags, &[_]type{ void, CustomButton });
        }
    };

    pub fn signalZeroReached(self: CustomButton) SignalProxyZeroReached {
        return .{ .object = self };
    }

    pub fn CallMethod(comptime method: []const u8) ?type {
        if (comptime std.mem.eql(u8, method, "setNumber")) return void;
        if (comptime std.mem.eql(u8, method, "getNumber")) return i32;
        if (comptime std.mem.eql(u8, method, "propertyNumber")) return PropertyProxyNumber;
        if (comptime std.mem.eql(u8, method, "signal")) return SignalProxyZeroReached;
        if (Parent.CallMethod(method)) |some| return some;
        return null;
    }

    pub fn callMethod(self: CustomButton, comptime method: []const u8, args: anytype) gen_return_type: {
        if (CallMethod(method)) |some| {
            break :gen_return_type some;
        } else {
            @compileError(std.fmt.comptimePrint("No such method {s}", .{method}));
        }
    } {
        if (comptime std.mem.eql(u8, method, "setNumber")) {
            return @call(.auto, setNumber, .{self} ++ args);
        } else if (comptime std.mem.eql(u8, method, "getNumber")) {
            return @call(.auto, getNumber, .{self} ++ args);
        } else if (comptime std.mem.eql(u8, method, "propertyNumber")) {
            return @call(.auto, propertyNumber, .{self} ++ args);
        } else if (comptime std.mem.eql(u8, method, "signalZeroReached")) {
            return @call(.auto, signalZeroReached, .{self} ++ args);
        } else if (Parent.CallMethod(method)) |_| {
            return self.into(Parent).callMethod(method, args);
        } else {
            @compileError("No such method");
        }
    }

    pub fn cType() type {
        return CustomButtonImpl;
    }

    pub fn gType() core.GType {
        return core.registerType(CustomButtonClass, CustomButton, "CustomButton", .{});
    }

    pub fn isAImpl(comptime T: type) bool {
        return meta.trait.hasField("traitCustomButton")(T);
    }

    pub fn into(self: CustomButton, comptime T: type) T {
        return core.upCast(T, self);
    }

    pub fn tryInto(self: CustomButton, comptime T: type) ?T {
        return core.downCast(T, self);
    }
};
