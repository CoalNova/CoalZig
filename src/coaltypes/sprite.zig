const sdl = @import("../coalsystem/coalsystem.zig").sdl;
const srf = @import("surface.zig");
const pnt = @import("../simpletypes/points.zig");


/// A surface sprite to use in software rendering the sprite ID and surface ID relate in that 
/// a surface has a possible sum of 256 possible sprites, the sprite and surface IDs reflect 
/// that combo. A sprite's dimensions are defined by width, length, and depth, as x, y, and z.
pub const Sprite = struct
{
    surface : *srf.Surface = undefined,
    volume : pnt.Point3 = .{.x = 0, .y = 0, .z = 0},
    offset : pnt.Point2 = .{.x = 0, .y = 0},
    id : u32 = 999999999,
    subscribers : u32 = 0
};