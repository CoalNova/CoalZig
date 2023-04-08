const std = @import("std");
const zgl = @import("zgl");
const mtl = @import("../coaltypes/material.zig");
const alc = @import("../coalsystem/allocationsystem.zig");
const chk = @import("../coaltypes/chunk.zig");
const fcs = @import("../coaltypes/focus.zig");
const pst = @import("../coaltypes/position.zig");
const rpt = @import("../coaltypes/report.zig");
const zmt = @import("zmt");

pub const Mesh = struct {
    id: u32 = 0,
    material: mtl.Material = .{},
    subscribers: u32 = 0,
    vao: u32 = 0,
    vbo: u32 = 0,
    ibo: u32 = 0,
    vio: u32 = 0,
    vertex_size: usize = 1,
    drawstyle_enum: u32 = 0,
    num_elements: i32 = 0,
    static: bool = false,
};

/// Mesh global collection
/// not globally accessible
/// just remains in scope
var meshes: ?std.ArrayList(Mesh) = null;

pub fn checkoutMesh(mesh_id: u32) ?Mesh {
    if (meshes == null)
        meshes = std.ArrayList(Mesh).init(alc.gpa_allocator);

    for (meshes.?.items) |mesh|
        if (mesh_id == mesh.id)
            return mesh;

    return loadMesh(mesh_id);
}

pub fn checkinMesh(mesh: Mesh) void {
    for (&meshes.?.items) |*m| {
        if (mesh.id == m.id)
            m.subscribers -= 1;
    }
}

fn loadMesh(mesh_id: u32) ?Mesh {
    var mesh: Mesh = .{ .id = mesh_id };

    //TODO resolve mesh_id gets material_id
    mesh.material = mtl.checkoutMaterial(@intCast(u16, mesh_id));

    zgl.genVertexArrays(1, &mesh.vao);
    zgl.genBuffers(1, &mesh.vbo);
    zgl.genBuffers(1, &mesh.ibo);
    zgl.genBuffers(1, &mesh.vio);

    //TODO not the debug cube
    mesh.drawstyle_enum = zgl.POINTS;
    zgl.bindVertexArray(mesh.vao);
    zgl.bindBuffer(zgl.ARRAY_BUFFER, mesh.vbo);
    zgl.bindBuffer(zgl.ELEMENT_ARRAY_BUFFER, mesh.ibo);
    const buff_data: u32 = 1;
    zgl.bufferData(zgl.ARRAY_BUFFER, @sizeOf(u32), &buff_data, zgl.STATIC_DRAW);
    zgl.bufferData(zgl.ELEMENT_ARRAY_BUFFER, @sizeOf(u32), &buff_data, zgl.STATIC_DRAW);
    //void glVertexAttribPointer(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const void * pointer);
    zgl.vertexAttribPointer(1, @sizeOf(u32), zgl.FLOAT, 0, @sizeOf(u32), null);
    zgl.enableVertexAttribArray(1);

    mesh.num_elements = 1;

    meshes.?.append(mesh) catch |err| {
        std.debug.print("{}\n", .{err});
        rpt.logReportInit(@enumToInt(rpt.ReportCatagory.level_error), 81, [4]i32{ @intCast(i32, mesh_id), 0, 0, 0 });
        return checkoutMesh(0);
    };
    return mesh;
}

pub fn destroyTerrainMesh(chunk: *chk.Chunk) void {
    if (chunk.mesh != null) {
        var mesh = chunk.mesh.?;
        zgl.deleteBuffers(1, &mesh.vao);
        zgl.deleteBuffers(1, &mesh.vbo);
        zgl.deleteBuffers(1, &mesh.ibo);
        alc.gpa_allocator.destroy(mesh);
        chunk.mesh = null;
    }
}

