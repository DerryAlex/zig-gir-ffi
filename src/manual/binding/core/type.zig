const std = @import("std");
const GLib = @import("../GLib.zig");
const GObject = @import("../GObject.zig");

const Int = @Int(@typeInfo(c_int).int.signedness, @typeInfo(c_int).int.bits);
const UInt = @Int(@typeInfo(c_uint).int.signedness, @typeInfo(c_uint).int.bits);
const Long = @Int(@typeInfo(c_long).int.signedness, @typeInfo(c_long).int.bits);
pub const ULong = @Int(@typeInfo(c_ulong).int.signedness, @typeInfo(c_ulong).int.bits);

/// Is `T` a basic C type
fn isBasicType(comptime T: type) bool {
    return switch (comptime Type.from(T)) {
        .invalid, .param, .object, .variant => false,
        else => true,
    };
}

/// How should `value: T` be passed as function argument
pub fn Arg(comptime T: type) type {
    return if (isBasicType(T)) T else *T;
}

/// Reverse of `Arg(T)`
fn ReverseArg(comptime T: type) type {
    return if (@typeInfo(T) == .pointer and Arg(std.meta.Child(T)) == T) std.meta.Child(T) else T;
}

/// A numerical value which represents the unique identifier of a registered type
pub const Type = enum(usize) {
    invalid = 0,
    none = 4,
    interface = 8,
    char = 12,
    uchar = 16,
    boolean = 20,
    int = 24,
    uint = 28,
    long = 32,
    ulong = 36,
    int64 = 40,
    uint64 = 44,
    @"enum" = 48,
    flags = 52,
    float = 56,
    double = 60,
    string = 64,
    pointer = 68,
    boxed = 72,
    param = 76,
    object = 80,
    variant = 84,
    /// placeholder for `Type`
    type = std.math.maxInt(usize),
    _,

    /// Resolves zig's type to `Type`.
    pub fn from(comptime T: type) Type {
        if (T == void) return .none;
        if (T == i8) return .char;
        if (T == u8) return .uchar;
        if (T == bool) return .boolean;
        if (T == c_int or T == Int) return .int;
        if (T == c_uint or T == UInt) return .uint;
        if (T == c_long or T == Long) return .long;
        if (T == c_ulong or T == ULong) return .ulong;
        if (T == i64) return .int64;
        if (T == u64) return .uint64;
        if (T == f32) return .float;
        if (T == f64) return .double;
        if (T == [*:0]const u8) return .string;
        if (T == GObject.ParamSpec) return .param;
        if (T == GObject.Object) return .object;
        if (T == GLib.Variant) return .variant;
        if (T == Type) return if (@inComptime()) .type else gType();
        switch (@typeInfo(T)) {
            .pointer => |p| if (p.size == .one) return .pointer,
            .@"enum" => |e| if (e.is_exhaustive) return if (@inComptime()) .@"enum" else T.gType(),
            .@"struct" => |s| if (s.layout == .@"packed") return if (@inComptime()) .flags else T.gType(),
            else => {},
        }
        if (@inComptime()) return .invalid;
        if (@hasDecl(T, "gType")) return T.gType();
        @compileError(std.fmt.comptimePrint("Cannot obtain gType of {s}", .{@typeName(T)}));
    }

    /// Returns `Type` of `Type`.
    pub fn gType() Type {
        const cFn = @extern(*const fn () callconv(.c) Type, .{ .name = "g_gtype_get_type" });
        return cFn();
    }
};

pub fn List(comptime T: type) type {
    return extern struct {
        data: *T,
        prev: ?*Node,
        next: ?*Node,

        const Node = @This();
    };
}

pub fn SList(comptime T: type) type {
    return extern struct {
        data: *T,
        next: ?*Node,

        const Node = @This();
    };
}

pub fn Array(comptime T: type) type {
    return extern struct {
        data: [*]T,
        len: UInt,

        pub fn slice(self: *Slice) []T {
            return self.data[0..self.len];
        }

        const Slice = @This();
    };
}

pub fn PtrArray(comptime T: type) type {
    return Array(*T);
}

pub fn HashTable(comptime K: type, comptime V: type) type {
    return opaque {
        fn raw(self: *Map) *GLib.HashTable {
            return @ptrCast(self);
        }

        const Map = @This();

        pub fn get(self: *Map, key: K) ?V {
            const value_ptr = self.raw().lookup(&key);
            return if (value_ptr) |v| v.* else null;
        }

        pub fn set(self: *Map, key: K, value: V) void {
            _ = self.raw().insert(&key, &value);
        }

        pub fn clear(self: *Map) void {
            self.raw().removeAll();
        }

        pub fn contains(self: *Map, key: K) bool {
            return self.raw().contains(&key);
        }

        pub fn remove(self: *Map, key: K) void {
            _ = self.raw().remove(&key);
        }

        pub fn iterator(self: *Map) Iterator {
            return .{ .iter = .init(self) };
        }

        pub const Iterator = struct {
            iter: GLib.HashTableIter,

            pub fn init(map: *Map) Iterator {
                var iter: GLib.HashTableIter = undefined;
                iter.init(map.raw());
                return .{ .iter = iter };
            }

            pub fn next(self: *Iterator) ?Entry {
                const entry = self.iter.next();
                if (entry.ret) return .{
                    .key_ptr = @ptrCast(entry.key),
                    .value_ptr = @ptrCast(entry.value),
                };
                return null;
            }

            pub const Entry = struct {
                key_ptr: *K,
                value_ptr: *V,
            };
        };
    };
}
