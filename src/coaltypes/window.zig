const sdl = @import("../coalsystem/coalsystem.zig").sdl;

/// Window container struct that houses the SDL window,
/// render surfaces, renderer and local mouse position.
/// Will contain GLcontext and relevant GL handles for 3D
pub const Window = struct
{
    sdl_window : ?*sdl.SDL_Window = undefined,
    sdl_renderer : ?*sdl.SDL_Renderer = undefined,
    window_rect : sdl.SDL_Rect = undefined,
    pixel_format : u32 = undefined,
    window_surface : ?*sdl.SDL_Surface = undefined,
    terrain_surface : ?*sdl.SDL_Surface = undefined,
    scene_surface : ?*sdl.SDL_Surface = undefined,
    object_surface : ?*sdl.SDL_Surface = undefined,
    gui__surface : ?*sdl.SDL_Surface = undefined,
    mouse_position : [2]i32 = undefined,
    gl_context: *sdl.GLcontext,
};