const std = @import("std");
const Dense = @import("DenseMap.zig");
const Sparse = @import("SparseMap.zig");
const Container = @import("Container.zig");

const RoaringBitmap = @This();

allocator: std.mem.Allocator,
chunks: []Container,

pub const U32 = packed struct {
    pub const MSB = packed struct { b: u16 };
    pub const LSB = packed struct { b: u16 };

    msb: MSB,
    lsb: LSB,

    pub fn from(x: u32) U32 {
        return .{
            .msb = .{ .b = @truncate(u16, x >> 16) },
            .lsb = .{ .b = @truncate(u16, x) },
        };
    }

    pub fn to(self: U32) u32 {
        return (@as(u32, self.msb.b) << 16) | self.lsb.b;
    }
};

pub fn init(alloc: std.mem.Allocator) RoaringBitmap {
    return RoaringBitmap{
        .allocator = alloc,
        .chunks = alloc.alloc(Container, 0) catch unreachable,
    };
}

pub fn deinit(self: *RoaringBitmap) void {
    for (self.chunks[0..]) |*c| {
        c.deinit(self.allocator);
    }
    self.allocator.free(self.chunks);
}

pub fn addRange(
    self: *RoaringBitmap,
    min: u32,
    max: u32,
    step: u32,
) !void {
    var i = min;
    while (i < max) : (i += step) {
        try self.add(i);
    }
}

pub fn clear(self: *RoaringBitmap) void {
    _ = self;
}

pub fn toU32Slice(self: *RoaringBitmap, alloc: ?std.mem.Allocator) []const u32 {
    _ = self;
    _ = alloc;
    std.debug.todo("Not yet implemented");
}

pub fn iterate()void{}//self: *RoaringBitmap) Iterator {}

pub fn copyNewAlloc(self: *RoaringBitmap, alloc: ?std.mem.Allocator) RoaringBitmap {
    _ = self;
    _ = alloc;
    std.debug.todo("Not yet implemented");
}

//

pub fn cardinality(self: *const RoaringBitmap) u33 {
    var i: u33 = 0;
    for (self.chunks) |c| {
        i += c.cardinality();
    }
    return i;
}

pub fn intersect(
    self: *const RoaringBitmap,
    other: *const RoaringBitmap,
) bool {
    _ = self;
    _ = other;
    std.debug.todo("Not yet implemented");
}

pub fn eql(
    self: *const RoaringBitmap,
    other: *const RoaringBitmap,
) bool {
    _ = self;
    _ = other;
    std.debug.todo("Not yet implemented");
}

pub fn subset(
    self: *const RoaringBitmap,
    other: *const RoaringBitmap,
) bool {
    _ = self;
    _ = other;
    std.debug.todo("Not yet implemented");
}

pub fn strictSubset(
    self: *const RoaringBitmap,
    other: *const RoaringBitmap,
) bool {
    _ = self;
    _ = other;
    std.debug.todo("Not yet implemented");
}

pub fn intersectWithRange(
    self: *const RoaringBitmap,
    min: u32,
    max: u32,
) bool {
    _ = self;
    _ = min;
    _ = max;
    std.debug.todo("Not yet implemented");
}

//

pub fn andCardinality(
    self: *const RoaringBitmap,
    other: *const RoaringBitmap,
) u33 {
    _ = self;
    _ = other;
    std.debug.todo("Not yet implemented");
}

pub fn andInplace(
    self: *RoaringBitmap,
    other: *const RoaringBitmap,
) void {
    _ = self;
    _ = other;
    std.debug.todo("Not yet implemented");
}

pub fn andNew(
    self: *const RoaringBitmap,
    other: *const RoaringBitmap,
    alloc: ?std.mem.Allocator,
) RoaringBitmap {
    _ = self;
    _ = other;
    _ = alloc;
    std.debug.todo("Not yet implemented");
}

//

pub fn rank(
    self: *const RoaringBitmap,
    x: u32,
) u32 {
    _ = self;
    _ = x;
    std.debug.todo("Not yet implemented");
}

