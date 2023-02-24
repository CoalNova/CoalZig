const std = @import("std");
const sys = @import("coalsystem.zig");
const sdl = sys.sdl;
const wns = @import("windowsystem.zig");
const wnd = @import("../coaltypes/window.zig");
const fcs = @import("../coaltypes/focus.zig");
const chk = @import("../coaltypes/chunk.zig");
const pst = @import("../coaltypes/position.zig");
const evs = @import("eventsystem.zig");

/// Software renders the provided window.
/// TODO catch SDL returns and log errors
/// TODO track and update only what needs rendering
pub fn softRender(window: *wnd.Window, focal_point: *fcs.Focus) void {
    // _ = sdl.SDL_SetRenderDrawColor(window.sdl_renderer, 123, 128, 240, 255 );
    // _ = sdl.SDL_RenderClear(window.sdl_renderer);
    // _ = sdl.SDL_RenderPresent(window.sdl_renderer);
    renderSoftTerrain(window, focal_point);
    _ = sdl.SDL_BlitSurface(window.terr_surface, null, window.wind_surface, null);
    _ = sdl.SDL_UpdateWindowSurface(window.sdl___window);
}

/// Rendering subcomponent, specifically to render/update the terrain tiles
/// TODO depth rendering based on GetHeight(), screenspace-driven axial coords, zoom-level movement
fn renderSoftTerrain(window: *wnd.Window, focal_point: *fcs.Focus) void {
    const chunk: *chk.Chunk = chk.getChunk(focal_point.active_chunks[0]);
    const sprite = chunk.ground_sprite;

    const wind__width = @divFloor(@intCast(i32, window.window__rect.w), sprite.volume.x) + 1;
    const wind_height = @divFloor(@intCast(i32, window.window__rect.h), sprite.volume.y) + 1;

    var screen_rect: sdl.SDL_Rect = undefined;
    var sprite_rect = sdl.SDL_Rect{ .w = sprite.volume.x, .h = sprite.volume.z, .x = sprite.offset.x, .y = sprite.offset.y };

    var axial = focal_point.position.axial();

    var s_off_x = @floatToInt(i32, @mod(axial.x, 1.0) * @intToFloat(f32, sprite.volume.x >> 1)) + @floatToInt(i32, @mod(axial.y, 1.0) * @intToFloat(f32, sprite.volume.x >> 1));
    var s_off_y = (sprite.volume.y >> 1) + @floatToInt(i32, @mod(axial.x, 1.0) * @intToFloat(f32, sprite.volume.y >> 1)) - @floatToInt(i32, @mod(axial.y, 1.0) * @intToFloat(f32, sprite.volume.y >> 1));

    const focal_height = @floatToInt(i32, chk.getHeight(focal_point.position) * @intToFloat(f32, sprite.volume.y));

    var y: i32 = 0;
    while (y <= (wind_height << 1)) : (y += 1) {
        var x: i32 = 0;
        while (x <= (wind__width << 1)) : (x += 1) {
            screen_rect = sdl.SDL_Rect{ .h = 0, .w = 0, .x = x * (sprite.volume.x >> 1) - y * sprite.volume.y + (wind__width >> 1) * sprite.volume.x - s_off_x, .y = y * (sprite.volume.y >> 1) + x * (sprite.volume.x >> 2) - (wind_height >> 1) * (sprite.volume.y >> 1) - s_off_y };

            if (screen_rect.x > -sprite.volume.x and screen_rect.x < window.window__rect.w + sprite.volume.x) {
                var s_vec = pst.vct.Vector3.init(@intToFloat(f32, (x - wind__width)), @intToFloat(f32, -(y - wind_height)), 0.0);
                s_vec = s_vec.add(focal_point.position.axial());
                var s_vex = pst.vct.Vector3.init(std.math.floor(s_vec.x), std.math.floor(s_vec.y), std.math.floor(s_vec.z));
                var s_pos = pst.Position.init(focal_point.position.index(), s_vex);
                var s_off = chk.getHeight(s_pos) * @intToFloat(f32, sprite.volume.y);

                screen_rect.y -= @floatToInt(i32, s_off);
                screen_rect.y += focal_height;
                _ = sdl.SDL_BlitSurface(sprite.surface.sdl_surface, &sprite_rect, window.terr_surface, &screen_rect);
            }
        }
    }
}
