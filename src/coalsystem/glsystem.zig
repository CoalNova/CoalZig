const std = @import("std");
const zgl = @import("zgl");
const sys = @import("../coalsystem/coalsystem.zig");


pub const GLSError = error{
    GLInitFailed,
    GLValueOoB
}; 

pub var max2DTexArrayLayers : i32 = 0;
pub var maxTexBindingPoints : i32 = 0;
     

pub fn initalizeGL() !void
{

    zgl.loadCoreProfile(@ptrCast(*const fn([:0]const u8) ?*anyopaque, &sys.sdl.SDL_GL_GetProcAddress), 3, 3) catch
    {
        std.debug.print("GL initialization failed\n", .{});
        return GLSError.GLInitFailed;
    };

    zgl.polygonMode(zgl.FRONT_AND_BACK, zgl.FILL);
    zgl.enable(zgl.DEPTH_TEST);
    zgl.enable(zgl.BLEND);
    zgl.blendFunc(zgl.SRC_ALPHA, zgl.ONE_MINUS_SRC_ALPHA);
    zgl.depthFunc(zgl.LESS);
    zgl.clearColor(0.01, 0.0, 0.02, 1.0);


    zgl.getIntegerv(zgl.MAX_ARRAY_TEXTURE_LAYERS, &max2DTexArrayLayers);
    zgl.getIntegerv(zgl.MAX_TEXTURE_IMAGE_UNITS, &maxTexBindingPoints);
}
