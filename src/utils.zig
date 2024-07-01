const std = @import("std");

pub fn readWgslWithIncludes(allocator: std.mem.Allocator, filepath: []const u8) ![]const u8 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var result = std.ArrayList(u8).init(arena_allocator);
    try processFile(arena_allocator, &result, filepath);

    return allocator.dupe(u8, result.items);
}

fn processFile(allocator: std.mem.Allocator, result: *std.ArrayList(u8), filepath: []const u8) !void {
    const file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (std.mem.startsWith(u8, std.mem.trim(u8, line, &std.ascii.whitespace), "//!include")) {
            var it = std.mem.split(u8, line, " ");
            _ = it.next(); // Skip "//!include"
            while (it.next()) |include_path| {
                try processFile(allocator, result, include_path);
            }
        } else {
            try result.appendSlice(line);
            try result.append('\n');
        }
    }
}
