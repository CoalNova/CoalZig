const std = @import("std");
const sdl = @import("../coalsystem/coalsystem.zig").sdl;
const alc = @import("../coalsystem/allocationsystem.zig");
const pnt = @import("../simpletypes/points.zig");
const fcs = @import("../coaltypes/focus.zig");

pub const WindowType = enum { software, hardware, textware };

/// Window container struct that houses the SDL window,
/// render surfaces, renderer and local mouse position.
/// Will contain GLcontext and relevant GL handles for 3D
pub const Window = struct {
    window_type: WindowType = WindowType.textware,
    sdl_window: ?*sdl.SDL_Window = undefined,
    sdl_renderer: ?*sdl.SDL_Renderer = undefined,
    gl_context: sdl.SDL_GLContext = undefined,
    window_rect: sdl.SDL_Rect = undefined,
    window_surface: ?*sdl.SDL_Surface = undefined,
    mouse_position: [2]i32 = undefined,
    focal_point: fcs.Focus = undefined,
};

var window_group : []Window = undefined;
var window_count: u16 = 0;

pub fn initWindowGroup() !void
{
    window_group = try alc.gpa_allocator.alloc(Window, 4);
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
        },
        WindowType.software => {
            window.sdl_renderer = sdl.SDL_CreateRenderer(window.sdl_window, -1, sdl.SDL_RENDERER_SOFTWARE | sdl.SDL_RENDERER_PRESENTVSYNC);
        },
        WindowType.textware => {}
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
    
}
