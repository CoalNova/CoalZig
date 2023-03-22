const zmt = @import("zmt");
const wnd = @import("../coaltypes/window.zig");
const euc = @import("../coaltypes/euclid.zig");
const std = @import("std");

pub const Camera = struct {
    euclid : euc.Euclid = undefined,
    fov : f32 = 65,
    near_plane : f32 = 0.03,
    far_plane : f32 = 3000.0,
    view_matrix : zmt.Mat = undefined,
    projection_matrix : zmt.Mat = undefined,
    mvp_matrix : zmt.Mat = undefined,
    horizon_matrix : zmt.Mat = undefined,
    rotation_matrix : zmt.Mat = undefined,
    bubble_matrix : zmt.Mat = undefined,
    pub fn calculateMatrices(self : *Camera, window : *wnd.Window)void
    {
        self.projection_matrix = zmt.perspectiveFovRhGl
            (self.fov, @intToFloat(f32, window.size.x) / @intToFloat(f32, window.size.y), 
            self.near_plane, self.far_plane);
        self.view_matrix = zmt.matFromQuat(self.euclid.quaternion);
    }
};