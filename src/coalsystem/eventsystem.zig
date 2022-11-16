const sys = @import("coalsystem.zig");

/// The states available to the various inputs
/// TODO provide input axis and phase support
pub const InputStates = enum(u2) { inp_down, inp_stay, inp_up, inp_off };

/// The struct for an 'input'
/// TODO expand to handle stick/axis, event, and other inputs
pub const Input = struct
{
    scancode : sys.sdl.SDL_Scancode = undefined,
    input_state : InputStates = undefined
};

// collection of inputs
var inputs : [32]Input = [_]Input{.{.scancode = sys.sdl.SDL_SCANCODE_WWW, .input_state = InputStates.inp_off}} ** 32;

/// Run through SDL events and handle inputs
pub fn processEvents() void
{
    var sdl_event : sys.sdl.SDL_Event = undefined;
    while (sys.sdl.SDL_PollEvent(&sdl_event) != 0)
    {
        // check if quit
        if (sdl_event.type == sys.sdl.SDL_QUIT)
            sys.setEngineStateFlag(sys.EngineFlag.ef_quitflag);
        
        // process key states
        for(inputs) |input, index| 
        {
            if (input.input_state == InputStates.inp_down) inputs[index].input_state = InputStates.inp_stay;
            if (input.input_state == InputStates.inp_up)
            {
                inputs[index].input_state = InputStates.inp_off;
                inputs[index].scancode = sys.sdl.SDL_SCANCODE_WWW;
            } 
        }

        //check for any depressed keys
        if (sdl_event.type == sys.sdl.SDL_KEYDOWN)
        {
            var index_match : usize = inputs.len;
            var index_first : usize = inputs.len;
            for(inputs) |input, index|
            {
                if (input.scancode == sdl_event.key.keysym.scancode)
                    index_match = index;
                if (input.scancode == sys.sdl.SDL_SCANCODE_WWW and index_first == inputs.len)
                    index_first = index;
            } 

            if (index_match < inputs.len)
            {
                inputs[index_match].input_state = if (inputs[index_match].input_state != InputStates.inp_stay) 
                    InputStates.inp_down else inputs[index_match].input_state;
            }
            else if (index_first < inputs.len)
            {
                inputs[index_first].scancode = sdl_event.key.keysym.scancode; 
                inputs[index_first].input_state = InputStates.inp_down;
            }
        }
            
        
        // check for any released keys 
        if (sdl_event.type == sys.sdl.SDL_KEYUP)
            for(inputs) |input, index| 
                if (inputs[index].scancode == sdl_event.key.keysym.scancode and (input.input_state == InputStates.inp_down or input.input_state == InputStates.inp_stay))
                {
                    inputs[index].input_state = InputStates.inp_up;
                    break; 
                };
     
    }
}

/// Returns if the key of the provided scancode is of the provided state
pub fn matchKeyState(scancode : sys.sdl.SDL_Scancode, input_state : InputStates) bool
{
    for(inputs) |input|
        if (input.scancode == scancode and input.input_state == input_state)
            return true;
    return false;
}