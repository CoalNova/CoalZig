const std = @import("std");
const sys = @import("../coalsystem/coalsystem.zig");
const sdl = sys.sdl;
const glw = sys.glw;
const wnd = @import("../coaltypes/window.zig");
const rpt = @import("../coaltypes/report.zig");
const cat = rpt.ReportCatagory;

pub fn renderWindow(window : *const ?wnd.Window) void
{
    if (window.* != null)
    {
        var w = window.*.?;
        switch (w.window_type) {
            wnd.WindowType.hardware=> renderHardware(&w),
            else => {},
        }
    }
}
    

fn renderHardware(window : *const wnd.Window) void
{
    if (sdl.SDL_GL_MakeCurrent(window.sdl_window, window.gl_context) != 0) 
    {
        //error here
        return;
    }
    glw.glClear(glw.GL_COLOR_BUFFER_BIT | glw.GL_DEPTH_BUFFER_BIT);
    //var window_size = sdl.SDL_GetWindowBordersSize.Window.getSize(window.sdl_window);
    //glw.Viewport(0, 0, window_size[0], window_size[1]);
    
    sdl.SDL_GL_SwapWindow(window.sdl_window);
    
}

fn renderSoftware(window : *const wnd.Window) void
{
    _ = window;
    
}

fn renderTextware(window : *const wnd.Window) void
{
    rpt.logReportInit(@enumToInt(cat.level_warning) | @enumToInt(cat.renderer), 1, [4]i32{0,0,0,0});
    _ = window;
}