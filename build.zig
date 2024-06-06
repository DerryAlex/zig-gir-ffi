const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const options = b.addOptions();
    const version = b.option([]const u8, "version", "Version string") orelse "0.8.3";
    options.addOption([]const u8, "version", version);
    const namespace = b.option([]const u8, "namespace", "GI namespace to use, e.g. \"Gtk\"") orelse "Gtk";
    options.addOption([]const u8, "namespace", namespace);
    const namespace_version = b.option([]const u8, "namespace-version", "Version of namespace, may be null for latest");
    options.addOption(?[]const u8, "namespace_version", namespace_version);

    const clap = b.dependency("clap", .{}).module("clap");

    const exe = b.addExecutable(.{
        .name = "main",
        .root_source_file = .{ .path = "src/main.zig" },
        .optimize = optimize,
        .target = target,
    });
    exe.root_module.addOptions("config", options);
    exe.root_module.addImport("clap", clap);
    exe.linkLibC();
    exe.linkSystemLibrary("gobject-introspection-1.0");
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const run_tar = b.addSystemCommand(&[_][]const u8{ "tar", "cahf" });
    run_tar.addArgs(&[_][]const u8{ "gtk4.tar.gz", "gtk4" });
    const release_step = b.step("release", "Create the release tar ball (Please run generator first)");
    release_step.dependOn(&run_tar.step);
}
