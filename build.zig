const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const xml = b.createModule(.{ .source_file = .{ .path = "src/deps/zig-xml/Parser.zig" } });

    const exe = b.addExecutable(.{
        .name = "main",
        .root_source_file = .{ .path = "src/main.zig" },
        .optimize = optimize,
        .target = target,
    });
    exe.addModule("xml", xml);
    exe.linkLibC();
    exe.linkSystemLibrary("gobject-introspection-1.0");
    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Generate the binding");
    run_step.dependOn(&run_exe.step);

    const tests = b.addTest(.{ .root_source_file = .{ .path = "src/gir.zig" } });
    tests.linkLibC();
    tests.linkSystemLibrary("gobject-introspection-1.0");

    const test_step = b.step("test_gir", "Test gir.zig");
    test_step.dependOn(&tests.step);
}
