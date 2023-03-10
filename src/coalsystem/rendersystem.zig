const std = @import("std");
const sys = @import("../coalsystem/coalsystem.zig");
const sdl = sys.sdl;
const zgl = @import("zgl");
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
    zgl.clear(zgl.COLOR_BUFFER_BIT | zgl.DEPTH_BUFFER_BIT);

    //reject error, embrace plowing through issues we don't care to address
    _ = sdl.SDL_GetWindowSize(window.sdl_window, &window.size.x, &window.size.y);
    zgl.viewport(0,0,window.size.x, window.size.y);
    
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