const std = @import("std");
const spt = @import("sprite.zig");
const asy = @import("../coalsystem/assetsystem.zig");
const alc = @import("../coalsystem/allocationsystem.zig");
const pst = @import("position.zig");
const fio = @import("../coalsystem/fileiosystem.zig");

/// The container struct for dimensional-relevant data
pub const Chunk = struct
{
    index : pst.pnt.Point3 = .{.x = 0, .y = 0, .z = 0},
    heights : []u16,
    height_mod : u8,
    ground_sprite : *spt.Sprite,
    loaded: bool
};
 
// map of all chunks arranged linearly
// TODO utilize allocation for large chunk maps
const chunk_map_size = 8;
var chunk_map = [_]Chunk
{
    .{
        .index = undefined, 
        .heights = undefined, 
        .height_mod = 0, 
        .ground_sprite = undefined,
        .loaded = false
    }
} ** (chunk_map_size * chunk_map_size);

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
    if (chunkIndexIsValid(index))
    {
        var chunk = getChunk(index);

        // TODO perform atomic check to prevent loading and unloading based on .loaded flag
        if (chunk.loaded == false)
        {
            chunk.loaded = true;

            _ = try fio.loadChunkHeightFile(chunk);
            chunk.ground_sprite = asy.getSprite(1);
        }
        return chunk;
    }
    // index validation should be performed before attempts at loading
    return error.InvalidChunkIndex;
}

/// Deletes chunk data, but does not delete generated content based on said data 
/// TODO concept out a robust self-fulfilling deletion system to prevent orphaned resources
pub fn unloadChunk(index : pst.pnt.Point3) void
{
    if (chunkIndexIsValid(index))
    {
        var chunk = getChunk(index);
        chunk.height_mod = 0;

        // TODO perform atomic check to prevent loading and unloading based on .loaded flag
        if (chunk.loaded == true)
        {
            alc.gpa_allocator.free(chunk.heights);
            chunk.loaded = false;
        }   
        
    }
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

    return @max(0.0, dist) + a;
}

pub fn applyNewHeightMap(bmp : fio.BMP) !void
{
    var diff_width : usize = @intCast(usize, @divFloor(bmp.width, chunk_map_size));
    var diff_length : usize = @intCast(usize, @divFloor(bmp.height, chunk_map_size));
    
    // put this here so we aren't wasting time reallocating it
    var heights = try alc.gpa_allocator.alloc(u32, 512 * 512);
    defer alc.gpa_allocator.free(heights);

    // for each chunk
    var cy : i32 = 0;
    while ( cy < chunk_map_size) : (cy += 1)
    {
        var cx : i32 = 0;
        while (cx < chunk_map_size) : (cx += 1)
        {
            var chunk = getChunk(.{.x = cx, .y = cy, .z = 0});
            if (chunk.loaded == false)
            {
                chunk.heights = try alc.gpa_allocator.alloc(u16, 512 * 512);
                chunk.loaded = true;
            }

            var lowest : u32 = ((1 << 32) - 1);

            // height entries per heightmap pixel
            var blit_width : usize = @divFloor(chunk_map_size * 512, bmp.width);
            var blit_length : usize = @divFloor(chunk_map_size * 512, bmp.height);

            //for each applicable height within
            var dy : usize = 0;
            while ( dy < diff_length) : (dy += 1)
            {
                var dx : usize = 0;
                while (dx < diff_width) : (dx += 1)
                {
                    
                    //values at multiplier of 20 will resolve to 0-5120
                    //the oceanic depth of 120m will leave 5km of elevation
                    //for pacmap, *40 may be preferred to achieve -120m to 10120m

                    var base : usize = (dx + @intCast(usize, cx) * diff_width + (dy + @intCast(usize, cy) * diff_length) *  bmp.width);
                    var over : usize = (dx + @intCast(usize, cx) * diff_width + 1 + (dy + @intCast(usize, cy) * diff_length) * bmp.width);
                    var uppr : usize = (dx + @intCast(usize, cx) * diff_width + (dy + @intCast(usize, cy) * diff_length + 1) * bmp.width);
                    var outr : usize = (dx + @intCast(usize, cx) * diff_width + 1 + (dy + @intCast(usize, cy) * diff_length + 1) * bmp.width);                    //height is such that the continental shelf sea-depth of 60-200m should be respected
                    
                    var a_height : u32 = @as(u32, bmp.px[@intCast(usize, base)]) * 20;
                    var b_height : u32 = if (over < bmp.width * bmp.height) @as(u32, bmp.px[@intCast(usize, over)]) * 20 else 0;
                    var c_height : u32 = if (uppr < bmp.width * bmp.height) @as(u32, bmp.px[@intCast(usize, uppr)]) * 20 else 0;
                    var d_height : u32 = if (outr < bmp.width * bmp.height) @as(u32, bmp.px[@intCast(usize, outr)]) * 20 else 0;

                    // c | d
                    // -----
                    // a | b

                    var iy : u32 = 0;
                    while (iy < blit_length) : (iy += 1)
                    {
                        var ix : u32 = 0;
                        while (ix < blit_width) : (ix += 1)
                        {
                            var mx : f32 = @intToFloat(f32, ix) / @intToFloat(f32, blit_width);
                            var my : f32 = @intToFloat(f32, iy) / @intToFloat(f32, blit_length);
                            
                            var a : f32 = @intToFloat(f32, a_height) * (1.0 - mx); 
                            var b : f32 = @intToFloat(f32, b_height) * mx; 
                            var c : f32 = @intToFloat(f32, c_height) * (1.0 - mx); 
                            var d : f32 = @intToFloat(f32, d_height) * mx;

                            var this_height : u32 = @floatToInt(u32, (a + b) * (1.0 - my) + (c + d) * my);
                                 
                            this_height = a_height;

                            lowest = if (this_height < lowest) this_height else lowest;
                            
                            std.debug.assert(this_height <= 5120);
                            
                            var height_index : usize = dx * blit_width + dy * blit_length * 512 + ix + iy * 512;

                            heights[height_index] = this_height;
                        }
                    }
                }
            }
            
            // filter out any anomolous entries, probably should log, perhaps even error rather than clamp
            // check if filtering is necessary to avoid wasting time
            std.debug.print("lowest: {d}\n", .{lowest});
            chunk.height_mod = @intCast(u8, (@divFloor(lowest, 10240) & 255));
            var cap : u32 = @as(u32, chunk.height_mod) * 10240;

            _ = cap;
            for(heights) |h, i|
            {
                if(h > 65535)
                {
                    std.debug.print("at {d}, height {d}\n", .{i, h});
                }
                else
                {
                    chunk.heights[i] = @intCast(u16, h);
                }
            }
            
            _ = try fio.saveChunkHeightFile(chunk);
            unloadChunk(chunk.index);
            std.debug.print("Completed scan input of chunk ({d}, {d}, {d})", .{chunk.index.x, chunk.index.y, chunk.index.z});
        }
    }    
}