const std = @import("std");
const Voxel = @import("voxel.zig").Voxel;
const Allocator = std.mem.Allocator;

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

        const half_size = size / 2;
        const child_index = @as(usize, @intCast(((x >= half_size) << 2) |
            ((y >= half_size) << 1) |
            (z >= half_size)));

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
