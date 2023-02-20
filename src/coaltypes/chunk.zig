const std = @import("std");
const sys = @import("../coalsystem/coalsystem.zig");
const spt = @import("sprite.zig");
const asy = @import("../coalsystem/assetsystem.zig");
const alc = @import("../coalsystem/allocationsystem.zig");
const pst = @import("position.zig");
const fio = @import("../coalsystem/fileiosystem.zig");
const evs = @import("../coalsystem/eventsystem.zig");

/// The container struct for world chunk
/// will contain references to create/destroy/move setpieces and objects
/// based on OGD
pub const Chunk = struct {
    index: pst.pnt.Point3 = .{ .x = 0, .y = 0, .z = 0 },
    heights: []u16,
    height_mod: u8,
    ground_sprite: *spt.Sprite,
    loaded: bool,
};

/// Chunk map
var chunk_map: *Chunk = undefined;
var map_bounds: pst.pnt.Point3 = .{ .x = 0, .y = 0, .z = 0 };

pub fn initializeChunkMap(allocator: std.mem.Allocator, bounds: pst.pnt.Point3) !void {
    map_bounds = bounds;
    chunk_map = try allocator.alloc(Chunk, bounds.x * bounds.y);
}

/// Returns Chunk at provided Point3 index
///     or an Out of Bounds Chunk Access error if the index is so
/// The z axis of the Point3 is unused for chunk access at this time
///     and is implemented to avoid needing to downcast
pub fn getChunk(index: pst.pnt.Point3) !*Chunk {
    var chunk: *Chunk = undefined;
    if (index.x >= map_bounds.x or index.x < 0 or
        index.y >= map_bounds.y or index.y < 0)
    {
        return error{OutofBoundsChunkMapAccess};
    }
    chunk = try &chunk_map[index.x + index.y * map_bounds.x];
    return chunk;
}
