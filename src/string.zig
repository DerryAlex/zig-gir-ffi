const std = @import("std");

pub const String = struct {
    data: [256 + 1]u8 = undefined,
    len: usize = 0,

    pub fn new_from(comptime fmt: []const u8, args: anytype) String {
        var result: String = .{};
        const buf = std.fmt.bufPrintZ(result.data[0..], fmt, args) catch @panic("BufPrintError");
        result.len = buf.len;
        return result;
    }

    pub fn slice(self: *const String) [:0]const u8 {
        return self.data[0..self.len :0];
    }

    pub fn format(self: *const String, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        comptime {
            std.debug.assert(std.mem.eql(u8, fmt, "s"));
        }
        try std.fmt.formatBuf(self.slice(), options, writer);
    }

    pub fn to_camel(self: *const String) String {
        var result: String = .{};
        var to_upper = false;
        for (0..self.len) |i| {
            if (self.data[i] == '_' or self.data[i] == '-') {
                to_upper = true;
            } else {
                if (to_upper) {
                    result.data[result.len] = std.ascii.toUpper(self.data[i]);
                    result.len += 1;
                    to_upper = false;
                } else {
                    result.data[result.len] = self.data[i];
                    result.len += 1;
                }
            }
        }
        result.data[result.len] = 0;
        return result;
    }

    pub fn to_snake(self: *const String) String {
        var result: String = .{};
        for (0..self.len) |i| {
            if (std.ascii.isUpper(self.data[i])) {
                if (i != 0 and (i != 1 or self.data[0] != 'G')) {
                    result.data[result.len] = '_';
                    result.len += 1;
                }
                result.data[result.len] = std.ascii.toLower(self.data[i]);
                result.len += 1;
            } else {
                result.data[result.len] = self.data[i];
                result.len += 1;
            }
        }
        result.data[result.len] = 0;
        return result;
    }

    pub fn to_identifier(self: *const String) String {
        const str = self.slice();
        if (std.zig.isValidId(str)) {
            if (std.mem.eql(u8, str, "self")) {
                return String.new_from("{s}", .{"getSelf"});
            } else {
                return String.new_from("{s}", .{self});
            }
        } else {
            return String.new_from("@\"{s}\"", .{self});
        }
    }
};
