const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const xml = b.dependency("xml", .{});

    const options = b.addOptions();
    const version = b.option([]const u8, "version", "application version string") orelse "0.8.1";
    options.addOption([]const u8, "version", version);

    const exe = b.addExecutable(.{
        .name = "main",
        .root_source_file = .{ .path = "src/main.zig" },
        .optimize = optimize,
        .target = target,
    });
    exe.root_module.addImport("xml", xml.module("xml"));
    exe.root_module.addOptions("config", options);
    exe.linkLibC();
    exe.linkSystemLibrary("gobject-introspection-1.0");
    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Generate the binding");
    run_step.dependOn(&run_exe.step);

    const run_tar = b.addSystemCommand(&[_][]const u8{ "tar", "cahf" });
    run_tar.addArgs(&[_][]const u8{ "gtk4.tar.gz", "gtk4" });
    const release_step = b.step("release", "Create the release tar ball (Please run generator first)");
    release_step.dependOn(&run_tar.step);
}
