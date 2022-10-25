const sys = @import("coalsystem/coalsystem.zig");
const evs = @import("coalsystem/eventsystem.zig");
const rns = @import("coalsystem/rendersystem.zig");
const wns = @import("coalsystem/windowsystem.zig");

pub fn main() !void 
{

    // Start system, exit if initialization failure
    if (sys.ignite() != 0)
        return;
    defer (sys.douse());
    
    // Main loop, all logic calls will be accessed through this
    while (!sys.getEngineStateFromFlag(sys.EngineFlag.ef_quitflag)) 
    {
        // Process SDL events
        evs.processEvents();


        // render 
        rns.softRender(wns.getWindow());
        sys.sdl.SDL_Delay(15);
    }
}

