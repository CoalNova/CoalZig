const std = @import("std");
const sdl = @import("../coalsystem/coalsystem.zig").sdl;
const glw = @import("../coalsystem/coalsystem.zig").glw;
const wnd = @import("../coaltypes/window.zig");
const rpt = @import("../coaltypes/report.zig");
const cat = rpt.ReportCatagory;

pub fn renderWindow(window : *const wnd.Window) void
{
    switch (window.window_type) {
         wnd.WindowType.hardware=> renderHardware(window),
         wnd.WindowType.software=> renderSoftware(window),
         wnd.WindowType.textware=> renderTextware(window),
         wnd.WindowType.unused=> {},
    }
}
    

fn renderHardware(window : *const wnd.Window) void
{
    _ = sdl.SDL_GL_MakeCurrent(window.sdl_window, window.gl_context);
    glw.glClear(glw.GL_COLOR_BUFFER_BIT | glw.GL_DEPTH_BUFFER_BIT);
    
    glw.glViewport(0, 0, window.window_rect.w, window.window_rect.h);
    const tri = [_]f32{
        0.0, -1.0, -1.0, 0.0,
        1.0, -1.0, 0.0,
        0.0, 1.0, 0.0,
        };

    
    var vbo_id : u32 = 0;
    glw.__glewGenBuffers.?(1, &vbo_id);
    glw.__glewBindBuffer.?(glw.GL_ARRAY_BUFFER, vbo_id);
    glw.__glewBufferData.?(glw.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(tri[0])) * tri.len, &tri, glw.GL_STATIC_DRAW);

    glw.__glewEnableVertexAttribArray.?(0);
    glw.__glewBindBuffer.?(glw.GL_ARRAY_BUFFER, vbo_id);
    glw.__glewVertexAttribPointer.?(0,3,glw.GL_FLOAT,0,0,@intToPtr(*i1,1));

    glw.glDrawArrays(glw.GL_TRIANGLES, 0, 3); 
    
	glw.__glewDeleteBuffers.?(1, &vbo_id);
    sdl.SDL_GL_SwapWindow(window.sdl_window);
	_ = sdl.SDL_GL_SetSwapInterval(1);
}

fn renderSoftware(window : *const wnd.Window) void
{
    
    sdl.SDL_RenderPresent(window.sdl_renderer);
}

fn renderTextware(window : *const wnd.Window) void
{
    rpt.logReportInit(@enumToInt(cat.level_warning) | @enumToInt(cat.renderer), 1, [4]i32{0,0,0,0});
    _ = window;
}