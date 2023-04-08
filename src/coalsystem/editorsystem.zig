const std = @import("std");
const alc = @import("../coalsystem/allocationsystem.zig");
const fio = @import("../coalsystem/fileiosystem.zig");
const pnt = @import("../simpletypes/points.zig");

const EditError = error{
    GeneratedHeightRangeOoB,
};

/// Generates a new chunk map and saves under provided name
/// height_map is a 1Byte per Pixel heightmap of the terrain
/// height_mod is an offset multiplier for heightmap values
///     note: that pixel values will be per 0.10 meters(or units)
/// map_name is the name of the chunk map files to be generated under
/// map_size is a touple containing the outer x,y bounds of the map
///     note: map bounds start at 0 and work outward towards max
pub fn generateNewChunkMap(height_map: []u8, height_mod: u16, map_name: []const u8, height_map_size: pnt.Point2, map_size: pnt.Point2) !void {
    const bytes_per_chunk: pnt.Point2 = .{ .x = @divTrunc(height_map_size.x, map_size.x), .y = @divTrunc(height_map_size.y, map_size.y) };
    const height_per_byte: pnt.Point2 = .{ .x = @divTrunc(512, bytes_per_chunk.x), .y = @divTrunc(512, bytes_per_chunk.y) };

    var heights: []f32 = try alc.gpa_allocator.alloc(f32, 512 * 512);
    defer alc.gpa_allocator.free(heights);
    var chunk_ready_height_data: []u16 = try alc.gpa_allocator.alloc(u16, 512 * 512);
    defer alc.gpa_allocator.free(chunk_ready_height_data);

    const bpcx = @intCast(usize, bytes_per_chunk.x);
    const bpcy = @intCast(usize, bytes_per_chunk.y);
    const hmsx = @intCast(usize, height_map_size.x);
    const hmsy = @intCast(usize, height_map_size.y);
    const hpbx = @intCast(usize, height_per_byte.x);
    const hpby = @intCast(usize, height_per_byte.y);

    //iterate over chunks
    for (0..@intCast(usize, map_size.y)) |cy|
        for (0..@intCast(usize, map_size.x)) |cx| {
            std.debug.print("Generating fresh heights for {} {} for world \"{s}\" ", .{ cx, cy, map_name });

            //iterate over the pixels in the chunk
            //if not perfectly diviseable then this is gonna suck
            for (0..@intCast(usize, bytes_per_chunk.y)) |by|
                for (0..@intCast(usize, bytes_per_chunk.x)) |bx| {
                    //get height(s) necessary for basic slope molding
                    // c | d
                    // -----
                    // a | b

                    const height_index = cx * bpcx + cy * hmsx * bpcx + bx + by * hmsx;
                    const a: i32 = @as(i32, height_map[height_index]) * height_mod;
                    const b: i32 = if (cx * bpcx + bx + 1 < hmsx) @as(i32, height_map[height_index + 1]) * height_mod else 0;
                    const c: i32 = if (cy * bpcx + by + 1 < hmsy) @as(i32, height_map[height_index + hmsx]) * height_mod else 0;
                    const d: i32 = if (cx * bpcx + bx + 1 < hmsx and
                        cy * bpcy + by + 1 < hmsy) @as(i32, height_map[height_index + 1 + hmsx]) * height_mod else 0;

                    for (0..hpby) |ay|
                        for (0..hpbx) |ax| {
                            const index = (bx * hpbx + by * hpbx * 512 + ax + ay * 512);

                            const x_scale: f32 = @intToFloat(f32, ax) / @intToFloat(f32, hpbx);
                            const y_scale: f32 = @intToFloat(f32, ay) / @intToFloat(f32, hpby);
                            const invrt_x: f32 = 1.0 - x_scale;
                            const invrt_y: f32 = 1.0 - y_scale;

                            const height = (@intToFloat(f32, a) * invrt_x + @intToFloat(f32, b) * x_scale) * invrt_y +
                                (@intToFloat(f32, c) * invrt_x + @intToFloat(f32, d) * x_scale) * y_scale;

                            heights[index] = height;
                        };
                };

            //convert to collapsed height data

            //capture the bounds, hopefully nothing has generated ridiculously high data
            var tollest: f32 = 0;
            var smollest: f32 = 9999999.0;
            for (heights) |h| {
                if (h > tollest) tollest = h;
                if (h < smollest) smollest = h;
            }

            //check that possible ranges isn't exceeded
            if (tollest - smollest > 5500.0) {
                std.debug.print("Generated chunk height range exceeded! {},{}", .{ tollest, smollest });
                return EditError.GeneratedHeightRangeOoB;
            }

            //capture height data
            var offset_mod: u8 = @floatToInt(u8, smollest / 1024);
            for (heights, 0..) |h, i|
                chunk_ready_height_data[i] = @floatToInt(u16, (h - (@intToFloat(f32, offset_mod) * 1024)) * 10);

            std.debug.print(" complete!\n\tsaving ", .{});

            try fio.saveChunkHeights(chunk_ready_height_data, offset_mod, .{ .x = @intCast(i32, cx), .y = @intCast(i32, cy), .z = 0 }, map_name);
            std.debug.print("done!\n", .{});
        };
}
