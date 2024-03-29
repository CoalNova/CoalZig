const std = @import("std");
const zmt = @import("libs/zmath/build.zig");
const zgl = @import("libs/zopengl/build.zig");

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

    // OS version check for linking while developing on seperate platforms
    if (target.isWindows()) {
        std.debug.print("Building in a Windows environment\n", .{});
        exe.addIncludePath("libs\\SDL\\include");
        exe.addLibraryPath("libs\\SDL\\lib");
        b.installBinFile("libs\\SDL\\bin\\SDL2.dll", "SDL2.dll");
        exe.addIncludePath("libs\\glew\\include");
        exe.addLibraryPath("libs\\glew\\lib");
        b.installBinFile("libs\\glew\\bin\\glew32.dll", "glew32.dll");
        exe.addIncludePath("libs\\cglm\\include");
        exe.addLibraryPath("libs\\cglm\\lib");
        //b.installBinFile("libs\\cglm\\bin\\glew32.dll", "glew32.dll");
        exe.linkSystemLibrary("opengl32");
    } else {
        std.debug.print("Building in a Linux environment\n", .{});
        exe.linkSystemLibrary("glew");
    }
    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("SDL2");
    //exe.linkSystemLibrary("cglm");

    //ZMATH
    const zmt_pkg = zmt.package(b, target, optimize, .{
        .options = .{ .enable_cross_platform_determinism = true },
    });
    const zgl_pkg = zgl.package(b, target, optimize, .{});

    exe.addModule("zmt", zmt_pkg.zmath);
    exe.addModule("zgl", zgl_pkg.zopengl);

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

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
        .root_source_file = .{ .path = "coaltest.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe_tests.addModule("zmt", zmt_pkg.zmath);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
