const zglfw = @import("zglfw");
const zmath = @import("zmath");
const State = @import("state.zig").State;

pub const Camera = struct {
    position: zmath.F32x4,
    front: zmath.F32x4,
    up: zmath.F32x4,
    right: zmath.F32x4,
    yaw: f32,
    pitch: f32,

    pub fn update(self: *Camera, window: *zglfw.Window, delta_time: f32) void {
        const speed = zmath.f32x4s(10.0);
        const delta_time_vec = zmath.f32x4s(delta_time); // Convert delta_time to a vector
        const transform = zmath.mul(zmath.rotationX(self.pitch), zmath.rotationY(self.yaw));
        var forward = zmath.normalize3(zmath.mul(zmath.f32x4(0.0, 0.0, 1.0, 0.0), transform));

        // Direct component-wise multiplication
        const right = zmath.normalize3(zmath.cross3(zmath.f32x4(0.0, 1.0, 0.0, 0.0), forward)) * speed * delta_time_vec;
        forward *= speed * delta_time_vec; // Simplified multiplication

        var cam_pos = zmath.loadArr4(self.position);

        if (window.getKey(.w) == .press) {
            cam_pos += forward;
        } else if (window.getKey(.s) == .press) {
            cam_pos -= forward;
        }
        if (window.getKey(.d) == .press) {
            cam_pos += right;
        } else if (window.getKey(.a) == .press) {
            cam_pos -= right;
        }

        zmath.storeArr4(&self.position, cam_pos);
    }
};
