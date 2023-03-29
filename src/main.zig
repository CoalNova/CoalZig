//! The main entry point of the CoalStar Engine
//!
//!     Any ops here should be abstract calls. Testing here must be temporary,
//! and moved out once complete. Avoid cluttering with multiple test codes to
//! avoid an ugly mess.
//!
//!     File/Folder layout is such that:
//! - 'Simpltypes' refers to files with types that have only member functions,
//!    and do not utilize Imports.
//! - 'CoalTypes' are files which contain structs and many utility functions,
//!    both member and external. Each file should contain and implement info
//!    relevant to that struct's operation. If ambiguity exists between
//!    ownership of functions and systems, (such as with mesh implementation)
//!    the owner should be seen as the commonality (mesh owns functions).
//! - 'CoalSystem' contain no structs, or no struct is the focus of the file.
//!    Instead, the focus is on function implementations and systems. Systems
//!    focus on facilitation and providing solutions to structs or engine. The
//!    suffix of 'system' is appended to denote useage, and prevent ambiguity
//!    between itself and any implemented element (such as event).
//!
//!     Imported files/libraries use a three-digit name to easily identify and
//! to not cause ambiguity by overlaping with any implemented... elements?
//!
//!
//!
const std = @import("std");
const zmt = @import("zmt");
const sys = @import("coalsystem/coalsystem.zig");
const stp = @import("coaltypes/setpiece.zig");
const wnd = @import("coaltypes/window.zig");
const chk = @import("coaltypes/chunk.zig");
const pnt = @import("simpletypes/points.zig");
const cam = @import("coaltypes/camera.zig");
const cms = @import("coalsystem/coalmathsystem.zig");
const evs = @import("coalsystem/eventsystem.zig");
const pst = @import("coaltypes/position.zig");

pub fn main() void {
    // Start system,
    sys.ignite();
    // Defer closing of system
    defer (sys.douse());

    const cube = stp.getSetpiece(.{});
    var camera: *cam.Camera = undefined;
    const window = wnd.getWindow(wnd.WindowCategory.hardware).?;

    stp_blk: for (window.focal_point.active_chunks) |index| {
        const focal_index: pnt.Point3 = window.focal_point.position.index();
        if (index.equals(focal_index)) {
            var chunk = chk.getChunk(index);
            if (chunk != null) {
                chunk.?.setpieces.?.append(cube) catch |err|
                    std.debug.print("{}\n", .{err});
                camera = &window.camera;
                camera.euclid.position = pst.Position.init(.{ .x = 0, .y = 0, .z = 0 }, .{ .x = 0, .y = 0, .z = 0 });
                break :stp_blk;
            }
        }
    }

    //main loop
    while (sys.runEngine()) {
        //camera.euclid.quaternion = zmt.qmul(camera.euclid.quaternion, zmt.quatFromRollPitchYaw(0.0, 0.0, 0.01));

        const angles = cms.convQuatToEul(camera.euclid.quaternion);
        std.debug.print("x:{d:.4}, y:{d:.4}, z:{d:.4}\n", .{ angles[0] / (std.math.pi * 0.5), angles[1] / (std.math.pi * 0.5), angles[2] * (90.0 / (std.math.pi * 0.5)) });
        std.debug.print("x:{d:.4}, y:{d:.4}, z:{d:.4} w:{d:.4}\n", .{ camera.forward[0], camera.forward[1], camera.forward[2], camera.forward[3] });
        std.debug.print("{}\n", .{camera.euclid.position.x & ((1 << 28) - 1)});
        std.debug.print("x:{d:.4}, y:{d:.4}, z:{d:.4}\n", .{ camera.euclid.position.axial().x, camera.euclid.position.axial().y, camera.euclid.position.axial().z });
        for (camera.view_matrix) |row|
            std.debug.print("[{d:.3},{d:.3},{d:.3},{d:.3}]\n", .{ row[0], row[1], row[2], row[3] });
        std.debug.print("\n", .{});

        var new_x: f32 = 0.0;
        var new_y: f32 = 0.0;

        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_W)) {
            std.debug.print("W", .{});
            new_y = 0.1;
        }

        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_A)) {
            std.debug.print("A", .{});
            new_x = -0.1;
        }

        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_S)) {
            std.debug.print("S", .{});
            new_y = -0.1;
        }

        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_D)) {
            std.debug.print("D", .{});
            new_x = 0.1;
        }

        camera.euclid.position = camera.euclid.position.addAxial(.{ .x = new_x, .y = new_y, .z = 0 });
    }
}
