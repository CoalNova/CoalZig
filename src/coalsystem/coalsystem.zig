pub const sdl = @cImport({@cInclude("SDL2/SDL.h");});
const std = @import("std");
const alc = @import("../coalsystem/allocationsystem.zig");
const rpt = @import("../coaltypes/report.zig");
const chk = @import("../coaltypes/chunk.zig");
const wnd = @import("../coaltypes/window.zig");


// The current tic of the engine,
// used for logging and perhaps indescriminately timed occurances
var engine_tick: usize = 0;

// the current engine state
// seperate from any game event, this tracks engine specific details
var engine_state: u32 = 0;

/// Engine Flags are operational guidelines for any special engine operations
/// TODO attempt to conceptualize necessary engine modes required
pub const EngineFlag = enum(u16) {
    ef_quitflag = 0b0000_0000_0000_0001,
    ef_term_option = 0b0000_0000_0000_0010,
    ef_execute_render = 0b0000_0000_0000_0100,
    ef_process_events = 0b0000_0000_0000_1000,
};

/// Starts the engine through systematic initialization of
/// SDL lib, initialization of memory, and other such processes
/// TODO system to handle engine component failure better than simply failing out
/// TODO get logging system in for engine specific behavior problems
/// TODO xml, json, or other meta file for initializing engine params
pub fn ignite() i32 {
    var startup_state: i32 = 0;

    startup_state = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
    if (startup_state != 0) {
        engine_state |= @enumToInt(EngineFlag.ef_quitflag);
        rpt.logReport(rpt.Report.init
            (
                @enumToInt(rpt.ReportType.level_terminal | rpt.ReportType.sdl_system),
                10,
                i32{0,0,0,0},
                engine_tick,
            ));
        return startup_state;
    }
    rpt.logReport(rpt.Report.init
        (
            @enumToInt(rpt.ReportType.level_information | rpt.ReportType.sdl_system),
            11,
            i32{0,0,0,0},
            engine_tick,
        ));

    chk.initializeChunkMap(alc.gpa_allocator);

    startup_state = wnd.createWindow();
    if (startup_state != 0) {
        return startup_state;
    }
    return startup_state;
}

/// Shuts down the engine, deinitializes systems, and frees memory
/// TODO actualize quit states for error checking and handling "* stopped responding" on quit is unacceptable
pub fn douse() void {
    _ = wnd.destroyWindow();
    sdl.SDL_Quit();
}

/// Increments engine tic, run only once per frame
pub fn incrementEngineTick() void {
    engine_tick +%= 1;
}

/// Retrieves a copy of the current engine tic
pub fn getEngineTick() usize {
    return engine_tick;
}

/// Retrieves a copy of the current engine state bit array
pub fn getEngineState() u32 {
    return engine_state;
}

/// Sets a flag on the engine state bit array
pub fn setEngineStateFlag(engine_flag: EngineFlag) void {
    engine_state |= @enumToInt(engine_flag);
}

/// Returns if the provided flag is set to true
pub fn getEngineStateFromFlag(engine_flag: EngineFlag) bool {
    return ((@enumToInt(engine_flag) & engine_state) != 0);
}
