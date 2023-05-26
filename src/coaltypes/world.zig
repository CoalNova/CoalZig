const std = @import("std");
const msh = @import("../coaltypes/mesh.zig");
const tex = @import("../coaltypes/texture.zig");
const vct = @import("../simpletypes/vectors.zig");

pub var world = World{};

const World = struct {
    lod_world: ?msh.Mesh = null,
    sky_data: SkyData = .{},
};

const SkyData = struct {
    //TODO needs: textures for sky parts(night sky, special effects)
    sky_mesh: ?msh.Mesh = null,
    //MEBE textureid?
    textures: [16]?tex.Texture = [_]?tex.Texture{null} ** 16,
    apex_color: vct.Vector4 = .{},
    horizon_color: vct.Vector4 = .{},
    sun_color: vct.Vector4 = .{},
};
