const wnd = @import("../coaltypes/window.zig");
const sys = @import("coalsystem.zig");

var window : wnd.Window = .{};

/// returns the window object
/// TODO catch deinitialized state
pub fn getWindow() *wnd.Window
{
    return &window;
}

/// Creates and assigns the window to the prearranged "global" position
/// TODO arrange for varying window count
/// TODO manage GLContext for 3D implementation
pub fn createWindow() i32
{
    var rect = sys.sdl.SDL_Rect
    {   
        .w = 640,
        .h = 480,
        .x = 300,
        .y = 100
    };
    
    window = wnd.Window
    {
        .window__rect = rect,
        .sdl___window = sys.sdl.SDL_CreateWindow(
            "CoalZig", 
            rect.x, 
            rect.y,
            rect.w,
            rect.h, 
            sys.sdl.SDL_WINDOW_BORDERLESS),
        .sdl_renderer = sys.sdl.SDL_CreateRenderer(window.sdl___window, -1, sys.sdl.SDL_RENDERER_SOFTWARE),
        .wind_surface = sys.sdl.SDL_GetWindowSurface(window.sdl___window),
        .pixel_format = sys.sdl.SDL_GetWindowPixelFormat(window.sdl___window),
        .terr_surface = sys.sdl.SDL_CreateRGBSurfaceWithFormat(0, rect.w, rect.h, 64, window.pixel_format),
        .scne_surface = sys.sdl.SDL_CreateRGBSurfaceWithFormat(0, rect.w, rect.h, 64, window.pixel_format),
        .objc_surface = sys.sdl.SDL_CreateRGBSurfaceWithFormat(0, rect.w, rect.h, 64, window.pixel_format),
        .gui__surface = sys.sdl.SDL_CreateRGBSurfaceWithFormat(0, rect.w, rect.h, 64, window.pixel_format),
        
    };

    return 0;
}


/// Destroys the globally assigned window and its components
/// TODO catch possible error states
pub fn destroyWindow() u32
{
    sys.sdl.SDL_FreeSurface(window.gui__surface);
    sys.sdl.SDL_FreeSurface(window.objc_surface);
    sys.sdl.SDL_FreeSurface(window.scne_surface);
    sys.sdl.SDL_FreeSurface(window.terr_surface);
    sys.sdl.SDL_DestroyWindow(window.sdl___window);
    return 0;
}