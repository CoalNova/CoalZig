const std = @import("std");
const pst = @import("src/coaltypes/position.zig");
const sys = @import("src/coalsystem/coalsystem.zig");

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

// test "SDL operationality" {
//     var sdl_state = sys.sdl.SDL_Init(sys.sdl.SDL_INIT_EVERYTHING);
//     defer sys.sdl.SDL_Quit();

//     std.testing.expect(sdl_state == 0) catch |err| {
//         std.debug.print("sdl initialization failed {}\n, {}\n", .{ sdl_state, err });
//         return err;
//     };
//     std.debug.print("SDL successfully initialized\n", .{});
// }
