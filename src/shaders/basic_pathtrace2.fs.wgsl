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

const VOXEL_SIZE: f32 = 1.0;
const GRID_SIZE: i32 = 32;
const MAX_STEPS: u32 = 100;
const MAX_DISTANCE: f32 = 100.0;
const EPSILON: f32 = 0.001;
const MAX_BOUNCES: u32 = 5;

fn ray_voxel_intersection(ray_origin: vec3<f32>, ray_dir: vec3<f32>) -> vec3<i32> {
    let t_delta = abs(vec3<f32>(VOXEL_SIZE) / ray_dir);
    var voxel = vec3<i32>(floor(ray_origin / VOXEL_SIZE));
    let step = vec3<i32>(sign(ray_dir));
    var t_max = (vec3<f32>(voxel + max(step, vec3<i32>(0))) * VOXEL_SIZE - ray_origin) / ray_dir;

    for (var i: u32 = 0u; i < MAX_STEPS; i++) {
        if (any(voxel < vec3<i32>(0)) || any(voxel >= vec3<i32>(GRID_SIZE))) {
            break;
        }

        let index = voxel.x + voxel.y * GRID_SIZE + voxel.z * GRID_SIZE * GRID_SIZE;
        if (voxels[index].is_solid != 0u) {
            return voxel;
        }

        if (t_max.x < t_max.y) {
            if (t_max.x < t_max.z) {
                voxel.x += step.x;
                t_max.x += t_delta.x;
            } else {
                voxel.z += step.z;
                t_max.z += t_delta.z;
            }
        } else {
            if (t_max.y < t_max.z) {
                voxel.y += step.y;
                t_max.y += t_delta.y;
            } else {
                voxel.z += step.z;
                t_max.z += t_delta.z;
            }
        }
    }

    return vec3<i32>(-1);
}

fn get_random(seed: ptr<function, u32>) -> f32 {
    *seed = *seed * 747796405u + 2891336453u;
    let result = (((*seed >> (((*seed >> 28u) + 4u) & 15u)) ^ *seed) * 277803737u) >> 22u;
    return f32(result) / 4294967295.0;
}

fn trace_path(ray_origin: vec3<f32>, ray_dir: vec3<f32>, seed: ptr<function, u32>) -> vec3<f32> {
    var result = vec3<f32>(0.0);
    var throughput = vec3<f32>(1.0);
    var bounce_ray_origin = ray_origin;
    var bounce_ray_dir = ray_dir;

    for (var bounce: u32 = 0u; bounce < MAX_BOUNCES; bounce++) {
        let hit_voxel = ray_voxel_intersection(bounce_ray_origin, bounce_ray_dir);
        if (any(hit_voxel < vec3<i32>(0))) {
            // Sky color
            result += throughput * vec3<f32>(0.5, 0.7, 1.0);
            break;
        }

        let voxel_index = hit_voxel.x + hit_voxel.y * GRID_SIZE + hit_voxel.z * GRID_SIZE * GRID_SIZE;
        let voxel = voxels[voxel_index];

        // Add emission
        result += throughput * voxel.emission;

        // Calculate new ray direction (simple diffuse reflection)
        let phi = 2.0 * 3.14159265 * get_random(seed);
        let cos_theta = sqrt(get_random(seed));
        let sin_theta = sqrt(1.0 - cos_theta * cos_theta);
        let x = cos(phi) * sin_theta;
        let y = sin(phi) * sin_theta;
        let z = cos_theta;

        // Assuming the normal is always pointing up for simplicity
        let normal = vec3<f32>(0.0, 1.0, 0.0);
        let tangent = normalize(cross(normal, vec3<f32>(1.0, 0.0, 0.0)));
        let bitangent = cross(normal, tangent);

        bounce_ray_dir = normalize(tangent * x + bitangent * y + normal * z);
        bounce_ray_origin = vec3<f32>(hit_voxel) * VOXEL_SIZE + bounce_ray_dir * EPSILON;

        // Update throughput
        throughput *= voxel.color;

        // Russian Roulette
        if (bounce > 2u) {
            let p = max(throughput.r, max(throughput.g, throughput.b));
            if (get_random(seed) > p) {
                break;
            }
            throughput /= p;
        }
    }

    return result;
}

//!include src/shaders/math.wgsl

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

    var seed = u32(uv.x * 1000.0 + uv.y * 1000.0 + uniforms.time * 1000.0);
    let color = trace_path(ray_origin, ray_dir, &seed);

    return vec4<f32>(color, 1.0);
    if (length(ray_origin - vec3<f32>(16.0, 0.0, 16.0)) < 1.0) {
        return vec4<f32>(1.0, 1.0, 1.0, 1.0);  // White dot at the center of the grid
    }
    let hit_voxel = ray_voxel_intersection(ray_origin, ray_dir);
    if (any(hit_voxel < vec3<i32>(0))) {
        //return vec4<f32>(0.5, 0.7, 1.0, 1.0);  // Sky color
        return vec4<f32>(0.0, 0.0, 0.0, 1.0);  // Black
    } else {
        return vec4<f32>(1.0, 0.0, 0.0, 1.0);  // Hit color (red)
    }
}
