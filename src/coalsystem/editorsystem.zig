const std = @import("std");
const alc = @import("../coalsystem/allocationsystem.zig");



/// Generates a new chunk map and saves under provided name
/// height_map is a 1Byte per Pixel heightmap of the terrain
/// height_mod is an offset multiplier for heightmap values
///     note: that pixel values will be per 0.10 meters(or units)
/// perlin_map is a seamless perlin noise heightmap
/// perlin_mod is an offset multiplier, following the height_mod rules
/// map_name is the name of the chunk map files to be generated under
/// map_size is a touple containing the outer x,y bounds of the map
///     note: map bounds start at 0 and work outward towards max
pub fn generateNewChunkMap(
    height_map : []u8, 
    height_mod : u16, 
    perlin_map : []u8, 
    perlin_mod : u16, 
    map_name : []const u8, 
    height_size : .{u32,u32}, 
    map_size : .{u32, u32}) !void
{
    _ = map_name;
    _ = height_mod;
    _ = perlin_map;
    _ = perlin_mod;

    const bytes_per_chunk : .{u32, u32} = .{ height_size.@"0" / map_size.@"0", height_size.@"1" / map_size.@"1" };
    const height_per_byte : .{u32, u32} = .{512 / bytes_per_chunk.@"0", 512 / bytes_per_chunk.@"1"};
    //file locations are ./assets/world/{map_name}/
    //var filename : []u8 = alc.gpa_allocator.alloc(u8, map_name.len + 30);
    var filename : []u8 = "./assets/world/pac/00000000.chf";
    var heights : []u8 = alc.gpa_allocator.alloc(u8, 512 * 512);
    defer alc.gpa_allocator.free(heights);

    for(0..map_size.@"1") |cy|
    {
        for(0..map_size.@"0") |cx|
        {
            filename[19] = cx / 1000 + 48;
            filename[20] = (cx % 1000) / 100;
            filename[21] = (cx % 100) / 10;
            filename[22] = cx % 10; 

            filename[23] = cy / 1000 + 48;
            filename[24] = (cy % 1000) / 100;
            filename[25] = (cy % 100) / 10;
            filename[26] = cy % 10; 

            for(0..bytes_per_chunk.@"1") |by|
            {
                for(0..bytes_per_chunk.@"0") |bx|
                {
                    const b = height_map[cx + cy * map_size.@"0" + bx + by * map_size.@"0"];
                    for (0..height_per_byte.@"1") |ay|
                    {
                        for (0..height_per_byte.@"1") |ax|
                        {
                           
                            heights[bx + ax + ay] = b;

                        }
                    }
                }
            }





        }
    }

}