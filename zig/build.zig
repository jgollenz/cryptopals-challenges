const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("code", "src/code.zig");
    lib.setBuildMode(mode);
    lib.install();

    const lib_tests = b.addTest("src/code.zig");
    lib_tests.setBuildMode(mode);

    const cryptopal_challenges = b.addTest("src/challenges.zig");

    const test_step = b.step("test-code", "Run code library tests");
    test_step.dependOn(&lib_tests.step);

    const challenges_step = b.step("challenges", "Run the cryptopal challenges");
    challenges_step.dependOn(&cryptopal_challenges.step);
}
