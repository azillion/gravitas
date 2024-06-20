const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raymath");

const MAX_BALLS = 69;

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "Gravitas");
    defer rl.closeWindow();

    var balls: [MAX_BALLS]rl.Vector2 = undefined;
    var ballColors: [MAX_BALLS]rl.Color = undefined;

    for (0..balls.len) |i| {
        balls[i].y = @floatFromInt(rl.getRandomValue(0, screenHeight));
        balls[i].x = @floatFromInt(rl.getRandomValue(0, screenWidth));

        ballColors[i] = rl.Color.init(
            @as(u8, @intCast(rl.getRandomValue(200, 240))),
            @as(u8, @intCast(rl.getRandomValue(200, 240))),
            @as(u8, @intCast(rl.getRandomValue(200, 250))),
            255,
        );
    }

    var camera = rl.Camera2D{
        .target = rl.Vector2.init(0.0, 0.0),
        .offset = rl.Vector2.init(screenWidth / 2, screenHeight / 2),
        .rotation = 0.0,
        .zoom = 1.0,
    };

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        camera.target = rl.Vector2.init(0.0, 0.0);

        if (rl.isKeyDown(rl.KeyboardKey.key_a)) {
            camera.rotation -= 1;
        } else if (rl.isKeyDown(rl.KeyboardKey.key_s)) {
            camera.rotation += 1;
        }

        camera.rotation = rlm.clamp(camera.rotation, -40, 40);

        camera.zoom += rl.getMouseWheelMove() * 0.05;

        camera.zoom = rlm.clamp(camera.zoom, 0.1, 3.0);

        if (rl.isKeyPressed(rl.KeyboardKey.key_r)) {
            camera.zoom = 1.0;
            camera.rotation = 0.0;
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        {
            camera.begin();
            defer camera.end();

            rl.drawRectangle(-6000, 320, 13000, 8000, rl.Color.dark_gray);

            for (balls, 0..) |ball, i| {
                rl.drawCircleV(ball, 60, ballColors[i]);
            }
        }
    }
}
