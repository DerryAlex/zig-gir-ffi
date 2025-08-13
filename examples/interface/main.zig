const std = @import("std");
const gi = @import("gi");
const Object = gi.GObject.Object;
const TypedInt = @import("int.zig").TypedInt;
const PartialEq = @import("eq.zig").PartialEq;
const PartialOrd = @import("ord.zig").PartialOrd;

pub fn main() void {
    var rand_backend: std.Random.DefaultPrng = .init(@intCast(@mod(std.time.nanoTimestamp(), std.time.ns_per_ms)));
    const rand: std.Random = .init(&rand_backend, @TypeOf(rand_backend).fill);
    const v1 = rand.int(i8);
    const v2 = rand.int(i8);
    const ti1: *TypedInt = .new(v1);
    defer ti1.into(Object).unref();
    const ti2: *TypedInt = .new(v2);
    defer ti2.into(Object).unref();
    std.log.info("{} {}", .{ v1, v2 });
    inline for ([_][]const u8{ "eq", "ne" }) |rel| {
        std.log.info("{s} {}", .{ rel, @field(PartialEq, rel)(ti1.into(PartialEq), ti2.into(PartialEq)) });
    }
    inline for ([_][]const u8{ "lt", "le", "gt", "ge" }) |rel| {
        std.log.info("{s} {}", .{ rel, @field(PartialOrd, rel)(ti1.into(PartialOrd), ti2.into(PartialOrd)) });
    }
}
