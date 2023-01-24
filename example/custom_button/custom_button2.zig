const std = @import("std");
const root = @import("root");
const Gtk = root.Gtk;
const core = Gtk.core;
const meta = std.meta;

const Properties = enum(u32) {
    Number = 1,
};

var properties: [@enumToInt(Properties.Number) + 1]core.ParamSpec = undefined;

const SignalZeroReached = core.Signal(&[_]type{ void, CustomButton });
const SignalDebug = core.Signal(&[_]type{ bool });

pub const CustomButtonClass = extern struct {
    parent: Gtk.ButtonClass,

    pub fn init(self: *CustomButtonClass) void {
        var object_class = @ptrCast(*core.ObjectClass, self);
        // custom properties
        object_class.set_property = &set_property;
        object_class.get_property = &get_property;
        properties[@enumToInt(Properties.Number)] = core.paramSpecInt("number", null, null, 0, 10, 10, .Readwrite);
        object_class.installProperties(properties[0..]);
        // overrides
        object_class.constructed = &constructed;
        object_class.dispose = &dispose;
        var button_class = @ptrCast(*Gtk.ButtonClass, self);
        button_class.clicked = &clicked;
    }

    pub fn constructed(object: core.Object) callconv(.C) void {
        var button = object.tryInto(CustomButton).?;
        button.constructedOverride();
    }

    pub fn dispose(object: core.Object) callconv(.C) void {
        var button = object.tryInto(CustomButton).?;
        button.disposeOverride();
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

pub const CustomButtonPrivateImpl = struct {
    zeroReached: SignalZeroReached, // custom signal
    debug: SignalDebug, // test default handler, test connect flags, test disable
    number: i32,
    cleared: bool,
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
        self.instance.private.zeroReached = SignalZeroReached.init();
        _ = self.instance.private.zeroReached.overrideDefault(emitDebug, .{}, .{});
        self.instance.private.debug = SignalDebug.initAccumulator(core.accumulatorTrueHandled, .{});
    }

    pub fn disposeOverride(self: CustomButton) void {
        if (!self.instance.private.cleared) { // equivalent to g_clear_pointer
            self.signalZeroReached().deinit();
            self.instance.private.cleared = true;
        }
        self.callMethod("disposeV", .{Parent.gType()});
    }

    pub fn clickedOverride(self: CustomButton) void {
        const decremented_number = self.instance.private.number - 1;
        self.setNumber(decremented_number);
    }

    fn emitDebug(self: CustomButton) void {
        _ = self.signalDebug().emit(.{});
    }

    pub fn setNumber(self: CustomButton, number: i32) void {
        if (number < 0 or number > 10) {
            std.log.warn("{} is out of range for property number", .{number});
            return;
        }
        self.instance.private.number = number;
        if (number == 0) {
            switch (self.signalZeroReached().emit(.{self})) {
                .Ok => |_| {},
                .Err => |_| {
                    std.log.warn("No default handler for signal zero-reached", .{});
                },
            }
        }
        self.callMethod("notifyByPspec", .{properties[@enumToInt(Properties.Number)]});
    }

    pub fn getNumber(self: CustomButton) i32 {
        return self.instance.private.number;
    }

    const PropertyProxyNumber = struct {
        object: CustomButton,

        pub fn connectNotify(self: PropertyProxyNumber, comptime handler: anytype, args: anytype, comptime flags: core.ConnectFlagsZ) usize {
            core.connectZ(self.object.into(core.Object), "notify::number", handler, args, flags, &[_]type{ void, CustomButton, core.ParamSpec });
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

    pub fn signalZeroReached(self: CustomButton) *SignalZeroReached {
        return &self.instance.private.zeroReached;
    }

    pub fn signalDebug(self: CustomButton) *SignalDebug {
        return &self.instance.private.debug;
    }

    pub fn CallMethod(comptime method: []const u8) ?type {
        if (comptime std.mem.eql(u8, method, "setNumber")) return void;
        if (comptime std.mem.eql(u8, method, "getNumber")) return i32;
        if (comptime std.mem.eql(u8, method, "propertyNumber")) return PropertyProxyNumber;
        if (comptime std.mem.eql(u8, method, "signalZeroReached")) return SignalZeroReached;
        if (comptime std.mem.eql(u8, method, "signalDebug")) return SignalDebug;
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
