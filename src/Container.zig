const std = @import("std");
const Dense = @import("DenseMap.zig");
const Sparse = @import("SparseMap.zig");
const RoaringBitmap = @import("RoaringBitmap.zig");
const U32 = RoaringBitmap.U32;

const Container = @This();

pub const DataSets = union(enum) {
    Sparse: *Sparse,
    Dense: *Dense,
    // Run: *Run,
};

msb: U32.MSB,
data: DataSets,

pub fn init(
    alloc: std.mem.Allocator,
    elem: U32,
) std.mem.Allocator.Error!Container {
    return Container{
        .msb = elem.msb,
        .data = .{ .Sparse = try Sparse.init(alloc, elem.lsb) },
    };
}

pub fn deinit(
    self: *Container,
    alloc: std.mem.Allocator,
) void {
    switch (self.data) {
        inline else => |d| d.deinit(alloc),
    }
}

pub fn add(
    self: *Container,
    alloc: std.mem.Allocator,
    bits: U32.LSB,
) std.mem.Allocator.Error!void {
    switch (self.data) {
        .Sparse => |s| {
            s.add(bits) catch |err| switch (err) {
                error.Full => {
                    self.data = .{ .Dense = try Dense.consumeSparse(alloc, s) };
                    self.data.Dense.add(bits);
                },
            };
        },
        .Dense => |d| d.add(bits),
    }
}

pub fn remove(
    self: *const Container,
    bits: U32.LSB,
) error{Empty}!void {
    switch (self.data) {
        inline else => |d| try d.remove(bits),
    }
}

pub fn contains(
    self: *const Container,
    bits: U32.LSB,
) bool {
    return switch (self.data) {
        inline else => |d| d.contains(bits),
    };
}

pub fn cardinality(self: *const Container) u17 {
    const card = switch (self.data) {
        inline else => |d| d.cardinality(),
    };
    std.debug.assert(card > 0);
    return card;
}

/// Guaranteed to return a `U32.LSB` (not nullable) because any empty Container would be
/// automatically destroyed.
pub fn minimum(self: *const Container) U32.LSB {
    std.debug.assert(self.cardinality() > 0);
    return switch (self.data) {
        inline else => |d| d.minimum(),
    };
}

/// Guaranteed to return a `U32.LSB` (not nullable) because any empty Container would be
/// automatically destroyed.
pub fn maximum(self: *const Container) U32.LSB {
    std.debug.assert(self.cardinality() > 0);
    return switch (self.data) {
        inline else => |d| d.maximum(),
    };
}
