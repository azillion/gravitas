const std = @import("std");
const Voxel = @import("voxel.zig").Voxel;
const Allocator = std.mem.Allocator;

// TODO: we need to completely rewrite this

pub const OctreeNode = struct {
    children: ?[]*OctreeNode,
    voxel: ?Voxel,

    pub fn isLeaf(self: *const OctreeNode) bool {
        return self.children == null;
    }

    pub fn init(allocator: Allocator) !*OctreeNode {
        const node = try allocator.create(OctreeNode);
        node.* = .{ .children = null, .voxel = null };
        return node;
    }

    pub fn deinit(self: *OctreeNode, allocator: Allocator) void {
        if (self.children) |children| {
            for (children) |child| {
                child.deinit(allocator);
            }
            allocator.free(children);
        }
        allocator.destroy(self);
    }
};

pub const SparseVoxelOctree = struct {
    root: *OctreeNode,
    max_depth: u32,
    allocator: Allocator,

    pub fn init(allocator: Allocator, max_depth: u32) !SparseVoxelOctree {
        const root = try OctreeNode.init(allocator);
        return SparseVoxelOctree{ .root = root, .max_depth = max_depth, .allocator = allocator };
    }

    pub fn deinit(self: *SparseVoxelOctree) void {
        self.root.deinit(self.allocator);
    }

    pub fn getVoxel(self: *const SparseVoxelOctree, x: i32, y: i32, z: i32) ?Voxel {
        return self.getVoxelRecursive(self.root, x, y, z, 0, @as(i32, 1) << @intCast(self.max_depth - 1));
    }

    fn getVoxelRecursive(self: *const SparseVoxelOctree, node: *OctreeNode, x: i32, y: i32, z: i32, depth: u32, size: i32) ?Voxel {
        if (node.isLeaf()) {
            return node.voxel;
        }

        if (depth == self.max_depth) {
            return null;
        }

        const child_index = SparseVoxelOctree.getChildIndex(x, y, z, size);
        const half_size = @divTrunc(size, 2);

        if (node.children) |children| {
            const child = children[child_index];
            return self.getVoxelRecursive(child, x & (size - 1), y & (size - 1), z & (size - 1), depth + 1, half_size);
        }

        return null;
    }

    pub fn setVoxel(self: *SparseVoxelOctree, x: i32, y: i32, z: i32, voxel: Voxel) !void {
        try self.setVoxelRecursive(self.root, x, y, z, 0, @as(i32, 1) << @intCast(self.max_depth - 1), voxel);
    }

    fn setVoxelRecursive(self: *SparseVoxelOctree, node: *OctreeNode, x: i32, y: i32, z: i32, depth: u32, size: i32, voxel: Voxel) !void {
        if (depth == self.max_depth) {
            node.voxel = voxel;
            return;
        }

        if (node.children == null) {
            node.children = try self.allocator.alloc(*OctreeNode, 8);
            for (node.children.?) |*child| {
                child.* = try OctreeNode.init(self.allocator);
            }
        }

        const child_index = SparseVoxelOctree.getChildIndex(x, y, z, size);
        const half_size = @divTrunc(size, 2);

        try self.setVoxelRecursive(node.children.?[child_index], x & (size - 1), y & (size - 1), z & (size - 1), depth + 1, half_size, voxel);
    }

    fn getChildIndex(x: i32, y: i32, z: i32, size: i32) u8 {
        const half_size = @divTrunc(size, 2);
        return @intCast((@as(u3, @intFromBool(x >= half_size)) << 2) |
            (@as(u3, @intFromBool(y >= half_size)) << 1) |
            @as(u3, @intFromBool(z >= half_size)));
    }

    pub fn intersect(self: *const SparseVoxelOctree, origin: [3]f32, direction: [3]f32) ?Voxel {
        return self.intersectRecursive(self.root, origin, direction, 0, 0, 0, @as(i32, 1) << @intCast(self.max_depth - 1));
    }

    fn intersectRecursive(self: *const SparseVoxelOctree, node: *const OctreeNode, origin: [3]f32, direction: [3]f32, x: i32, y: i32, z: i32, size: i32) ?Voxel {
        if (node.isLeaf()) {
            return node.voxel;
        }

        const half_size = @divTrunc(size, 2);
        const child_indices = self.getTraversalOrder(origin, direction);

        for (child_indices) |i| {
            const child_x = x + @as(i32, @intCast(i & 1)) * half_size;
            const child_y = y + @as(i32, @intCast((i >> 1) & 1)) * half_size;
            const child_z = z + @as(i32, @intCast((i >> 2) & 1)) * half_size;

            if (node.children) |children| {
                if (self.intersectRecursive(children[i], origin, direction, child_x, child_y, child_z, half_size)) |voxel| {
                    return voxel;
                }
            }
        }

        return null;
    }

    fn getTraversalOrder(self: *const SparseVoxelOctree, origin: [3]f32, direction: [3]f32) [8]u8 {
        _ = self;
        var order: [8]u8 = undefined;
        var index: usize = 0;

        for (0..8) |i| {
            const x = @as(i32, @intCast(i & 1));
            const y = @as(i32, @intCast((i >> 1) & 1));
            const z = @as(i32, @intCast((i >> 2) & 1));

            const t_x: f32 = if (direction[0] != 0) (@as(f32, @floatFromInt(x)) - origin[0]) / direction[0] else std.math.inf(f32);
            const t_y = if (direction[1] != 0) (@as(f32, @floatFromInt(y)) - origin[1]) / direction[1] else std.math.inf(f32);
            const t_z = if (direction[2] != 0) (@as(f32, @floatFromInt(z)) - origin[2]) / direction[2] else std.math.inf(f32);

            const t = @min(t_x, @min(t_y, t_z));

            if (t >= 0) {
                order[index] = @intCast(i);
                index += 1;
            }
        }

        return order;
    }

    pub fn generateSimpleTerrain(self: *SparseVoxelOctree, width: i32, height: i32, depth: i32) !void {
        var x: i32 = 0;
        while (x < width) : (x += 1) {
            var z: i32 = 0;
            while (z < depth) : (z += 1) {
                const y = @as(i32, @intFromFloat(@floor(@sin(@as(f32, @floatFromInt(x)) * 0.1) *
                    @cos(@as(f32, @floatFromInt(z)) * 0.1) *
                    @as(f32, @floatFromInt(height)) / 4) +
                    @as(f32, @floatFromInt(height)) / 2));
                try self.setVoxel(x, y, z, .{ .material = 1 });
            }
        }
    }
};
