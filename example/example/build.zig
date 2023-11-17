const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{ .name = "example", .root_source_file = .{ .path = "example.zig" }, .optimize = optimize, .target = target });
    const gtk = b.createModule(.{ .source_file = .{ .path = "../../publish/Gtk.zig" } });
    exe.addModule("gtk", gtk);
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
