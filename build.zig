const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "CoalZig",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // OS version check for linking whil developing on seperate platforms
    if (target.isWindows()) {
        std.debug.print("Building in a Windows environment\n", .{});
        // change to the desired code path
        const sdl_path = "C:\\SDL2\\";
        const glew_path = "C:\\glew\\";
        exe.addIncludePath(sdl_path ++ "include\\");
        exe.addIncludePath(glew_path ++ "include\\");
        exe.addLibraryPath(sdl_path ++ "lib64\\");
        exe.addLibraryPath(glew_path ++ "lib\\Release\\x64\\");
        b.installBinFile(sdl_path ++ "lib64\\SDL2.dll", "SDL2.dll");
        exe.linkSystemLibrary("libglew32");
        exe.linkSystemLibrary("libglew32mx");
        exe.linkSystemLibrary("glew32s");
    } else {
        std.debug.print("Building in a Linux environment\n", .{});
        exe.linkSystemLibrary("glew");
    }
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("c");

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    exe.install();

    // This *creates* a RunStep in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = exe.run();

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing.
    const exe_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}

fn printWinReqs() void {
    std.debug.print("Compilation on windows requires the libraries of:\n", .{});
    std.debug.print("SDL https://www.libsdl.org/ @ C:\\SDL2 with include and lib(32/64) within\n", .{});
    std.debug.print("GLEW https://glew.sourceforge.net/ @ C:\\glew\n", .{});
    std.debug.print("ZMath(of ziggamedev) https://github.com/michal-z/zig-gamedev/tree/main/libs/zmath in the ./libs folder", .{});
}
