const std = @import("std");
const sys = @import("coalsystem/coalsystem.zig");

pub fn main() void 
{
    // Start system,
    sys.ignite();
    defer (sys.douse());

    while(!sys.getEngineStateFlag(sys.EngineFlag.ef_quitflag))
    {
        sys.runEngine();
        std.debug.print("{d}\n",.{sys.getEngineState()});
    }

}
