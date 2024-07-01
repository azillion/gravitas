struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) uv: vec2<f32>,
}

struct CameraUniform {
    position: vec3<f32>,
    forward: vec3<f32>,
    up: vec3<f32>,
    right: vec3<f32>,
    fov: f32,
}

@group(0) @binding(0) var<uniform> camera: CameraUniform;
@group(0) @binding(1) var voxel_texture: texture_3d<u32>;

fn ray_march_1(ray_origin: vec3<f32>, ray_direction: vec3<f32>) -> vec4<f32> {
    var t = 0.0;
    let max_distance = 100.0;
    let step = 0.1;

    for (var i = 0; i < 1000; i++) {
        let position = ray_origin + t * ray_direction;
        
        // Scale position to fit within our 32x32x32 texture
        let scaled_position = position * 32.0;
        
        // Check if we're outside the voxel volume
        if (any(scaled_position < vec3<f32>(0.0)) || any(scaled_position >= vec3<f32>(32.0))) {
            break;
        }

        let voxel = textureLoad(voxel_texture, vec3<i32>(scaled_position), 0);
        
        if (voxel.r > 0u) {
            // Hit a voxel
            let normal = -normalize(ray_direction);
            let light_dir = normalize(vec3<f32>(1.0, 1.0, 1.0));
            let diffuse = max(dot(normal, light_dir), 0.0);
            let color = vec3<f32>(f32(voxel.r) / 255.0, 0.0, 0.0); // Red color based on voxel value
            return vec4<f32>(color * diffuse, 1.0);
        }

        t += step;
        if (t > max_distance) {
            break;
        }
    }

    // No hit, return background color
    return vec4<f32>(0.1, 0.2, 0.3, 1.0);
}

fn ray_march(ray_origin: vec3<f32>, ray_direction: vec3<f32>) -> vec4<f32> {
    var t = 0.0;
    let max_distance = 100.0;
    let step = 0.1;

    for (var i = 0; i < 1000; i++) {
        let position = ray_origin + t * ray_direction;
        
        // Scale position to fit within our 32x32x32 texture
        let scaled_position = position * 32.0;
        
        // Visualize the sampling position
        if (all(scaled_position >= vec3<f32>(0.0)) && all(scaled_position < vec3<f32>(32.0))) {
            return vec4<f32>(scaled_position / 32.0, 1.0);
        }

        t += step;
        if (t > max_distance) {
            break;
        }
    }

    // No hit, return background color
    return vec4<f32>(0.1, 0.2, 0.3, 1.0);
}

@fragment
fn fs_main_test(in: VertexOutput) -> @location(0) vec4<f32> {
    let aspect_ratio = 1600.0 / 1000.0; // Adjust based on your window size
    let fov_factor = tan(camera.fov * 0.5);
    
    let ray_direction = normalize(
        camera.forward +
        (in.uv.x * 2.0 - 1.0) * camera.right * fov_factor * aspect_ratio +
        (1.0 - in.uv.y * 2.0) * camera.up * fov_factor
    );

    // Visualize ray direction
    return vec4<f32>((ray_direction + 1.0) * 0.5, 1.0);
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    //let aspect_ratio = 1600.0 / 1000.0; // Adjust based on your window size
    //let fov_factor = tan(camera.fov * 0.5);
    //
    //let ray_direction = normalize(
    //    camera.forward +
    //    (in.uv.x * 2.0 - 1.0) * camera.right * fov_factor * aspect_ratio +
    //    (1.0 - in.uv.y * 2.0) * camera.up * fov_factor
    //);

    // let color = ray_march(camera.position, ray_direction);
    let color = vec4<f32>(0.0, 0.0, 0.0, 1.0);

    var output: FragmentOutput;
    output.color = color;
    return output;
}
