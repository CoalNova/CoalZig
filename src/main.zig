const std = @import("std");
const sys = @import("coalsystem/coalsystem.zig");
const evs = @import("coalsystem/eventsystem.zig");
const rns = @import("coalsystem/rendersystem.zig");
const wns = @import("coalsystem/windowsystem.zig");
const fcs = @import("coaltypes/focus.zig");
const pst = @import("coaltypes/position.zig");

pub fn main() !void 
{

    // Start system, exit if initialization failure
    if (sys.ignite() != 0)
        return;
    defer (sys.douse());
    
    // the focal point used for the system
    // TODO establish and finalize a relationship between focus and window
    var focus = fcs.Focus{};
    focus.position = pst.Position.init(.{.x = 1, .y = 1, .z = 0}, .{.x = 512.0, .y = 512.0, .z = 0});
    focus.range = 32; 

    fcs.updateFocalPoint(&focus);

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

