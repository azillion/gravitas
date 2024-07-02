fn inverse_mat4(m: mat4x4<f32>) -> mat4x4<f32> {
    let c00 = m[2][2] * m[3][3] - m[3][2] * m[2][3];
    let c02 = m[1][2] * m[3][3] - m[3][2] * m[1][3];
    let c03 = m[1][2] * m[2][3] - m[2][2] * m[1][3];

    let c04 = m[2][1] * m[3][3] - m[3][1] * m[2][3];
    let c06 = m[1][1] * m[3][3] - m[3][1] * m[1][3];
    let c07 = m[1][1] * m[2][3] - m[2][1] * m[1][3];

    let c08 = m[2][1] * m[3][2] - m[3][1] * m[2][2];
    let c10 = m[1][1] * m[3][2] - m[3][1] * m[1][2];
    let c11 = m[1][1] * m[2][2] - m[2][1] * m[1][2];

    let c12 = m[2][0] * m[3][3] - m[3][0] * m[2][3];
    let c14 = m[1][0] * m[3][3] - m[3][0] * m[1][3];
    let c15 = m[1][0] * m[2][3] - m[2][0] * m[1][3];

    let c16 = m[2][0] * m[3][2] - m[3][0] * m[2][2];
    let c18 = m[1][0] * m[3][2] - m[3][0] * m[1][2];
    let c19 = m[1][0] * m[2][2] - m[2][0] * m[1][2];

    let c20 = m[2][0] * m[3][1] - m[3][0] * m[2][1];
    let c22 = m[1][0] * m[3][1] - m[3][0] * m[1][1];
    let c23 = m[1][0] * m[2][1] - m[2][0] * m[1][1];

    let f0 = vec4<f32>(c00, c00, c02, c03);
    let f1 = vec4<f32>(c04, c04, c06, c07);
    let f2 = vec4<f32>(c08, c08, c10, c11);
    let f3 = vec4<f32>(c12, c12, c14, c15);
    let f4 = vec4<f32>(c16, c16, c18, c19);
    let f5 = vec4<f32>(c20, c20, c22, c23);

    let v0 = vec4<f32>(m[1][0], m[0][0], m[0][0], m[0][0]);
    let v1 = vec4<f32>(m[1][1], m[0][1], m[0][1], m[0][1]);
    let v2 = vec4<f32>(m[1][2], m[0][2], m[0][2], m[0][2]);
    let v3 = vec4<f32>(m[1][3], m[0][3], m[0][3], m[0][3]);

    let inv0 = vec4<f32>(v1 * f0 - v2 * f1 + v3 * f2);
    let inv1 = vec4<f32>(v0 * f0 - v2 * f3 + v3 * f4);
    let inv2 = vec4<f32>(v0 * f1 - v1 * f3 + v3 * f5);
    let inv3 = vec4<f32>(v0 * f2 - v1 * f4 + v2 * f5);

    let sign_a = vec4<f32>(1.0, -1.0, 1.0, -1.0);
    let sign_b = vec4<f32>(-1.0, 1.0, -1.0, 1.0);

    let inverse = mat4x4<f32>(inv0 * sign_a, inv1 * sign_b, inv2 * sign_a, inv3 * sign_b);

    let col0 = vec4<f32>(inverse[0][0], inverse[1][0], inverse[2][0], inverse[3][0]);
    let col1 = vec4<f32>(inverse[0][1], inverse[1][1], inverse[2][1], inverse[3][1]);
    let col2 = vec4<f32>(inverse[0][2], inverse[1][2], inverse[2][2], inverse[3][2]);
    let col3 = vec4<f32>(inverse[0][3], inverse[1][3], inverse[2][3], inverse[3][3]);

    let det = dot(m[0], vec4<f32>(col0.x, col1.x, col2.x, col3.x));
    return inverse * (1.0 / det);
}
