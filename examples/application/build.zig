const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe,
    });

    const gtk = b.dependency("gtk", .{});

    const exe = b.addExecutable(.{
        .name = "application",
        .root_source_file = b.path("application.zig"),
        .optimize = optimize,
        .target = target,
    });
    exe.root_module.addImport("gtk", gtk.module("gtk"));
    var pid = try std.posix.fork();
    if (pid == 0) {
        const argv = [_:null]?[*:0]const u8{ "glib-compile-resources", "exampleapp.gresource.xml", "--target=resources.c", "--generate-source" };
        const envp = [_:null]?[*:0]const u8{};
        const err = std.posix.execvpeZ("glib-compile-resources", &argv, &envp);
        return err;
    } else {
        std.debug.assert(std.posix.waitpid(pid, 0).status == 0);
    }
    pid = try std.posix.fork();
    if (pid == 0) {
        const argv = [_:null]?[*:0]const u8{ "glib-compile-schemas", "." };
        const envp = [_:null]?[*:0]const u8{};
        const err = std.posix.execvpeZ("glib-compile-schemas", &argv, &envp);
        return err;
    } else {
        std.debug.assert(std.posix.waitpid(pid, 0).status == 0);
    }
    exe.addCSourceFile(.{
        .file = b.path("resources.c"),
        .flags = &[_][]const u8{},
    });
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
