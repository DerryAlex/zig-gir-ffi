const std = @import("std");
const GObject = @import("../GObject.zig");

const _type = @import("type.zig");
const Arg = _type.Arg;
const cast = @import("cast.zig");
const dynamicCast = cast.dynamicCast;
const _value = @import("value.zig");
const Value = _value.Value;
const _closure = @import("closure.zig");
const Closure = _closure.Closure;
const signal = @import("signal.zig");
const HandlerId = signal.HandlerId;

/// Type-safe wrapper for property.
///
/// Safety: property should be at offset 0 of an object.
pub fn Property(comptime T: type, comptime name: [:0]const u8) type {
    return extern struct {
        const Self = @This();

        pub fn get(self: *Self) Arg(T) {
            var prop: Value = .init(T);
            defer prop.deinit();
            const object = dynamicCast(GObject.Object, self).?;
            object.getProperty(name, &prop.c_value);
            return prop.get(T);
        }

        pub fn set(self: *Self, value: Arg(T)) void {
            var prop: Value = .init(T);
            defer prop.deinit();
            prop.set(T, value);
            const object = dynamicCast(GObject.Object, self).?;
            object.setProperty(name, &prop.c_value);
        }

        pub fn connectNotify(self: *Self, closure: Closure(fn (*GObject.Object, *GObject.ParamSpec) void), flags: GObject.ConnectFlags) HandlerId {
            const object = dynamicCast(GObject.Object, self).?;
            return GObject.signalConnectClosure(object, "notify::" ++ name, @ptrCast(closure.closure), flags.after);
        }
    };
}
