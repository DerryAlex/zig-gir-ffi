const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{ .name = "application", .root_source_file = .{ .path = "application.zig" }, .optimize = optimize, .target = target });
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
    exe.addCSourceFile("resources.c", &[_][]const u8{""});
    const gtk_mod = b.createModule(.{ .source_file = .{ .path = "../../publish/Gtk.zig" } });
    exe.addModule("Gtk", gtk_mod);
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
