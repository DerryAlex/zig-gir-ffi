const std = @import("std");
pub const Gtk = @import("Gtk");
const core = Gtk.core;

pub fn main() void {
    var app = Gtk.Application.new("org.zig_gir.clock", .FlagsNone);
    defer app.callMethod("unref", .{});
    _ = app.callMethod("signalActivate", .{}).connect(buildUi, .{}, .{});
    _ = app.callMethod("run", .{std.os.argv});
}

pub fn buildUi(arg_app: core.Application) void {
    var app = arg_app.tryInto(Gtk.Application).?;
    var window = Gtk.ApplicationWindow.new(app);
    window.callMethod("setTitle", .{"Clock Example"});
    window.callMethod("setDefaultSize", .{ 260, 40 });
    var label = Gtk.Label.new(null);
    _ = tick(label);
    var closure = core.createClosure(&tick, .{label}, false, &[_]type{core.Boolean}, .C);
    _ = core.timeoutAddSeconds(core.PRIORITY_DEFAULT, 1, closure.invoke_fn(), closure, closure.deinit_fn());
    window.callMethod("setChild", .{label.into(Gtk.Widget).asSome()});
    window.callMethod("present", .{});
}

pub fn tick(label: Gtk.Label) core.Boolean {
    var time = std.time.timestamp();
    const s: u6 = @intCast(u6, @mod(time, std.time.s_per_min));
    time = @divFloor(time, std.time.s_per_min);
    const min: u6 = @intCast(u6, @mod(time, 60));
    time = @divFloor(time, 60);
    const hour: u5 = @intCast(u5, @mod(time, 24));
    time = @divFloor(time, 24);
    const days_y1972 = 2 * 365;
    // 1970-2099
    const year: u14 = gen_year: {
        if (time < days_y1972) {
            const res: u14 = switch (time) {
                0...364 => 0,
                365...729 => 1,
                else => unreachable,
            };
            time = switch (time) {
                0...364 => time,
                365...729 => time - 365,
                else => unreachable,
            };
            break :gen_year 1970 + res;
        } else {
            const res1: u14 = 4 * @intCast(u14, @divFloor(time - days_y1972, 4 * 365 + 1));
            const tmp = @mod(time, 4 * 365 + 1);
            const res2: u14 = switch (tmp) {
                0...365 => 0,
                366...730 => 1,
                731...1095 => 2,
                1096...1460 => 3,
                else => unreachable,
            };
            time = switch (tmp) {
                0...365 => tmp,
                366...730 => tmp - 366,
                731...1095 => tmp - 731,
                1096...1460 => tmp - 1096,
                else => unreachable,
            };
            break :gen_year 1972 + res1 + res2;
        }
    };
    const month: u4 = gen_month: {
        if (@mod(year, 4) == 0) {
            const res: u4 = switch (time) {
                0...30 => 1,
                31...59 => 2,
                60...90 => 3,
                91...120 => 4,
                121...151 => 5,
                152...181 => 6,
                182...212 => 7,
                213...243 => 8,
                244...273 => 9,
                274...304 => 10,
                305...334 => 11,
                335...365 => 12,
                else => unreachable,
            };
            time = switch (time) {
                0...30 => time,
                31...59 => time - 31,
                60...90 => time - 60,
                91...120 => time - 91,
                121...151 => time - 121,
                152...181 => time - 152,
                182...212 => time - 182,
                213...243 => time - 213,
                244...273 => time - 244,
                274...304 => time - 274,
                305...334 => time - 305,
                335...365 => time - 335,
                else => unreachable,
            };
            break :gen_month res;
        } else {
            const res: u4 = switch (time) {
                0...30 => 1,
                31...58 => 2,
                59...89 => 3,
                90...119 => 4,
                120...150 => 5,
                151...180 => 6,
                181...211 => 7,
                212...242 => 8,
                243...272 => 9,
                273...303 => 10,
                304...333 => 11,
                334...364 => 12,
                else => unreachable,
            };
            time = switch (time) {
                0...30 => time,
                31...55 => time - 31,
                59...89 => time - 59,
                90...119 => time - 90,
                120...150 => time - 120,
                151...180 => time - 151,
                181...211 => time - 181,
                212...242 => time - 212,
                243...272 => time - 243,
                273...303 => time - 273,
                304...333 => time - 304,
                334...364 => time - 334,
                else => unreachable,
            };
            break :gen_month res;
        }
    };
    const day: u5 = @intCast(u5, time + 1);
    var buf: [21]u8 = undefined;
    const str = std.fmt.bufPrintZ(buf[0..], "{d:0>4}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}Z", .{year, month, day, hour, min, s}) catch @panic("No Space Left");
    label.setLabel(str);
    return .True; // true to continue, false to stop
}
