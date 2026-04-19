const std = @import("std");
const GObject = @import("../GObject.zig");

const assert = std.debug.assert;

const ULong = @import("type.zig").ULong;
const _closure = @import("closure.zig");
const Closure = _closure.Closure;
const ZigClosure = _closure.ZigClosure;

pub const HandlerId = ULong;

/// A simple implementation of signal and slot mechanism.
pub fn SimpleSignal(comptime Fn: type) type {
    return extern struct {
        slots: [8]?*ZigClosure = @splat(null),
        n_slot: usize = 0,

        const Self = @This();

        const Args = std.meta.ArgsTuple(Fn);
        const Return = @typeInfo(Fn).@"fn".return_type.?;
        comptime {
            assert(Return == void);
        }

        /// Connects a closure to a signal for a particular object.
        pub fn connect(self: *Self, closure: Closure(Fn), flags: GObject.ConnectFlags) HandlerId {
            if (flags.after) std.log.warn("SimpleSignal.connect: unsupported flag 'after'", .{});
            if (flags.swapped) std.log.warn("SimpleSignal.connect: unsupported flag 'swapped'", .{});
            self.slots[self.n_slot] = closure.closure;
            defer self.n_slot += 1;
            return self.n_slot;
        }

        /// Disconnects a handler from an instance.
        pub fn disconnect(self: *Self, id: HandlerId) void {
            if (id >= self.n_slot or self.slots[id] == null) {
                std.log.warn("SimpleSignal {*} has no handler with id {}", .{ self, id });
                return;
            }
            self.slots[id] = null;
        }

        /// Emits a signal. Signal emission is done synchronously.
        pub fn emit(self: *Self, args: Args) void {
            for (self.slots[0..self.n_slot]) |_slot| {
                if (_slot) |slot| {
                    @call(.auto, @as(*const fn (...) callconv(.c) void, @ptrCast(slot.c_callback)), .{slot} ++ args);
                }
            }
        }
    };
}

/// Type-safe wrapper for signal.
pub fn Signal(comptime Fn: type, comptime name: [:0]const u8) type {
    return extern struct {
        const Self = @This();

        /// Connects a closure to a signal for a particular object.
        pub fn connect(self: *Self, closure: Closure(Fn), flags: GObject.ConnectFlags) HandlerId {
            const Object = std.meta.Child(@typeInfo(Fn).@"fn".params[0].type.?);
            const _signals: *@FieldType(Object, "_signals") = @fieldParentPtr(name, self);
            const object: *Object = @alignCast(@fieldParentPtr("_signals", _signals));
            if (flags.swapped) std.log.warn("Signal.connect: unsupported flag 'swapped'", .{});
            return GObject.signalConnectClosure(object.into(GObject.Object), name, @ptrCast(closure.closure), flags.after);
        }
    };
}
