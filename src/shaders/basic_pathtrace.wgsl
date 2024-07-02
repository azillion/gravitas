//!include src/shaders/inverse.wgsl

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
@group(0) @binding(1) var<storage, read> voxels: array<Voxel>;

const EPSILON: f32 = 0.001;
const VOXEL_SIZE: f32 = 1.0;

fn ray_voxel_intersection(ray_origin: vec3<f32>, ray_dir: vec3<f32>) -> bool {
    let voxel_pos = vec3<f32>(0.0, 0.0, 0.0);  // Center of our single voxel
    let voxel_min = voxel_pos - vec3<f32>(VOXEL_SIZE * 0.5);
    let voxel_max = voxel_pos + vec3<f32>(VOXEL_SIZE * 0.5);

    let t1 = (voxel_min - ray_origin) / ray_dir;
    let t2 = (voxel_max - ray_origin) / ray_dir;

    let tmin = min(t1, t2);
    let tmax = max(t1, t2);

    let tenter = max(max(tmin.x, tmin.y), tmin.z);
    let texit = min(min(tmax.x, tmax.y), tmax.z);

    return tenter < texit && texit > 0.0;
}

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

    if (ray_voxel_intersection(ray_origin, ray_dir)) {
        // Voxel hit, color it red
        return vec4<f32>(1.0, 1.0, 1.0, 1.0);
    } else {
        // No hit, color it sky blue
        return vec4<f32>(0.5, 0.7, 1.0, 1.0);
    }
}
