const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("zig-roaring", "src/RoaringBitmap.zig");
    lib.setBuildMode(mode);
    lib.install();

    const main_tests = b.addTest("src/RoaringBitmap.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
