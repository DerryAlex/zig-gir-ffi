const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const exe = b.addExecutable(.{ .name = "main", .root_source_file = .{ .path = "src/main.zig" }, .optimize = optimize, .target = target });
    exe.linkLibC();
    exe.linkSystemLibrary("gobject-introspection-1.0");
    b.installArtifact(exe);

    const tests = b.addTest(.{ .root_source_file = .{ .path = "src/gir.zig" } });
    tests.linkLibC();
    tests.linkSystemLibrary("gobject-introspection-1.0");

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&tests.step);
}
