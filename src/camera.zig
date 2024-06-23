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
    last_x: f32,
    last_y: f32,
    sensitivity: f32,
    first_mouse: bool,

    pub fn init() Camera {
        return .{
            .position = zmath.f32x4(3.0, 3.0, 3.0, 1.0),
            .front = zmath.normalize3(zmath.f32x4(-3.0, -3.0, -3.0, 0.0)),
            .up = zmath.f32x4(0.0, 1.0, 0.0, 0.0),
            .right = zmath.normalize3(zmath.cross3(zmath.f32x4(-3.0, -3.0, -3.0, 0.0), zmath.f32x4(0.0, 1.0, 0.0, 0.0))),
            .yaw = -135.0,
            .pitch = -30.0,
            .last_x = 0,
            .last_y = 0,
            .sensitivity = 0.01,
            .first_mouse = true,
        };
    }

    pub fn update(self: *Camera, window: *zglfw.Window, delta_time: f32) void {
        const speed = zmath.f32x4s(10.0);
        const delta_time_vec = zmath.f32x4s(delta_time);
        const transform = zmath.mul(zmath.rotationX(self.pitch), zmath.rotationY(self.yaw));

        // Forward vector (for W/S movement)
        const forward = zmath.normalize3(zmath.mul(zmath.f32x4(0.0, 0.0, -1.0, 0.0), transform));

        // Right vector (for A/D movement)
        const right = zmath.normalize3(zmath.cross3(forward, zmath.f32x4(0.0, 1.0, 0.0, 0.0)));

        // Up vector (for Space/Left Shift movement)
        const up = zmath.f32x4(0.0, 1.0, 0.0, 0.0);

        // Scale movement vectors
        const scaled_forward = forward * speed * delta_time_vec;
        const scaled_right = right * speed * delta_time_vec;
        const scaled_up = up * speed * delta_time_vec;

        var cam_pos = zmath.loadArr4(self.position);

        if (window.getKey(.w) == .press) {
            cam_pos += scaled_forward;
        } else if (window.getKey(.s) == .press) {
            cam_pos -= scaled_forward;
        }

        if (window.getKey(.d) == .press) {
            cam_pos += scaled_right;
        } else if (window.getKey(.a) == .press) {
            cam_pos -= scaled_right;
        }

        if (window.getKey(.space) == .press) {
            cam_pos += scaled_up;
        } else if (window.getKey(.left_shift) == .press) {
            cam_pos -= scaled_up;
        }

        zmath.storeArr4(&self.position, cam_pos);

        // Update front vector
        self.front = zmath.normalize3(forward);
        // Update right vector
        self.right = zmath.normalize3(right);
    }
};
