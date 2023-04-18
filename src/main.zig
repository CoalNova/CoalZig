//! The main entry point of the CoalStar Engine
//!
//!     Any ops here should be abstract calls. Testing here must be temporary,
//! and moved out once complete. Avoid cluttering with multiple test codes to
//! avoid an ugly mess.
//!
//!     File/Folder layout is such that:
//! - 'Simpletypes' refers to files with types that have only member functions,
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
//! Should confusion arise, perhaps an underscore suffix could be used?
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
const gls = @import("coalsystem/glsystem.zig");
const eds = @import("coalsystem/editorsystem.zig");
const fio = @import("coalsystem/fileiosystem.zig");
const fcs = @import("coaltypes/focus.zig");
const alc = @import("coalsystem/allocationsystem.zig");

pub fn main() void {
    sys.prepareStar() catch |err| return std.debug.print("{!}\n", .{err});

    if (true) {
        var map = fio.loadBMP("./assets/world/map.bmp") catch |err| {
            std.debug.print("file error: {}\n", .{err});
            return;
        };

        // var chunk_bounds = chk.getMapBounds();
        const t_count = std.Thread.getCpuCount() catch |err|
            return std.debug.print("{!}\n", .{err});
        var threads = alc.gpa_allocator.alloc(std.Thread, t_count) catch |err|
            return std.debug.print("{!}\n", .{err});

        std.debug.print("\nthread count: {}\n", .{t_count});

        const t_divsr = @divTrunc(128, t_count);

        for (0..t_count) |t| {
            const t_start = pnt.Point3{ .x = 0, .y = @intCast(i32, t_divsr * t), .z = 0 };
            const t_end = pnt.Point3{ .x = 0, .y = if (t_count - 1 > t) @intCast(i32, t_divsr * (t + 1)) else 128, .z = 0 };

            std.debug.print("thread {}: [{}, {}][{}, {}]\n", .{ t, t_start.x, t_start.y, t_end.x, t_end.y });

            threads[t] = std.Thread.spawn(.{}, eds.generateNewChunkMap, .{
                map.px,
                20,
                sys.getMetaHeader().map_name,
                .{ .x = @intCast(i32, map.width), .y = @intCast(i32, map.height) },
                .{ .x = sys.getMetaHeader().map_size.x, .y = sys.getMetaHeader().map_size.y },
                t_start,
                t_end,
            }) catch |err| return std.debug.print("{!}\n", .{err});
        }

        for (0..t_count) |t|
            threads[t].join();

        for (0..t_count) |t| {
            const t_start = pnt.Point3{ .x = 0, .y = @intCast(i32, t_divsr * t), .z = 0 };
            const t_end = pnt.Point3{ .x = 0, .y = if (t_count - 1 > t) @intCast(i32, t_divsr * (t + 1)) else 128, .z = 0 };

            threads[t] = std.Thread.spawn(
                .{},
                eds.smooveChunkMap,
                .{ .{ .x = sys.getMetaHeader().map_size.x, .y = sys.getMetaHeader().map_size.y }, 1, 1, 4, t_start, t_end },
            ) catch |err| return std.debug.print("{!}\n", .{err});
        }

        for (0..t_count) |t|
            threads[t].join();
    }

    defer sys.releaseStar();
    sys.igniteStar();
    defer sys.douseStar();

    const window = wnd.getWindow(wnd.WindowCategory.hardware).?;
    var camera = &window.camera;
    camera.euclid.position = pst.Position.init(.{ .x = 0, .y = 0, .z = 0 }, .{ .x = 0, .y = 0, .z = 1.75 });
    var cube = stp.generateSetPiece(.{}, chk.getChunk(window.focal_point.position.index()).?).?;
    //sys.setEngineStateFlag(sys.EngineFlag.ef_quitflag);

    //debug testing loop
    while (sys.runEngine()) {
        var new_x: f32 = 0;
        var new_y: f32 = 0;
        var rot_x: f32 = 0;
        var rot_y: f32 = 0;
        var rot_z: f32 = 0;

        if (evs.getKeyDown(sys.sdl.SDL_SCANCODE_LALT)) {
            _ = sys.sdl.SDL_SetRelativeMouseMode(sys.sdl.SDL_TRUE);
            sys.sdl.SDL_WarpMouseInWindow(window.sdl_window, window.size.x >> 1, window.size.y >> 1);
        }

        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_LALT)) {
            var _x: c_int = 0;
            var _y: c_int = 0;
            _ = sys.sdl.SDL_GetMouseState(&_x, &_y);
            rot_x += @intToFloat(f32, (_y - (window.size.y >> 1))) * 0.001;
            rot_z += @intToFloat(f32, (_x - (window.size.x >> 1))) * 0.001;
            sys.sdl.SDL_WarpMouseInWindow(window.sdl_window, window.size.x >> 1, window.size.y >> 1);
        }

        if (evs.getKeyUp(sys.sdl.SDL_SCANCODE_LALT))
            _ = sys.sdl.SDL_SetRelativeMouseMode(sys.sdl.SDL_FALSE);

        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_W)) new_y = 0.1;
        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_A)) new_x = -0.1;
        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_S)) new_y = -0.1;
        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_D)) new_x = 0.1;

        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_L)) rot_z += 0.04;
        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_J)) rot_z -= 0.04;
        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_I)) rot_x += 0.04;
        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_K)) rot_x -= 0.04;
        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_Q)) rot_y += 0.04;
        if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_E)) rot_y -= 0.04;

        const speed_mod: f32 = if (evs.getKeyHeld(sys.sdl.SDL_SCANCODE_LSHIFT)) 20.0 else 0.3;

        if (evs.getKeyDown(sys.sdl.SDL_SCANCODE_SPACE))
            gls.toggleWireFrame();

        var cam_rot = cms.convQuatToEul(camera.euclid.quaternion);

        camera.euclid.position =
            camera.euclid.position.addAxial(.{
            .x = (new_x * @cos(cam_rot[2]) + new_y * @sin(cam_rot[2])) * speed_mod,
            .y = (new_y * @cos(cam_rot[2]) - new_x * @sin(cam_rot[2])) * speed_mod,
            .z = 0,
        });

        camera.euclid.position = pst.Position.init(camera.euclid.position.index(), .{
            .x = camera.euclid.position.axial().x,
            .y = camera.euclid.position.axial().y,
            .z = chk.getHeight(camera.euclid.position) + 1.75,
        });

        camera.euclid.quaternion =
            zmt.qmul(zmt.qmul(zmt.quatFromRollPitchYaw(0, 0, rot_z), camera.euclid.quaternion), zmt.quatFromRollPitchYaw(rot_x, rot_y, 0));

        cube.euclid.position = camera.euclid.position.addAxial(.{
            .x = 1,
            .y = 1,
            .z = -0.75 + @sin(@intToFloat(f32, sys.getEngineTick()) * 0.01) * 0.3,
        });

        const dist = camera.euclid.position.squareDistance(window.focal_point.position);
        if (dist > 128) {
            fcs.updateFocalPoint(&window.focal_point, camera.euclid.position);
        }

        cube.euclid.quaternion = zmt.qmul(cube.euclid.quaternion, zmt.quatFromRollPitchYaw(0.01, 0.02, 0.03));
        // TODO replace with proper clock timing
        sys.sdl.SDL_Delay(15);
    }
}
