const std = @import("std");
const sys = @import("coalsystem.zig");
const sdl = sys.sdl;
const wns = @import("windowsystem.zig");
const wnd = @import("../coaltypes/window.zig");
const fcs = @import("../coaltypes/focus.zig");
const chk = @import("../coaltypes/chunk.zig");
const pst = @import("../coaltypes/position.zig");


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
    const sprite = chunk.ground_sprite;
    
    const wind__width = @divFloor(@intCast(i32, window.window__rect.w) , sprite.volume.x) + 1;
    const wind_height = @divFloor(@intCast(i32, window.window__rect.h) , sprite.volume.y) + 1;

    var screen_rect : sdl.SDL_Rect = undefined;
    var sprite_rect = sdl.SDL_Rect{.w = sprite.volume.x, .h = sprite.volume.z, .x = sprite.offset.x, .y = sprite.offset.y};

    var y : i32 = 0;
    while (y <= wind_height) : (y += 1)
    {
        var x : i32 = 0;
        while (x <= wind__width) : (x += 1)
        {

            var x_coord = @floatToInt(i32, focal_point.position.axial().x) + x - (wind__width >> 1) + y - (wind_height >> 1);
            var y_coord = @floatToInt(i32, focal_point.position.axial().y) + x - (wind__width >> 1) - y - (wind_height >> 1);
            _ = y_coord;
            _ = x_coord;
            screen_rect = sdl.SDL_Rect
                {
                    .h = 0, 
                    .w = 0, 
                    .x = -sprite.volume.x + x * sprite.volume.x + (y & 1) * (sprite.volume.x >> 1), 
                    .y = -sprite.volume.y + y * sprite.volume.y
                };
            _ = sdl.SDL_BlitSurface(sprite.surface.sdl_surface, &sprite_rect, window.terr_surface, &screen_rect);
        }
    } 

    
}
