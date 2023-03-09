const zmt = @import("zmt");
const euc = @import("../coaltypes/euclid.zig");

pub const Camera = struct {
    euclid : euc.Euclid = undefined,
    fov : f32,
    near_plane : f32,
    far_plane : f32,
    view_matrix : @Vector(16, f32),
    projection_matrix : @Vector(16, f32),
    mvp_matrix : @Vector(16, f32),
    horizon_matrix : @Vector(16, f32),
    rotation_matrix : @Vector(16, f32),
    bubble_matrix : @Vector(16, f32),
    pub fn calculateMatrices(self : *Camera)void
    {
        _ = self;
    }
};