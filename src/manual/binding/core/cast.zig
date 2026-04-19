const std = @import("std");
const GObject = @import("../GObject.zig");

/// Returns a function to check whether a type can be cast to T
pub fn isA(comptime T: type) fn (type) bool {
    return struct {
        pub fn trait(comptime S: type) bool {
            if (S == T) return true;
            if (@hasDecl(S, "Prerequisites")) {
                for (S.Prerequisites) |Prerequisite| {
                    if (trait(Prerequisite)) return true;
                }
            }
            if (@hasDecl(S, "Interfaces")) {
                for (S.Interfaces) |Interface| {
                    if (trait(Interface)) return true;
                }
            }
            if (@hasDecl(S, "Parent")) {
                if (trait(S.Parent)) return true;
            }
            return false;
        }
    }.trait;
}

/// Converts to base type T
pub inline fn upCast(comptime T: type, object: anytype) *T {
    const S = std.meta.Child(@TypeOf(object));
    if (comptime !isA(T)(S)) {
        @compileError(std.fmt.comptimePrint("{s} cannot be upcast to {s}", .{ @typeName(S), @typeName(T) }));
    }
    return unsafeCast(T, object);
}

/// Converts to derived type T
pub inline fn downCast(comptime T: type, object: anytype) ?*T {
    const S = std.meta.Child(@TypeOf(object));
    if (comptime !isA(S)(T)) {
        @compileError(std.fmt.comptimePrint("{s} cannot be downcast to {s}", .{ @typeName(S), @typeName(T) }));
    }
    return dynamicCast(T, object);
}

/// Converts to type T safely
pub inline fn dynamicCast(comptime T: type, object: anytype) ?*T {
    const instance = unsafeCast(GObject.TypeInstance, object);
    return if (GObject.typeCheckInstanceIsA(instance, .from(T))) unsafeCast(T, instance) else null;
}

/// Converts to type T.
///
/// Safety: It is the caller's responsibility to ensure that the cast is legal.
pub inline fn unsafeCast(comptime T: type, object: anytype) *T {
    return @ptrCast(@alignCast(object));
}
