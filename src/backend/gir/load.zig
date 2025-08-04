const std = @import("std");
const File = std.fs.File;
const gi = @import("../../gi.zig");
const Scanner = @import("Scanner.zig");

pub fn loadGir(repo: *gi.Repository, file: File) !void {
    var buffer: [4096]u8 = undefined;
    var reader = file.reader(&buffer);
    var scanner: Scanner = .init(&reader.interface);
    while (scanner.next()) |token| {
        std.log.debug("{f}", .{token});
        if (token == .end_of_document) break;
    } else |err| {
        return err;
    }
    _ = repo;
}
