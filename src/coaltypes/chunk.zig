const std = @import("std");
const spt = @import("sprite.zig");
const asy = @import("../coalsystem/assetsystem.zig");
const alc = @import("../coalsystem/allocationsystem.zig");
const pst = @import("position.zig");


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
    index : pst.pnt.Point3 = .{.x = 0, .y = 0, .z = 0},
    heights : []u16,
    height_mod : u8,
    ground_sprite : *spt.Sprite
};

/// Verifies the supplied index can exist in the chunk map
pub fn chunkIndexIsValid(index : pst.pnt.Point3) bool
{
    return index.x >= 0 and index.x < chunk_map_size and index.y >= 0 and index.y < chunk_map_size;
}

/// Returns a pointer to the chunk struct associated to the provided index
pub fn getChunk(index : pst.pnt.Point3) *Chunk
{
    return &chunk_map[@intCast(usize, index.x + index.y * chunk_map_size)];
}

/// Loads chunk data, but does not perform any generation based on said data
pub fn loadChunk(index : pst.pnt.Point3) !*Chunk
{
    const index_pos = @intCast(usize, index.x + index.y * chunk_map_size);

    chunk_map[index_pos].heights = try alc.gpa_allocator.alloc(u16,512 * 512);
    chunk_map[index_pos].ground_sprite = asy.getSprite(1);
    
    return &chunk_map[@intCast(usize, index.x + index.y * chunk_map_size)];
}

/// Deletes chunk data, but does not delete generated content based on said data 
/// TODO concept out a robust self-fulfilling deletion system to prevent orphaned resources
pub fn unloadChunk(index : pst.pnt.Point3) void
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
            const index = pst.pnt.Point3{.x = x, .y = y, .z = 0};
            getChunk(index).index =  index;
        }
    }
}

pub fn getHeight(position : pst.Position) f32
{
    
    //check if requested height could exist
    if (!chunkIndexIsValid(position.index()))
        return 0.0;
    //check if chunk has loaded height data
    if (getChunk(position.index()).heights == null)
        return 0.0;
    const raw = position.raw;
    
    //check if requested height is rounded value
    if ((raw.x & ((1 << 18) - 1)) == 0 and (raw.y & ((1 << 18) - 1)) == 0)
    {
        //check if position indices are odd and interpolate if so
        if (((raw.x >> 18) & 1) == 1 and ((raw.y >> 18) & 1) == 1)
            return (
                getHeight(.{.raw = raw + @Vector(3, u64){1 << 18, 1 << 18, 0}}) +
                getHeight(.{.raw = raw + @Vector(3, u64){1 << 18, 0, 0} - @Vector(3, u64){0, 1 << 18, 0}}) +
                getHeight(.{.raw = raw - @Vector(3, u64){1 << 18, 1 << 18, 0}}) +
                getHeight(.{.raw = raw - @Vector(3, u64){1 << 18, 0, 0} + @Vector(3, u64){0, 1 << 18, 0}}) 
                ) / 4.0;
        if ((raw.x >> 18) & 1)
            return(
                getHeight(.{.raw = raw + @Vector(3, u64){1 << 18, 0, 0}}) +
                getHeight(.{.raw = raw - @Vector(3, u64){1 << 18, 0, 0}})
                ) / 2.0;
        if ((raw.y >> 18) & 1)
            return(
                getHeight(.{.raw = raw + @Vector(3, u64){0, 1 << 18, 0}}) +
                getHeight(.{.raw = raw - @Vector(3, u64){0, 1 << 18, 0}})
                ) / 2.0;
        //otherwise resolve directly
        var chunk = getChunk(position.index());
        //height data is stored in chunks using a major and minor value
        //the major value is the heightmod, which blanketly sets the base height at some value in an unsigned char * 1024.0f
        //the minor value is an unsigned short * 0.02f, keeping per-height accuracy down to 2 centimeters (or two-hundredths of chosen unit of measure)
        return chunk.heights[@floatToInt(i32, position.axial().x / 2.0) + @floatToInt(i32, (position.axial().y / 2.0) * 512)] * 0.02 + chunk.heightMod * 1024.0;
    }

    //else all, utilize the nearest points 

    // c | d
    // - - -
    // a | b

    raw = @Vector(3,u64){position.raw.x & (((1 << 18) - 1) << 14), position.raw.y & (((1 << 18) - 1) << 14), position.raw.z & (((1 << 18) - 1) << 14)};

    var a = getHeight(.{.raw = raw});
    var b = getHeight(.{.raw = raw + @Vector(3,u64){1 << 18, 0, 0}});
    var c = getHeight(.{.raw = raw + @Vector(3,u64){0, 1 << 18, 0}});
    var d = getHeight(.{.raw = raw + @Vector(3,u64){1 << 18, 1 << 18, 0}});

    //calculate ray plane slope intersection formula 
    var origin = pst.vct.Vector3
    {
        .x = @intToFloat(f32, (position.raw.x & ((1 << 18) - 1))) / @intToFloat(f32, 1 << 18), 
        .y = @intToFloat(f32, (position.raw.x & ((1 << 18) - 1))) / @intToFloat(f32, 1 << 18), 
        .z = 1
    };
    var ray = pst.vct.Vector3(0, 0, -1);
    var alpha : pst.vct.Vector3 = undefined;
    if (raw.x > raw.y)
    {
        alpha = .{.x = 1.0, .y = 0.0, .z = b - a};
    }
    else
    {
        alpha = .{ .x = 0.0, .y = 1.0, .z = c - a};
    }
    var gamma = pst.vct.Vector3{1, 1, d - a};
    var normal = alpha.badCross(gamma);

    var denom = normal.vectorDot(ray);
    var dist : f32 = 0.0;
    if (denom > 0.00001 or denom > 0.00001)
    {
        var inv = pst.vct.Vector3{.x = -origin.x, .y = -origin.y, .z = -origin.z};
        dist = inv.vectorDot(normal) / denom;
    }

    return @maximum(0.0, dist) + a;
    
}