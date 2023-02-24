const sys = @import("coalsystem/coalsystem.zig");

pub fn main() void 
{
    // Start system,
    sys.ignite();
    defer (sys.douse());

    while(!sys.getEngineStateFlag(sys.EngineFlag.ef_quitflag))
    {
        sys.runEngine();
    }

}
