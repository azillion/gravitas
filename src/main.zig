const std = @import("std");
const math = std.math;
const zglfw = @import("zglfw");
const zgpu = @import("zgpu");
const wgpu = zgpu.wgpu;
const zgui = @import("zgui");
const zmath = @import("zmath");
const svo = @import("svo/octree.zig");
const Voxel = @import("svo/voxel.zig").SimpleVoxel;
const camera = @import("camera.zig");
const CameraUniform = camera.CameraUniform;
const State = @import("state.zig").State;

const content_dir = "assets/";
const window_title = "Gravitas Engine";
const default_window_width = 1600;
const default_window_height = 1000;

const wgsl_vs = @embedFile("shaders/basic_raymarcher.vs.wgsl");
const wgsl_fs = @embedFile("shaders/basic_raymarcher.fs.wgsl");

const Vertex = struct {
    position: [3]f32,
    uv: [2]f32,
};

// set up our ray casting quad
const vertices = [_]Vertex{
    .{ .position = .{ -1.0, -1.0, 0.0 }, .uv = .{ 0.0, 0.0 } },
    .{ .position = .{ 1.0, -1.0, 0.0 }, .uv = .{ 1.0, 0.0 } },
    .{ .position = .{ 1.0, 1.0, 0.0 }, .uv = .{ 1.0, 1.0 } },
    .{ .position = .{ -1.0, 1.0, 0.0 }, .uv = .{ 0.0, 1.0 } },
};

const indices = [_]u16{ 0, 1, 2, 0, 2, 3 };

fn init(allocator: std.mem.Allocator, window: *zglfw.Window) !State {
    const gctx = try zgpu.GraphicsContext.create(allocator, .{
        .window = window,
        .fn_getTime = @ptrCast(&zglfw.getTime),
        .fn_getFramebufferSize = @ptrCast(&zglfw.Window.getFramebufferSize),
        .fn_getWin32Window = @ptrCast(&zglfw.getWin32Window),
        .fn_getX11Display = @ptrCast(&zglfw.getX11Display),
        .fn_getX11Window = @ptrCast(&zglfw.getX11Window),
        .fn_getWaylandDisplay = @ptrCast(&zglfw.getWaylandDisplay),
        .fn_getWaylandSurface = @ptrCast(&zglfw.getWaylandWindow),
        .fn_getCocoaWindow = @ptrCast(&zglfw.getCocoaWindow),
    }, .{});
    errdefer gctx.destroy(allocator);

    const cam = camera.Camera.init();

    const camera_buffer = gctx.createBuffer(.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(CameraUniform),
    });

    const bind_group_layout = gctx.createBindGroupLayout(&.{
        zgpu.bufferEntry(0, .{ .vertex = true, .fragment = true }, .uniform, false, 0),
    });
    defer gctx.releaseResource(bind_group_layout);

    const pipeline_layout = gctx.createPipelineLayout(&.{bind_group_layout});
    defer gctx.releaseResource(pipeline_layout);

    const pipeline = pipelines: {
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
            .fragment = &wgpu.FragmentState{
                .module = fs_module,
                .entry_point = "fs_main",
                .target_count = color_targets.len,
                .targets = &color_targets,
            },
        };
        break :pipelines gctx.createRenderPipeline(pipeline_layout, pipeline_descriptor);
    };
    const bind_group = gctx.createBindGroup(bind_group_layout, &.{
        .{ .binding = 0, .buffer_handle = camera_buffer, .offset = 0, .size = @sizeOf(CameraUniform) },
    });

    return State{
        .gctx = gctx,
        .pipeline = pipeline,
        .bind_group = bind_group,
        .camera_buffer = camera_buffer,
        .camera = cam,
        .frame_times = std.ArrayList(f32).init(allocator),
        .last_frame_time = zglfw.getTime(),
    };
}

fn deinit(allocator: std.mem.Allocator, state: *State) void {
    state.frame_times.deinit();
    state.gctx.destroy(allocator);
    state.* = undefined;
}

