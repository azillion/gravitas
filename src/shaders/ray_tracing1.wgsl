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

fn hit_sphere(center: vec3<f32>, radius: f32, ray_origin: vec3<f32>, ray_dir: vec3<f32>) -> f32 {
    let oc = ray_origin - center;
    let a = dot(ray_dir, ray_dir);
    let b = -2.0 * dot(ray_dir, oc);
    let c = dot(oc, oc) - radius * radius;
    let discriminant = b * b - 4.0 * a * c;

    if (discriminant < 0.0) {
        return -1.0;
    } else {
        return (-b - sqrt(discriminant)) / (2.0 * a);
    }
}

fn ray_color(ray_origin: vec3<f32>, ray_dir: vec3<f32>) -> vec4<f32> {
    let t = hit_sphere(vec3<f32>(0.0, 0.0, -1.0), 0.5, ray_origin, ray_dir);
    if (t > 0.0) {
        let N = normalize(ray_origin + t * ray_dir - vec3<f32>(0.0, 0.0, -1.0));
        return vec4(0.5 * vec3(1.0 + N.x, 1.0 + N.y, 1.0 + N.z), 1.0);
    }
    let a = 0.5*(ray_dir.y + 1.0);
    return vec4((1.0-a) * vec3(1.0, 1.0, 1.0) + a * vec3(0.5, 0.7, 1.0), 1.0);
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

    return ray_color(ray_origin, ray_dir);
}
