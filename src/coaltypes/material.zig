const shd = @import("../coaltypes/shader.zig");
const tex = @import("../coaltypes/texture.zig");

pub const Material = struct {
    id : u32 = 0,
    shader : *shd.Shader = undefined,
    tex : [16]tex.Texture = undefined,
    renderstyle: u32 = 0, 
    subscribers: u32 = 0
}; 