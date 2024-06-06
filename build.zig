const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const options = b.addOptions();
    const version = b.option([]const u8, "version", "Version string") orelse "0.8.3";
    options.addOption([]const u8, "version", version);
    const namespace = b.option([]const u8, "gi-namespace", "GI namespace to use, e.g. \"Gtk\"") orelse "Gtk";
    options.addOption([]const u8, "gi_namespace", namespace);
    const namespace_version = b.option([]const u8, "gi-version", "Version of namespace, may be null for latest");
    options.addOption(?[]const u8, "gi_version", namespace_version);
    const outputdir = b.option([]const u8, "outputdir", "Output directory") orelse "output";
    options.addOption([]const u8, "outputdir", outputdir);

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
    } else {
        run_cmd.addArgs(&.{ "--outputdir", "gtk4" });
        run_cmd.addArgs(&.{ "--includedir", "lib/girepository-1.0" });
        run_cmd.addArgs(&.{ "--pkg-name", "gtk4" });
        run_cmd.addArgs(&.{ "--pkg-version", version });
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const run_tar = b.addSystemCommand(&.{ "tar", "cahf" });
    run_tar.addArgs(&.{ "gtk4.tar.gz", "gtk4" });
    run_tar.step.dependOn(run_step);

    const dist_step = b.step("dist", "Generate release archive");
    dist_step.dependOn(&run_tar.step);
}
