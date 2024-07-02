const std = @import("std");

const assets_dir = "assets/";

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "gravitas",
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
    });

    // Add the assets directory to the include path
    const install_content_step = b.addInstallDirectory(.{
        .source_dir = b.path(assets_dir),
        .install_dir = .{ .custom = "" },
        .install_subdir = "bin/" ++ assets_dir,
    });
    exe.step.dependOn(&install_content_step.step);

    @import("system_sdk").addLibraryPathsTo(exe);
    @import("zgpu").addLibraryPathsTo(exe);

    const zgpu = b.dependency("zgpu", .{});
    exe.root_module.addImport("zgpu", zgpu.module("root"));
    exe.linkLibrary(zgpu.artifact("zdawn"));

    const zglfw = b.dependency("zglfw", .{});
    exe.root_module.addImport("zglfw", zglfw.module("root"));
    exe.linkLibrary(zglfw.artifact("glfw"));

    const zgui = b.dependency("zgui", .{
        .target = target,
        .backend = .glfw_wgpu,
    });
    exe.root_module.addImport("zgui", zgui.module("root"));
    exe.linkLibrary(zgui.artifact("imgui"));

    const zmath = b.dependency("zmath", .{});
    exe.root_module.addImport("zmath", zmath.module("root"));

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run gravitas");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);
}
