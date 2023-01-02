const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("application", "application.zig");
    var pid = try std.os.fork();
    if (pid == 0) {
        const argv = [_:null]?[*:0]const u8{ "glib-compile-resources", "exampleapp.gresource.xml", "--target=resources.c", "--generate-source", null };
        const envp = [_]?[*:0]const u8{null};
        var err = std.os.execvpeZ("glib-compile-resources", @ptrCast([*:null]const ?[*:0]u8, &argv), @ptrCast([*:null]const ?[*:0]u8, &envp));
        return err;
    } else {
        std.debug.assert(std.os.waitpid(pid, 0).status == 0);
    }
    pid = try std.os.fork();
    if (pid == 0) {
        const argv = [_]?[*:0]const u8{ "glib-compile-schemas", ".", null };
        const envp = [_]?[*:0]const u8{null};
        var err = std.os.execvpeZ("glib-compile-schemas", @ptrCast([*:null]const ?[*:0]u8, &argv), @ptrCast([*:null]const ?[*:0]u8, &envp));
        return err;
    } else {
        std.debug.assert(std.os.waitpid(pid, 0).status == 0);
    }
    exe.addCSourceFile("resources.c", &[_][]const u8{""});
    exe.addPackagePath("Gtk", "../generate/output/Gtk.zig");
    exe.addPackagePath("core", "../generate/output/core.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.linkLibC();
    exe.linkSystemLibrary("gtk4");
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
