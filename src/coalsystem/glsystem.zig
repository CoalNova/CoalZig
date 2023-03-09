const std = @import("std");
const zgl = @import("zgl");
const sys = @import("../coalsystem/coalsystem.zig");


pub const GLSError = error{
    GLInitFailed,
    GLValueOoB
}; 

pub fn initalizeGL() !void
{

    zgl.loadCoreProfile(@ptrCast(*const fn([:0]const u8) ?*anyopaque, &sys.sdl.SDL_GL_GetProcAddress), 3, 3) catch
    {
        std.debug.print("GL initialization failed\n", .{});
        return GLSError.GLInitFailed;
    };
}