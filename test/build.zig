const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe,
    });

    const test_abi = b.addTest(.{
        .name = "test_abi",
        .root_source_file = b.path("test_abi.zig"),
        .optimize = optimize,
        .target = target,
        .filters = &.{ "g_", "gi_", "gtk_", "gsk_", "gdk_", "pango_", "cairo_" },
        .use_llvm = true,
    });
    test_abi.root_module.addAnonymousImport("c", .{ .root_source_file = b.path("abi/c.zig") });

    const run_test_abi = b.addRunArtifact(test_abi);

    const test_step = b.step("test", "Run the tests");
    test_step.dependOn(&run_test_abi.step);
}
