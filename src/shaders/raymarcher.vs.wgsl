struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) ray_origin: vec3<f32>,
    @location(1) ray_direction: vec3<f32>,
};

@group(0) @binding(0) var<uniform> world_to_clip: mat4x4<f32>;
@group(0) @binding(1) var<uniform> inverse_projection: mat4x4<f32>;
@group(0) @binding(2) var<uniform> clip_to_world: mat4x4<f32>;

@vertex
fn vs_main(@builtin(vertex_index) vert_idx: u32) -> VertexOutput {
    var out: VertexOutput;
    
    // Generate full-screen triangle
    let x = f32(i32(vert_idx) - 1);
    let y = f32(i32(vert_idx & 1u) * 2 - 1);
    out.position = vec4<f32>(x, y, 0.0, 1.0);
    
    // Calculate ray origin and direction
    let clip_space = vec4<f32>(x, y, 1.0, 1.0);
    let view_space = inverse_projection * clip_space;
    let world_space = clip_to_world * vec4<f32>(view_space.xyz / view_space.w, 1.0);
    
    out.ray_origin = clip_to_world[3].xyz;
    out.ray_direction = normalize(world_space.xyz - out.ray_origin);
    
    return out;
}
