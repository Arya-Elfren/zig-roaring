const std = @import("std");
const Sparse = @import("SparseMap.zig");
const RoaringBitmap = @import("RoaringBitmap.zig");
const U32 = RoaringBitmap.U32;

const Dense = @This();

pub const len = std.math.maxInt(u16) + 1;
const BitSet = std.bit_set.ArrayBitSet(usize, len);

data: BitSet,

pub fn consumeSparse(
    alloc: std.mem.Allocator,
    sparse: *Sparse,
) std.mem.Allocator.Error!*Dense {
    const d = try Dense.init(alloc);
    for (sparse.buffer.b[0..sparse.idx.len()]) |s| {
        d.add(s);
    }
    sparse.deinit(alloc);
    d.assertInvariants();
    return d;
}

fn init(alloc: std.mem.Allocator) std.mem.Allocator.Error!*Dense {
    var d = try alloc.create(Dense);
    d.* = .{ .data = BitSet.initEmpty() };
    return d;
}

pub fn deinit(
    self: *Dense,
    alloc: std.mem.Allocator,
) void {
    alloc.destroy(self);
}

pub fn add(
    self: *Dense,
    int: U32.LSB,
) void {
    if (self.data.count() > 0) self.assertInvariants();
    self.data.set(int.b);
    self.assertInvariants();
}

pub fn remove(
    self: *Dense,
    int: U32.LSB,
) error{Empty}!void {
    self.assertInvariants();
    self.data.unset(int.b);
    if (@truncate(u17, self.data.count()) == 0) return error.Empty;
    self.assertInvariants();
}

pub fn minimum(self: *const Dense) U32.LSB {
    self.assertInvariants();
    return .{ .b = @truncate(u16, self.data.findFirstSet() orelse unreachable) };
}

pub fn maximum(self: *const Dense) U32.LSB {
    self.assertInvariants();
    var it = self.data.iterator(.{ .direction = .reverse });
    const m = it.next() orelse unreachable;
    return .{ .b = @truncate(u16, m) };
}

pub fn cardinality(self: *const Dense) u17 {
    self.assertInvariants();
    return @truncate(u17, self.data.count());
}

pub fn contains(
    self: *const Dense,
    int: U32.LSB,
) bool {
    self.assertInvariants();
    return self.data.isSet(int.b);
}

pub fn addRange(
    self: *Dense,
    min: u32,
    max: u32,
    step: u32,
) !void {
    self.assertInvariants();
    var i = min;
    while (i < max) : (i += step) {
        try self.add(i);
    }
    self.assertInvariants();
}

fn assertInvariants(self: *const Dense) void {
    std.debug.assert(self.data.count() > 0);
    std.debug.assert(self.data.count() < std.math.maxInt(u16) + 2);
}
