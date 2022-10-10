const std = @import("std");
const U32 = @import("RoaringBitmap.zig").U32;

const Sparse = @This();

test "Buffer" {
    std.testing.refAllDecls(Buffer);
}

const Buffer = struct {
    b: [MaxLen]U32.LSB,

    pub const MaxLen = std.math.maxInt(Idx.Type) + 1;

    test "Idx" {
        std.testing.refAllDecls(Idx);
    }

    pub const Idx = struct {
        b: Type,

        pub const Type = u12;

        pub fn len(self: Idx) u13 {
            return @as(u13, self.b) + 1;
        }

        test "size" {
            try std.testing.expectEqual(
                @sizeOf(u12),
                @sizeOf(Idx),
            );
        }

        test "bitSize" {
            try std.testing.expectEqual(
                @bitSizeOf(u12),
                @bitSizeOf(Idx),
            );
        }

        test "len max" {
            try std.testing.expectEqual(
                (Idx{ .b = std.math.maxInt(u12) }).len(),
                std.math.maxInt(u12) + 1,
            );
        }

        test "len 0" {
            try std.testing.expectEqual(
                (Idx{ .b = 0 }).len(),
                1,
            );
        }
    };

    test "size" {
        try std.testing.expectEqual(
            @sizeOf(u16) * Buffer.MaxLen,
            @sizeOf(Buffer),
        );
    }

    test "bitSize" {
        try std.testing.expectEqual(
            @bitSizeOf(u16) * Buffer.MaxLen,
            @bitSizeOf(Buffer),
        );
    }

    test "max index" {
        // The max index can't be out of bounds.
        _ = (Buffer{ .b = undefined }).b[(Idx{ .b = std.math.maxInt(Idx.Type) }).b];
    }
};

buffer: Buffer,
idx: Buffer.Idx,

test "size" {
    try std.testing.expectEqual(
        @sizeOf(u16) * Buffer.MaxLen + @sizeOf(Buffer.Idx),
        @sizeOf(Sparse),
    );
}

test "bitSize" {
    try std.testing.expectEqual(
        @bitSizeOf(u16) * Buffer.MaxLen + @bitSizeOf(Buffer.Idx),
        @bitSizeOf(Sparse),
    );
}

/// Allocate a SparseSet and set the first element. This is the only way to initialize it because
/// an empty set is auto de-initialized and destroyed.
///
/// Call `Sparse.deinit()` or otherwise consume the set to stop memory leaks.
pub fn init(
    alloc: std.mem.Allocator,
    elem: U32.LSB,
) std.mem.Allocator.Error!*Sparse {
    var ret = try alloc.create(Sparse);
    ret.* = Sparse{
        // The buffer doesn't matter because we should only access fields we explicitly set.
        .buffer = .{ .b = undefined },
        .idx = .{ .b = 0 },
    };
    ret.buffer.b[0] = elem;
    // The set should already be a valid set.
    ret.assertInvariants();
    return ret;
}

test "init/deinit" {
    const sparse = try Sparse.init(std.testing.allocator, .{ .b = 0 });
    defer sparse.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(u16, 0), sparse.buffer.b[0].b);
    try std.testing.expectEqual(@as(u13, 1), sparse.idx.len());
}

pub fn deinit(
    self: *Sparse,
    alloc: std.mem.Allocator,
) void {
    self.* = undefined;
    alloc.destroy(self);
}