fn showDebugWindow(state: *State) void {
    const current_time = zglfw.getTime();
    const frame_time = current_time - state.last_frame_time;
    state.last_frame_time = current_time;

    state.frame_times.append(@floatCast(frame_time)) catch {};
    if (state.frame_times.items.len > 100) {
        _ = state.frame_times.orderedRemove(0);
    }

    var avg_frame_time: f32 = 0;
    for (state.frame_times.items) |time| {
        avg_frame_time += time;
    }
    avg_frame_time /= @as(f32, @floatFromInt(state.frame_times.items.len));

    const fps = 1.0 / avg_frame_time;

    zgui.setNextWindowPos(.{ .x = 10, .y = 10 });
    zgui.setNextWindowSize(.{ .w = 300, .h = 150, .cond = .always });

    if (zgui.begin("Debug Info", .{ .flags = .{ .no_move = true, .no_resize = true } })) {
        zgui.text("Frame Time: {d:.3} ms", .{avg_frame_time * 1000});
        zgui.text("FPS: {d:.1}", .{fps});
    }
    defer zgui.end();
}

fn update(state: *State) void {
    zgui.backend.newFrame(
        state.gctx.swapchain_descriptor.width,
        state.gctx.swapchain_descriptor.height,
    );

    showDebugWindow(state);
}

fn draw(state: *State) void {
    const gctx = state.gctx;

    const camera_data: CameraUniform = state.camera.getShaderData();
    const camera_data_slice: [1]CameraUniform = .{camera_data};
    gctx.queue.writeBuffer(gctx.lookupResource(state.camera_buffer).?, 0, CameraUniform, &camera_data_slice);

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
            pass.draw(3, 1, 0, 0); // Draw 3 vertices for a full-screen triangle
            zgui.backend.draw(pass);
        }

        break :commands encoder.finish(null);
    };
    defer commands.release();

    gctx.submit(&.{commands});
    _ = gctx.present();
}

fn mouseCallback(window: *zglfw.Window, xpos: f64, ypos: f64) callconv(.C) void {
    const state = window.getUserPointer(State) orelse return;
    var cam = &state.camera;

    const x = @as(f32, @floatCast(xpos));
    const y = @as(f32, @floatCast(ypos));

    if (cam.first_mouse) {
        cam.last_x = x;
        cam.last_y = y;
        cam.first_mouse = false;
    }

    const xoffset = (x - cam.last_x) * cam.sensitivity;
    const yoffset = (cam.last_y - y) * cam.sensitivity; // Reversed since y-coordinates range from bottom to top
    cam.last_x = x;
    cam.last_y = y;

    cam.yaw += xoffset;
    cam.pitch += yoffset;

    // Constrain the pitch
    cam.pitch = std.math.clamp(cam.pitch, -89.0, 89.0);

    // Update front, right and up Vectors using the updated Euler angles
    const front = zmath.normalize3(zmath.f32x4(@cos(math.degreesToRadians(cam.yaw)) * @cos(math.degreesToRadians(cam.pitch)), @sin(math.degreesToRadians(cam.pitch)), @sin(math.degreesToRadians(cam.yaw)) * @cos(math.degreesToRadians(cam.pitch)), 0.0));
    cam.front = front;
    cam.right = zmath.normalize3(zmath.cross3(front, zmath.f32x4(0.0, 1.0, 0.0, 0.0)));
    cam.up = zmath.normalize3(zmath.cross3(cam.right, front));
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

    const window = try zglfw.Window.create(default_window_width, default_window_height, window_title, null);
    defer window.destroy();
    window.setSizeLimits(400, 400, -1, -1);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var state = try init(allocator, window);
    defer deinit(allocator, &state);

    const scale_factor = scale_factor: {
        const scale = window.getContentScale();
        break :scale_factor @max(scale[0], scale[1]);
    };

    ////////////// gui initialization
    zgui.init(allocator);
    defer zgui.deinit();

    _ = zgui.io.addFontFromFile(content_dir ++ "Roboto-Medium.ttf", math.floor(16.0 * scale_factor));

    zgui.backend.init(
        window,
        state.gctx.device,
        @intFromEnum(zgpu.GraphicsContext.swapchain_format),
        @intFromEnum(wgpu.TextureFormat.undef),
    );
    defer zgui.backend.deinit();
    zgui.getStyle().scaleAllSizes(scale_factor);
    //////////////////////////

    window.setUserPointer(&state);
    _ = window.setCursorPosCallback(mouseCallback);
    window.setInputMode(.cursor, .disabled);

    var last_time: f64 = zglfw.getTime();

    while (!window.shouldClose() and window.getKey(.escape) != .press) {
        const current_time = zglfw.getTime();
        const delta_time: f32 = @floatCast(current_time - last_time);
        last_time = current_time;

        zglfw.pollEvents();
        update(&state);
        state.camera.update(window, delta_time);
        draw(&state);
    }
}
