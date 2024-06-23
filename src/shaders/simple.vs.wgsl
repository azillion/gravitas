struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
};

@group(0) @binding(0) var<uniform> mvp: mat4x4<f32>;

@vertex
fn vs_main(@location(0) position: vec3<f32>, @location(1) color: vec3<f32>) -> VertexOutput {
    var output: VertexOutput;
    output.position = mvp * vec4<f32>(position, 1.0);
    output.color = color;
    return output;
}
