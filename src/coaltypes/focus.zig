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

pub fn updateFocalPoint(focal_point: *Focus, position: pst.Position) void {
    if (!position.index().equals(focal_point.position.index())) {
        focal_point.position = position;

        const focal_index = focal_point.position.index();
        for (focal_point.active_chunks) |index| {
            if (chk.indexIsMapValid(index)) {
                const diff = focal_index.differenceAbs(index);
                if (diff.x > 1 or diff.y > 1)
                    msh.destroyTerrainMesh(chk.getChunk(index).?); // check for chunkiness
                if (diff.x > 2 or diff.y > 2)
                    chk.unloadChunk(index);
            }
        }

        //stack set of applicable indices
        var indices: [25]pnt.Point3 = [_]pnt.Point3{.{}} ** 25;
        for (0..5) |y|
            for (0..5) |x| {
                indices[x + y * 5] = .{ .x = @intCast(i32, x) + focal_index.x - 2, .y = @intCast(i32, y) + focal_index.y - 2, .z = 0 };
            };

        for (indices) |index| {
            if (chk.indexIsMapValid(index)) {
                load_block: {
                    for (focal_point.active_chunks) |active_index|
                        if (index.equals(active_index)) break :load_block;
                    chk.loadChunk(index);
                }
            }
        }

        for (indices, 0..) |index, i| {
            if (chk.indexIsMapValid(index)) {
                const blob = focal_point.position.index().differenceAbs(index);
                if (blob.x < 2 and blob.y < 2) {
                    std.debug.print("constructing mesh for {} {}\n", .{ index.x, index.y });
                    msh.constructBaseTerrainMesh(chk.getChunk(index).?, focal_point);
                }
            }
            focal_point.active_chunks[i] = index;
        }
    } else {
        focal_point.position = position;
        for (focal_point.active_chunks) |index| {
            if (chk.indexIsMapValid(index)) {
                const chunk = chk.getChunk(index).?;
                if (chunk.mesh != null)
                    msh.updateTerrainMeshResolution(chunk, focal_point);
            }
        }
    }
}
