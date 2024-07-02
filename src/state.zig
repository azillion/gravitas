const std = @import("std");
const zgpu = @import("zgpu");
const camera = @import("camera.zig");
const Voxel = @import("voxels/voxel.zig").Voxel;

pub const State = struct {
    gctx: *zgpu.GraphicsContext,
    pipeline: zgpu.RenderPipelineHandle,
    bind_group: zgpu.BindGroupHandle,
    voxel_buffer: zgpu.BufferHandle,
    voxel_uniform_buffer: zgpu.BufferHandle,
    window_width: i32,
    window_height: i32,
    camera: camera.Camera,
    voxels: []Voxel,
    last_x: f32,
    last_y: f32,
    first_mouse: bool,
    frame_times: std.ArrayList(f32),
    last_frame_time: f64,
};
