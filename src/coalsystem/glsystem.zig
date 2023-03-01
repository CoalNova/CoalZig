const sys = @import("../coalsystem/coalsystem.zig");
const sdl = sys.sdl;

pub const GLError = error{
    GLInitFailed,
    GLValueOoB
}; 

pub fn initalizeGL() !void
{


}