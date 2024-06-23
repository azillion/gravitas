struct FragmentInput {
    @location(0) color: vec3<f32>,
    @location(1) world_position: vec3<f32>,
    @location(2) world_normal: vec3<f32>,
};

@fragment
fn fs_main(input: FragmentInput) -> @location(0) vec4<f32> {
    let light_direction = normalize(vec3<f32>(1.0, 1.0, 1.0));
    let light_color = vec3<f32>(1.0, 1.0, 1.0);
    
    let ambient_strength = 0.1;
    let ambient = ambient_strength * light_color;
    
    let diff = max(dot(input.world_normal, light_direction), 0.0);
    let diffuse = diff * light_color;
    
    let result = (ambient + diffuse) * input.color;
    return vec4<f32>(result, 1.0);
}
