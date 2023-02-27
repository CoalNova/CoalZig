const shd = @import("../coaltypes/shader.zig");

pub const Mesh = struct {
    shader : ?*shd.Shader = null
};
