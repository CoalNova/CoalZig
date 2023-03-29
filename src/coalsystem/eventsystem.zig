const std = @import("std");
const sys = @import("../coalsystem/coalsystem.zig");
const wnd = @import("../coaltypes/window.zig");
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
    while (sdl.SDL_PollEvent(&event) != 0) {

        // process key states
        for (&inputs) |*input| {
            if (input.state == InputStates.down) {
                input.state = InputStates.held;
            } else if (input.state == InputStates.up) {
                input.state = InputStates.off;
            }
        }

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
