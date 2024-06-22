struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) ray_origin: vec3<f32>,
    @location(1) ray_direction: vec3<f32>,
};

struct FragmentOutput {
    @location(0) color: vec4<f32>,
};

@group(0) @binding(3) var<storage, read> voxel_data: array<u32>;

fn get_voxel(pos: vec3<i32>) -> u32 {
    // Implement octree traversal here
    // For now, we'll use a simple 3D texture lookup
    let index = pos.x + pos.y * 256 + pos.z * 256 * 256;
    return voxel_data[index];
}

fn ray_march(origin: vec3<f32>, direction: vec3<f32>) -> vec4<f32> {
    var pos = floor(origin);
    let step = sign(direction);
    let tDelta = abs(1.0 / direction);
    var tMax = (step * (1.0 - fract(origin)) + 1.0) * tDelta;
    
    for (var i = 0; i < 256; i++) {
        let voxel = get_voxel(vec3<i32>(pos));
        if (voxel != 0u) {
            // Hit a voxel, return color based on normal
            let normal = -step * vec3<f32>(
                f32(tMax.x <= min(tMax.y, tMax.z)),
                f32(tMax.y <= min(tMax.x, tMax.z)),
                f32(tMax.z <= min(tMax.x, tMax.y))
            );
            return vec4<f32>(normal * 0.5 + 0.5, 1.0);
        }
        
        if (tMax.x < tMax.y) {
            if (tMax.x < tMax.z) {
                pos.x += step.x;
                tMax.x += tDelta.x;
            } else {
                pos.z += step.z;
                tMax.z += tDelta.z;
            }
        } else if (tMax.y < tMax.z) {
            pos.y += step.y;
            tMax.y += tDelta.y;
        } else {
            pos.z += step.z;
            tMax.z += tDelta.z;
        }
    }
    
    // No hit, return sky color
    return vec4<f32>(0.6, 0.8, 1.0, 1.0);
}

@fragment
fn fs_main(in: VertexOutput) -> FragmentOutput {
    var out: FragmentOutput;
    out.color = ray_march(in.ray_origin, in.ray_direction);
    return out;
}
