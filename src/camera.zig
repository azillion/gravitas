const std = @import("std");
const zglfw = @import("zglfw");
const zmath = @import("zmath");
const math = @import("std").math;
const State = @import("state.zig").State;

// TODO: rework this entirely
// We just need a simple camera for now, we can add controls later

const DEFAULT_CAMERA_POSITION = zmath.f32x4(0.0, 0.0, 0.0, 1.0);

pub fn getDefaultCameraPosition() zmath.F32x4 {
    return DEFAULT_CAMERA_POSITION;
}

pub const Camera = struct {
    position: zmath.F32x4,
    front: zmath.F32x4,
    up: zmath.F32x4,
    right: zmath.F32x4,
    world_up: zmath.F32x4,
    yaw: f32,
    pitch: f32,
    movement_speed: f32,
    mouse_sensitivity: f32,
    zoom: f32,

    pub fn init(position: zmath.F32x4, up: zmath.F32x4, yaw: f32, pitch: f32) Camera {
        var camera = Camera{
            .position = position,
            .world_up = up,
            .yaw = yaw,
            .pitch = pitch,
            .front = zmath.f32x4(0.0, 0.0, -1.0, 0.0),
            .movement_speed = 2.5,
            .mouse_sensitivity = 0.1,
            .zoom = 100.0,
            .up = undefined,
            .right = undefined,
        };
        camera.updateCameraVectors();
        return camera;
    }

    pub fn getViewMatrix(self: *const Camera) zmath.Mat {
        return zmath.lookAtRh(self.position, self.position + self.front, self.up);
    }

    pub fn getProjectionMatrix(self: *const Camera, aspect_ratio: f32) zmath.Mat {
        return zmath.perspectiveFovRh(math.degreesToRadians(self.zoom), aspect_ratio, 0.1, 100.0);
    }

    pub fn processKeyboard(self: *Camera, direction: enum { Forward, Backward, Left, Right }, delta_time: f32) void {
        const velocity = self.movement_speed * delta_time;
        switch (direction) {
            .Forward => self.position += self.front * zmath.f32x4s(velocity),
            .Backward => self.position -= self.front * zmath.f32x4s(velocity),
            .Left => self.position -= self.right * zmath.f32x4s(velocity),
            .Right => self.position += self.right * zmath.f32x4s(velocity),
        }
    }

    pub fn processMouseMovement(self: *Camera, xoffset: f32, yoffset: f32, constrain_pitch: bool) void {
        self.yaw += xoffset * self.mouse_sensitivity;
        self.pitch -= yoffset * self.mouse_sensitivity; // Invert y-axis

        if (constrain_pitch) {
            self.pitch = std.math.clamp(self.pitch, -89.0, 89.0);
        }

        self.updateCameraVectors();
    }

    pub fn processMouseScroll(self: *Camera, yoffset: f32) void {
        self.zoom -= yoffset;
        if (self.zoom < 1.0) {
            self.zoom = 1.0;
        }
        if (self.zoom > 45.0) {
            self.zoom = 45.0;
        }
    }

    fn updateCameraVectors(self: *Camera) void {
        // Calculate the new Front vector
        const x = math.cos(math.degreesToRadians(self.yaw)) * math.cos(math.degreesToRadians(self.pitch));
        const y = math.sin(math.degreesToRadians(self.pitch));
        const z = math.sin(math.degreesToRadians(self.yaw)) * math.cos(math.degreesToRadians(self.pitch));
        self.front = zmath.normalize3(zmath.f32x4(x, y, z, 0.0));
        // Re-calculate the Right and Up vector
        self.right = zmath.normalize3(zmath.cross3(self.front, self.world_up));
        self.up = zmath.normalize3(zmath.cross3(self.right, self.front));
    }

    pub fn update(self: *Camera, window: *zglfw.Window, delta_time: f32) void {
        const velocity = self.movement_speed * delta_time;

        if (window.getKey(.w) == .press) {
            self.processKeyboard(.Forward, delta_time);
        }
        if (window.getKey(.s) == .press) {
            self.processKeyboard(.Backward, delta_time);
        }
        if (window.getKey(.a) == .press) {
            self.processKeyboard(.Left, delta_time);
        }
        if (window.getKey(.d) == .press) {
            self.processKeyboard(.Right, delta_time);
        }
        if (window.getKey(.r) == .press) {
            // Reset camera position
            self.position = getDefaultCameraPosition();
            self.yaw = 0.0;
            self.pitch = 0.0;
        }

        // You can add vertical movement if desired
        if (window.getKey(.space) == .press) {
            self.position += self.up * zmath.f32x4s(velocity);
        }
        if (window.getKey(.left_shift) == .press) {
            self.position -= self.up * zmath.f32x4s(velocity);
        }

        // The camera vectors (front, right, up) are already updated in processKeyboard,
        // so we don't need to update them here again.
    }
};
