const pst = @import("../coaltypes/position.zig");

pub const Euclid = struct {
    position: pst.Position = .{},
    scale: pst.vct.Vector3 = .{ .x = 1.0, .y = 1.0, .z = 1.0 },
    quaternion: @Vector(4, f32) = @Vector(4, f32){ 0.0, 0.0, 0.0, 1.0 },
};

//Euclid will contain the relevant calculational data
