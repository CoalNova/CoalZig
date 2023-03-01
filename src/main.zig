const sys = @import("coalsystem/coalsystem.zig");
const fio = @import("coalsystem/fileiosystem.zig");
const wnd = @import("coaltypes/window.zig");
const pnt = @import("simpletypes/points.zig");
const std = @import("std");

pub fn main() void 
{
    // Start system,
    sys.ignite();
    // Defer closing of system
    defer (sys.douse());

    //main loop here for now, 
    //TODO coalsystem will need to divy to threadsystem
    while(!sys.getEngineStateFlag(sys.EngineFlag.ef_quitflag))
    {
        sys.runEngine();
    }
}
