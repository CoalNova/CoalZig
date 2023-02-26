const std = @import("std");
const zdl = @import("zdl");
const zgl = @import("zgl");
const wnd = @import("../coaltypes/window.zig");
const rpt = @import("../coaltypes/report.zig");
const cat = rpt.ReportCatagory;

pub fn renderWindow(window : *const wnd.Window) void
{
    switch (window.window_type) {
         wnd.WindowType.hardware=> renderHardware(window),
         else => {},
    }
}
    

fn renderHardware(window : *const wnd.Window) void
{
    _ = zdl.gl.makeCurrent(window.sdl_window, window.gl_context) catch |err| std.debug.print("{!}\n", .{err});
    zgl.clear(zgl.COLOR_BUFFER_BIT | zgl.DEPTH_BUFFER_BIT);
    var window_size = zdl.Window.getSize(window.sdl_window);
    zgl.viewport(0, 0, window_size[0], window_size[1]);
    
    zdl.gl.swapWindow(window.sdl_window);
    
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