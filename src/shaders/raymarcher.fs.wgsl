struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) ray_origin: vec3<f32>,
    @location(1) ray_direction: vec3<f32>,
};

@group(0) @binding(4) var<storage, read> voxel_data: array<u32>;

fn get_voxel(pos: vec3<i32>) -> u32 {
    let index = pos.x + pos.y * 256 + pos.z * 256 * 256;
    return voxel_data[index];
}
fn ray_march(origin: vec3<f32>, direction: vec3<f32>) -> vec4<f32> {
    var pos = origin;
    
    for (var i = 0; i < 256; i++) {
        let voxel_pos = floor(pos);
        let voxel = get_voxel(vec3<i32>(voxel_pos));
        
        if (voxel != 0u) {
            // Hit a voxel, return debug color
            return vec4<f32>(voxel_pos / 256.0, 1.0);
        }
        
        pos += direction;
    }
    
    // No hit, return sky color
    return vec4<f32>(0.6, 0.8, 1.0, 1.0);
}
fn ray_march_2(origin: vec3<f32>, direction: vec3<f32>) -> vec4<f32> {
    var pos = floor(origin);
    let step = sign(direction);
    let tDelta = abs(1.0 / direction);
    var tMax = (step * (1.0 - fract(origin)) + 1.0) * tDelta;
    
    for (var i = 0; i < 256; i++) {
        let voxel = get_voxel(vec3<i32>(pos));
        if (voxel != 0u) {
            // Hit a voxel, return color based on normal
            // Debug: Return voxel value as color
            return vec4<f32>(f32(voxel) / 255.0, 0.0, 0.0, 1.0);
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
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    return vec4<f32>(normalize(in.ray_direction) * 0.5 + 0.5, 1.0);
    return ray_march(in.ray_origin, in.ray_direction);
}
@fragment
fn fs_main_debug(in: VertexOutput) -> @location(0) vec4<f32> {
    let normalized_origin = (in.ray_origin - vec3<f32>(0.0, 0.0, -128.0)) / 256.0;
    let normalized_direction = normalize(in.ray_direction) * 0.5 + 0.5;
    //return vec4<f32>(normalized_origin, 1.0);
    // Uncomment the next line and comment the above to see ray direction
    return vec4<f32>(normalized_direction, 1.0);
}
