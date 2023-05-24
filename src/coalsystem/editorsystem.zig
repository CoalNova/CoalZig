const std = @import("std");
const alc = @import("../coalsystem/allocationsystem.zig");
const fio = @import("../coalsystem/fileiosystem.zig");
const pnt = @import("../simpletypes/points.zig");
const chk = @import("../coaltypes/chunk.zig");
const pst = @import("../coaltypes/position.zig");
const rpt = @import("../coaltypes/report.zig");
const zmt = @import("zmt");

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
    for (@intCast(usize, start_index.y)..@intCast(usize, end_index.y)) |cy| {
        std.debug.print("Generating fresh heights for [0, {}], in world \"{s}\"\n", .{ cy, map_name });
        for (0..@intCast(usize, map_size.x)) |cx| {

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
        }
    }
}

pub fn smooveChunkMap(
    map_size: pnt.Point2,
    smooving_factor: u8,
    smoove_steps: u8,
    smoove_range: u8,
    start_index: pnt.Point3,
    end_index: pnt.Point3,
) void {

    //iterate over all chunks
    for (@intCast(usize, start_index.y)..@intCast(usize, end_index.y)) |y| {
        std.debug.print("Smooving heights for chunk [0, {}]\n", .{y});
        for (0..@intCast(usize, map_size.x)) |x| {

            //preload chunks
            for (0..3) |oy|
                for (0..3) |ox| {
                    const load_dex = pnt.Point3{ .x = @intCast(i32, x + ox), .y = @intCast(i32, y + oy), .z = 0 };
                    if (chk.indexIsMapValid(load_dex))
                        chk.loadChunk(load_dex);
                };

            const chunk = chk.getChunk(.{ .x = @intCast(i32, x), .y = @intCast(i32, y), .z = 0 }).?;
            var new_heights: [512 * 512]u16 = [_]u16{0} ** (512 * 512);
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

                    //TODO figure out what to do with these
                    _ = smoove_range;
                    _ = smoove_steps;

                    //TODO ALSO use normal-based sampling?

                    height += chk.getHeight(position.addAxial(.{ .x = -2.0, .y = 4.0, .z = 0.0 }));
                    height += chk.getHeight(position.addAxial(.{ .x = 4.0, .y = 2.0, .z = 0.0 }));
                    height += chk.getHeight(position.addAxial(.{ .x = 2.0, .y = -4.0, .z = 0.0 }));
                    height += chk.getHeight(position.addAxial(.{ .x = -4.0, .y = -2.0, .z = 0.0 }));
                    height += height_center * @intToFloat(f32, smooving_factor);

                    height /= 4 + @intToFloat(f32, smooving_factor);

                    height -= @intToFloat(f32, chunk.height_mod) * 1024.0;
                    new_heights[heightdex] = if (height < 0.0) 0.0 else @floatToInt(u16, height * 10);
                };
            for (chunk.heights, 0..) |*h, i| h.* = new_heights[i];
            chk.saveChunk(chunk.index);
            //save and unload chunks
            for (0..3) |oy|
                for (0..3) |ox| {
                    const load_dex = pnt.Point3{ .x = @intCast(i32, x + ox), .y = @intCast(i32, y + oy), .z = 0 };
                    if (chk.indexIsMapValid(load_dex)) {
                        chk.unloadChunk(load_dex);
                    }
                };
        }
    }
}

pub fn generateFreshLODTerrain(map_bounds: pnt.Point3, stride: u32) void {
    const strivisor = @divTrunc(1024, stride);

    //lod vbo layout
    // [xxxx xxxx xxxx xxxx yyyy yyyy yyyy yyyy]
    // [zzzz zzzz zzzz zzzz nxnx nyny zozo zozo]
    // pos.x/y = x/y * stride,
    // each vert is increment, stride 256 = max 16k chunks
    // height rounded to nearest unit 0-65,535
    // -8 to +7 for normal, calced after heights got
    // zone rules still applies

    var vbo = alc.gpa_allocator.alloc(
        u32,
        @intCast(u32, map_bounds.x) * strivisor * @intCast(u32, map_bounds.y) * strivisor * 2,
    ) catch |err|
        {
        std.debug.print("LODworld: {!}\n", .{err});
        const cat = @enumToInt(rpt.ReportCatagory.level_error) |
            @enumToInt(rpt.ReportCatagory.memory_allocation);
        rpt.logReportInit(cat, 101, [_]i32{ 0, 0, 0, 0 });
        return;
    };
    defer alc.gpa_allocator.free(vbo);

    for (0..@intCast(u32, map_bounds.y)) |cy| {
        //load line
        std.debug.print("LODWorld proc'ing chunk row {d}... ", .{cy});
        for (0..@intCast(u32, map_bounds.x)) |cx|
            chk.loadChunk(.{ .x = @intCast(i32, cx), .y = @intCast(i32, cy), .z = 0 });

        for (0..@intCast(u32, map_bounds.x)) |cx| {
            for (0..strivisor) |vy| {
                for (0..strivisor) |vx| {
                    const vbo_index = cx * strivisor + vx + (cy * strivisor + vy) * @intCast(u32, map_bounds.x) * strivisor * 2;
                    vbo[vbo_index] = (@intCast(u32, (cx * strivisor + vx) & 65535) << 16) + @intCast(u32, cy * strivisor + vy);
                    const pos = pst.Position.init(
                        .{ .x = @intCast(i32, cx), .y = @intCast(i32, cy), .z = 0 },
                        .{ .x = @intToFloat(f32, vx * stride), .y = @intToFloat(f32, vy * stride), .z = 0 },
                    );
                    vbo[vbo_index + 1] = @floatToInt(u32, chk.getHeight(pos)) << @as(u32, 16);
                }
            }
        }

        for (0..@intCast(u32, map_bounds.x)) |cx|
            chk.unloadChunk(.{ .x = @intCast(i32, cx), .y = @intCast(i32, cy), .z = 0 });
        std.debug.print(" Done!\n", .{});
    }
    fio.saveLODWorld(vbo, "dawn");
}

