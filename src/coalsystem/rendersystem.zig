const std = @import("std");
const zgl = @import("zgl");
const zmt = @import("zmt");
const sys = @import("../coalsystem/coalsystem.zig");
const stp = @import("../coaltypes/setpiece.zig");
const wnd = @import("../coaltypes/window.zig");
const rpt = @import("../coaltypes/report.zig");
const chk = @import("../coaltypes/chunk.zig");
const cam = @import("../coaltypes/camera.zig");
const vct = @import("../simpletypes/vectors.zig");
const sdl = sys.sdl;
const cat = rpt.ReportCatagory;

pub fn renderWindow(window: ?*wnd.Window) void {
    if (window != null) {
        var w = window.?;
        w.camera.calculateMatrices(window.?);

        switch (w.category) {
            wnd.WindowCategory.hardware => renderHardware(w),
            else => {},
        }
    }
}

fn renderHardware(window: *wnd.Window) void {
    if (sdl.SDL_GL_MakeCurrent(window.sdl_window, window.gl_context) != 0) {
        //error here
        return;
    }
    zgl.clear(zgl.COLOR_BUFFER_BIT | zgl.DEPTH_BUFFER_BIT);

    //reject error, embrace plowing through issues we don't care to address
    _ = sdl.SDL_GetWindowSize(window.sdl_window, @ptrCast([*c]c_int, &window.size.x), @ptrCast([*c]c_int, &window.size.y));
    zgl.viewport(0, 0, window.size.x, window.size.y);

    for (window.focal_point.active_chunks) |chunk_index| {
        const chunk = chk.getChunk(chunk_index);
        if (chunk != null) {
            if (chunk.?.setpieces != null) {
                for (chunk.?.setpieces.?.items) |setpiece| {
                    renderHardwareDynamicSetpiece(window.camera, setpiece);
                }
            }
        }
    }

    sdl.SDL_GL_SwapWindow(window.sdl_window);
}

fn renderSoftware(window: *const wnd.Window) void {
    _ = window;
}

fn renderTextware(window: *const wnd.Window) void {
    rpt.logReportInit(@enumToInt(cat.level_warning) | @enumToInt(cat.renderer), 1, [4]i32{ 0, 0, 0, 0 });
    _ = window;
}

fn renderHardwareDynamicSetpiece(camera: cam.Camera, setpiece: stp.Setpiece) void {
    const mesh = setpiece.mesh;

    // const model: zmt.Mat = [_]@Vector(4, f32){
    //     @Vector(4, f32){ 0.5, 0.0, 0.0, 0.0 },
    //     @Vector(4, f32){ 0.0, 0.5, 0.0, 0.0 },
    //     @Vector(4, f32){ 0.0, 0.0, 0.5, 0.0 },
    //     @Vector(4, f32){ 0.0, 0.0, 0.0, 1.0 },
    //};

    const model =
        zmt.mul(zmt.translation(0, 0, 1), zmt.mul(zmt.matFromQuat(setpiece.euclid.quaternion), zmt.scaling(1, 1, 1)));

    const mvp: zmt.Mat =
        zmt.mul(camera.mvp_matrix, model);

    zgl.useProgram(mesh.material.shader.program);
    //bind mesh
    zgl.bindVertexArray(mesh.vao);
    //assign uniforms
    zgl.uniformMatrix4fv(mesh.material.shader.mtx_name, 1, zgl.FALSE, &mvp[0][0]);
    //draw
    zgl.drawElements(mesh.drawstyle_enum, mesh.num_elements, zgl.UNSIGNED_INT, null);
}
