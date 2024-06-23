const std = @import("std");
const math = std.math;
const zglfw = @import("zglfw");
const zgpu = @import("zgpu");
const wgpu = zgpu.wgpu;
const zgui = @import("zgui");
const zm = @import("zmath");
const svo = @import("svo/octree.zig");
const Voxel = @import("svo/voxel.zig").Voxel;

const content_dir = "assets/";
const window_title = "Gravitas Engine";

const wgsl_vs = @embedFile("shaders/raymarcher.vs.wgsl");
const wgsl_fs = @embedFile("shaders/raymarcher.fs.wgsl");

const State = struct {
    gctx: *zgpu.GraphicsContext,
    pipeline: zgpu.RenderPipelineHandle,
    bind_group: zgpu.BindGroupHandle,
    camera_buffer: zgpu.BufferHandle,
    camera_position_buffer: zgpu.BufferHandle,
    inverse_projection_buffer: zgpu.BufferHandle,
    clip_to_world_buffer: zgpu.BufferHandle,
    voxel_data_buffer: zgpu.BufferHandle,
    octree: svo.SparseVoxelOctree,
};

fn init(allocator: std.mem.Allocator, window: *zglfw.Window) !State {
    var octree = try svo.SparseVoxelOctree.init(allocator, 8); // 8 levels of detail
    try octree.generateSimpleTerrain(256, 256, 256);

    const gctx = try zgpu.GraphicsContext.create(
        allocator,
        .{
            .window = window,
            .fn_getTime = @ptrCast(&zglfw.getTime),
            .fn_getFramebufferSize = @ptrCast(&zglfw.Window.getFramebufferSize),
            .fn_getWin32Window = @ptrCast(&zglfw.getWin32Window),
            .fn_getX11Display = @ptrCast(&zglfw.getX11Display),
            .fn_getX11Window = @ptrCast(&zglfw.getX11Window),
            .fn_getWaylandDisplay = @ptrCast(&zglfw.getWaylandDisplay),
            .fn_getWaylandSurface = @ptrCast(&zglfw.getWaylandWindow),
            .fn_getCocoaWindow = @ptrCast(&zglfw.getCocoaWindow),
        },
        .{},
    );
    errdefer gctx.destroy(allocator);

    const bind_group_layout = gctx.createBindGroupLayout(&.{
        zgpu.bufferEntry(0, .{ .vertex = true, .fragment = true }, .uniform, false, 0),
        zgpu.bufferEntry(1, .{ .vertex = true, .fragment = true }, .uniform, false, 0),
        zgpu.bufferEntry(2, .{ .vertex = true, .fragment = true }, .uniform, false, 0),
        zgpu.bufferEntry(3, .{ .vertex = true, .fragment = true }, .uniform, false, 0),
        zgpu.bufferEntry(4, .{ .fragment = true }, .read_only_storage, false, 0),
    });
    defer gctx.releaseResource(bind_group_layout);

    const pipeline_layout = gctx.createPipelineLayout(&.{bind_group_layout});
    defer gctx.releaseResource(pipeline_layout);

    const pipeline = pipeline: {
        const vs_module = zgpu.createWgslShaderModule(gctx.device, wgsl_vs, "vs");
        defer vs_module.release();

        const fs_module = zgpu.createWgslShaderModule(gctx.device, wgsl_fs, "fs");
        defer fs_module.release();

        const color_targets = [_]wgpu.ColorTargetState{.{
            .format = zgpu.GraphicsContext.swapchain_format,
        }};

        const pipeline_descriptor = wgpu.RenderPipelineDescriptor{
            .vertex = wgpu.VertexState{
                .module = vs_module,
                .entry_point = "vs_main",
                .buffer_count = 0,
                .buffers = null,
            },
            .primitive = wgpu.PrimitiveState{
                .front_face = .ccw,
                .cull_mode = .none,
                .topology = .triangle_list,
            },
            .fragment = &wgpu.FragmentState{
                .module = fs_module,
                .entry_point = "fs_main",
                .target_count = color_targets.len,
                .targets = &color_targets,
            },
        };
        break :pipeline gctx.createRenderPipeline(pipeline_layout, pipeline_descriptor);
    };

    const camera_buffer = gctx.createBuffer(.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(zm.Mat),
    });

    const camera_position_buffer = gctx.createBuffer(.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(zm.F32x4),
    });

    const inverse_projection_buffer = gctx.createBuffer(.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(zm.Mat),
    });

    const clip_to_world_buffer = gctx.createBuffer(.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(zm.Mat),
    });

    const voxel_data_buffer = gctx.createBuffer(.{
        .usage = .{ .copy_dst = true, .storage = true },
        .size = 256 * 256 * 256 * @sizeOf(u32),
    });

    const bind_group = gctx.createBindGroup(bind_group_layout, &.{
        .{ .binding = 0, .buffer_handle = camera_buffer, .offset = 0, .size = @sizeOf(zm.Mat) },
        .{ .binding = 1, .buffer_handle = inverse_projection_buffer, .offset = 0, .size = @sizeOf(zm.Mat) },
        .{ .binding = 2, .buffer_handle = clip_to_world_buffer, .offset = 0, .size = @sizeOf(zm.Mat) },
        .{ .binding = 3, .buffer_handle = camera_position_buffer, .offset = 0, .size = @sizeOf(zm.F32x4) },
        .{ .binding = 4, .buffer_handle = voxel_data_buffer, .offset = 0, .size = 256 * 256 * 256 * @sizeOf(u32) },
    });

    return State{
        .gctx = gctx,
        .pipeline = pipeline,
        .bind_group = bind_group,
        .camera_buffer = camera_buffer,
        .camera_position_buffer = camera_position_buffer,
        .inverse_projection_buffer = inverse_projection_buffer,
        .clip_to_world_buffer = clip_to_world_buffer,
        .voxel_data_buffer = voxel_data_buffer,
        .octree = octree,
    };
}

