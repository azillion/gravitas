const std = @import("std");
const zgpu = @import("zgpu");
const camera = @import("camera.zig");

pub const State = struct {
    gctx: *zgpu.GraphicsContext,
    pipeline: zgpu.RenderPipelineHandle,
    bind_group: zgpu.BindGroupHandle,
    camera_buffer: zgpu.BufferHandle,
    camera: camera.Camera,
    frame_times: std.ArrayList(f32),
    last_frame_time: f64,
};