pub fn constructBaseTerrainMesh(chunk: *chk.Chunk, focal_position: pst.Position) void {

    //probably check that mesh is not already constructed
    chunk.mesh = alc.gpa_allocator.create(Mesh) catch |err| {
        std.debug.print("{!}\n", .{err});
        const cat = @enumToInt(rpt.ReportCatagory.level_terminal) |
            @enumToInt(rpt.ReportCatagory.renderer) |
            @enumToInt(rpt.ReportCatagory.chunk_system);
        rpt.logReportInit(cat, 101, [4]i32{ chunk.index.x, chunk.index.y, 0, 0 });
        return;
    };
    var mesh = chunk.mesh.?;
    mesh.material = mtl.checkoutMaterial(65535);
    mesh.drawstyle_enum = zgl.TRIANGLES;

    zgl.useProgram(mesh.material.shader.program);

    zgl.genVertexArrays(1, &mesh.vao);
    zgl.bindVertexArray(mesh.vao);

    zgl.genBuffers(1, &mesh.vbo);
    zgl.genBuffers(1, &mesh.ibo);

    zgl.bindBuffer(zgl.ARRAY_BUFFER, mesh.vbo);
    zgl.bindBuffer(zgl.ELEMENT_ARRAY_BUFFER, mesh.ibo);

    //TODO fixed buffer solution for in-scope traversal?
    var vbo = std.ArrayList(u32).init(alc.gpa_allocator);
    defer vbo.deinit();

    //catagory should vbo append fail
    const app_cat = @enumToInt(rpt.ReportCatagory.level_error) |
        @enumToInt(rpt.ReportCatagory.memory_allocation) |
        @enumToInt(rpt.ReportCatagory.chunk_system) |
        @enumToInt(rpt.ReportCatagory.renderer);

    for (0..1025) |y|
        for (0..1025) |x| {
            var position = pst.Position.init(
                chunk.index,
                .{ .x = @intToFloat(f32, x) - 512, .y = @intToFloat(f32, y) - 512.0, .z = 0 },
            );

            var height = chk.getHeight(position);

            var n = chk.getHeight(position.addAxial(.{ .x = 1, .y = 0, .z = 0 }));
            var s = chk.getHeight(position.addAxial(.{ .x = -1, .y = 0, .z = 0 }));
            var e = chk.getHeight(position.addAxial(.{ .x = 0, .y = 1, .z = 0 }));
            var w = chk.getHeight(position.addAxial(.{ .x = 0, .y = -1, .z = 0 }));

            const north = zmt.f32x4(0, 1, (n - height), 1.0);
            const south = zmt.f32x4(0, -1, (s - height), 1.0);
            const east = zmt.f32x4(1, 0, (e - height), 1.0);
            const west = zmt.f32x4(-1, 0, (w - height), 1.0);
            const norm = zmt.normalize3(zmt.cross3(south, west) + zmt.cross3(north, east));

            const xi_norm: u8 = @floatToInt(u8, norm[0] * 128.0 + 127);
            const yi_norm: u8 = @floatToInt(u8, norm[1] * 128.0 + 127);

            // [0] szzz_zzzz_zzzz_zzzz_zzZo_ZoZo_ZoXn_XnXn
            // [1] XnYn_YnYn_Ynxx_xxxx_xxxx_xyyy_yyyy_yyyy
            var super_zone: u32 = 0;
            var super_vert: u32 = (@intCast(u22, x) << 11) + @intCast(u11, y);
            //var height = chk.getHeight(pst.Position.init(chunk.index, .{ .x = @intToFloat(f32, x), .y = @intToFloat(f32, y), .z = 0 }));

            super_zone += @floatToInt(u31, height * 10.0) << 14;
            super_zone += xi_norm >> 2;
            super_vert += @as(u32, @truncate(u2, xi_norm)) << 30;
            super_vert += @as(u32, yi_norm) << 22;

            vbo.append(super_zone) catch
                return rpt.logReportInit(app_cat, 101, [4]i32{ 0, 0, 0, 0 });
            vbo.append(super_vert) catch
                return rpt.logReportInit(app_cat, 101, [4]i32{ 0, 0, 0, 0 });

            //ah, yes, *this* bug. I haven't a clue.
            if (x == 1024 and y == 1024) {
                vbo.append(super_zone) catch
                    return rpt.logReportInit(app_cat, 101, [4]i32{ 0, 0, 0, 0 });
                vbo.append(super_vert) catch
                    return rpt.logReportInit(app_cat, 101, [4]i32{ 0, 0, 0, 0 });
                vbo.append(super_zone) catch
                    return rpt.logReportInit(app_cat, 101, [4]i32{ 0, 0, 0, 0 });
                vbo.append(super_vert) catch
                    return rpt.logReportInit(app_cat, 101, [4]i32{ 0, 0, 0, 0 });
            }
        };

    zgl.bufferData(zgl.ARRAY_BUFFER, @intCast(isize, @sizeOf(f32) * vbo.items.len), @ptrCast(?*const anyopaque, vbo.items), zgl.STATIC_DRAW);

    //void glVertexAttribPointer(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const void * pointer);
    zgl.vertexAttribPointer(0, @sizeOf(f32), zgl.FLOAT, 0, @sizeOf(f32) * 2, null);
    zgl.vertexAttribPointer(1, @sizeOf(f32), zgl.FLOAT, 0, @sizeOf(f32) * 2, @intToPtr(*void, @sizeOf(f32)));
    zgl.enableVertexAttribArray(0);
    zgl.enableVertexAttribArray(1);

    updateTerrainMeshResolution(chunk, focal_position);
}