fn deinit(allocator: std.mem.Allocator, state: *State) void {
    state.octree.deinit();
    state.gctx.destroy(allocator);
    state.* = undefined;
}

fn update(state: *State) void {
    zgui.backend.newFrame(
        state.gctx.swapchain_descriptor.width,
        state.gctx.swapchain_descriptor.height,
    );

    zgui.showDemoWindow(null);
}

fn updateVoxelData(state: *State, allocator: *std.mem.Allocator) void {
    const gctx = state.gctx;
    var voxel_data = std.ArrayList(u32).init(allocator.*);
    defer voxel_data.deinit();

    var non_zero_count: usize = 0;

    for (0..256) |z| {
        for (0..256) |y| {
            for (0..256) |x| {
                const voxel = state.octree.getVoxel(@intCast(x), @intCast(y), @intCast(z)) orelse Voxel{ .material = 0 };
                voxel_data.append(voxel.material) catch unreachable;
                if (voxel.material != 0) {
                    non_zero_count += 1;
                }
            }
        }
    }

    std.debug.print("Non-zero voxels: {}/{}\n", .{ non_zero_count, 256 * 256 * 256 });

    gctx.queue.writeBuffer(
        gctx.lookupResource(state.voxel_data_buffer).?,
        0,
        u32,
        voxel_data.items,
    );
}

