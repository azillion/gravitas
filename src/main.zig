const std = @import("std");
const math = std.math;
const zglfw = @import("zglfw");
const zgui = @import("zgui");
const zmath = @import("zmath");
const zvk = @import("vulkan");

const content_dir = "assets/";
const shaders_dir = "src/shaders/";
const window_title = "Gravitas Engine";
const default_window_width = 800;
const default_window_height = 600;
const shader_hot_reload_interval = 1.0;

// need to switch to c glfw, not the zig bindings

pub fn main() !void {
    try zglfw.init();
    defer zglfw.terminate();

    var current_dir: []u8 = undefined;
    var executable_path: []const u8 = undefined;

    // get the current working directory and executable path
    {
        var buffer: [1024]u8 = undefined;
        current_dir = try std.fs.cwd().realpath(".", buffer[0..]);
        executable_path = try std.fs.selfExeDirPath(buffer[0..]);
    }

    zglfw.windowHintTyped(.client_api, .no_api);

    const aspect_ratio = 16.0 / 9.0;
    const height = @as(i32, @intFromFloat(@divFloor(default_window_width, aspect_ratio)));

    const extent: zvk.Extent2D = .{ .width = default_window_width, .height = height };

    const window = try zglfw.Window.create(@intCast(extent.width), @intCast(extent.height), window_title, null);
    defer window.destroy();
    window.setSizeLimits(400, 400, -1, -1);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // var extensionCount: u32 = 0;
    // var extensions: []const u8 = null;
    // try zglfw.getRequiredInstanceExtensions(&extensionCount, &extensions);
    // std.debug.print("Extension count: {}\n", extensionCount);

    // const allocator = gpa.allocator();
    //
    // const scale_factor = scale_factor: {
    //     const scale = window.getContentScale();
    //     break :scale_factor @max(scale[0], scale[1]);
    // };

    ////////////// gui initialization
    // zgui.init(allocator);
    // defer zgui.deinit();
    //
    // try std.posix.chdir(executable_path);
    // _ = zgui.io.addFontFromFile(content_dir ++ "Roboto-Medium.ttf", math.floor(16.0 * scale_factor));
    //
    // // Change current working directory back to the project root.
    // try std.posix.chdir(current_dir);
    //
    // zgui.backend.init(
    //     window,
    //     state.gctx.device,
    //     @intFromEnum(zgpu.GraphicsContext.swapchain_format),
    //     @intFromEnum(wgpu.TextureFormat.undef),
    // );
    // defer zgui.backend.deinit();
    // zgui.getStyle().scaleAllSizes(scale_factor);
    //////////////////////////

    // window.setUserPointer(&state);
    // _ = window.setCursorPosCallback(mouseCallback);
    // _ = window.setFramebufferSizeCallback(frameBufferResizeCallback);
    window.setInputMode(.cursor, .disabled);

    var last_time: f64 = zglfw.getTime();

    while (!window.shouldClose() and window.getKey(.escape) != .press) {
        const current_time = zglfw.getTime();
        const delta_time: f32 = @floatCast(current_time - last_time);
        _ = delta_time;
        last_time = current_time;

        zglfw.pollEvents();
    }
}
