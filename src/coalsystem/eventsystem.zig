const std = @import("std");
const sys = @import("../coalsystem/coalsystem.zig");
const wnd = @import("../coaltypes/window.zig");
const alc = @import("../coalsystem/allocationsystem.zig");
const rpt = @import("../coaltypes/report.zig");
const sdl = sys.sdl;

/// The states available to the various inputs
/// TODO provide input axis and phase support
pub const InputStates = enum(u2) { down, held, up, off };

/// The struct for an 'input'
/// TODO expand to handle stick/axis, event, and other inputs
pub const Input = struct {
    scancode: sdl.SDL_Scancode = sdl.SDL_SCANCODE_UNKNOWN,
    state: InputStates = InputStates.off,
};

// collection of inputs
var inputs: [32]Input = [_]Input{.{}} ** 32;

/// Run through SDL events and handle inputs
pub fn processEvents() void {
    var event: sdl.SDL_Event = undefined;

    // process key states
    for (&inputs) |*input| {
        if (input.state == InputStates.down) {
            input.state = InputStates.held;
        } else if (input.state == InputStates.up) {
            input.state = InputStates.off;
        }
    }

    while (sdl.SDL_PollEvent(&event) != 0) {

        // check if quit
        switch (event.type) {
            sdl.SDL_QUIT => sys.setEngineStateFlag(sys.EngineFlag.ef_quitflag),
            sdl.SDL_KEYUP => {
                rls_blk: for (&inputs) |*input|
                    if (input.scancode == event.key.keysym.scancode and
                        (input.state == InputStates.down or input.state == InputStates.held))
                    {
                        input.state = InputStates.up;
                        break :rls_blk;
                    };
            },
            sdl.SDL_KEYDOWN => {
                prs_blk: {
                    //find existing scancode
                    for (&inputs) |*input| {
                        if (input.scancode == event.key.keysym.scancode) {
                            if (input.state != InputStates.held)
                                input.state = InputStates.down;
                            break :prs_blk;
                        }
                    }
                    //create new entry from first unused or 'off' input
                    for (&inputs) |*input| {
                        if (input.state == InputStates.off) {
                            input.scancode = event.key.keysym.scancode;
                            input.state = InputStates.down;
                            break :prs_blk;
                        }
                    }
                }
            },
            else => {},
        }
    }
}

/// Returns if the key of the provided scancode is of the provided state
pub fn matchKeyState(scancode: sdl.SDL_Scancode, input_state: InputStates) bool {
    for (inputs) |input|
        if (input.scancode == scancode and input.state == input_state)
            return true;
    return false;
}

pub inline fn getKeyDown(scancode: sdl.SDL_Scancode) bool {
    return matchKeyState(scancode, InputStates.down);
}
pub inline fn getKeyHeld(scancode: sdl.SDL_Scancode) bool {
    return matchKeyState(scancode, InputStates.held);
}
pub inline fn getKeyUp(scancode: sdl.SDL_Scancode) bool {
    return matchKeyState(scancode, InputStates.up);
}

pub const IExecutor = struct {
    executeFn: fn (*IExecutor) void,
    pub fn execute(executor: *IExecutor) void {
        return executor.executeFn(executor);
    }
};

var perFrameExecutors: std.ArrayList(*IExecutor) = undefined;
pub fn initPerFrameExecutors() void {
    perFrameExecutors = std.ArrayList(*IExecutor).init(alc.gpa_allocator);
}
/// Executes all subscribed functors
pub fn executePerFrame() void {
    for (perFrameExecutors) |executor| executor.executeFn();
}
pub fn subscribePerFrame(executor: *IExecutor) !void {
    perFrameExecutors.append(executor) catch |err|
        {
        const cat = @enumToInt(rpt.ReportCatagory.level_error) |
            @enumToInt(rpt.ReportCatagory.scripting) |
            @enumToInt(rpt.ReportCatagory.memory_allocation);
        rpt.logReportInit(cat, 101, [4]i32{ perFrameExecutors.items.len, 0, 0, 0 });
        return err;
    };
}
pub fn unsubscribePerFrame(executor: *IExecutor) void {
    if (perFrameExecutors.items.len == 1) {
        perFrameExecutors.clearAndFree();
        return;
    }
    for (perFrameExecutors, 0..) |e, i|
        if (e == executor) {
            perFrameExecutors.items[i] = perFrameExecutors.pop();
            return;
        };

    const cat = @enumToInt(rpt.ReportCatagory.level_error) |
        @enumToInt(rpt.ReportCatagory.scripting);
    rpt.logReportInit(cat, 301, [4]i32{ perFrameExecutors.items.len, 0, 0, 0 });
}

var iterativeExecutors = std.ArrayList(*IExecutor);
var iterativeIndexer: usize = 0;
pub fn initIterativeExecutors() void {}
/// Runs execution serialy
pub fn executeIterative() void {}

var balancedExecutors: []std.ArrayList(*IExecutor) = undefined;
pub fn initBalancedExecutors() void {}
/// Spreads execution over a predefined series of balanced
/// The argument is an index
pub fn executeBalanced() void {}
