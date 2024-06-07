const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raymath");

const MAX_BALLS = 50;

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
        // if (rl.isKeyDown(rl.KeyboardKey.key_right)) {
        //     player.x += 10;
        // } else if (rl.isKeyDown(rl.KeyboardKey.key_left)) {
        //     player.x -= 10;
        // }

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

        rl.clearBackground(rl.Color.ray_white);

        {
            camera.begin();
            defer camera.end();

            rl.drawRectangle(-6000, 320, 13000, 8000, rl.Color.dark_gray);

            for (balls, 0..) |ball, i| {
                rl.drawCircleV(ball, 60, ballColors[i]);
            }

            // rl.drawRectangleRec(player, rl.Color.red);

            // rl.drawLine(
            //     @as(i32, @intFromFloat(camera.target.x)),
            //     -screenHeight * 10,
            //     @as(i32, @intFromFloat(camera.target.x)),
            //     screenHeight * 10,
            //     rl.Color.green,
            // );
            // rl.drawLine(
            //     -screenWidth * 10,
            //     @as(i32, @intFromFloat(camera.target.y)),
            //     screenWidth * 10,
            //     @as(i32, @intFromFloat(camera.target.y)),
            //     rl.Color.green,
            // );
        }

        // rl.drawText("SCREEN AREA", 640, 10, 20, rl.Color.red);
        //
        // rl.drawRectangle(0, 0, screenWidth, 5, rl.Color.red);
        // rl.drawRectangle(0, 5, 5, screenHeight - 10, rl.Color.red);
        // rl.drawRectangle(screenWidth - 5, 5, 5, screenHeight - 10, rl.Color.red);
        // rl.drawRectangle(0, screenHeight - 5, screenWidth, 5, rl.Color.red);
        //
        // rl.drawRectangle(10, 10, 250, 113, rl.Color.sky_blue.fade(0.5));
        // rl.drawRectangleLines(10, 10, 250, 113, rl.Color.blue);
        //
        // rl.drawText("Free 2D camera controls:", 20, 20, 10, rl.Color.black);
        // rl.drawText("- Right/Left to move Offset", 40, 40, 10, rl.Color.dark_gray);
        // rl.drawText("- Mouse Wheel to Zoom in-out", 40, 60, 10, rl.Color.dark_gray);
        // rl.drawText("- A/S to Rotate", 40, 80, 10, rl.Color.dark_gray);
        // rl.drawText("- R to reset Zoom and Rotation", 40, 100, 10, rl.Color.dark_gray);
    }
}
