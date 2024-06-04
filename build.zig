const std = @import("std");
const Build = std.Build;
const OptimizeMode = std.builtin.OptimizeMode;
const sokol = @import("sokol");

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });

    // special case handling for native vs web build
    if (target.result.isWasm()) {
        try buildWeb(b, target, optimize, dep_sokol);
    } else {
        try buildNative(b, target, optimize, dep_sokol);
    }
}

// this is the regular build for all native platforms, nothing surprising here
fn buildNative(b: *Build, target: Build.ResolvedTarget, optimize: OptimizeMode, dep_sokol: *Build.Dependency) !void {
    const gravitas = b.addExecutable(.{
        .name = "gravitas",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/gravitas.zig"),
    });
    gravitas.root_module.addImport("sokol", dep_sokol.module("sokol"));
    b.installArtifact(gravitas);
    const run = b.addRunArtifact(gravitas);
    b.step("run", "Run gravitas").dependOn(&run.step);
}

// for web builds, the Zig code needs to be built into a library and linked with the Emscripten linker
fn buildWeb(b: *Build, target: Build.ResolvedTarget, optimize: OptimizeMode, dep_sokol: *Build.Dependency) !void {
    const gravitas = b.addStaticLibrary(.{
        .name = "gravitas",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/gravitas.zig"),
    });
    gravitas.root_module.addImport("sokol", dep_sokol.module("sokol"));

    // create a build step which invokes the Emscripten linker
    const emsdk = dep_sokol.builder.dependency("emsdk", .{});
    const link_step = try sokol.emLinkStep(b, .{
        .lib_main = gravitas,
        .target = target,
        .optimize = optimize,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = false,
        .shell_file_path = dep_sokol.path("src/sokol/web/shell.html").getPath(b),
    });
    // ...and a special run step to start the web build output via 'emrun'
    const run = sokol.emRunStep(b, .{ .name = "gravitas", .emsdk = emsdk });
    run.step.dependOn(&link_step.step);
    b.step("run", "Run gravitas").dependOn(&run.step);
}
