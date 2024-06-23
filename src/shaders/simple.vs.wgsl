struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) color: vec3<f32>,
    @location(2) normal: vec3<f32>,
};

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
    @location(1) world_position: vec3<f32>,
    @location(2) world_normal: vec3<f32>,
};

@group(0) @binding(0) var<uniform> mvp: mat4x4<f32>;
@group(0) @binding(1) var<uniform> model: mat4x4<f32>;

@vertex
fn vs_main(input: VertexInput) -> VertexOutput {
    var output: VertexOutput;
    output.position = mvp * vec4<f32>(input.position, 1.0);
    output.world_position = (model * vec4<f32>(input.position, 1.0)).xyz;
    output.world_normal = normalize((model * vec4<f32>(input.normal, 0.0)).xyz);
    output.color = input.color;
    return output;
}
