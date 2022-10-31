const sdl = @import("../coalsystem/coalsystem.zig").sdl;
const srf = @import("surface.zig");


/// A surface sprite to use in software rendering
/// the sprite ID and surface ID relate in that 
/// a surface has a possible sum of 256 possible 
/// sprites, the sprite and surface IDs reflect 
/// that combo
pub const Sprite = struct
{
    surface : *srf.Surface = undefined,
    rect : sdl.SDL_Rect = .{.x = 0, .y = 0, .h = 16, .w = 16},
    sprite_id : u32 = 999999999,
    subscribers : u32 = 0
};