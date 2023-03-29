//! The Central System for Engine Operations
//! 
//!     Conceptually the hind-brain and spinal column of the engine, CoalStar
//! System should only concern itself with reacting to engine flags and 
//! delegating functions to subsystems/type-owned-functions.
//! 
//!     Currently the CoalStarSystem concerns itself with engine initialization, 
//! deinitialization, and engine frame operation. Eventually it will need to 
//! handle calling the thread system and communing with the various helpers. 
//! 

pub const glw = @cImport({@cInclude("GL/glew.h");});
pub const glm = @cImport({@cInclude("cglm/cglm.h");});
pub const sdl = @cImport({@cInclude("SDL2/SDL.h");});
const std = @import("std");
const alc = @import("../coalsystem/allocationsystem.zig");
const evs = @import("../coalsystem/eventsystem.zig");
const rpt = @import("../coaltypes/report.zig");
const wnd = @import("../coaltypes/window.zig");
const rnd = @import("../coalsystem/rendersystem.zig");
const fio = @import("../coalsystem/fileiosystem.zig");
const pnt = @import("../simpletypes/points.zig");
const fcs = @import("../coaltypes/focus.zig");
const chk = @import("../coaltypes/chunk.zig");
const gls = @import("../coalsystem/glsystem.zig");
const pst = @import("../coaltypes/position.zig");


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
    ef_gl_initialized = 0b0000_0000_0001_0000
};


// hardware env variables
pub var max_tex_layers : i32 = 0;
pub var max_tex_binds : i32 = 0;


pub fn ignite() void {

    rpt.initLog() catch |err| 
    {
        std.debug.print("initialization of report log failed {!}\n", .{err});
        setEngineStateFlag(EngineFlag.ef_quitflag);
        return;
    };

    wnd.initWindowGroup();

    if (sdl.SDL_Init(sdl.SDL_INIT_EVERYTHING) != 0)
    {
        rpt.logReport(rpt.Report.init
        (
            @enumToInt(rpt.ReportCatagory.level_terminal) | @enumToInt(rpt.ReportCatagory.sdl_system),
            11, [_]i32{ 0, 0, 0, 0 }, engine_tick,
        ));
        setEngineStateFlag(EngineFlag.ef_quitflag);
        return;
    }


    // read game meta header 
    var meta_header : fio.MetaHeader = fio.loadMetaHeader("");

    chk.initializeChunkMap(alc.gpa_allocator, pnt.Point3.init(1,1,1)) catch |err|
    {
        std.debug.print("map initialization failed {!}\n", .{err});
        setEngineStateFlag(EngineFlag.ef_quitflag);
        return;
    };

    //construct windows
    win_blk:for(meta_header.window_init_types) |window_type|
    {
        var window = wnd.createWindow(window_type, "CoalStar", pnt.Point4.init( 640, 480, 320, 240));
        if (window == null)
        {
            //window creation failed
            continue : win_blk;
        }

        if (window_type == wnd.WindowCategory.hardware and !getEngineStateFlag(EngineFlag.ef_quitflag))
        {
        
            gli_blk:
            {
                if (sdl.SDL_GL_MakeCurrent(window.?.sdl_window, window.?.gl_context) != 0)
                    break :gli_blk;
                gls.initalizeGL() catch
                    break : gli_blk;
                
                setEngineStateFlag(EngineFlag.ef_gl_initialized);
            }
            
        }

        if (window_type == wnd.WindowCategory.hardware or wnd.WindowCategory.software == window_type)
        {
            window.?.focal_point.position = pst.Position.init(.{}, .{});
            window.?.focal_point.active_chunks = [_]pnt.Point3{.{.x = -1, .y = -1, .z = 0}} ** 25;
            fcs.updateFocalPoint(&window.?.focal_point);
            window.?.camera.euclid.quaternion = @Vector(4, f32){0,0,0,1};
        }

    }

    rpt.logReport(rpt.Report.init
    (
        @enumToInt(rpt.ReportCatagory.level_information) | @enumToInt(rpt.ReportCatagory.sdl_system),
        10, [_]i32{ 0, 0, 0, 0 }, engine_tick,
    ));
}

/// Shuts down the engine, deinitializes systems, and frees memory
pub fn douse() void {

    wnd.deinitWindowGroup();
    sdl.SDL_Quit();
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

/// Processes and engine frame
/// Returns the inverse state of the quit flag
pub fn runEngine() bool 
{
    //update engine tick
    engine_tick +%= 1;

    //process events
    evs.processEvents();

    if (evs.matchKeyState(sdl.SDL_SCANCODE_ESCAPE, evs.InputStates.down))
        setEngineStateFlag(EngineFlag.ef_quitflag);



    //render
    for(wnd.getWindowGroup()) |window|
        rnd.renderWindow(window.?);
    
    
    // TODO replace with proper clock timing
    sdl.SDL_Delay(15);    

    return(!getEngineStateFlag(EngineFlag.ef_quitflag));
}
