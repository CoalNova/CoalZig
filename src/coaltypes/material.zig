const std = @import("std");
const shd = @import("../coaltypes/shader.zig");
const tex = @import("../coaltypes/texture.zig");
const alc = @import("../coalsystem/allocationsystem.zig");

pub const Material = struct {
    id: u32 = 0,
    shader: shd.Shader = undefined,
    tex: [16]tex.Texture = undefined,
    renderstyle: u32 = 0,
    subscribers: u32 = 0,
};

var materials: ?std.ArrayList(Material) = null;

pub fn checkoutMaterial(mat_id: u16) Material {
    if (materials == null)
        materials = std.ArrayList(Material).init(alc.gpa_allocator);
    for (materials.?.items) |material|
        if (material.id == mat_id)
            return material;
    return loadMaterial(mat_id);
}

pub fn loadMaterial(mat_id: u16) Material {
    var mat: Material = .{};
    mat.id = mat_id;
    //this is where a db system needs to exist
    //materials will most likely utilize multiple textures

    switch (mat_id) {
        65535 => { //terrain
            mat.renderstyle = 0;
            //TODO texture stack

        },
        else => {},
    }
    mat.shader = shd.checkoutShader(mat_id);

    materials.?.append(mat) catch |err|
        {
        std.debug.print("{}\n", .{err});
        return checkoutMaterial(0);
    };
    return mat;
}
