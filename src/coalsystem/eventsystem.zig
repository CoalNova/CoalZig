const sys = @import("coalsystem.zig");

/// 
pub fn processEvents() void
{
    var sdl_event : sys.sdl.SDL_Event = undefined;
    while (sys.sdl.SDL_PollEvent(&sdl_event) != 0)
    {
        if (sdl_event.type == sys.sdl.SDL_QUIT)
            sys.setEngineStateFlag(sys.EngineFlag.ef_quitflag);
        
        
    }
}