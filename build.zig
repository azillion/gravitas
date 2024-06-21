const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{ .name = "gravitas", .root_source_file = b.path("src/main.zig"), .optimize = optimize, .target = target });

    @import("system_sdk").addLibraryPathsTo(exe);
    @import("zgpu").addLibraryPathsTo(exe);

    const zgpu = b.dependency("zgpu", .{});
    exe.root_module.addImport("zgpu", zgpu.module("root"));
    exe.linkLibrary(zgpu.artifact("zdawn"));

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run gravitas");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);
}
