const std = @import("std");
const GObject = @import("../GObject.zig");

const _type = @import("type.zig");
const Type = _type.Type;
const Arg = _type.Arg;
const cast = @import("cast.zig");
const isA = cast.isA;
const upCast = cast.upCast;
const downCast = cast.downCast;
const unsafeCast = cast.unsafeCast;

/// A structure used to hold different types of values.
pub const Value = extern struct {
    c_value: GObject.Value,

    const Self = @This();

    /// Initializes `Value` with the default value.
    pub fn init(comptime T: type) Self {
        var value = std.mem.zeroes(Self);
        _ = value.c_value.init(.from(T));
        return value;
    }

    /// Clears the current value.
    pub fn deinit(self: *Self) void {
        self.c_value.unset();
    }

    /// Get the contents of a `Value`.
    pub fn get(self: *Self, comptime T: type) Arg(T) {
        const v = &self.c_value;
        return switch (comptime Type.from(T)) {
            .none => unreachable,
            .char => v.getSchar(),
            .uchar => v.getUchar(),
            .boolean => v.getBoolean(),
            .int => v.getInt(),
            .uint => v.getUint(),
            .long => v.getLong(),
            .ulong => v.getUlong(),
            .int64 => v.getInt64(),
            .uint64 => v.getUint64(),
            .@"enum" => @enumFromInt(v.getEnum()),
            .flags => @bitCast(v.getFlags()),
            .float => v.getFloat(),
            .double => v.getDouble(),
            .string => v.getString().?,
            .pointer => @ptrCast(v.getPointer()),
            .param => v.getParam(),
            .variant => v.getVariant().?,
            .type => v.getGtype(),
            else => if (comptime isA(GObject.Object)(T)) downCast(T, v.getObject().?) else unsafeCast(T, v.getBoxed().?),
        };
    }

    /// Set the contents of a `Value`.
    pub fn set(self: *Self, comptime T: type, value: Arg(T)) void {
        const v = &self.c_value;
        switch (comptime Type.from(T)) {
            .none => unreachable,
            .char => v.setSchar(value),
            .uchar => v.setUchar(value),
            .boolean => v.setBoolean(value),
            .int => v.setInt(value),
            .uint => v.setUint(value),
            .long => v.setLong(value),
            .ulong => v.setUlong(value),
            .int64 => v.setInt64(value),
            .uint64 => v.setUint64(value),
            .@"enum" => v.setEnum(@intFromEnum(value)),
            .flags => v.setFlags(@bitCast(value)),
            .float => v.setFloat(value),
            .double => v.setDouble(value),
            .string => v.setString(value),
            .pointer => v.setPointer(value),
            .param => v.setParam(value),
            .variant => v.setVariant(value),
            .type => v.setGtype(value),
            else => if (comptime isA(GObject.Object)(T)) v.setObject(upCast(GObject.Object, value)) else v.setBoxed(value),
        }
    }
};
