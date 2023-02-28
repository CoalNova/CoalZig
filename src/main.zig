const sys = @import("coalsystem/coalsystem.zig");
const fio = @import("coalsystem/fileiosystem.zig");
const wnd = @import("coaltypes/window.zig");
const pnt = @import("simpletypes/points.zig");
const std = @import("std");

pub fn main() void 
{
    std.debug.print("{}\n", .{@sizeOf(bool)});

    // Start system,
    sys.ignite();
    // Defer closing of system
    defer (sys.douse());

    // read game meta header 
    var meta_header : fio.MetaHeader = fio.loadMetaHeader("");

    //construct windows
    for(meta_header.window_init_types) |window_type|
    {
        wnd.createWindow(window_type, "CoalStar", pnt.Point4.init(320, 240, 640, 480)) catch |err|
            std.debug.print("{}\n", .{err});
    }

    //main loop here for now, 
    //TODO coalsystem will need to divy to threadsystem
    while(!sys.getEngineStateFlag(sys.EngineFlag.ef_quitflag))
    {
        sys.runEngine();
    }
}
