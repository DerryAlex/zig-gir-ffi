const std = @import("std");

pub fn getVersion() !std.SemanticVersion {
    const zon = @import("build.zig.zon");
    return try .parse(zon.version);
}

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    // Options
    const options = b.addOptions();
    options.addOption(std.SemanticVersion, "version", try getVersion());
    const has_gir_backend = b.option(bool, "gir", "Gir backend") orelse false;
    options.addOption(bool, "has_gir", has_gir_backend);
    const has_typelib_backend = b.option(bool, "typelib", "Typelib backend") orelse true;
    options.addOption(bool, "has_typelib", has_typelib_backend);

    // Check step
    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
    });
    const exe_check = b.addExecutable(.{
        .name = "main",
        .root_module = root_module,
    });
    exe_check.root_module.addOptions("options", options);

    const check = b.step("check", "Check if compiles");
    check.dependOn(&exe_check.step);

    // Install step
    const exe = b.addExecutable(.{
        .name = "main",
        .root_module = root_module,
    });
    exe.root_module.addOptions("options", options);
    if (has_typelib_backend) {
        exe.linkLibC();
        exe.linkSystemLibrary("girepository-2.0");
    }

    b.installArtifact(exe);

    // Run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    } else {
        run_cmd.addArgs(&.{ "-I", "data/gir" });
        run_cmd.addArgs(&.{ "-I", "data/typelib" });
        run_cmd.addArgs(&.{"Gtk"});
        // run_cmd.addArgs(&.{ "GLib", "GLibUnix", "GLibWin32" });
        // run_cmd.addArgs(&.{ "Gio", "GioUnix", "GioWin32" });
        // run_cmd.addArgs(&.{ "Gdk", "GdkWayland", "GdkX11", "GdkWin32", "GdkMacos" });
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Dist step
    const run_tar = b.addSystemCommand(&.{ "tar", "cahf" });
    run_tar.addArgs(&.{ "gi.tar.gz", "gi" });
    run_tar.step.dependOn(run_step);

    const dist_step = b.step("dist", "Generate release archive");
    dist_step.dependOn(&run_tar.step);
}
