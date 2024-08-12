const std = @import("std");

// TODO: https://github.com/ziglang/zig/issues/14531
pub fn import_zon_version(b: *std.Build) std.SemanticVersion {
    const cwd = std.fs.cwd();
    const zon = cwd.openFile("build.zig.zon", .{}) catch @panic("File.OpenError");
    defer zon.close();
    const reader = zon.reader();
    var line = std.ArrayList(u8).init(b.allocator);
    defer line.deinit();
    while (reader.streamUntilDelimiter(line.writer(), '\n', null)) {
        defer line.clearRetainingCapacity();
        var is_version_line = false;
        var iter = std.mem.splitScalar(u8, line.items, '\"');
        while (iter.next()) |seq| {
            if (is_version_line) {
                var version = std.SemanticVersion.parse(seq) catch @panic("SemanticVersion.ParseError");
                if (version.pre) |_pre| {
                    version.pre = b.allocator.dupe(u8, _pre) catch @panic("Allocator.Error");
                }
                if (version.build) |_build| {
                    version.build = b.allocator.dupe(u8, _build) catch @panic("Allocator.Error");
                }
                return version;
            }
            if (std.mem.indexOf(u8, seq, ".version")) |_| {
                is_version_line = true;
            }
        }
    } else |_| {
        @panic("Reader.Error");
    }
}

// adopted from zig's build.zig
pub fn get_version(b: *std.Build) []const u8 {
    if (!std.process.can_spawn) {
        std.debug.print("error: version info cannot be retrieved from git.\n", .{});
        std.process.exit(1);
    }
    const version = import_zon_version(b);
    const version_string = b.fmt("{d}.{d}.{d}", .{ version.major, version.minor, version.patch });

    var code: u8 = undefined;
    const git_describe_untrimmed = b.runAllowFail(&[_][]const u8{
        "git",
        "-C",
        b.build_root.path orelse ".",
        "describe",
        "--match",
        "*.*.*",
        "--tags",
        "--abbrev=9",
    }, &code, .Ignore) catch {
        return version_string;
    };
    const git_describe = git_describe: {
        const git_describe_trimmed = std.mem.trim(u8, git_describe_untrimmed, " \n\r");
        break :git_describe if (git_describe_trimmed[0] != 'v') git_describe_trimmed else git_describe_trimmed[1..];
    };

    switch (std.mem.count(u8, git_describe, "-")) {
        0 => {
            // Tagged release version (e.g. 0.10.0).
            if (!std.mem.eql(u8, git_describe, version_string)) {
                std.debug.print("Version '{s}' does not match Git tag '{s}'\n", .{ version_string, git_describe });
                std.process.exit(1);
            }
            return version_string;
        },
        2 => {
            // Untagged development build (e.g. 0.10.0-dev.2025+ecf0050a9).
            var it = std.mem.splitScalar(u8, git_describe, '-');
            const tagged_ancestor = it.first();
            const commit_height = it.next().?;
            const commit_id = it.next().?;

            const ancestor_ver = std.SemanticVersion.parse(tagged_ancestor) catch {
                std.debug.print("Failed to parse tagged ancestor '{s}'", .{tagged_ancestor});
                std.process.exit(1);
            };
            if (version.order(ancestor_ver) != .gt) {
                std.debug.print("Version '{}' must be greater than tagged ancestor '{}'\n", .{ version, ancestor_ver });
                std.process.exit(1);
            }

            // Check that the commit hash is prefixed with a 'g' (a Git convention).
            if (commit_id.len < 1 or commit_id[0] != 'g') {
                std.debug.print("Unexpected `git describe` output: {s}\n", .{git_describe});
                return version_string;
            }

            // The version is reformatted in accordance with the https://semver.org specification.
            return b.fmt("{s}-dev.{s}+{s}", .{ version_string, commit_height, commit_id[1..] });
        },
        else => {
            std.debug.print("Unexpected `git describe` output: {s}\n", .{git_describe});
            return version_string;
        },
    }
}

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    // Options
    const options = b.addOptions();
    const version = b.option([]const u8, "version", "Version string") orelse get_version(b);
    options.addOption([]const u8, "version", version);
    const namespace = b.option([]const []const u8, "gi-namespaces", "GI namespace to use, e.g. \"Gtk\"") orelse &[_][]const u8{"Gtk"};
    options.addOption([]const []const u8, "gi_namespaces", namespace);
    const namespace_version = b.option([]const []const u8, "gi-versions", "Version of namespace, may be null for latest");
    options.addOption(?[]const []const u8, "gi_versions", namespace_version);
    const outputdir = b.option([]const u8, "outputdir", "Output directory") orelse "gi-output";
    options.addOption([]const u8, "outputdir", outputdir);

    // Dependecies
    const clap = b.dependency("clap", .{}).module("clap");

    // Check step
    const exe_check = b.addExecutable(.{
        .name = "main",
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
    });
    exe_check.root_module.addOptions("config", options);
    exe_check.root_module.addImport("clap", clap);

    const check = b.step("check", "Check if compiles");
    check.dependOn(&exe_check.step);

    // Install step
    const exe = b.addExecutable(.{
        .name = "main",
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
    });
    exe.root_module.addOptions("config", options);
    exe.root_module.addImport("clap", clap);
    exe.linkLibC();
    exe.linkSystemLibrary("girepository-2.0");

    b.installArtifact(exe);

    // Run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    } else {
        run_cmd.addArgs(&.{ "--outputdir", "gtk4" });
        run_cmd.addArgs(&.{ "--includedir", "lib/girepository-1.0" });
        run_cmd.addArgs(&.{ "--gi-namespaces", "GLib" }); // load glib before glib_*
        run_cmd.addArgs(&.{ "--gi-namespaces", "GLibUnix" });
        run_cmd.addArgs(&.{ "--gi-namespaces", "GLibWin32" });
        run_cmd.addArgs(&.{ "--gi-namespaces", "Gio" }); // load gio before gio_*
        run_cmd.addArgs(&.{ "--gi-namespaces", "GioUnix" });
        run_cmd.addArgs(&.{ "--gi-namespaces", "GioWin32" });
        run_cmd.addArgs(&.{ "--gi-namespaces", "Gdk" }); // load gdk before gdk_*
        run_cmd.addArgs(&.{ "--gi-namespaces", "GdkWayland" });
        run_cmd.addArgs(&.{ "--gi-namespaces", "GdkX11" });
        run_cmd.addArgs(&.{ "--gi-namespaces", "GdkWin32" });
        run_cmd.addArgs(&.{ "--gi-namespaces", "Gtk" });
        run_cmd.addArgs(&.{ "--pkg-name", "gtk" });
        run_cmd.addArgs(&.{ "--pkg-version", version });
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Dump abi step
    const run_abi_cmd = b.addRunArtifact(exe);
    run_abi_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_abi_cmd.addArgs(args);
    } else {
        run_abi_cmd.addArgs(&.{ "--outputdir", "test/abi" });
        run_abi_cmd.addArgs(&.{ "--includedir", "lib/girepository-1.0" });
        run_abi_cmd.addArgs(&.{"--emit-abi"});
    }

    const dump_abi_step = b.step("dump-abi", "Dump abi");
    dump_abi_step.dependOn(&run_abi_cmd.step);

    // Dist step
    const run_tar = b.addSystemCommand(&.{ "tar", "cahf" });
    run_tar.addArgs(&.{ "gtk4.tar.gz", "gtk4" });
    run_tar.step.dependOn(run_step);

    const dist_step = b.step("dist", "Generate release archive");
    dist_step.dependOn(&run_tar.step);
}