pub fn genZoneGroup(
    row_width: usize,
    start_row: usize,
    end_row: usize,
    sea_level: u32,
) void {
    for (start_row..end_row) |y| {
        for (0..row_width) |x| {
            genZone(.{
                .x = @intCast(i32, x),
                .y = @intCast(u32, y),
                .z = 0,
            }, sea_level);
        }
    }
}

pub fn genZone(index: pnt.Point3, sea_level: u32) void {
    if (!chk.indexIsMapValid(index)) {
        const cat = @enumToInt(rpt.ReportCatagory.chunk_system) |
            @enumToInt(rpt.ReportCatagory.level_error);
        rpt.logReportInit(cat, 9, [_]i32{ index.x, index.y, 0, 0 });
        return;
    }

    var chunk = chk.getChunk(index).?;

    //load if not already loaded
    const preloaded = chunk.heights.len > 0;
    if (!preloaded)
        chk.loadChunk(index);

    //discard error as lack of regionmap file is expectable behavior
    const regionmap: ?fio.BMP = fio.loadBMP("../assets/world/regionmap.bmp") catch null;

    var regiondex: usize = 0;
    var pxxperchk: usize = 0;
    var pxyperchk: usize = 0;
    //var regionwid: usize = 0;
    if (regionmap == null) {
        const cat = @enumToInt(rpt.ReportCatagory.file_io) | @enumToInt(rpt.ReportCatagory.level_warning);
        rpt.logReportInit(cat, 501, {});
    } else {
        pxxperchk = @divTrunc(regionmap.?.width, chk.getMapBounds().x);
        pxyperchk = @divTrunc(regionmap.?.height, chk.getMapBounds().y);
        regiondex = index.x * pxxperchk + index.y * pxxperchk * regionmap.?.width;
    }

    //go through and apply zones based on default rules
    for (0..1024) |y| {
        for (0..1024) |x| {

            //get region type if available
            //MEBE use noisemap and radial blur as a swap?
            const region: u8 = if (regionmap == null)
                0
            else
                regionmap.?.px[regiondex + (x / pxxperchk >> 10) + (y / pxyperchk >> 10) * regionmap.?.width];

            //get height
            const altitude = chk.getHeight(pst.Position.init(index, .{ .x = x, .y = y, .z = 0 }));

            //get slope(as best as is possible), is abs dot product multiplied by 255
            const vec_a = zmt.f32x4(
                if (x == 0) 1 else -1,
                0,
                chk.getHeight(pst.Position.init(index, .{
                    .x = x + if (x == 0) 1 else -1,
                    .y = y,
                    .z = 0,
                })) - altitude,
                1,
            ); //x
            const vec_b = zmt.f32x4(
                0,
                if (y == 0) 1 else -1,
                chk.getHeight(pst.Position.init(index, .{
                    .x = x,
                    .y = y + if (y == 0) 1 else -1,
                    .z = 0,
                })),
                1,
            ); //y
            const slope = @floatToInt(u8, std.math.fabs(zmt.dot3(vec_a, vec_b)[0]) * 255);

            //preliminary zone placement should add latitude to altitude, to simulate colder northern conditions
            //perhaps a better option is a gradient map, so that areas may have their environment dynamically assigned
            const specific = if (altitude < sea_level) 4 else 2 - (slope >> 6);

            chunk.zones[x + y * 1024] = (((region / 32) & @as(u8, 7)) << 3) + specific;
        }
    }
    //save chunk and retain loaded/unloaded state
    if (!preloaded)
        chk.unloadChunk(index);
}

pub fn applyNoiseMapGroup(noise_map: []u8, noise_map_size: pnt.Point3, noise_scale: u32, row_width: usize, start_row: usize, end_row: usize) void {
    for (start_row..end_row) |y| {
        for (0..row_width) |x| {
            applyNoiseMap(noise_map, noise_map_size, noise_scale, .{ .x = @intCast(i32, x), .y = @intCast(i32, y), .z = 0 });
        }
        std.debug.print("Applied noisemap for row {}\n", .{y});
    }
}

pub fn applyNoiseMap(
    noise_map: []u8,
    noise_map_size: pnt.Point3,
    noise_scale: u32,
    index: pnt.Point3,
) void {
    if (!chk.indexIsMapValid(index)) {
        const cat = @enumToInt(rpt.ReportCatagory.chunk_system) |
            @enumToInt(rpt.ReportCatagory.level_error);
        rpt.logReportInit(cat, 9, [_]i32{ index.x, index.y, 0, 0 });
        return;
    }

    var chunk = chk.getChunk(index).?;

    const loaded = (chunk.heights.len > 0);
    if (!loaded) chk.loadChunk(index);

    const x_scale: usize = @intCast(u31, noise_map_size.x) / 512;
    const y_scale: usize = @intCast(u31, noise_map_size.y) / 512;

    for (0..512) |y| {
        for (0..512) |x| {
            const height_index = x + y * 512;
            const noise_index =
                (x_scale * x + y * y_scale * @intCast(usize, noise_map_size.x)) * @intCast(usize, noise_map_size.z);
            chunk.heights[height_index] += @intCast(u16, noise_map[noise_index] * noise_scale);
        }
    }

    chk.saveChunk(index);

    if (!loaded) chk.unloadChunk(index);
}