pub fn minimum(self: *const RoaringBitmap) ?u32 {
    if (self.chunks.len == 0) return null;
    const n = U32{
        .msb = self.chunks[0].msb,
        .lsb = self.chunks[0].minimum(),
    };
    return n.to();
}

pub fn maximum(self: *const RoaringBitmap) ?u32 {
    if (self.chunks.len == 0) return null;
    const n = U32{
        .msb = self.chunks[self.chunks.len - 1].msb,
        .lsb = self.chunks[self.chunks.len - 1].maximum(),
    };
    return n.to();
}

pub fn jaccardIndex()void{
    std.debug.todo("Not yet implemented");
}//self: *RoaringBitmap, other: *RoaringBitmap)

//

pub fn notRangeInplace(
    self: *RoaringBitmap,
    min: u32,
    max: u32,
) !void {
    _ = self;
    _ = min;
    _ = max;
    std.debug.todo("Not yet implemented");
}

pub fn notRangeNew(
    self: *const RoaringBitmap,
    alloc: ?std.mem.Allocator,
    min: u32,
    max: u32,
) RoaringBitmap {
    _ = self;
    _ = alloc;
    _ = min;
    _ = max;
    std.debug.todo("Not yet implemented");
}

//

pub fn orCardinality(
    self: *const RoaringBitmap,
    other: *const RoaringBitmap,
) u33 {
    _ = self;
    _ = other;
    std.debug.todo("Not yet implemented");
}

pub fn orInplace(
    self: *RoaringBitmap,
    other: *const RoaringBitmap,
) void {
    _ = self;
    _ = other;
    std.debug.todo("Not yet implemented");
}

pub fn orNew(
    self: *const RoaringBitmap,
    other: *const RoaringBitmap,
    alloc: ?std.mem.Allocator,
) RoaringBitmap {
    _ = self;
    _ = other;
    _ = alloc;
    std.debug.todo("Not yet implemented");
}

pub fn orMany(
    self: *const RoaringBitmap,
    other: []const *const RoaringBitmap,
    alloc: ?std.mem.Allocator,
) RoaringBitmap {
    _ = self;
    _ = other;
    _ = alloc;
    std.debug.todo("Not yet implemented");
}

//

pub fn xorCardinality(
    self: *const RoaringBitmap,
    other: *const RoaringBitmap,
) u33 {
    _ = self;
    _ = other;
    std.debug.todo("Not yet implemented");
}

pub fn xorInplace(
    self: *RoaringBitmap,
    other: *const RoaringBitmap,
) void {
    _ = self;
    _ = other;
    std.debug.todo("Not yet implemented");
}

pub fn xorNew(
    self: *const RoaringBitmap,
    other: *const RoaringBitmap,
    alloc: ?std.mem.Allocator,
) RoaringBitmap {
    _ = self;
    _ = other;
    _ = alloc;
    std.debug.todo("Not yet implemented");
}

pub fn xorMany(
    self: *const RoaringBitmap,
    other: []const *const RoaringBitmap,
    alloc: ?std.mem.Allocator,
) RoaringBitmap {
    _ = self;
    _ = other;
    _ = alloc;
    std.debug.todo("Not yet implemented");
}

//

pub fn andNotCardinality(
    self: *const RoaringBitmap,
    other: *const RoaringBitmap,
) u33 {
    _ = self;
    _ = other;
    std.debug.todo("Not yet implemented");
}

pub fn andNotInplace(
    self: *RoaringBitmap,
    other: *const RoaringBitmap,
) void {
    _ = self;
    _ = other;
    std.debug.todo("Not yet implemented");
}

pub fn andNotNew(
    self: *const RoaringBitmap,
    other: *const RoaringBitmap,
    alloc: ?std.mem.Allocator,
) RoaringBitmap {
    _ = self;
    _ = other;
    _ = alloc;
    std.debug.todo("Not yet implemented");
}

pub const RemoveStatus = enum { Empty, NotEmpty };

