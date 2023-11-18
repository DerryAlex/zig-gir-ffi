const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const gtk = b.dependency("gtk", .{});

    const exe = b.addExecutable(.{ .name = "main", .root_source_file = .{ .path = "main.zig" }, .optimize = optimize, .target = target });
    exe.addModule("gtk", gtk.module("gtk"));
    exe.linkLibC();
    exe.linkSystemLibrary("gtk4");
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
