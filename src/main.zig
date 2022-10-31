const std = @import("std");
const sys = @import("coalsystem/coalsystem.zig");
const evs = @import("coalsystem/eventsystem.zig");
const rns = @import("coalsystem/rendersystem.zig");
const wns = @import("coalsystem/windowsystem.zig");
const asy = @import("coalsystem/assetsystem.zig");
const fcs = @import("coaltypes/focus.zig");
const chk = @import("coaltypes/chunk.zig");
const pnt = @import("simpletypes/points.zig");

pub fn main() !void 
{

    // Start system, exit if initialization failure
    if (sys.ignite() != 0)
        return;
    defer (sys.douse());
    
    // the focal point used for the system
    // TODO establish and finalize a relationship between focus and window
    var focus = fcs.Focus
    {
        .position = .
        { 
            .index = pnt.Point3.init(0,0,0), 
            .axial = .{.x = 512.0, .y = 512.0, .z = 512.0}
        }
    };

    // DEBUG BLOCK temporary chunk loading here to verify correctness of process
    var chunk : *chk.Chunk = try chk.loadChunk(focus.position.index);
    defer chk.unloadChunk(chunk.index);
    focus.active_chunks[0] = chunk.index;
    std.debug.print("0x{x}, 0x{x}\n", .{@ptrToInt(chk.getChunk(focus.active_chunks[0])), @ptrToInt(chunk)});
    std.debug.assert(chk.getChunk(focus.active_chunks[0]) == chunk);
    // END DEBUG BLOCK


    // Main loop, all logic calls will be accessed through this
    while (!sys.getEngineStateFromFlag(sys.EngineFlag.ef_quitflag)) 
    {
        // Process SDL events
        evs.processEvents();

        // render all portions of scene
        rns.softRender(wns.getWindow(), &focus);
        sys.sdl.SDL_Delay(15);
    }
}

