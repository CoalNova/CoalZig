const std = @import("std");
const zdl = @import("zdl");
const alc = @import("../coalsystem/allocationsystem.zig");
const evs = @import("../coalsystem/eventsystem.zig");
const rpt = @import("../coaltypes/report.zig");
const wnd = @import("../coaltypes/window.zig");
const rnd = @import("../coalsystem/rendersystem.zig");


// The current tic of the engine,
// used for logging and perhaps indescriminately timed occurances
var engine_tick: usize = 0;

// the current engine state
// seperate from any game event, this tracks engine specific details
var engine_state: u16 = 0;

/// Engine Flags are operational guidelines for any special engine operations
/// TODO attempt to conceptualize necessary engine modes required
pub const EngineFlag = enum(u16) {
    ef_quitflag = 0b0000_0000_0000_0001,
    ef_term_option = 0b0000_0000_0000_0010,
    ef_execute_render = 0b0000_0000_0000_0100,
    ef_process_events = 0b0000_0000_0000_1000,
};

/// GL Initialization flag
pub var gl_initialized : bool = false;

var max_tex_layers : i32 = 0;
var max_tex_binds : i32 = 0;

pub fn setMax2DTexArrayLayers(max_tex_array_layers : i32) void 
{
    max_tex_layers = max_tex_array_layers;
}
pub fn setMaxTexBindingPoints(max_tex_bind_points : i32) void 
{
    max_tex_binds = max_tex_bind_points;
}

/// Starts the engine through systematic initialization of
/// SDL lib, initialization of memory, and other such processes
/// TODO system to handle engine component failure better than simply failing out
/// TODO get logging system in for engine specific behavior problems
/// TODO xml, json, or other meta file for initializing engine params
pub fn ignite() void {

    rpt.initLog() catch |err| 
    {
        std.debug.print("initialization of report log failed {!}\n", .{err});
        setEngineStateFlag(EngineFlag.ef_quitflag);
        return;
    };

    wnd.initWindowGroup() catch |err| 
    {
        std.debug.print("initialization of window group collection failed {!}\n", .{err});
        rpt.logReport(rpt.Report.init
        (
            @enumToInt(rpt.ReportCatagory.level_terminal) | @enumToInt(rpt.ReportCatagory.memory_allocation),
            31,
            [4]i32{0,0,0,0}, 
            engine_tick
        ));            
        setEngineStateFlag(EngineFlag.ef_quitflag);
        return;
    };

    zdl.init(zdl.InitFlags.everything) catch |err| 
    {
        std.debug.print("{!}\n", .{err});
        rpt.logReport(rpt.Report.init
        (
            @enumToInt(rpt.ReportCatagory.level_terminal) | @enumToInt(rpt.ReportCatagory.sdl_system),
            11, [_]i32{ 0, 0, 0, 0 }, engine_tick,
        ));
        setEngineStateFlag(EngineFlag.ef_quitflag);
        return;
    };

    rpt.logReport(rpt.Report.init
    (
        @enumToInt(rpt.ReportCatagory.level_information) | @enumToInt(rpt.ReportCatagory.sdl_system),
        10, [_]i32{ 0, 0, 0, 0 }, engine_tick,
    ));
    var name : [8]u8 = [_]u8{'a'} ** 8; 
    wnd.createWindow(wnd.WindowType.hardware, &name, .{ .w = 50, .x = 50, .y = 50, .z = 50 }) catch |err|
    {
        std.debug.print("Window generation failed: {!}\n", .{err});
        rpt.logReport(rpt.Report.init
        (
            @enumToInt(rpt.ReportCatagory.level_error) | @enumToInt(rpt.ReportCatagory.window_system),
            33,[4]i32{0,0,0,0}, engine_tick
        ));
    };
}

/// Shuts down the engine, deinitializes systems, and frees memory
/// TODO actualize quit states for error checking and handling "* stopped responding" on quit is unacceptable
pub fn douse() void {
    
    zdl.quit();
}

/// Retrieves a copy of the current engine tic
pub fn getEngineTick() usize {
    return engine_tick;
}

/// Retrieves a copy of the current engine state bit array
pub fn getEngineState() u16 {
    return engine_state;
}

/// Sets a flag on the engine state bit array
pub fn setEngineStateFlag(engine_flag: EngineFlag) void {
    engine_state |= @enumToInt(engine_flag);
}

/// Returns if the provided flag is set
pub fn getEngineStateFlag(engine_flag : EngineFlag) bool 
{
    return (@enumToInt(engine_flag) & engine_state) != 0;
}

//
pub fn runEngine() void 
{
    //update engine tick
    engine_tick +%= 1;

    //process events
    evs.processEvents();

    if (evs.matchKeyState(zdl.Scancode.escape, evs.InputStates.down))
        setEngineStateFlag(EngineFlag.ef_quitflag);

    // render
    for(wnd.getWindowGroup()) |window|
        if (window.window_type != wnd.WindowType.unused)
            rnd.renderWindow(&window);
    
    // wait, 
    // TODO replace with proper clock timing
    zdl.delay(15);
    std.debug.print("got here, too\n",.{});
    
}
