const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe,
    });

    const gi = b.dependency("gi", .{});
    const root_module = b.createModule(.{
        .root_source_file = b.path("application.zig"),
        .optimize = optimize,
        .target = target,
    });
    root_module.addImport("gi", gi.module("gi"));
    root_module.link_libc = true;
    root_module.linkSystemLibrary("gtk4", .{});

    const exe_check = b.addExecutable(.{
        .name = "application",
        .root_module = root_module,
    });
    const check = b.step("check", "Check if compiles");
    check.dependOn(&exe_check.step);

    const compile_resource = b.addSystemCommand(&.{ "glib-compile-resources", "exampleapp.gresource.xml", "--target=resources.c", "--generate-source" });
    const compile_schema = b.addSystemCommand(&.{ "glib-compile-schemas", "." });

    const exe = b.addExecutable(.{
        .name = "application",
        .root_module = root_module,
    });
    exe.addCSourceFile(.{
        .file = b.path("resources.c"),
        .flags = &[_][]const u8{},
    });
    exe.step.dependOn(&compile_resource.step);
    exe.step.dependOn(&compile_schema.step);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
