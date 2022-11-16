const std = @import("std");
const sys = @import("coalsystem.zig");
const sdl = sys.sdl;
const spt = @import("../coaltypes/sprite.zig");
const srf = @import("../coaltypes/surface.zig");


// constants to assign as array pop initialization
const max_sprite_count = 4096;
const max_surface_count = 64;

// collections for assets
// TODO experiment with localizing these within the individual struct files
var sprites = [_]spt.Sprite{.{}} ** max_sprite_count;
var surfaces = [_]srf.Surface{.{}} ** max_surface_count;

/// Procures the sprite associated to the provided spriteID
/// Generates sprite if not yet loaded, increments subscriber count
/// TODO design/utilize a system like C++'s shared_ptr
pub fn getSprite(sprite_id : u32) *spt.Sprite
{
    //check if sprite is unloaded, or equals initialized value
    if(sprites[sprite_id].id == 999999999)
    {
        sprites[sprite_id] = spt.Sprite
        {
            .surface = getSurface(sprite_id >> 8),
            .volume = .{.x = 32, .y = 16, .z = 80},
            .offset = .{.x = 0, .y = 0},
            .id = sprite_id,
            .subscribers = 0,
        };
        //TODO sprite rect x/y offset procurement
        //TODO animated sprite ruleset
    }
    sprites[sprite_id].subscribers += 1;
    return &sprites[sprite_id];
}

/// Informs the system that the owned sprite is no longer in use. The
/// counter is decremented and if no longer needed (subscriber == 0)
/// then the resource is unloaded.
/// TODO determine a single word for "returning after use" that isn't either
/// a colloqualism for (take) or related to a keyword (return)
pub fn giveBackSprite(sprite : *spt.Sprite) void
{
    sprite.subscribers -= 1;
    if (sprite.subscribers == 0)
    {
        giveBackSurface(sprite.surface);
        sprites[sprite.id] = spt.Sprite{};
    }
}

/// Procures the SDL Surface associated to the provided surfaceID
/// Loads surface asset if not yet loaded, increments subscriber count
pub fn getSurface(surface_id : u32) *srf.Surface
{
    if (surfaces[surface_id].surface_id == 999999999)
    {
        // TODO use lut or loaded conf/xml for sprite reference metadata
        var surf_point = sdl.SDL_LoadBMP("./assets/ground.bmp");
        surfaces[surface_id] = srf.Surface
        {
            .sdl_surface = surf_point,
            .surface_id = surface_id,
            .subscribers = 0,
        };
    }
    surfaces[surface_id].subscribers += 1;
    return &surfaces[surface_id];
}

/// Decrements the surface usercount, removes if no longer in use
pub fn giveBackSurface(surface : *srf.Surface) void 
{
    surface.subscribers -= 0;
    if (surface.subscribers == 0)
    {
        sdl.SDL_FreeSurface(surface.sdl_surface);
        surfaces[surface.surface_id] = srf.Surface{};
    }
}