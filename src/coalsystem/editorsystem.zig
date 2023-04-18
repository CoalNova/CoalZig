const std = @import("std");
const alc = @import("../coalsystem/allocationsystem.zig");
const fio = @import("../coalsystem/fileiosystem.zig");
const pnt = @import("../simpletypes/points.zig");
const chk = @import("../coaltypes/chunk.zig");
const pst = @import("../coaltypes/position.zig");

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
pub fn generateNewChunkMap(
    height_map: []u8,
    height_mod: u16,
    map_name: []const u8,
    height_map_size: pnt.Point2,
    map_size: pnt.Point2,
    start_index: pnt.Point3,
    end_index: pnt.Point3,
) void {
    const bytes_per_chunk: pnt.Point2 = .{
        .x = @divTrunc(height_map_size.x, map_size.x),
        .y = @divTrunc(height_map_size.y, map_size.y),
    };
    const height_per_byte: pnt.Point2 = .{
        .x = @divTrunc(512, bytes_per_chunk.x),
        .y = @divTrunc(512, bytes_per_chunk.y),
    };

    var heights: []f32 = alc.gpa_allocator.alloc(f32, 512 * 512) catch |err|
        return std.debug.print("{!}\n", .{err});
    defer alc.gpa_allocator.free(heights);
    var chunk_ready_height_data: []u16 = alc.gpa_allocator.alloc(u16, 512 * 512) catch |err|
        return std.debug.print("{!}\n", .{err});
    defer alc.gpa_allocator.free(chunk_ready_height_data);

    const bpcx = @intCast(usize, bytes_per_chunk.x);
    const bpcy = @intCast(usize, bytes_per_chunk.y);
    const hmsx = @intCast(usize, height_map_size.x);
    const hmsy = @intCast(usize, height_map_size.y);
    const hpbx = @intCast(usize, height_per_byte.x);
    const hpby = @intCast(usize, height_per_byte.y);

    //iterate over chunks
    for (@intCast(usize, start_index.y)..@intCast(usize, end_index.y)) |cy|
        for (0..@intCast(usize, map_size.x)) |cx| {
            std.debug.print("Generating fresh heights for [{}, {}], in world \"{s}\"\n", .{ cx, cy, map_name });

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
                return std.debug.print(
                    "Generated chunk height range exceeded! [{}, {}] {},{}",
                    .{ cx, cy, tollest, smollest },
                );
            }

            //capture height data
            var offset_mod: u8 = @floatToInt(u8, smollest / 1024);
            for (heights, 0..) |h, i|
                chunk_ready_height_data[i] = @floatToInt(u16, (h - (@intToFloat(f32, offset_mod) * 1024)) * 10);

            fio.saveChunkHeights(
                chunk_ready_height_data,
                offset_mod,
                .{ .x = @intCast(i32, cx), .y = @intCast(i32, cy), .z = 0 },
                map_name,
            ) catch |err| {
                std.debug.print("{!}\n", .{err});
            };
            std.debug.print("[{}, {}] done!\n", .{ cx, cy });
        };
}

pub fn smooveChunkMap(
    map_size: pnt.Point2,
    smooving_factor: u8,
    smoove_steps: u8,
    smoove_range: u8,
    start_index: pnt.Point3,
    end_index: pnt.Point3,
) void {
    for (@intCast(usize, start_index.y)..@intCast(usize, end_index.y)) |y|
        for (0..@intCast(usize, map_size.x)) |x| {
            std.debug.print("Smooving heights for chunk [{}, {}]\n", .{ x, y });

            for (0..3) |oy|
                for (0..3) |ox| {
                    chk.loadChunk(.{ .x = @intCast(i32, x + ox), .y = @intCast(i32, y + oy), .z = 0 });
                };

            const chunk = chk.getChunk(.{ .x = @intCast(i32, x), .y = @intCast(i32, y), .z = 0 }).?;
            for (0..512) |hy|
                for (0..512) |hx| {
                    const heightdex = hx + hy * 512;
                    const position = pst.Position.init(chunk.index, .{
                        .x = @intToFloat(f32, hx * 2),
                        .y = @intToFloat(f32, hy * 2),
                        .z = 0,
                    });
                    const height_center = chk.getHeight(position);
                    var height: f32 = 0;

                    for (0..(smoove_steps * 2 + 1)) |sy|
                        for (0..(smoove_steps * 2 + 1)) |sx| {
                            height += chk.getHeight(position.addAxial(.{
                                .x = @intToFloat(f32, smoove_range * (@intCast(i32, sx) - smoove_steps)),
                                .y = @intToFloat(f32, smoove_range * (@intCast(i32, sy) - smoove_steps)),
                                .z = 0,
                            }));
                        };

                    height += height_center * @intToFloat(f32, smooving_factor);
                    height = height / comptime @intToFloat(f32, @intCast(u32, smoove_steps * 2 + 1) *
                        @intCast(u32, smoove_steps * 2 + 1) + smooving_factor);
                    height -= @intToFloat(f32, chunk.height_mod) * 1024.0;
                    chunk.heights[heightdex] = if (height < 0.0) 0.0 else @floatToInt(u16, height * 10);
                };
            for (0..3) |oy|
                for (0..3) |ox| {
                    const chunk_index = pnt.Point3{
                        .x = @intCast(i32, x + ox),
                        .y = @intCast(i32, y + oy),
                        .z = 0,
                    };
                    chk.saveChunk(chunk_index);
                    chk.unloadChunk(chunk_index);
                };
            std.debug.print("Completed smooving for chunk [{}, {}]\n", .{ x, y });
        };
}
