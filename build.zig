const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("CoalZig", "src/main.zig");

    // OS version check for linking whil developing on seperate platforms
    if (target.isWindows()) {
        std.debug.print("Building in a Windows environment\n", .{});
        // change to the desired code path
        const sdl_path = "C:/SDL2/";
        exe.addIncludePath(sdl_path ++ "include");
        exe.addLibraryPath(sdl_path ++ "lib64/");
        b.installBinFile(sdl_path ++ "lib64/SDL2.dll", "SDL2.dll");
    } else {
        std.debug.print("Building in a Linux environment\n", .{});
    }
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("c");
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
