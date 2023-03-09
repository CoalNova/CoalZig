//! Window is the catchall for the Window struct
//! 
//!     Each window exist under the indow struct, and should allow for 
//! hardware, software, "textware", and other styles of window. 
//! 
//! Hardware: Utlizies GL renderer to generate the world and UI.
//! Software: Utilizes SDL software renderer to draw iso world.
//! Textware: Utilizes SDL software renderer to draw software UI.
//! 
//!     A window will house the focus, as the focus will cascadingly reference 
//! data linked to that window's glcontext

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

pub const WindowType = enum(u8) { 
    unused = 0x00, software = 0x01, hardware = 0x02, textware = 0x03 };

/// Window container struct that houses the SDL window,
/// render surfaces, renderer and local mouse position.
/// Will contain GLcontext and relevant GL handles for 3D
pub const Window = struct {
    window_type: WindowType = WindowType.unused,
    sdl_window: ?*sdl.SDL_Window = null,
    gl_context: sdl.SDL_GLContext = undefined,
    sdl_renderer: ?*sdl.SDL_Renderer = null,
    window_surface: [*c]sdl.SDL_Surface = null,
    mouse_position: [2]i32 = [_]i32{0,0},
    focal_point: fcs.Focus = .{},
};

var window_group : []?Window = undefined;
var window_count: u16 = 0;

pub fn initWindowGroup() !void
{
    window_group = try alc.gpa_allocator.alloc(?Window, 4);
    for (0..4) |index|
        window_group[index] = null;
}

//TODO windowID? 
pub fn getWindow(window_type : WindowType) ?Window
{
    for(window_group) |window|
    {
        if (window != null)
            if (window.?.window_type == window_type)
                return window;
    }
    return null;
}

pub fn getWindowGroup() []?Window
{
    return window_group;
}

pub fn getWindowCount() u16
{
    return window_count;
}

const WindowError = error {
    ErrorWindowNull,
    ErrorWindowFlag,
    ErrorGLContext,
    ErrorSoftRenderer
};

pub fn createWindow(window_type: WindowType, window_name: []const u8, rect: pnt.Point4) ?Window {

    //catch eronius request first
    if (window_type == WindowType.unused)
        return null;

    var window: Window = .{};

    window.window_type = window_type;

    var flags: sdl.SDL_WindowFlags = sdl.SDL_WINDOW_RESIZABLE;
    
    if (window_type == WindowType.hardware) 
        flags |= sdl.SDL_WINDOW_OPENGL;

    window.sdl_window = sdl.SDL_CreateWindow(@ptrCast([*c]const u8, window_name), rect.y, rect.z, rect.w, rect.x, flags);
    if (window.sdl_window == null)
        return null;

    errdefer 
        sdl.SDL_DestroyWindow(window.sdl_window);

    switch (window_type) {
        WindowType.hardware => 
        {
            window.gl_context = sdl.SDL_GL_CreateContext(window.sdl_window);
        },
        WindowType.software => 
        {
            window.sdl_renderer = sdl.SDL_CreateRenderer(window.sdl_window, -1, sdl.SDL_RENDERER_SOFTWARE);
            if (window.sdl_renderer == null)
                return null;
            
            window.window_surface = sdl.SDL_GetWindowSurface(window.sdl_window);
        },
        WindowType.textware => {},
        WindowType.unused => {}
    }

    if (window_count > window_group.len) {
        var new_group = alc.gpa_allocator.alloc(?Window, window_group.len * 2) catch |err| {
            std.debug.print("Allocation of increased window group failed: {!}\n", .{err});
            return null;
        };
        for (window_group, 0..) |w, i| new_group[i] = w;
        alc.gpa_allocator.free(window_group);
        window_group = new_group;
    }
    window_group[window_count] = window;
    window_count += 1;

    return window;
}

pub fn destroyWindowGroup() void
{
    for(0..window_count) |index|
    {
        if (window_group[index] != null)
        {
            switch(window_group[index].?.window_type)
            {
                WindowType.hardware =>
                    sdl.SDL_GL_DeleteContext(window_group[index].?.gl_context),
                WindowType.software =>
                    sdl.SDL_DestroyRenderer(window_group[index].?.sdl_renderer),
                WindowType.textware => {},
                WindowType.unused => {}
            }

            sdl.SDL_DestroyWindow(window_group[index].?.sdl_window);
            window_group[index] = null;
        }
    }
    window_count = 0;
}

pub fn destroyWindow(window : *Window) void
{   switch(window.window_type)
    {
        WindowType.hardware =>
            sdl.SDL_GL_DeleteContext(window.gl_context),
        WindowType.software =>
            sdl.SDL_DestroyRenderer(window.renderer),
        WindowType.textware => {},
        WindowType.unused => {}
    }

    if (window.focal_point != null)
        alc.gpa_allocator.free(window.focal_point);

    sdl.SDL_DestroyWindow(window.sdl_window);

    for(window_group, 0..) |w, i|
        if (&w == window)
        {  
            for(window_group, (i+1)..) |w_, i_|
                window_group[i_ - 1] = w_;
            window_count -= 1;
        };
    rpt.logReportInit(@enumToInt(rct.level_information) | @enumToInt(rct.window_system), 33, [4]i32{0,0,0,0});
}
