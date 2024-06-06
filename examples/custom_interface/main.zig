const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const TypedInt = @import("int.zig").TypedInt;
const PartialEq = @import("eq.zig").PartialEq;
const PartialOrd = @import("ord.zig").PartialOrd;

pub fn main() void {
    var rand_backend = std.rand.DefaultPrng.init(@intCast(@mod(std.time.nanoTimestamp(), 1_000_000)));
    var rand = std.rand.Random.init(&rand_backend, @TypeOf(rand_backend).fill);
    const v1 = rand.int(i8);
    const v2 = rand.int(i8);
    var ti1 = TypedInt.new(v1);
    defer ti1.__call("unref", .{});
    var ti2 = TypedInt.new(v2);
    defer ti2.__call("unref", .{});
    std.log.info("{} {}", .{ v1, v2 });
    inline for ([_][]const u8{ "eq", "ne" }) |rel| {
        std.log.info("{s} {}", .{ rel, ti1.__call(rel, .{ti2.into(PartialEq)}) });
    }
    inline for ([_][]const u8{ "lt", "le", "gt", "ge" }) |rel| {
        std.log.info("{s} {}", .{ rel, ti1.__call(rel, .{ti2.into(PartialOrd)}) });
    }
}
