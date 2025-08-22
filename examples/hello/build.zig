const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe,
    });

    const gi = b.dependency("gi", .{});
    const root_module = b.addModule("example", .{
        .root_source_file = b.path("example.zig"),
        .optimize = optimize,
        .target = target,
    });
    root_module.addImport("gi", gi.module("gi"));
    root_module.link_libc = true;
    root_module.linkSystemLibrary("gtk4", .{});

    const exe_check = b.addExecutable(.{
        .name = "example",
        .root_module = root_module,
    });
    const check = b.step("check", "Check if compiles");
    check.dependOn(&exe_check.step);

    const exe = b.addExecutable(.{
        .name = "example",
        .root_module = root_module,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
