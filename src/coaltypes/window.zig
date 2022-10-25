const sdl = @import("../coalsystem/coalsystem.zig").sdl;

/// Window container struct that houses the SDL window,
/// render surfaces, renderer and local mouse position.
/// Will contain GLcontext and relevant GL handles for 3D
pub const Window = struct
{
    sdl___window : ?*sdl.SDL_Window = undefined,
    sdl_renderer : ?*sdl.SDL_Renderer = undefined,
    window__rect : sdl.SDL_Rect = undefined,
    pixel_format : u32 = undefined,
    wind_surface : ?*sdl.SDL_Surface = undefined,
    terr_surface : ?*sdl.SDL_Surface = undefined,
    scne_surface : ?*sdl.SDL_Surface = undefined,
    objc_surface : ?*sdl.SDL_Surface = undefined,
    gui__surface : ?*sdl.SDL_Surface = undefined,
    mouse_positn : [2]i32 = undefined,
};