pub fn updateTerrainMeshResolution(chunk: *chk.Chunk, focal_position: pst.Position) void {
    var new_ibo = std.ArrayList(u32).init(alc.gpa_allocator);
    defer new_ibo.deinit();

    zgl.bindVertexArray(chunk.mesh.?.vao);
    
    const index = chunk.index.difference(focal_position.index());
    const axial = focal_position.axial().add(.{ .x = @intToFloat(f32, index.x * 1024), .y = @intToFloat(f32, index.y * 1024), .z = 0 });
    //terrainMeshResolutionSubRun(axial, &new_ibo, 0, 0, 256);

    for (0..1024) |y|
        for (0..1024) |x| {
            const dist = (axial.x - (@intToFloat(f32, x) - 512.0)) * (axial.x - (@intToFloat(f32, x) - 512.0)) +
                (axial.y - (@intToFloat(f32, y) - 512.0)) * (axial.y - (@intToFloat(f32, y) - 512.0));
            if (dist < 64) {
                procFace(x, y, 1, &new_ibo);
            }
        };

    if (chunk.mesh.?.ibo != 0) {
        //delete ibo
        zgl.deleteBuffers(1, &chunk.mesh.?.ibo);
    }
    chunk.mesh.?.num_elements = @intCast(i32, new_ibo.items.len);

    //generate and attach ibo
    zgl.genBuffers(1, &chunk.mesh.?.ibo);
    zgl.bindBuffer(zgl.ELEMENT_ARRAY_BUFFER, chunk.mesh.?.ibo);
    zgl.bufferData(zgl.ELEMENT_ARRAY_BUFFER, @intCast(isize, @sizeOf(u32) * new_ibo.items.len), @ptrCast(?*const anyopaque, new_ibo.items), zgl.STATIC_DRAW);

    std.debug.print("{}, {}, {}\n", .{
        chunk.index.x,
        chunk.index.y,
        chunk.mesh.?.ibo,
    });
}

fn terrainMeshResolutionSubRun(focal_axial: pst.vct.Vector3, new_ibo: *std.ArrayList(u32), cur_x: usize, cur_y: usize, stride: usize) void {
    const width = 1025;

    for (0..4) |y|
        for (0..4) |x| {
            const diffx = focal_axial.x - (@intToFloat(f32, cur_x + x * stride + stride >> 1) - 512.0);
            const diffy = focal_axial.y - (@intToFloat(f32, cur_y + y * stride + stride >> 1) - 512.0);
            const dist = diffx * diffx + diffy * diffy;

            const valid_inner: bool = dist < @intToFloat(f32, (stride * stride));
            const valid_outer: bool = dist > @intToFloat(f32, (stride * stride));

            if (valid_inner and stride > 1)
                terrainMeshResolutionSubRun(focal_axial, new_ibo, cur_x + x * stride, cur_y + y * stride * width, if (stride == 1) 1 else stride / 4);

            const index = cur_x + x * stride + cur_y + y * stride * width;
            if (valid_outer) {
                new_ibo.append(@truncate(u32, index)) catch return;
                new_ibo.append(@truncate(u32, index + stride)) catch return;
                new_ibo.append(@truncate(u32, index + stride + stride * width)) catch return;
                new_ibo.append(@truncate(u32, index)) catch return;
                new_ibo.append(@truncate(u32, index + stride + stride * width)) catch return;
                new_ibo.append(@truncate(u32, index + stride * width)) catch return;
            }
        };
}

fn procFace(x: usize, y: usize, stride: usize, new_ibo: *std.ArrayList(u32)) void {
    const width = 1025;
    const index = x + y * width;
    new_ibo.append(@truncate(u32, index)) catch return;
    new_ibo.append(@truncate(u32, index + stride)) catch return;
    new_ibo.append(@truncate(u32, index + stride + stride * width)) catch return;
    new_ibo.append(@truncate(u32, index)) catch return;
    new_ibo.append(@truncate(u32, index + stride + stride * width)) catch return;
    new_ibo.append(@truncate(u32, index + stride * width)) catch return;
}
