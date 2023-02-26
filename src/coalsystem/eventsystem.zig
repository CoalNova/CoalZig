const std = @import("std");
const zdl = @import("zdl");
const sys = @import("../coalsystem/coalsystem.zig");
const wnd = @import("../coaltypes/window.zig");

/// The states available to the various inputs
/// TODO provide input axis and phase support
pub const InputStates = enum(u2) { down, held, up, off };

/// The struct for an 'input'
/// TODO expand to handle stick/axis, event, and other inputs
pub const Input = struct 
{ 
    scancode : zdl.Scancode = zdl.Scancode.www, 
    state: InputStates = InputStates.off 
};

// collection of inputs
var inputs: [32]Input = [_]Input{.{}} ** 32;

/// Run through SDL events and handle inputs
pub fn processEvents() void {
    var event: zdl.Event = undefined;
    while (zdl.pollEvent(&event)) {
        
        // process key states
        for (&inputs) |*input| {
            if (input.state == InputStates.down) 
            {
                input.state = InputStates.held;
            }
            else if (input.state == InputStates.up)
            {
                input.state = InputStates.off;
            }
        }
        
        // check if quit
        _ = switch (event.type) {
            .quit => sys.setEngineStateFlag(sys.EngineFlag.ef_quitflag),
            .keyup =>
            {
                rls_blk:for (&inputs) |*input|
                    if (input.scancode == event.key.keysym.scancode and 
                        (input.state == InputStates.down or input.state == InputStates.held)) {
                        input.state = InputStates.up;
                        break:rls_blk;
                    };
            },
            .keydown => 
            {              
                prs_blk:
                {
                    //find existing scancode
                    for (&inputs) |*input| 
                    {
                        if (input.scancode == event.key.keysym.scancode)
                        {
                            if (input.state != InputStates.held)
                                input.state = InputStates.down;
                            break:prs_blk;
                        }    
                    }
                    //create new entry from first unused or 'off' input
                    for (&inputs) |*input|
                    {
                        if (input.state == InputStates.off)
                        {
                            input.scancode = event.key.keysym.scancode;
                            input.state = InputStates.down;
                            break:prs_blk;
                        }
                    }

                }

            },
            else => null,
        };
        
    }
}

/// Returns if the key of the provided scancode is of the provided state
pub fn matchKeyState(scancode: zdl.Scancode, input_state: InputStates) bool {
    for (inputs) |input|
        if (input.scancode == scancode and input.state == input_state)
            return true;
    return false;
}
