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
pub const Focus = struct {
    position: pst.Position = .{},
    active_chunks: [25]pnt.Point3 = [_]pnt.Point3{.{ .x = -1, .y = -1, .z = -1 }} ** 25,
    range: u32 = ((1 << 32) - 1),
};
