const std = @import("std");
const zmt = @import("zmt");
const sys = @import("../coalsystem/coalsystem.zig");
const wnd = @import("../coaltypes/window.zig");
const euc = @import("../coaltypes/euclid.zig");
const gls = @import("../coalsystem/glsystem.zig");
const idx = @import("../simpletypes/index.zig");
const vct = @import("../simpletypes/vectors.zig");
const cms = @import("../coalsystem/coalmathsystem.zig");

pub const Camera = struct {
    euclid: euc.Euclid = undefined,
    fov: f32 = 65,
    render_index: idx.Index32_4 = undefined,
    forward: cms.Vec4 = undefined,
    upward: cms.Vec4 = undefined,
    near_plane: f32 = 0.03,
    far_plane: f32 = 3000.0,
    view_matrix: zmt.Mat = undefined,
    projection_matrix: zmt.Mat = undefined,
    mvp_matrix: zmt.Mat = undefined,
    horizon_matrix: zmt.Mat = undefined,
    rotation_matrix: zmt.Mat = undefined,
    bubble_matrix: zmt.Mat = undefined,
    pub fn calculateMatrices(self: *Camera, window: *wnd.Window) void {
        // self.render_index = idx.Index32_4{
        //     .w = 0,
        //     .x = @truncate(u8, @intCast(u64, self.euclid.position.index().x)),
        //     .y = @truncate(u8, @intCast(u64, self.euclid.position.index().y)),
        //     .z = @truncate(u8, @intCast(u64, self.euclid.position.index().z)),
        // };

        const tmp_pos = self.euclid.position.axial();
        const cam_pos = cms.Vec4{ tmp_pos.x, tmp_pos.y, tmp_pos.z, 1 };
        const cam_eul = cms.vec3ToH(cms.convQuatToEul(self.euclid.quaternion));
        self.forward = zmt.normalize4(zmt.mul(zmt.quatToMat(self.euclid.quaternion), cms.Vec4{ 0, 1, 0, 1 }));
        const right = zmt.normalize4(zmt.mul(zmt.quatToMat(self.euclid.quaternion), cms.Vec4{ 1, 0, 0, 1 }));
        self.upward = zmt.normalize4(zmt.cross3(right, self.forward));

        //TODO allow adjustment of this for leaining
        //self.upward = cms.Vec4{ 0, 0, 1, 1 };

        self.horizon_matrix = cms.convQuatToMat4(cms.convEulToQuat(cms.Vec3{ 0, 0, (cam_eul[2] + 90) * std.math.pi / 180 }));
        self.rotation_matrix = cms.convQuatToMat4(cms.convEulToQuat(cms.Vec3{ (cam_eul[0]) * std.math.pi / 180, 0, (cam_eul[2] + 90) * std.math.pi / 180 }));

        self.view_matrix = zmt.lookAtRh(
            cam_pos,
            cam_pos + self.forward,
            self.upward,
        );

        self.projection_matrix =
            zmt.perspectiveFovRhGl(self.fov, @intToFloat(f32, window.size.x) / @intToFloat(f32, window.size.y), self.near_plane, self.far_plane);

        self.mvp_matrix = zmt.mul(self.view_matrix, self.projection_matrix);
    }
};
