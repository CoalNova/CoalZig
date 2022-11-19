const std = @import("std");
const sys = @import("../coalsystem/coalsystem.zig");
const rps = @import("../coalsystem/reportsystem.zig");
const rpt = @import("report.zig");
const pst = @import("position.zig");
const pnt = @import("../simpletypes/points.zig");
const chk = @import("chunk.zig");

/// The focus of the loaded regions of the worldspace
/// Used to track positional updates necessary for loading and rendering
/// TODO Manage scene assets and handle intervalled positionial updates
///     in 2D this object is purely for direct rendering the scene and is
///     acting as the 'camera' for the scene. In 3D the role will take
///     on a greater impact of managing rendered assets through instancing,
///     LOD mesh swapping, and asset loading. 3D assets are larger and
///     require faster management of more data.
pub const Focus = struct { position: pst.Position = .{}, active_chunks: [25]pnt.Point3 = [_]pnt.Point3{.{ .x = -1, .y = -1, .z = -1 }} ** 25, range: u32 = ((1 << 32) - 1) };

pub fn updateFocalPoint(focal_point: *Focus) void {
    // create list of new points for chunks
    var new_points: [25]pnt.Point3 = [_]pnt.Point3{pnt.Point3.init(-1, -1, 0)} ** 25;
    var y: usize = 0;
    while (y < 5) : (y += 1) {
        var x: usize = 0;
        while (x < 5) : (x += 1) {
            new_points[x + y * 5] = pnt.Point3.init(@intCast(i32, x) - 2, @intCast(i32, y) - 2, 0).add(focal_point.position.index());
            std.debug.print("Loading {d}, {d}\n", .{ x, y });
        }
    }

    // remove unneeded chunks
    var i: usize = 0;
    while (i < 25) : (i += 1) {
        var contains: bool = false;
        for (new_points) |new_point|
            contains = contains or new_point.equals(focal_point.active_chunks[i]);

        if (!contains and chk.chunkIndexIsValid(focal_point.active_chunks[i])) {
            chk.unloadChunk(chk.getChunk(focal_point.active_chunks[i]).index);
            focal_point.active_chunks[i] = pnt.Point3.init(-1, -1, 0);
        }
    }

    // add new chunks
    for (new_points) |new_point| {
        if (chk.chunkIndexIsValid(new_point)) {
            var contains = false;
            var first_empty: usize = 0;
            i = 0;
            while (i < 25) : (i += 1) {
                contains = contains or focal_point.active_chunks[i].equals(new_point);
                if (focal_point.active_chunks[i].x == -1 and first_empty == -1)
                    first_empty = i;
            }

            if (!contains) {
                var chunk: *chk.Chunk = chk.loadChunk(new_point) catch undefined;
                std.debug.print("{x}\n", .{@ptrToInt(chunk)});
                focal_point.active_chunks[first_empty] = chunk.index;
            }
        }
    }
}
