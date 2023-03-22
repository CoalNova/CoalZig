//! Window is the catchall for the Window struct
//! 
//!     Each window exist under the indow struct, and should allow for 
//! hardware, software, "textware", and other styles of window. 
//! 
//! Hardware: Utlizies GL renderer to generate the world and UI.
//! Software: Utilizes SDL software renderer to draw iso world.
//! Textware: Utilizes SDL software renderer to draw software UI.
//! 
//!     A window will house the Focus, and Camera as the focus will cascadingly
//! reference data linked to that window's glcontext, and camera is relevant to 
//! in-game projections.
//! 
//!     This is prone to change in the future as how to handle rendering. It
//! may be prudent to handle any window that handles worldspace rendering 
//! separate from UI, base text, etc. In this circumstance the Software and 
//! Hardware elements would need to be communal. This would allow for: 
//! (A)Selective render modes for computers with very low graphics overhead. 
//! (B)Mid-game swapping of perspectives to facilitate gameplay transitions.
//! 
//! 

const std = @import("std");
const sys = @import("../coalsystem/coalsystem.zig");
const alc = @import("../coalsystem/allocationsystem.zig");
const pnt = @import("../simpletypes/points.zig");
const fcs = @import("../coaltypes/focus.zig");
const rpt = @import("../coaltypes/report.zig");
const stp = @import("../coaltypes/setpiece.zig");
const msh = @import("../coaltypes/mesh.zig");
const shd = @import("../coaltypes/shader.zig");
const rct = rpt.ReportCatagory;
const sdl = sys.sdl;
const cam = @import("../coaltypes/camera.zig");

pub const WindowCategory = enum(u8) { 
    unused = 0x00, software = 0x01, hardware = 0x02, textware = 0x03 };

/// Window container struct that houses the SDL window,
/// render surfaces, renderer and local mouse position.
/// Will contain GLcontext and relevant GL handles for 3D
pub const Window = struct {
    category: WindowCategory = WindowCategory.unused,
    size : pnt.Point2 = .{},
    sdl_window: ?*sdl.SDL_Window = null,
    gl_context: sdl.SDL_GLContext = null,
    sdl_renderer: ?*sdl.SDL_Renderer = null,
    window_surface: [*c]sdl.SDL_Surface = null,
    mouse_position: [2]i32 = [_]i32{0,0},
    focal_point: fcs.Focus = .{},
    camera : cam.Camera = .{},
};

var window_group : std.ArrayList(?*Window) = undefined;

pub fn initWindowGroup() void
{
    window_group = std.ArrayList(?*Window).init(alc.gpa_allocator);
}
pub fn deinitWindowGroup() void
{
    for (window_group.items) |window|
        if (window != null)
        {
           switch(window.?.category)
            {
                WindowCategory.hardware =>
                    sdl.SDL_GL_DeleteContext(window.?.gl_context),
                WindowCategory.software =>
                    sdl.SDL_DestroyRenderer(window.?.sdl_renderer),
                WindowCategory.textware => {},
                WindowCategory.unused => {}
            }
            sdl.SDL_DestroyWindow(window.?.sdl_window);
            
            window.?.category = WindowCategory.unused;
        };
}


//TODO windowID? 
pub fn getWindow(category : WindowCategory) ?*Window
{
    for(window_group.items) |window|
    {
        if (window != null)
            if (window.?.category == category)
                return window;
    }
    return null;
}

/// Returns Window Group 
/// Treat as a temporary
pub fn getWindowGroup() []?*Window
{
    return window_group.items;
}

const WindowError = error {
    ErrorWindowNull,
    ErrorWindowFlag,
    ErrorGLContext,
    ErrorSoftRenderer
};

pub fn createWindow(category: WindowCategory, window_name: []const u8, rect: pnt.Point4) ?*Window {

    //catch eronius request first
    if (category == WindowCategory.unused)
        return null;

    var window: *Window = undefined;
    wnd_blk:
    {
        for (window_group.items) |w|
            if (w.?.category == WindowCategory.unused)
            {
                window = w.?;
                break : wnd_blk;
            };
        window = alc.gpa_allocator.create(Window) catch |err| {
            std.debug.print("window create err: {}\n", .{err});
            const cat : u16 = @enumToInt(rpt.ReportCatagory.level_error) &  @enumToInt(rpt.ReportCatagory.memory_allocation);
            rpt.logReportInit(cat, 101, [4]i32{0, 0, 0, 0});
            return null;
        };
        window_group.append(window) catch |err|
        {
            std.debug.print("window add err: {}\n", .{err});
            const cat : u16 = @enumToInt(rpt.ReportCatagory.level_error) &  @enumToInt(rpt.ReportCatagory.memory_allocation);
            rpt.logReportInit(cat, 101, [4]i32{0, 0, 0, 0});
            return null;
        };
    }

    window.category = category;

    var flags: sdl.SDL_WindowFlags = sdl.SDL_WINDOW_RESIZABLE;
    
    if (category == WindowCategory.hardware) 
        flags |= sdl.SDL_WINDOW_OPENGL;

    window.sdl_window = sdl.SDL_CreateWindow(@ptrCast([*c]const u8, window_name), rect.y, rect.z, rect.w, rect.x, flags);
    window.size = .{.x = rect.y, .y = rect.z};
    if (window.sdl_window == null)
        return null;

    errdefer 
        sdl.SDL_DestroyWindow(window.sdl_window);

    switch (category) {
        WindowCategory.hardware => 
        {
            window.gl_context = sdl.SDL_GL_CreateContext(window.sdl_window);
            window.camera = .{};
        },
        WindowCategory.software => 
        {
            window.sdl_renderer = sdl.SDL_CreateRenderer(window.sdl_window, -1, sdl.SDL_RENDERER_SOFTWARE);
            if (window.sdl_renderer == null)
                return null;
            
            window.window_surface = sdl.SDL_GetWindowSurface(window.sdl_window);
        },
        WindowCategory.textware => {},
        WindowCategory.unused => {}
    }

    return window;
}

pub fn destroyWindow(window : *Window) void
{   switch(window.category)
    {
        WindowCategory.hardware =>
            sdl.SDL_GL_DeleteContext(window.gl_context),
        WindowCategory.software =>
            sdl.SDL_DestroyRenderer(window.renderer),
        WindowCategory.textware => {},
        WindowCategory.unused => {}
    }

    if (window.focal_point != null)
        alc.gpa_allocator.free(window.focal_point);

    sdl.SDL_DestroyWindow(window.sdl_window);

    rpt.logReportInit(@enumToInt(rct.level_information) | @enumToInt(rct.window_system), 33, [4]i32{0,0,0,0});
}
