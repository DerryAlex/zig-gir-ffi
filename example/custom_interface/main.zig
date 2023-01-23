const std = @import("std");
pub const Gtk = @import("Gtk");
const File = @import("file.zig").File;

pub fn main() void {
    var file = File.new();
    defer file.callMethod("unref", .{});
    file.callMethod("save", .{});
}
