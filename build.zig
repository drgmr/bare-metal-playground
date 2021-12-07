const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("bare-metal-playground", "src/main.zig");
    exe.setTarget(.{ .cpu_arch = .i386, .os_tag = .freestanding });
    exe.setBuildMode(mode);
    exe.setLinkerScriptPath(.{ .path = "./linker.ld" });
    exe.install();

    const run_cmd = b.addSystemCommand(&[_][]const u8{
        "qemu-system-i386",
        "-kernel",
        "zig-out/bin/bare-metal-playground",
    });
    run_cmd.step.dependOn(&exe.step);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
