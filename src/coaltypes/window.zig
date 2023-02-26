const std = @import("std");
const zdl = @import("zdl");
const zgl = @import("zgl");
const sys = @import("../coalsystem/coalsystem.zig");
const alc = @import("../coalsystem/allocationsystem.zig");
const pnt = @import("../simpletypes/points.zig");
const fcs = @import("../coaltypes/focus.zig");
const rpt = @import("../coaltypes/report.zig");
const rct = rpt.ReportCatagory;

pub const WindowType = enum { software, hardware, textware, unused };

/// Window container struct that houses the SDL window,
/// render surfaces, renderer and local mouse position.
/// Will contain GLcontext and relevant GL handles for 3D
pub const Window = struct {
    window_type: WindowType = WindowType.unused,
    sdl_window: *zdl.Window = undefined,
    gl_context: zdl.gl.Context = undefined,
    mouse_position: [2]i32 = undefined,
    focal_point: ?*fcs.Focus = null,
};

var window_group : []Window = undefined;
var window_count: u16 = 0;

pub fn initWindowGroup() !void
{
    window_group = try alc.gpa_allocator.alloc(Window, 4);
}

pub fn getWindowGroup() []Window
{
    return window_group;
}

pub fn createWindow(window_type: WindowType, window_name: []const u8, rect: pnt.Point4) !void {

    var window: Window = .{};

    window.window_type = window_type;

    var flags: zdl.Window.Flags =.{};
    flags.resizable = true;
    
    if (window_type == WindowType.hardware) 
        flags.opengl = true;

    _ = window_name;
    
    window.sdl_window = try zdl.Window.create("CoalStar", rect.w, rect.x, rect.y, rect.z, flags);
    errdefer 
        zdl.Window.destroy(window.sdl_window);

    switch (window_type) {
        WindowType.hardware => {
            window.gl_context = try zdl.gl.createContext(window.sdl_window);
            
            if (!sys.gl_initialized)
            {
                try zdl.gl.makeCurrent(window.sdl_window, window.gl_context);
                try zgl.loadCoreProfile(zdl.gl.getProcAddress,3,3);
                
                zgl.enable(zgl.FRONT_AND_BACK);
                zgl.enable(zgl.FILL);
                zgl.enable(zgl.DEPTH_TEST);
                zgl.enable(zgl.BLEND);
                zgl.blendFunc(zgl.SRC_ALPHA, zgl.ONE_MINUS_SRC_ALPHA);
                zgl.depthFunc(zgl.LESS);
                zgl.clearColor(0.0, 0.0, 0.0, 1.0);

                var max_layers : i32 = 0;
                var max_points : i32 = 0;

                zgl.getIntegerv(zgl.MAX_ARRAY_TEXTURE_LAYERS, &max_layers);
                zgl.getIntegerv(zgl.MAX_TEXTURE_IMAGE_UNITS, &max_layers);
                
                try zdl.gl.setSwapInterval(1);
                sys.setMax2DTexArrayLayers(max_layers);
                sys.setMaxTexBindingPoints(max_points);
                sys.gl_initialized = true;
            }
        },
        WindowType.software => {},
        WindowType.textware => {},
        WindowType.unused => {}
    }

    window_count += 1;
    if (window_count > window_group.len) {
        var new_group = alc.gpa_allocator.alloc(Window, window_group.len * 2) catch |err| {
            std.debug.print("Allocation of increased window group failed: {!}\n", .{err});
            return;
        };
        for (window_group, 0..) |w, i| new_group[i] = w;
        alc.gpa_allocator.free(window_group);
        window_group = new_group;
    }
    window_group[window_count] = window;
}

pub fn destroyWindow(window : *Window) void
{
    switch(window.window_type)
    {
        WindowType.hardware =>
        zdl.gl.deleteContext(window.gl_context),
        WindowType.software => null,
        WindowType.textware => null,
        WindowType.unused => null
    }

    if (window.focal_point != null)
        alc.gpa_allocator.free(window.focal_point);

    zdl.destroyWindow(window.sdl_window);

    for(window_group, 0..) |w, i|
        if (&w == window)
        {  
            for(window_group, (i+1)..) |w_, i_|
                window_group[i_ - 1] = w_;
            window_count -= 1;

        };
    rpt.logReportInit(@enumToInt(rct.level_warning) | @enumToInt(rct.window_system), 33, [4]i32{0,0,0,0});
}
