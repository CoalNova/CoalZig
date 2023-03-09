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




    var vert_file = std.fs.cwd().openFile("shaders/debug_triangle.v.shader", .{}) catch |err|
    {
        std.debug.print("unable to open vertex file {}\n", .{err});
        return;
    };
    defer vert_file.close();

    var vert_source = vert_file.readToEndAlloc(alc.gpa_allocator, 65536) catch |err|
    {
        std.debug.print("unable to read vertex file {}\n", .{err});
        return;
    };
        //"#version 330 core\nlayout(location=0)in vec3 aPos;\nvoid main(){\ngl_Position=vec4(aPos.x,aPos.y,aPos.z,1.0f);}\x00";

    var frag_file = std.fs.cwd().openFile("shaders/debug_triangle.f.shader", .{}) catch |err|
    {
        std.debug.print("unable to open fragment file {}\n", .{err});
        return;
    };
    defer frag_file.close();

    var frag_source = frag_file.readToEndAlloc(alc.gpa_allocator, 65536) catch |err|
    {
        std.debug.print("unable to read fragment file {}\n", .{err});
        return;
    };
        //"#version 330 core\nout vec4 FragColor;\nvoid main(){\nFragColor = vec4(0.8f, 0.8f, 0.8f, 1.0f);}\x00";
    
    
    vert_source[vert_source.len - 1] = '\x00';
    frag_source[frag_source.len - 1] = '\x00';

    var vert_shader : u32 = zgl.createShader(zgl.VERTEX_SHADER);
    var frag_shader : u32 = zgl.createShader(zgl.FRAGMENT_SHADER);
    std.debug.print("{}\n\n", .{vert_source.len});
    zgl.shaderSource(vert_shader, 1, @ptrCast([*c]const [*c]const i8, &vert_source.ptr), null);
    std.debug.print("{}\n\n", .{frag_source.len});
    zgl.shaderSource(frag_shader, 1, @ptrCast([*c]const [*c]const i8, &frag_source.ptr), null);
    zgl.compileShader(vert_shader);
    zgl.compileShader(frag_shader);
    var shader_program : u32 = zgl.createProgram();
    zgl.attachShader(shader_program, vert_shader);
    zgl.attachShader(shader_program, frag_shader);
    zgl.linkProgram(shader_program);
    zgl.useProgram(shader_program);
    zgl.deleteShader(vert_shader);
    zgl.deleteShader(frag_shader);
    zgl.vertexAttribPointer(0,3,zgl.FLOAT, 0, 3 * @sizeOf(f32), null);
    zgl.enableVertexAttribArray(0);

    //main loop
    while(sys.runEngine())
    {
        zgl.clear(zgl.COLOR_BUFFER_BIT | zgl.DEPTH_BUFFER_BIT);
        //TODO implement non-engineframe related tasks here
        zgl.bindVertexArray(vao);
        zgl.drawArrays(zgl.TRIANGLES, 0, 3); 
        var err = zgl.getError();
        if (err != 0)
            std.debug.print("GL Error: {s}\n", .{sys.glw.glewGetErrorString(err)});
        var window = wnd.getWindow(wnd.WindowType.hardware).?;
        sys.sdl.SDL_GL_SwapWindow(window.sdl_window);
    
    }
}
