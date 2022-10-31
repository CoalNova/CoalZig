const pnt = @import("../simpletypes/points.zig");
const vct = @import("../simpletypes/vectors.zig");

/// Worldspace position struct, contains the dimensional
/// index and the intradimensional axial coordinates
/// TODO SIMD implementation
/// TODO integral/autorounding of axial -> index
pub const Position = struct
{
    index : pnt.Point3,
    axial : vct.Vector3
};