fn draw(state: *State) void {
    const gctx = state.gctx;
    const fb_width = gctx.swapchain_descriptor.width;
    const fb_height = gctx.swapchain_descriptor.height;

    const cam_world_to_view = zm.lookAtLh(
        zm.f32x4(128.0, 128.0, -128.0, 1.0), // Camera position
        zm.f32x4(128.0, 0.0, 128.0, 1.0), // Look at center of terrain
        zm.f32x4(0.0, 1.0, 0.0, 0.0),
    );
    const cam_view_to_clip = zm.perspectiveFovLh(
        0.25 * math.pi,
        @as(f32, @floatFromInt(fb_width)) / @as(f32, @floatFromInt(fb_height)),
        0.01,
        200.0,
    );
    const cam_world_to_clip = zm.mul(cam_world_to_view, cam_view_to_clip);
    const cam_clip_to_world = zm.inverse(cam_world_to_clip);
    const inverse_projection = zm.inverse(cam_view_to_clip);
    const camera_position = zm.f32x4(128.0, 128.0, -128.0, 1.0);

    gctx.queue.writeBuffer(gctx.lookupResource(state.camera_buffer).?, 0, zm.Mat, &.{cam_world_to_clip});
    gctx.queue.writeBuffer(gctx.lookupResource(state.inverse_projection_buffer).?, 0, zm.Mat, &.{inverse_projection});
    gctx.queue.writeBuffer(gctx.lookupResource(state.clip_to_world_buffer).?, 0, zm.Mat, &.{cam_clip_to_world});
    gctx.queue.writeBuffer(gctx.lookupResource(state.camera_position_buffer).?, 0, zm.F32x4, &.{camera_position});

    const back_buffer_view = gctx.swapchain.getCurrentTextureView();
    defer back_buffer_view.release();

    const commands = commands: {
        const encoder = gctx.device.createCommandEncoder(null);
        defer encoder.release();

        {
            const color_attachments = [_]wgpu.RenderPassColorAttachment{.{
                .view = back_buffer_view,
                .load_op = .clear,
                .store_op = .store,
            }};
            const render_pass_info = wgpu.RenderPassDescriptor{
                .color_attachment_count = color_attachments.len,
                .color_attachments = &color_attachments,
            };
            const pass = encoder.beginRenderPass(render_pass_info);
            defer {
                pass.end();
                pass.release();
            }

            pass.setPipeline(gctx.lookupResource(state.pipeline).?);
            pass.setBindGroup(0, gctx.lookupResource(state.bind_group).?, &.{});
            pass.draw(3, 1, 0, 0);
        }

        {
            const color_attachments = [_]wgpu.RenderPassColorAttachment{.{
                .view = back_buffer_view,
                .load_op = .load,
                .store_op = .store,
            }};
            const render_pass_info = wgpu.RenderPassDescriptor{
                .color_attachment_count = color_attachments.len,
                .color_attachments = &color_attachments,
            };
            const pass = encoder.beginRenderPass(render_pass_info);
            defer {
                pass.end();
                pass.release();
            }

            zgui.backend.draw(pass);
        }

        break :commands encoder.finish(null);
    };
    defer commands.release();

    gctx.submit(&.{commands});
    _ = gctx.present();
}

pub fn main() !void {
    try zglfw.init();
    defer zglfw.terminate();

    // Change current working directory to where the executable is located.
    {
        var buffer: [1024]u8 = undefined;
        const path = std.fs.selfExeDirPath(buffer[0..]) catch ".";
        try std.posix.chdir(path);
    }

    zglfw.windowHintTyped(.client_api, .no_api);

    const window = try zglfw.Window.create(1600, 1000, window_title, null);
    defer window.destroy();
    window.setSizeLimits(400, 400, -1, -1);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    var state = try init(allocator, window);
    defer deinit(allocator, &state);

    const scale_factor = scale_factor: {
        const scale = window.getContentScale();
        break :scale_factor @max(scale[0], scale[1]);
    };

    zgui.init(allocator);
    defer zgui.deinit();

    updateVoxelData(&state, &allocator);

    _ = zgui.io.addFontFromFile(content_dir ++ "Roboto-Medium.ttf", math.floor(16.0 * scale_factor));

    zgui.backend.init(
        window,
        state.gctx.device,
        @intFromEnum(zgpu.GraphicsContext.swapchain_format),
        @intFromEnum(wgpu.TextureFormat.undef),
    );
    defer zgui.backend.deinit();

    zgui.getStyle().scaleAllSizes(scale_factor);

    while (!window.shouldClose() and window.getKey(.escape) != .press) {
        zglfw.pollEvents();
        update(&state);
        draw(&state);
    }
}
