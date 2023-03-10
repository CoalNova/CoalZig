//! The main entry point of the CoalStar Engine
//! 
//!     Any ops here should be abstract calls. Testing here must be temporary, 
//! and moved out once complete. Avoid cluttering with multiple test codes to 
//! avoid an ugly mess.
//! 
//!     File/Folder layout is such that: 
//! - 'Simpltypes' refers to files with types that have only member functions, 
//!    and do not utilize Imports.
//! - 'CoalTypes' are files which contain structs and many utility functions,
//!    both member and external. Each file should contain and implement info 
//!    relevant to that struct's operation. If ambiguity exists between 
//!    ownership of functions and systems, (such as with mesh implementation)
//!    the owner should be seen as the commonality (mesh owns functions).
//! - 'CoalSystem' contain no structs, or no struct is the focus of the file.
//!    Instead, the focus is on function implementations and systems. Systems
//!    focus on facilitation and providing solutions to structs or engine. The 
//!    suffix of 'system' is appended to denote useage, and prevent ambiguity 
//!    between itself and any implemented element (such as event).
//!        
//!     Imported files/libraries use a three-digit name to easily identify and
//! to not cause ambiguity by overlaping with any implemented... elements? 
//!     
//! 
//! 
const sys = @import("coalsystem/coalsystem.zig");
const fio = @import("coalsystem/fileiosystem.zig");
const wnd = @import("coaltypes/window.zig");
const pnt = @import("simpletypes/points.zig");
const std = @import("std");
const zgl = @import("zgl");
const alc = @import("coalsystem/allocationsystem.zig");

pub fn main() void 
{
    // Start system,
    sys.ignite();
    // Defer closing of system
    defer (sys.douse());

    var point = [_]f32{
        -0.8, -0.8, 0.0,
         0.8, -0.8, 0.0,
         0.0,  0.8, 0.0,
        }; 

    std.debug.print("got here\n", .{});
    std.debug.print("GL Error: {}\n", .{zgl.getError()});

    var vao : u32 = 0;
    var vbo : u32 = 0;
    zgl.genVertexArrays(1, &vao);
    zgl.bindVertexArray(vao);
    zgl.genBuffers(1, &vbo);
    zgl.bindBuffer(zgl.ARRAY_BUFFER, vbo);
    zgl.bufferData(zgl.ARRAY_BUFFER, @sizeOf(f32) * point.len, &point, zgl.STATIC_DRAW);

    //main loop
    while(sys.runEngine())
    {
        
    }
}
