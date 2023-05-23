const std = @import("std");
const pst = @import("src/coaltypes/position.zig");
const sys = @import("src/coalsystem/coalsystem.zig");
const cms = @import("src/coalsystem/coalmathsystem.zig");

test "position initialization" {
    var pos_1: pst.Position = pst.Position.init(.{ .x = 0, .y = 0, .z = 0 }, .{ .x = 100, .y = 100, .z = 0 });

    std.testing.expect(pos_1.axial().x == 100) catch |err| {
        std.debug.print("expected {d}, got {d}, of {}\n, {}\n", .{ 100, pos_1.axial().x, pos_1.x, err });
        return err;
    };
    std.debug.print("expected {d}, got {d} OK\n", .{ 100, pos_1.axial().x });
}

test "position addition" {
    var pos_2: pst.Position = pst.Position.init(.{ .x = 0, .y = 0, .z = 0 }, .{ .x = 0, .y = 0, .z = 0 });
    pos_2 = pos_2.addAxial(.{ .x = 100, .y = 100, .z = 0 });

    std.testing.expect(pos_2.axial().x == 100) catch |err| {
        std.debug.print("expected {d}, got {d}, of {}\n, {}\n", .{ 100, pos_2.axial().x, pos_2.x, err });
        return err;
    };
    std.debug.print("expected {d}, got {d} OK\n", .{ 100, pos_2.axial().x });
}

test "positional rounding" {
    var pos_3: pst.Position = pst.Position.init(.{ .x = 0, .y = 0, .z = 0 }, .{ .x = 0, .y = 0, .z = 0 });
    pos_3 = pos_3.addAxial(.{ .x = 1024, .y = 0, .z = 0 });

    std.testing.expect(pos_3.axial().x == 0 and pos_3.index().x == 1) catch |err| {
        std.debug.print("expected {d} {d}, got {d} {d}, of {}\n, {}\n", .{ 0, 1, pos_3.axial().x, pos_3.index().x, pos_3.x, err });
        return err;
    };
    std.debug.print("expected {d} {d}, got {d} {d} OK\n", .{ 0, 1, pos_3.axial().x, pos_3.index().x });
}

test "ray meet plane" {
    const pl_or_0 = cms.Vec3{ 0, 0, 0 };
    const pl_or_1 = cms.Vec3{ 0, 0, 1.0 };
    const pl_or_2 = cms.Vec3{ 0, 0, -1.0 };
    const pl_or_3 = cms.Vec3{ 0, 0, 1000.0 };

    const pl_nm_0 = cms.Vec3{ 0, 0, 1.0 };
    const pl_nm_1 = cms.Vec3{ 0, 1.0, 0 };
    const pl_nm_2 = cms.Vec3{ 0, 0.5, 0.5 };
    const pl_nm_3 = cms.Vec3{ 0.5, 0.5, 0 };

    const ry_or_0 = cms.Vec3{ 0, 0, 1.0 };
    const ry_or_1 = cms.Vec3{ 0, 0.5, 1.0 };
    const ry_or_2 = cms.Vec3{ 0.5, 0, 1.0 };
    const ry_or_3 = cms.Vec3{ 0.5, 0.5, 1.0 };

    const ry_dr_0 = cms.Vec3{ 0, 0, -1.0 };
    const ry_dr_1 = cms.Vec3{ 0, 0, 1.0 };
    const ry_dr_2 = cms.Vec3{ 0, 1.0, 0 };
    const ry_dr_3 = cms.Vec3{ 1.0, 0, 0 };

    var length: f32 = 0;

    std.testing.expect(cms.rayPlane(pl_or_0, pl_nm_0, ry_or_0, ry_dr_0, &length)) catch |err| {
        std.debug.print("expected collision, got none\n");
        return err;
    };
    std.testing.expect(length == 1.0) catch |err| std.debug.print("Expected 1.000 got {d:.4} [{!}]\n", .{ length, err });
    std.testing.expect(cms.rayPlane(pl_or_1, pl_nm_1, ry_or_1, ry_dr_1, &length)) catch |err| {
        std.debug.print("expected collision, got none\n");
        return err;
    };
    std.testing.expect(length == 1.0) catch |err| std.debug.print("Expected 1.000 got {d:.4} [{!}]\n", .{ length, err });
    std.testing.expect(cms.rayPlane(pl_or_2, pl_nm_2, ry_or_2, ry_dr_2, &length)) catch |err| {
        std.debug.print("expected collision, got none\n");
        return err;
    };
    std.testing.expect(length == 1.0) catch |err| std.debug.print("Expected 1.000 got {d:.4} [{!}]\n", .{ length, err });
    std.testing.expect(cms.rayPlane(pl_or_3, pl_nm_3, ry_or_3, ry_dr_3, &length)) catch |err| {
        std.debug.print("expected collision, got none\n");
        return err;
    };
    std.testing.expect(length == 1.0) catch |err| std.debug.print("Expected 1.000 got {d:.4} [{!}]\n", .{ length, err });
}

// test "SDL operationality" {
//     var sdl_state = sys.sdl.SDL_Init(sys.sdl.SDL_INIT_EVERYTHING);
//     defer sys.sdl.SDL_Quit();

//     std.testing.expect(sdl_state == 0) catch |err| {
//         std.debug.print("sdl initialization failed {}\n, {}\n", .{ sdl_state, err });
//         return err;
//     };
//     std.debug.print("SDL successfully initialized\n", .{});
// }
