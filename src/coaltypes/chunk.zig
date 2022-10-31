const std = @import("std");
const pnt = @import("../simpletypes/points.zig");
const spt = @import("sprite.zig");
const asy = @import("../coalsystem/assetsystem.zig");
const alc = @import("../coalsystem/allocationsystem.zig");


// map of all chunks arranged linearly
// TODO utilize allocation for large chunk maps
const chunk_map_size = 5;
var chunk_map = [_]Chunk
{
    .{
        .index = undefined, 
        .heights = undefined, 
        .height_mod = 0, 
        .ground_sprite = undefined
    }
} ** (chunk_map_size * chunk_map_size);

/// The container struct for dimensional-relevant data
pub const Chunk = struct
{
    index : pnt.Point3 = .{.x = 0, .y = 0, .z = 0},
    heights : []u16,
    height_mod : u8,
    ground_sprite : *spt.Sprite
};

/// Verifies the supplied index can exist in the chunk map
pub fn chunkIndexIsValid(index : pnt.Point3) bool
{
    return index.x >= 0 and index.x < chunk_map_size and index.y >= 0 and index.y < chunk_map_size;
}

/// Returns a pointer to the chunk struct associated to the provided index
pub fn getChunk(index : pnt.Point3) *Chunk
{
    return &chunk_map[@intCast(usize, index.x + index.y * chunk_map_size)];
}

/// Loads chunk data, but does not perform any generation based on said data
pub fn loadChunk(index : pnt.Point3) !*Chunk
{
    const index_pos = @intCast(usize, index.x + index.y * chunk_map_size);

    chunk_map[index_pos].heights = try alc.gpa_allocator.alloc(u16,512 * 512);
    chunk_map[index_pos].ground_sprite = asy.getSprite(1);
    
    return &chunk_map[@intCast(usize, index.x + index.y * chunk_map_size)];
}

/// Deletes chunk data, but does not delete generated content based on said data 
/// TODO concept out a robust self-fulfilling deletion system to prevent orphaned resources
pub fn unloadChunk(index : pnt.Point3) void
{
    const index_pos = @intCast(usize, index.x + index.y * chunk_map_size);
    chunk_map[index_pos].height_mod = 0;
    alc.gpa_allocator.free(chunk_map[index_pos].heights);

}

/// Initialize chunk map, this will fill chunk default values, as well as assign correct index values
pub fn initializeChunkMap() void
{
    var y : i32 = 0;
    while (y < chunk_map_size) : ( y += 1)
    {

        var x : i32 = 0;
        while (x < chunk_map_size) : ( x += 1)
        {
            const index = pnt.Point3{.x = x, .y = y, .z = 0};
            getChunk(index).index =  index;
        }
    }
}