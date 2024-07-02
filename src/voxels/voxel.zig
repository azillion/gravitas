pub const Voxel = struct {
    color: [3]f32,
    _padding1: f32 = 0.0,
    emission: [3]f32,
    is_solid: bool,
};

pub const SimpleVoxel = struct {
    material: u8,
    position: [3]f32,
    color: [4]f32,
};