pub fn add(self: *RoaringBitmap, n: u32) !void {
    const num = U32.from(n);
    switch (self.findClosest(num.msb)) {
        .Found => |found_at_index| {
            std.debug.assert(self.chunks[found_at_index].msb.b == num.msb.b);
            try self.chunks[found_at_index].add(self.allocator, num.lsb);
        },
        .Closest => |c| {
            self.chunks = try self.allocator.realloc(self.chunks, self.chunks.len + 1);
            {
                var i = @truncate(u16, self.chunks.len - 1);
                while (i > c) : (i -= 1) {
                    self.chunks[i] = self.chunks[i - 1];
                }
            }
            self.chunks[c] = try Container.init(self.allocator, num);
        },
        .Empty => {
            self.chunks = try self.allocator.realloc(self.chunks, 1);
            self.chunks[0] = try Container.init(self.allocator, num);
        },
    }
}

pub fn remove(self: *RoaringBitmap, n: u32) void {
    const num = U32.from(n);
    if (self.get(num.msb)) |*c| {
        c.remove(num.lsb) catch |err| switch (err) {
            error.Empty => self.removeChunk(c.msb),
        };
    }
}

pub fn contains(
    self: *const RoaringBitmap,
    n: u32,
) bool {
    const num = U32.from(n);
    var c = self.get(num.msb) orelse return false;
    return c.contains(num.lsb);
}

fn removeChunk(
    self: *RoaringBitmap,
    elem: U32.MSB,
) void {
    {
        var i: u16 = self.find(elem) orelse return;
        self.chunks[i].deinit(self.allocator);
        while (i < self.chunks.len - 1) : (i += 1) {
            self.chunks[i] = self.chunks[i + 1];
        }
    }
    self.chunks = self.allocator.realloc(self.chunks, self.chunks.len - 1) catch unreachable;
}

fn findClosest(
    self: *const RoaringBitmap,
    elem: U32.MSB,
) union(enum) {
    Found: u16,
    Closest: u16,
    Empty,
} {
    if (self.chunks.len == 0) {
        return .Empty;
    }
    var left: u16 = 0;
    var right: u16 = @truncate(u16, self.chunks.len);

    while (left < right) {
        const mid = left + (right - left) / 2;
        switch (std.math.order(elem.b, self.chunks[mid].msb.b)) {
            .eq => return .{ .Found = mid },
            .gt => left = mid + 1,
            .lt => right = mid,
        }
    }

    return .{ .Closest = left };
}

fn find(
    self: *const RoaringBitmap,
    key: U32.MSB,
) ?u16 {
    return switch (self.findClosest(key)) {
        .Found => |f| f,
        .Closest, .Empty => null,
    };
}

pub fn get(
    self: *const RoaringBitmap,
    key: U32.MSB,
) ?Container {
    const idx = self.find(key) orelse return null;
    return self.chunks[idx];
}

test "refAllDeclsRecursive" {
    std.testing.refAllDeclsRecursive(@This());
}

test "cardinality for all add and remove" {
    var l = RoaringBitmap.init(std.testing.allocator);
    defer l.deinit();
    {
        var i: u32 = 0;
        try std.testing.expectEqual(@as(u33, i), l.cardinality());
        while (i < std.math.maxInt(u16) + 2) {
            try l.add(i);
            try std.testing.expect(l.contains(i));
            i += 1;
            try std.testing.expectEqual(@as(u33, i), l.cardinality());
        }
    }
    {
        var i: u32 = 0;
        try std.testing.expectEqual(@as(u33, std.math.maxInt(u16) + 2), l.cardinality());
        while (i < std.math.maxInt(u16) + 1) : (i += 1) {
            try l.add(i);
            try std.testing.expectEqual(@as(u33, std.math.maxInt(u16) + 2), l.cardinality());
        }
    }
    {
        var i: u32 = 0;
        try std.testing.expectEqual(@as(u33, std.math.maxInt(u16) + 2), l.cardinality());
        while (i < std.math.maxInt(u16) + 1) : (i += 1) {
            l.remove(i);
            try std.testing.expectEqual(@as(u33, std.math.maxInt(u16) + 1 - i), l.cardinality());
        }
    }
}
