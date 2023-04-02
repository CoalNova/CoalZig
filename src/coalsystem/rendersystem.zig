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
const pst = @import("../coaltypes/position.zig");
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

    //for every active chunk index listed to the focal point
    for (window.focal_point.active_chunks) |chunk_index| {
        //check that they aren't too far away
        const diff = window.focal_point.position.index().differenceAbs(chunk_index);
        if (diff.x < 2 and diff.y < 2 and diff.z < 1) {
            //get the chunk
            if (chk.getChunk(chunk_index) != null) {
                const chunk = chk.getChunk(chunk_index).?;
                renderTerrain(chunk, window.camera);
                if (chunk.setpieces.items.len > 0) {
                    for (chunk.setpieces.items) |setpiece| {
                        renderHardwareDynamicSetpiece(window.camera, setpiece);
                    }
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
    const axial = setpiece.euclid.position.axial();
    const model =
        zmt.mul(zmt.translation(axial.x, axial.y, axial.z), zmt.mul(zmt.matFromQuat(setpiece.euclid.quaternion), zmt.scaling(1, 1, 1)));

    const mvp: zmt.Mat =
        zmt.mul(model, camera.mvp_matrix);

    zgl.useProgram(mesh.material.shader.program);
    //bind mesh
    zgl.bindVertexArray(mesh.vao);

    //TODO uniform blasting (possibly bounds checked?)
    //assign uniforms
    zgl.uniformMatrix4fv(mesh.material.shader.mtx_name, 1, zgl.FALSE, &mvp[0][0]);
    //draw
    zgl.drawElements(mesh.drawstyle_enum, mesh.num_elements, zgl.UNSIGNED_INT, null);
}

fn renderTerrain(chunk: *chk.Chunk, camera: cam.Camera) void {
    if (chunk.mesh == null) {
        const category = @enumToInt(cat.level_warning) | @enumToInt(cat.renderer);
        rpt.logReportInit(category, 201, [4]i32{ chunk.index.x, chunk.index.y, chunk.index.z, 0 });
        return;
    }
    const diff = chunk.index.difference(camera.euclid.position.index());
    const mesh = chunk.mesh.?;
    const model = zmt.mul(zmt.translation(@intToFloat(f32, diff.x) * 1024.0, @intToFloat(f32, diff.y) * 1024.0, 0), zmt.scaling(1, 1, 1));

    var gl_err = zgl.getError();
    const mvp: zmt.Mat =
        zmt.mul(model, camera.mvp_matrix);

    zgl.useProgram(mesh.material.shader.program);
    zgl.bindVertexArray(mesh.vao);
    zgl.uniformMatrix4fv(mesh.material.shader.mtx_name, 1, zgl.FALSE, &mvp[0][0]);
    zgl.drawElements(mesh.drawstyle_enum, mesh.num_elements, zgl.UNSIGNED_INT, null);

    if (gl_err > 0)
        std.debug.print("ibo buff err {}\n", .{gl_err});
}
