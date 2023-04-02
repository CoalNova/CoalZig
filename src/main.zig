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
                chunk.?.setpieces.append(cube) catch |err|
                    std.debug.print("{}\n", .{err});
                camera = &window.camera;
                camera.euclid.position = pst.Position.init(.{ .x = 0, .y = 0, .z = 0 }, .{ .x = 0, .y = 0, .z = 1 });
                break :stp_blk;
            }
        }
    }

    //main loop
    while (sys.runEngine()) {
        var new_x: f32 = 0;
        var new_y: f32 = 0;
        var rot_x: f32 = 0;
        var rot_y: f32 = 0;
        var rot_z: f32 = 0;

        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_W)) new_y = 0.1;
        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_A)) new_x = -0.1;
        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_S)) new_y = -0.1;
        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_D)) new_x = 0.1;

        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_L)) rot_z += 0.04;
        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_J)) rot_z -= 0.04;
        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_I)) rot_x -= 0.04;
        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_K)) rot_x += 0.04;
        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_Q)) rot_y += 0.04;
        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_E)) rot_y -= 0.04;

        var cam_rot = cms.convQuatToEul(camera.euclid.quaternion);

        camera.euclid.position =
            camera.euclid.position.addAxial(.{
            .x = new_x * @cos(cam_rot[2]) + new_y * @sin(cam_rot[2]),
            .y = new_y * @cos(cam_rot[2]) - new_x * @sin(cam_rot[2]),
            .z = 0,
        });
        camera.euclid.quaternion =
            zmt.qmul(camera.euclid.quaternion, zmt.quatFromRollPitchYaw(rot_x, rot_y, rot_z));
    }
}
