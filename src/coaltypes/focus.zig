const std = @import("std");
const sys = @import("../coalsystem/coalsystem.zig");
const rps = @import("../coaltypes/report.zig");
const rpt = @import("report.zig");
const pst = @import("position.zig");
const pnt = @import("../simpletypes/points.zig");
const chk = @import("chunk.zig");
const msh = @import("../coaltypes/mesh.zig");

/// The focus of the loaded regions of the worldspace
///     Used to track positional updates necessary for loading and rendering
pub const Focus = struct {
    position: pst.Position = .{},
    active_chunks: [25]pnt.Point3 = [_]pnt.Point3{.{ .x = -1, .y = -1, .z = -1 }} ** 25,
    range: u32 = ((1 << 32) - 1),
};

pub fn checkFocalPoint(focal_point: Focus, new_position: pst.Position) bool {
    const f = focal_point.position.axial();
    const a = new_position.axial();
    return (((f.x - a.x) * (f.x - a.x) + (f.y - a.y) * (f.y - a.y)) > focal_point.range * focal_point.range);
}

pub fn updateFocalPoint(focal_point: *Focus) void {
    const focal_index = focal_point.position.index();

    for (&focal_point.active_chunks) |*chunk_index| {
        if ((chunk_index.x - focal_index.x) * (chunk_index.x - focal_index.x) > 4 or
            (chunk_index.y - focal_index.y) * (chunk_index.y - focal_index.y) > 4)
        {
            chk.unloadChunk(chunk_index.*);
            chunk_index.x = -1;
            chunk_index.y = -1;
            chunk_index.z = -1;
        }
    }

    for (0..5) |y|
        for (0..5) |x| {
            const index = pnt.Point3.init(focal_index.x + @intCast(i32, x) - 2, focal_index.y + @intCast(i32, y) - 2, 0);
            if (chk.indexIsMapValid(index)) {
                var contains = false;
                cnt_blk: for (focal_point.active_chunks) |chunk_index|
                    if (chunk_index.x == index.x and chunk_index.y == index.y) {
                        contains = true;
                        break :cnt_blk;
                    };
                if (!contains) {
                    plc_blk: for (&focal_point.active_chunks) |*chunk_index|
                        if (chunk_index.x == -1 and chunk_index.y == -1) {
                            chunk_index.x = index.x;
                            chunk_index.y = index.y;
                            chunk_index.z = index.z;
                            chk.loadChunk(index);
                            break :plc_blk;
                        };
                }
                std.debug.print("Trying terrain mesh for chunk: {}, {}: \n", .{ index.x, index.y });

                if (std.math.absCast(focal_index.x - @intCast(i32, index.x)) < 2 and focal_index.y + @intCast(i32, index.y) < 2) {
                    var c: *chk.Chunk = chk.getChunk(index).?;
                    if (c.mesh == null) {
                        msh.constructBaseTerrainMesh(c, focal_point);
                    }
                }
            }
        };
}
