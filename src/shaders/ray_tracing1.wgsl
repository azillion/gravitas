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
    // Define camera parameters
    let aspect_ratio = uniforms.aspect_ratio;
    let viewport_height = 2.0;
    let viewport_width = aspect_ratio * viewport_height;
    let focal_length = 1.0;

    // Calculate viewport vectors
    let viewport_u = vec3<f32>(viewport_width, 0.0, 0.0);
    let viewport_v = vec3<f32>(0.0, -viewport_height, 0.0);

    // Calculate upper left pixel location
    let viewport_upper_left = uniforms.camera_pos 
                            - vec3<f32>(0.0, 0.0, focal_length) 
                            - viewport_u * 0.5 
                            - viewport_v * 0.5;

    // Calculate pixel center
    let pixel_center = viewport_upper_left 
                     + uv.x * viewport_u
                     + (1.0 - uv.y) * viewport_v;

    // Calculate ray direction
    let ray_dir = normalize(pixel_center - uniforms.camera_pos);

    return ray_color(uniforms.camera_pos, ray_dir);
}
