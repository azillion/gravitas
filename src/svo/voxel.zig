pub const Voxel = struct {
    material: u8,
    // we can add more fields here
};

pub const SimpleVoxel = struct {
    position: [3]f32,
    color: [4]f32,
};
