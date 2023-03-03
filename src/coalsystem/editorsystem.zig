const std = @import("std");
const alc = @import("../coalsystem/allocationsystem.zig");
const fio = @import("../coalsystem/fileiosystem.zig");


const EditError = error{
    GeneratedHeightRangeOoB,
};


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
    _ = perlin_map;
    _ = perlin_mod;

    const bytes_per_chunk : .{u32, u32} = .{ height_size.@"0" / map_size.@"0", height_size.@"1" / map_size.@"1" };
    const height_per_byte : .{u32, u32} = .{512 / bytes_per_chunk.@"0", 512 / bytes_per_chunk.@"1"};
    //file locations are ./assets/world/{map_name}/
    //var filename : []u8 = alc.gpa_allocator.alloc(u8, map_name.len + 30);
    var filename : []u8 = "./assets/world/pac/00000000.chf";
    var heights : []f32 = alc.gpa_allocator.alloc(f32, 512 * 512);
    defer alc.gpa_allocator.free(heights);
    var chunk_ready_height_data : []u16 = alc.gpa_allocator.alloc(u16, 512 * 512);
    defer alc.gpa_allocator.free(chunk_ready_height_data);

    //iterate over chunks
    for(0..map_size.@"1") |cy|
        for(0..map_size.@"0") |cx|
        {
            //lazy filename
            filename[19] = cx / 1000 + 48;
            filename[20] = (cx % 1000) / 100;
            filename[21] = (cx % 100) / 10;
            filename[22] = cx % 10; 

            filename[23] = cy / 1000 + 48;
            filename[24] = (cy % 1000) / 100;
            filename[25] = (cy % 100) / 10;
            filename[26] = cy % 10; 

            //iterate over the pixels in the chunk
            //if not perfectly diviseable then this is gonna suck
            for(0..bytes_per_chunk.@"1") |by|
                for(0..bytes_per_chunk.@"0") |bx|
                {
                    //get height(s) necessary for basic slope molding
                    // c | d
					// -----
					// a | b

                    const height_index = cx * bytes_per_chunk + cy * height_size.@"0" * bytes_per_chunk + bx + by * height_size.@"0";
                    const a : i32 = @as(i32, height_map[height_index]) * height_mod;
                    const b : i32 = if (cx * bytes_per_chunk + bx + 1 < height_size.@"0") @as(i32, height_map[height_index + 1]) * height_mod else 0;
                    const c : i32 = if (cy * bytes_per_chunk + by + 1 < height_size.@"1") @as(i32, height_map[height_index + height_size.@"0"]) * height_mod else 0;
                    const d : i32 = if (cx * bytes_per_chunk + bx + 1 < height_size.@"0" and 
                                    cy * bytes_per_chunk + by + 1 < height_size.@"1") @as(i32, height_map[height_index + 1 + height_size.@"0"]) * height_mod else 0;


                    for (0..height_per_byte.@"1") |ay|
                        for (0..height_per_byte.@"0") |ax|
                        {
                            const x_scale : f32 = @as(f32, ax) / @as(f32, height_per_byte);
                            const y_scale : f32 = @as(f32, ay) / @as(f32, height_per_byte);
                            const invrt_x : f32 = 1.0 - x_scale;
                            const invrt_y : f32 = 1.0 - y_scale;

                            const height = (@as(f32, a) * invrt_x + @as(f32, b) * x_scale) * invrt_y +
                                (@as(f32, c) * invrt_x + @as(f32, d) * x_scale) * y_scale;


                            heights[ax + ay * 512 + bx * bytes_per_chunk + by * 512 * bytes_per_chunk] = height;
                        };
                };
            
            //convert to collapsed height data

            //capture the bounds, hopefully nothing has generated ridiculously high data
            var tollest : f32 = 0;
            var smollest : f32 = 9999999.0;
            for(heights) |h|
            {
                if (h > tollest) tollest = h;
                if (h < smollest) smollest = h;
            }

            //check that possible ranges isn't exceeded
            if (tollest - smollest > 5500.0)
            {
                std.debug.print("Generated chunk height range exceeded! {},{}", .{tollest, smollest});
                return EditError.GeneratedHeightRangeOoB;
            }

            var offset_mod : u8 = @truncate(u8, @trunc(smollest / 1024));
            for (heights, 0..) |h, i| 
                chunk_ready_height_data[i] = @truncate(u16, @trunc((h - (@as(f32, offset_mod) * 1024)) * 10));
            

        };

}