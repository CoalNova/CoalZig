const std = @import("std");
const sys = @import("../coalsystem/coalsystem.zig");
const alc = @import("../coalsystem/allocationsystem.zig");
const pnt = @import("../simpletypes/points.zig");
const fcs = @import("../coaltypes/focus.zig");
const rpt = @import("../coaltypes/report.zig");
const sdl = sys.sdl;
const glw = sys.glw;
const rct = rpt.ReportCatagory;

pub const WindowType = enum { software, hardware, textware, unused };

/// Window container struct that houses the SDL window,
/// render surfaces, renderer and local mouse position.
/// Will contain GLcontext and relevant GL handles for 3D
pub const Window = struct {
    window_type: WindowType = WindowType.unused,
    sdl_window: ?*sdl.SDL_Window = undefined,
    sdl_renderer: ?*sdl.SDL_Renderer = undefined,
    gl_context: sdl.SDL_GLContext = undefined,
    window_rect: sdl.SDL_Rect = undefined,
    window_surface: ?*sdl.SDL_Surface = undefined,
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

pub fn createWindow(window_type: WindowType, window_name: [*c]u8, window_rect: pnt.Point4) !void {

    var window: Window = .{};

    window.window_type = window_type;

    var flags: u32 = sdl.SDL_WINDOW_RESIZABLE;
    if (window_type == WindowType.hardware) flags |= sdl.SDL_WINDOW_OPENGL;
    window.sdl_window = sdl.SDL_CreateWindow(window_name, window_rect.w, window_rect.x, window_rect.y, window_rect.z, flags);
 
    if (window.sdl_window == null)
        return;    

    switch (window_type) {
        WindowType.hardware => {
            window.gl_context = sdl.SDL_GL_CreateContext(window.sdl_window);
            window.window_surface = sdl.SDL_GetWindowSurface(window.sdl_window);
            if (!sys.gl_initialized)
            {
                std.debug.print("SetAttrib Version: {d}\n", .{sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_PROFILE_MASK, sdl.SDL_GL_CONTEXT_PROFILE_CORE)});
                std.debug.print("SetAttribMajor: {d}\n", .{sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MAJOR_VERSION, 3)});
                std.debug.print("SetAttribMinor: {d}\n", .{sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MINOR_VERSION, 3)});
                std.debug.print("SetAttribStencils: {d}\n", .{sdl.SDL_GL_SetAttribute(sdl.SDL_GL_STENCIL_SIZE, 8)});
                glw.glewExperimental = 1;

                std.debug.print("make current: {d}\n", .{sdl.SDL_GL_MakeCurrent(window.sdl_window, window.gl_context)});

                std.debug.print("glewing it together: {d}\n", .{glw.glewInit()});

                glw.glPolygonMode(glw.GL_FRONT_AND_BACK, glw.GL_FILL);
                glw.glEnable(glw.GL_DEPTH_TEST);
                glw.glEnable(glw.GL_BLEND);
                glw.glBlendFunc(glw.GL_SRC_ALPHA, glw.GL_ONE_MINUS_SRC_ALPHA);
                glw.glDepthFunc(glw.GL_LESS);
                glw.glClearColor(0.0, 0.0, 0.0, 1.0);
               
                var max_layers : i32 = 0;
                var max_points : i32 = 0;
                glw.glGetIntegerv(glw.GL_MAX_ARRAY_TEXTURE_LAYERS, &max_layers);
                glw.glGetIntegerv(glw.GL_MAX_TEXTURE_IMAGE_UNITS, &max_points);
                sys.setMax2DTexArrayLayers(max_layers);
                sys.setMaxTexBindingPoints(max_points);
                sys.gl_initialized = true;
            }
        },
        WindowType.software => {
            window.sdl_renderer = sdl.SDL_CreateRenderer(window.sdl_window, -1, sdl.SDL_RENDERER_SOFTWARE | sdl.SDL_RENDERER_PRESENTVSYNC);
        },
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
        sdl.SDL_GL_DeleteContext(window.gl_context),
        WindowType.software =>
        sdl.SDL_DestroyRenderer(window.sdl_renderer),
        WindowType.textware =>
        null,
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
    rpt.logReportInit(@enumToInt(rct.level_warning) | @enumToInt(rct.window_system), 33, [4]i32{0,0,0,0});
}
