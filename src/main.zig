const std = @import("std");
const sys = @import("coalsystem/coalsystem.zig");
const evs = @import("coalsystem/eventsystem.zig");
const rns = @import("coalsystem/rendersystem.zig");
const wns = @import("coalsystem/windowsystem.zig");
const fcs = @import("coaltypes/focus.zig");
const pst = @import("coaltypes/position.zig");
const chk = @import("coaltypes/chunk.zig");
const fio = @import("coalsystem/fileiosystem.zig");

test "draw" {
    std.debug.print("\n", .{});
    var y: i32 = 0;
    while (y <= 6) : (y += 1) {
        var x_span = y * 6 - y * y;
        var x: i32 = 0;
        while (x <= ((6 - x_span) >> 1) + 1) : (x += 1) {
            std.debug.print("  ", .{});
        }
        x = 0;
        while (x <= x_span) : (x += 1) {
            std.debug.print(". ", .{});
        }
        std.debug.print("\n", .{});
    }
}

test "position accuracy" {
    var starter = pst.vct.Vector3.init(64, 64, 64);
    var taker = pst.Position.init(.{}, starter);

    std.debug.assert(taker.axial().x == starter.x);
}

pub fn main() !void {
    // Start system, exit if initialization failure
    if (sys.ignite() != 0)
        return;
    defer (sys.douse());

    // the focal point used for the system
    // TODO establish and finalize a relationship between focus and window
    var focus = fcs.Focus{};
    focus.position = pst.Position.init(.{ .x = 4, .y = 4, .z = 0 }, .{ .x = 512.0, .y = 512.0, .z = 0 });
    focus.range = 32;

    fcs.updateFocalPoint(&focus);

    // DEBUG
    try chk.applyNewHeightMap(try fio.loadBMP());

    // Main loop, all logic calls will be accessed through this
    while (!sys.getEngineStateFromFlag(sys.EngineFlag.ef_quitflag)) {
        // Process SDL events
        evs.processEvents();

        var m: f32 = 0.03;

        if (evs.matchKeyState(sys.sdl.SDL_SCANCODE_LSHIFT, evs.InputStates.inp_stay))
            m = 1.3;

        if (evs.matchKeyState(sys.sdl.SDL_SCANCODE_W, evs.InputStates.inp_stay))
            focus.position = focus.position.addVec(pst.vct.Vector3.init(-m, m, 0.0));
        if (evs.matchKeyState(sys.sdl.SDL_SCANCODE_S, evs.InputStates.inp_stay))
            focus.position = focus.position.addVec(pst.vct.Vector3.init(m, -m, 0.0));
        if (evs.matchKeyState(sys.sdl.SDL_SCANCODE_A, evs.InputStates.inp_stay))
            focus.position = focus.position.addVec(pst.vct.Vector3.init(-m, -m, 0.0));
        if (evs.matchKeyState(sys.sdl.SDL_SCANCODE_D, evs.InputStates.inp_stay))
            focus.position = focus.position.addVec(pst.vct.Vector3.init(m, m, 0.0));

        std.debug.print("position: ({e}, {e}, {e})\n", .{ focus.position.axial().x, focus.position.axial().y, chk.getHeight(focus.position) });

        // render all portions of scene
        rns.softRender(wns.getWindow(), &focus);
        sys.sdl.SDL_Delay(30);
    }
}
