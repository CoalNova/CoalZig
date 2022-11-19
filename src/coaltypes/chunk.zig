const std = @import("std");
const sys = @import("../coalsystem/coalsystem.zig");
const spt = @import("sprite.zig");
const asy = @import("../coalsystem/assetsystem.zig");
const alc = @import("../coalsystem/allocationsystem.zig");
const pst = @import("position.zig");
const fio = @import("../coalsystem/fileiosystem.zig");
const evs = @import("../coalsystem/eventsystem.zig");

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

    var chunk = getChunk(position.index());
    
    //check if chunk has loaded height data
    if (!chunk.loaded)
        return 0.0;

    var axial = position.axial();
    var ind_x = position.index().x;
    var ind_y = position.index().y;
    var pos_x = @floatToInt(i32, axial.x);
    var pos_y = @floatToInt(i32, axial.y);
    var dec_x = axial.x - @intToFloat(f32, pos_x);
    var dec_y = axial.y - @intToFloat(f32, pos_y);
    
    //check if requested height is rounded value
    if (dec_x == 0 and dec_y == 0)
    {
        //check if position indices are odd and interpolate if so
        if (pos_x == 1 and pos_y == 1)
            return (
                getHeight(position.addVec(pst.vct.Vector3.init(1.0, 1.0, 0))) +
                getHeight(position.addVec(pst.vct.Vector3.init(1.0, -1.0, 0))) +
                getHeight(position.addVec(pst.vct.Vector3.init(-1.0, -1.0, 0))) +
                getHeight(position.addVec(pst.vct.Vector3.init(-1.0, 1.0, 0))) 
                ) / 4.0;
        if (pos_x == 1)
            return(
                getHeight(position.addVec(pst.vct.Vector3.init(1.0, 0, 0))) +
                getHeight(position.addVec(pst.vct.Vector3.init(-1.0, 0, 0)))
                ) / 2.0;
        if (pos_y == 1)
            return(
                getHeight(position.addVec(pst.vct.Vector3.init(0.0, 1.0, 0))) +
                getHeight(position.addVec(pst.vct.Vector3.init(0.0, -1.0, 0)))
                ) / 2.0;
        //otherwise resolve directly
        //height data is stored in chunks using a major and minor value
        //the major value is the heightmod, which blanketly sets the base height at some value in an unsigned char * 1024.0f
        //the minor value is an unsigned short * 0.02f, keeping per-height accuracy down to 2 centimeters (or two-hundredths of chosen unit of measure)
        return @intToFloat(f32, chunk.heights[@intCast(usize, (pos_x >> 1) + (pos_y >> 1) * 512 )]) * 
            0.02 + @intToFloat(f32, chunk.height_mod) * 1024.0;
    }

    //else all, utilize the nearest points 

    // c | d
    // - - -
    // a | b

    var a = getHeight(.{.x = (ind_x << 28) + (pos_x << 18), .y =(ind_y << 28) + (pos_y << 18), .z = 0});
    var b = getHeight(.{.x = (ind_x << 28) + ((pos_x + 1) << 18), .y =(ind_y << 28) + (pos_y << 18), .z = 0});
    var c = getHeight(.{.x = (ind_x << 28) + (pos_x << 18), .y =(ind_y << 28) + ((pos_y + 1) << 18), .z = 0});
    var d = getHeight(.{.x = (ind_x << 28) + ((pos_x + 1) << 18), .y =(ind_y << 28) + ((pos_y + 1) << 18), .z = 0});

    //calculate ray plane slope intersection formula 
    var origin = pst.vct.Vector3
    {
        .x = dec_x, 
        .y = dec_y, 
        .z = 5.0
    };
    var ray = pst.vct.Vector3.init(0, 0, -1.0);
    var alpha : pst.vct.Vector3 = if (dec_x > dec_y) .{ .x = 1.0, .y = 0.0, .z = b - a} else .{ .x = 0.0, .y = 1.0, .z = c - a};
    
    var gamma = pst.vct.Vector3.init(1, 1, d - a);
    var normal = alpha.badCross(gamma);

    var denom = normal.vectorDot(ray);
    var dist : f32 = 0.0;
    if (denom > 0.00001 or denom < 0.00001)
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
                                 
                            //this_height = a_height;

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
            
            //_ = smooveHeights(chunk);

            _ = try fio.saveChunkHeightFile(chunk);
            unloadChunk(chunk.index);
            std.debug.print("Completed scan input of chunk ({d}, {d}, {d})", .{chunk.index.x, chunk.index.y, chunk.index.z});
        }
    }    
}

pub fn smooveHeights(chunk : *Chunk) *Chunk
{
    if (!chunk.loaded)
    {
        return chunk;
    }

    const range : i32 = 5; 
    const steps : i32 = 5;

    var y : usize = 0;
    while (y < 512) : (y += 1)
    {
        var x : usize = 0;
        while (x < 512) : (x += 1)
        {
            var avg : i32 = 0;
            var ctr : i32 = 0;

            var sy = -range * steps;
            while(sy <= range * steps) : (sy += steps)
            {
                var sx = -range * steps;
                while(sx <= range * steps) : (sx += steps)
                {
                    if (sx + @intCast(i32, x) < 512 and sx + @intCast(i32, x) >= 0 and 
                        sy + @intCast(i32, y) < 512 and sy + @intCast(i32, y) >= 0)
                    {
                        avg += chunk.heights[@intCast(usize, sx + @intCast(i32, x) + (sy + @intCast(i32, y)) * 512)];
                        ctr += 1;
                    }
                }
            }

            chunk.heights[x + y * 512] =  @intCast(u16, @divFloor(avg, ctr));
        }
    }
    

    return chunk;
}