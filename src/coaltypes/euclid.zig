const pst = @import("../coaltypes/position.zig");

pub const Euclid = struct
{
    position : pst.Position = .{},
    scale : pst.vct.Vector3 = .{},
    quaternion: pst.vct.Vector4 = .{.x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0}
};

//Euclid will contains the relevant calculational data