/// Add an element to the SparseSet.
pub fn add(
    self: *Sparse,
    lsb: U32.LSB,
) error{Full}!void {
    self.assertInvariants();
    if (self.full()) {
        return error.Full;
    }
    switch (self.findClosest(lsb)) {
        // It's a set so if it's already contained in the set don't add it
        .Found => |found_at_index| {
            std.debug.assert(lsb.b == self.buffer.b[found_at_index.b].b);
        },
        .Closest => |insert_index| {
            if (lsb.b < self.idx.b) {
                std.debug.assert(lsb.b < self.buffer.b[insert_index.b].b);
            }
            {
                var top_unshifted_index = self.idx;
                // Move each element up one in the array until the closest index to the new value.
                if (top_unshifted_index.b != 0) {
                    while (top_unshifted_index.b >= insert_index.b) : (top_unshifted_index.b -= 1) {
                        self.buffer.b[top_unshifted_index.b] = self.buffer.b[top_unshifted_index.b - 1];
                    }
                }
            }
            // Insert new value and increase the length.
            self.buffer.b[insert_index.b] = lsb;
            self.idx.b += 1;
        },
    }
    // If the buffer isn't full, every element after the last one is undefined.
    // if (!self.full()) {
    //     for (self.buffer.b[self.idx.len()..]) |_, idx| {
    //         self.buffer.b[idx] = undefined;
    //     }
    // }
    self.assertInvariants();
}

// Remove the element from the SparseSet.
pub fn remove(
    self: *Sparse,
    lsb: U32.LSB,
) error{Empty}!void {
    self.assertInvariants();
    // If the element isn't in the list there's nothing to remove
    switch (self.findClosest(lsb)) {
        .Found => |found_at_index| {
            std.debug.assert(lsb.b == self.buffer.b[found_at_index.b].b);
            // Early return only works if the element is the only one in the set.
            if (self.idx.b == 0) {
                self.buffer.b = undefined;
                return error.Empty;
            }
            var bottom_unshifted_index = found_at_index.b;
            // Move each later element down one in the list, overwriting the removed element.
            while (bottom_unshifted_index < self.idx.len()) : (bottom_unshifted_index += 1) {
                self.buffer.b[bottom_unshifted_index] = self.buffer.b[bottom_unshifted_index + 1];
            }
            self.idx.b -= 1;
        },
        .Closest => |closest_index| {
            if (lsb.b < self.idx.b) {
                std.debug.assert(lsb.b < self.buffer.b[closest_index.b].b);
            }
        },
    }
    // If the buffer isn't full, every element after the last one is undefined.
    // if (!self.full()) {
    //     for (self.buffer.b[self.idx.len()..]) |_, idx| {
    //         self.buffer.b[idx] = undefined;
    //    }
    // }
    // Only works because if the cardinality is 0 this would have returned earlier.
    self.assertInvariants();
}

/// Binary search for a number, if it's found return `.{ .Found = Idx }` if it isn't return
/// `.{ .Closest = Idx }` of the position it would be inserted at if it were in the array.
/// This means we only do one search, for if it's there or not.
fn findClosest(
    self: *const Sparse,
    lsb: U32.LSB,
) union(enum) {
    Found: Buffer.Idx,
    Closest: Buffer.Idx,
} {
    var left: Buffer.Idx = .{ .b = 0 };
    var right: Buffer.Idx = self.idx;
    var assert_dist_decreasing = right.b - left.b;
    while (left.b < right.b) {
        const mid: Buffer.Idx = .{ .b = left.b + @divFloor((right.b - left.b), 2) };
        switch (std.math.order(lsb.b, self.buffer.b[mid.b].b)) {
            .eq => return .{ .Found = mid },
            .gt => left = .{ .b = mid.b + 1 },
            .lt => right = mid,
        }
        std.debug.assert(right.b - left.b < assert_dist_decreasing);
        assert_dist_decreasing = right.b - left.b;
    }
    return switch (std.math.order(lsb.b, self.buffer.b[left.b].b)) {
        .eq => .{ .Found = left },
        .lt => .{ .Closest = left },
        .gt => .{ .Closest = .{
            .b = std.math.min(
                @as(u13, left.b) + 1,
                @as(Buffer.Idx.Type, std.math.maxInt(Buffer.Idx.Type)),
            ),
        } },
    };
}

