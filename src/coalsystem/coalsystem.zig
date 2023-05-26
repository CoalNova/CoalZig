//! The Central System for Engine Operations
//!
//!     Conceptually the hind-brain and spinal column of the engine, CoalStar
//! System should only concern itself with reacting to engine flags and
//! delegating functions to subsystems/type-owned-functions.
//!
//!     Currently the CoalStarSystem concerns itself with engine initialization,
//! deinitialization, and engine frame operation. Eventually it will need to
//! handle calling the thread system and possibly communing coordination.
//!
//!     The engine state flags are a collective u16 (maybe more in the future)
//! which track what flowpaths are available for engine processing. These
//! should include hardware rendering, software rendering, terminal
//! availability, event processing, execution processing, worldspace load
//! status, and more.
//!

pub const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});
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
const shd = @import("../coaltypes/shader.zig");

/// Engine Flags are operational guidelines for any special engine operations
/// MEBE validate if engine quit should be engine sustain,
///     and if engine state 0x0000 should be engine quit
pub const EngineFlag = enum(u16) {
    /// Engine Quit Flag (change tbd)
    ef_quitflag = 0b0000_0000_0000_0001,
    /// Terminal output is allowed
    ef_term_option = 0b0000_0000_0000_0010,
    /// OpenGL has been initialized
    ef_gl_initialized = 0b0000_0000_0000_0100,
    /// Worldspace has been initialized, and gameplay may begin
    ef_world_initialized = 0b0000_0000_0000_1000,
    /// Audio system initialized and ready to use
    ef_audio_initialized = 0b0000_0000_0001_0000,
    /// Gamepad priority (for features like rumble)
    ef_gpad_initialized = 0b0000_0000_0010_0000,
    /// Whether the engine has multiple threads available
    ef_multithread = 0b0000_0000_0100_0000,
    /// SDL Poll events are available
    ef_process_events = 0b0000_0001_0000_0000,
    /// Software Rendering is available
    ef_software_render = 0b0000_0010_0000_0000,
    /// Hardware Rendering is available
    ef_hardware_render = 0b0000_0100_0000_0000,
    /// Executor may commence
    ef_executor_live = 0b0001_0000_0000_0000,
    /// Ingame simulation may commence
    ef_timescale_live = 0b0010_0000_0000_0000,
    /// TBD External utility
    ef_integrated_ext = 0b0100_0000_0000_0000,
    /// Runs the engine in a safe-mode-esque system
    ef_debug_mode = 0b1000_0000_0000_0000,
};

// The current tic of the engine,
// used for logging and perhaps indescriminately timed occurances
var engine_tick: usize = 0;

// the current engine state
// seperate from any game event, this tracks engine specific details
var engine_state: u16 = 0;

var meta_header: fio.MetaHeader = undefined;

pub fn getMapName() []const u8 {
    return meta_header.map_name;
}

/// Basic initialization to prepare for engine ignition
/// Initializes memory allocation, engine-use collections
pub fn prepareStar() !void {
    rpt.initLog() catch |err| {
        std.debug.print("initialization of report log failed {!}\n", .{err});
        setEngineStateFlag(EngineFlag.ef_quitflag);
        return;
    };
    wnd.initWindowGroup();
    // read game meta header
    meta_header = fio.loadMetaHeader(alc.gpa_allocator);

    chk.initializeChunkMap(alc.gpa_allocator, meta_header.map_size) catch |err|
        {
        std.debug.print("map initialization failed {!}\n", .{err});
        setEngineStateFlag(EngineFlag.ef_quitflag);
        return;
    };

    shd.initializeShaders();
}

/// Releases all resources that had been initialized with prepare
pub fn releaseStar() void {
    alc.gpa_allocator.free(meta_header.map_name);
    shd.deinitializeShaders();
    wnd.deinitWindowGroup();
}

/// Ignition, initializes engine systems, SDL, and any related systems
pub fn igniteStar() void {
    if (sdl.SDL_Init(sdl.SDL_INIT_EVERYTHING) != 0) {
        rpt.logReport(rpt.Report.init(
            @enumToInt(rpt.ReportCatagory.level_terminal) | @enumToInt(rpt.ReportCatagory.sdl_system),
            11,
            [_]i32{ 0, 0, 0, 0 },
            engine_tick,
        ));
        setEngineStateFlag(EngineFlag.ef_quitflag);
        return;
    }

    //construct windows
    win_blk: for (meta_header.window_init_types) |window_type| {
        var window = wnd.createWindow(window_type, "CoalStar", pnt.Point4.init(640, 480, 320, 240));
        if (window == null) {
            //window creation failed
            continue :win_blk;
        }

        if (window_type == wnd.WindowCategory.hardware and !getEngineStateFlag(EngineFlag.ef_quitflag)) {
            gli_blk: {
                if (sdl.SDL_GL_MakeCurrent(window.?.sdl_window, window.?.gl_context) != 0)
                    break :gli_blk;
                gls.initalizeGL() catch
                    break :gli_blk;

                setEngineStateFlag(EngineFlag.ef_gl_initialized);
            }
        }

        //TODO disattach focalpoint updates from initialization
        if (window_type == wnd.WindowCategory.hardware or wnd.WindowCategory.software == window_type) {
            window.?.focal_point.position = pst.Position.init(.{ .x = -1, .y = -1, .z = 0 }, .{});
            window.?.focal_point.active_chunks = [_]pnt.Point3{.{ .x = -1, .y = -1, .z = 0 }} ** 25;
            fcs.updateFocalPoint(&window.?.focal_point, pst.Position.init(.{ .x = 34, .y = 31, .z = 0 }, .{}));
            window.?.camera.euclid.quaternion = @Vector(4, f32){ 0, 0, 0, 1 };
        }
    }

    rpt.logReport(rpt.Report.init(
        @enumToInt(rpt.ReportCatagory.level_information) | @enumToInt(rpt.ReportCatagory.sdl_system),
        10,
        [_]i32{ 0, 0, 0, 0 },
        engine_tick,
    ));
}

/// Shuts down the engine, deinitializes systems
pub fn douseStar() void {
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

/// Sets a flag on the engine state flags
///     please use caution
pub fn setEngineStateFlag(engine_flag: EngineFlag) void {
    engine_state |= @enumToInt(engine_flag);
}

/// Unsets a flag on the engine state flags
///     please use caution
pub fn unsetEngineStateFlag(engine_flag: EngineFlag) void {
    engine_state &= ~@enumToInt(engine_flag);
}

/// Returns if the supplied flag is set in the engine state flags
pub fn getEngineStateFlag(engine_flag: EngineFlag) bool {
    return (@enumToInt(engine_flag) & engine_state) != 0;
}

pub fn getMetaHeader() fio.MetaHeader {
    return meta_header;
}

/// Processes and engine frame
/// Returns the inverse state of the quit flag
pub fn runEngine() bool {
    //update engine tick
    engine_tick +%= 1;

    //process events
    evs.processEvents();

    if (evs.matchKeyState(sdl.SDL_SCANCODE_ESCAPE, evs.InputStates.down))
        setEngineStateFlag(EngineFlag.ef_quitflag);

    //render
    for (wnd.getWindowGroup()) |window|
        rnd.renderWindow(window.?);

    return (!getEngineStateFlag(EngineFlag.ef_quitflag));
}
