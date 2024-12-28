const std = @import("std");
const builtin = @import("builtin");

test {
    @setEvalBranchQuota(1_000_000);
    std.testing.refAllDecls(@import("abi/gtk.zig"));
    switch (builtin.os.tag) {
        .linux => {
            std.testing.refAllDecls(@import("abi/glib_unix.zig"));
            std.testing.refAllDecls(@import("abi/gio_unix.zig"));
            std.testing.refAllDecls(@import("abi/gdk_wayland.zig"));
            std.testing.refAllDecls(@import("abi/gdk_x11.zig"));
        },
        .windows => {
            std.testing.refAllDecls(@import("abi/glib_win32.zig"));
            std.testing.refAllDecls(@import("abi/gio_win32.zig"));
            std.testing.refAllDecls(@import("abi/gdk_win32.zig"));
        },
        .macos => {
            std.testing.refAllDecls(@import("abi/gdk_macos.zig"));
        },
        else => {},
    }
}