test "find closest full" {
    {
        var sparse = Sparse{
            .buffer = .{ .b = undefined },
            .idx = .{ .b = 0 },
        };
        {
            var i: u13 = 0;
            while (i < Buffer.MaxLen) : (i += 1) {
                sparse.buffer.b[i].b = i;
            }
            sparse.idx.b = std.math.maxInt(Buffer.Idx.Type);
        }
        {
            var i: u13 = 0;
            while (i < sparse.idx.len()) : (i += 1) {
                try std.testing.expectEqual(
                    sparse.findClosest(.{ .b = i }),
                    .{ .Found = .{ .b = @truncate(u12, i) } },
                );
            }
        }
    }
    {
        var sparse = Sparse{
            .buffer = .{ .b = undefined },
            .idx = .{ .b = 0 },
        };
        {
            var i: u13 = 0;
            while (i < Buffer.MaxLen) : (i += 1) {
                sparse.buffer.b[i].b = i + Buffer.MaxLen;
            }
            sparse.idx.b = std.math.maxInt(Buffer.Idx.Type);
        }
        {
            var i: u13 = 0;
            while (i < sparse.idx.len()) : (i += 1) {
                try std.testing.expectEqual(
                    sparse.findClosest(.{ .b = i + Buffer.MaxLen }),
                    .{ .Found = .{ .b = @truncate(u12, i) } },
                );
            }
        }
        {
            var i: u13 = 0;
            while (i < sparse.idx.len()) : (i += 1) {
                try std.testing.expectEqual(
                    sparse.findClosest(.{ .b = i }),
                    .{ .Closest = .{ .b = 0 } },
                );
            }
        }
        {
            var i: u13 = 0;
            while (i < sparse.idx.len()) : (i += 1) {
                try std.testing.expectEqual(
                    sparse.findClosest(.{ .b = @as(u16, i) + Buffer.MaxLen + Buffer.MaxLen }),
                    .{ .Closest = .{ .b = std.math.maxInt(Buffer.Idx.Type) } },
                );
            }
        }
    }
}

test "find closest 'empty'" {
    var sparse = Sparse{
        .buffer = .{ .b = undefined },
        .idx = .{ .b = 0 },
    };
    sparse.buffer.b[0] = .{ .b = 2 };
    sparse.idx.b = 0;

    try std.testing.expectEqual(
        sparse.findClosest(.{ .b = 1 }),
        .{ .Closest = .{ .b = 0 } },
    );
    try std.testing.expectEqual(
        sparse.findClosest(.{ .b = 2 }),
        .{ .Found = .{ .b = 0 } },
    );
    try std.testing.expectEqual(
        sparse.findClosest(.{ .b = 3 }),
        .{ .Closest = .{ .b = 1 } },
    );
}

fn full(self: *const Sparse) bool {
    return self.idx.len() == Buffer.MaxLen;
}

test "full artificial" {
    var sparse = Sparse{
        .buffer = undefined,
        .idx = .{ .b = std.math.maxInt(Buffer.Idx.Type) },
    };
    try std.testing.expect(sparse.full());
    sparse.idx.b -= 1;
    try std.testing.expect(!sparse.full());
}

pub fn minimum(self: *const Sparse) U32.LSB {
    self.assertInvariants();
    return self.buffer.b[0];
}

pub fn maximum(self: *const Sparse) U32.LSB {
    self.assertInvariants();
    return self.buffer.b[self.idx.b];
}

pub fn cardinality(self: *const Sparse) u13 {
    self.assertInvariants();
    return self.idx.len();
}

pub fn contains(
    self: *const Sparse,
    bits: U32.LSB,
) bool {
    self.assertInvariants();
    return switch (self.findClosest(bits)) {
        .Found => true,
        .Closest => false,
    };
}

fn assertInvariants(self: *const Sparse) void {
    std.debug.assert(self.idx.b < Buffer.MaxLen);
    std.debug.assert(self.idx.len() > 0);
    {
        var i: u13 = 1;
        var previous: U32.LSB = self.buffer.b[0];
        while (i < self.idx.len()) : (i += 1) {
            std.debug.assert(previous.b < self.buffer.b[i].b);
            previous = self.buffer.b[i];
        }
    }
}
