const std = @import("std");
const sys = @import("coalsystem.zig");
const sdl = sys.sdl;
const wns = @import("windowsystem.zig");
const wnd = @import("../coaltypes/window.zig");


/// Software renders the provided window.
/// TODO catch SDL returns and log errors
pub fn softRender(window : *wnd.Window) void
{
    _ = sdl.SDL_SetRenderDrawColor(window.sdl_renderer, 123, 128, 240, 255 );
    _ = sdl.SDL_RenderClear(window.sdl_renderer);
    _ = sdl.SDL_RenderPresent(window.sdl_renderer);
}