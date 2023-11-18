const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const gtk = b.dependency("gtk", .{});

    const exe = b.addExecutable(.{
        .name = "application",
        .root_source_file = .{ .path = "application.zig" },
        .optimize = optimize,
        .target = target,
    });
    exe.addModule("gtk", gtk.module("gtk"));
    var pid = try std.os.fork();
    if (pid == 0) {
        const argv = [_:null]?[*:0]const u8{ "glib-compile-resources", "exampleapp.gresource.xml", "--target=resources.c", "--generate-source" };
        const envp = [_:null]?[*:0]const u8{};
        const err = std.os.execvpeZ("glib-compile-resources", &argv, &envp);
        return err;
    } else {
        std.debug.assert(std.os.waitpid(pid, 0).status == 0);
    }
    pid = try std.os.fork();
    if (pid == 0) {
        const argv = [_:null]?[*:0]const u8{ "glib-compile-schemas", "." };
        const envp = [_:null]?[*:0]const u8{};
        const err = std.os.execvpeZ("glib-compile-schemas", &argv, &envp);
        return err;
    } else {
        std.debug.assert(std.os.waitpid(pid, 0).status == 0);
    }
    exe.addCSourceFile(.{
        .file = .{ .path = "resources.c" },
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
