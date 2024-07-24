//!include src/shaders/math.wgsl

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) uv: vec2<f32>,
}

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOutput {
    var output: VertexOutput;
    
    // Generate a full-screen triangle
    let x = f32(vertex_index & 1u) * 4.0 - 1.0;
    let y = f32((vertex_index >> 1u) & 1u) * 4.0 - 1.0;
    
    output.clip_position = vec4<f32>(x, y, 0.0, 1.0);
    output.uv = vec2<f32>((x + 1.0) * 0.5, (1.0 - y) * 0.5);
    
    return output;
}

struct Voxel {
    color: vec3<f32>,
    emission: vec3<f32>,
    is_solid: u32,
};

struct Uniforms {
    view_matrix: mat4x4<f32>,
    proj_matrix: mat4x4<f32>,
    camera_pos: vec3<f32>,
    aspect_ratio: f32,
    time: f32,
};

@group(0) @binding(0) var<uniform> uniforms: Uniforms;

const EPSILON: f32 = 0.001;
const VOXEL_SIZE: f32 = 1.0;
const GRID_SIZE: i32 = 32;

@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let view_proj = uniforms.proj_matrix * uniforms.view_matrix;
    let inv_view_proj = inverse_mat4(view_proj);
    
    let near_point = inv_view_proj * vec4<f32>(uv * 2.0 - 1.0, -1.0, 1.0);
    let far_point = inv_view_proj * vec4<f32>(uv * 2.0 - 1.0, 1.0, 1.0);
    
    let near_point_3d = near_point.xyz / near_point.w;
    let far_point_3d = far_point.xyz / far_point.w;
    let ray_dir = normalize(far_point_3d - near_point_3d);
    let ray_origin = uniforms.camera_pos;

    //if (length(ray_origin - vec3<f32>(16.0, 16.0, 16.0)) < 1.0) {
        //return vec4<f32>(1.0, 0.0, 0.0, 1.0);  // Red dot at the center of the grid
    //}

    //var voxel = vec3<i32>(floor(ray_origin / VOXEL_SIZE));
    //let hit = ray_voxel_intersection(ray_origin, ray_dir);
    
    //if (hit) {
        //return vec4<f32>(1.0, 1.0, 1.0, 1.0);  // White dot at the hit point
        //let index = voxel.x + voxel.y * GRID_SIZE + voxel.z * GRID_SIZE * GRID_SIZE;
        //return vec4<f32>(voxels[index].color, 1.0);
    //} else {
        // No hit, color it sky blue
        return vec4<f32>(0.5, 0.7, 1.0, 1.0);
    //}
}
