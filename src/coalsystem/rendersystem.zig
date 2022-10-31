const std = @import("std");
const sys = @import("coalsystem.zig");
const sdl = sys.sdl;
const wns = @import("windowsystem.zig");
const wnd = @import("../coaltypes/window.zig");
const fcs = @import("../coaltypes/focus.zig");
const chk = @import("../coaltypes/chunk.zig");


/// Software renders the provided window.
/// TODO catch SDL returns and log errors
/// TODO track and update only what needs rendering 
pub fn softRender(window : *wnd.Window, focal_point : *fcs.Focus) void
{
    //_ = sdl.SDL_SetRenderDrawColor(window.sdl_renderer, 123, 128, 240, 255 );
    //_ = sdl.SDL_RenderClear(window.sdl_renderer);
    //_ = sdl.SDL_RenderPresent(window.sdl_renderer);
   renderSoftTerrain(window, focal_point);
    _ = sdl.SDL_BlitSurface(window.terr_surface, null, window.wind_surface, null);
    _ = sdl.SDL_UpdateWindowSurface(window.sdl___window);
}

/// Rendering subcomponent, specifically to render/update the terrain tiles
/// TODO depth rendering based on GetHeight(), screenspace-driven axial coords, zoom-level movement  
fn renderSoftTerrain(window : *wnd.Window, focal_point : *fcs.Focus) void
{
    const chunk : *chk.Chunk = chk.getChunk(focal_point.active_chunks[0]);
    var screen_rect = sdl.SDL_Rect{.h = 16, .w = 16, .x = 16, .y = 16};

    std.debug.assert( chunk.ground_sprite.surface.sdl_surface != null);
    std.debug.assert( window.terr_surface != null);
    
    _ = sdl.SDL_BlitSurface(chunk.ground_sprite.surface.sdl_surface, &chunk.ground_sprite.rect, window.terr_surface, &screen_rect);
}
