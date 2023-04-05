const std = @import("std");
const zgl = @import("zgl");
const mtl = @import("../coaltypes/material.zig");
const alc = @import("../coalsystem/allocationsystem.zig");
const chk = @import("../coaltypes/chunk.zig");
const fcs = @import("../coaltypes/focus.zig");
const pst = @import("../coaltypes/position.zig");
const rpt = @import("../coaltypes/report.zig");

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

pub fn constructBaseTerrainMesh(chunk: *chk.Chunk, focal_point: *fcs.Focus) void {

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
            // [0] szzz_zzzz_zzzz_zzzz_zzZo_ZoZo_ZoXn_XnXn
            // [1] XnYn_YnYn_Ynxx_xxxx_xxxx_xyyy_yyyy_yyyy
            var super_zone: u32 = 0;
            var super_vert: u32 = (@intCast(u22, x) << 11) + @intCast(u11, y);
            //var height = chk.getHeight(pst.Position.init(chunk.index, .{ .x = @intToFloat(f32, x), .y = @intToFloat(f32, y), .z = 0 }));

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

    std.debug.print("{}\n", .{vbo.items.len});

    zgl.bufferData(zgl.ARRAY_BUFFER, @intCast(isize, @sizeOf(f32) * vbo.items.len), @ptrCast(?*const anyopaque, vbo.items), zgl.STATIC_DRAW);

    //void glVertexAttribPointer(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const void * pointer);
    zgl.vertexAttribPointer(0, @sizeOf(f32), zgl.FLOAT, 0, @sizeOf(f32) * 2, null);
    zgl.vertexAttribPointer(1, @sizeOf(f32), zgl.FLOAT, 0, @sizeOf(f32) * 2, @intToPtr(*void, @sizeOf(f32)));
    zgl.enableVertexAttribArray(0);
    zgl.enableVertexAttribArray(1);

    updateTerrainMeshResolution(chunk, focal_point);
}

const terrain_mesh_res_rings = [4]pst.vct.Vector2{
    .{ .x = 18, .y = 12 },
    .{ .x = 72, .y = 48 },
    .{ .x = 388, .y = 192 },
    .{ .x = 1152, .y = 768 },
};

pub fn updateTerrainMeshResolution(chunk: *chk.Chunk, focal_point: *fcs.Focus) void {
    var new_ibo = std.ArrayList(u32).init(alc.gpa_allocator);
    defer new_ibo.deinit();

    //terrainMeshResolutionSubRun(chunk, focal_point, &new_ibo, 0, 0, 256, 3);
    _ = focal_point;

    for (0..128) |y|
        for (0..128) |x| {
            const index = @truncate(u32, x * 8 + y * 8 * 1025);
            new_ibo.append(index) catch return;
            new_ibo.append(index + 8) catch return;
            new_ibo.append(index + 8 + 8 * 1025) catch return;
            new_ibo.append(index) catch return;
            new_ibo.append(index + 8 + 8 * 1025) catch return;
            new_ibo.append(index + 8 * 1025) catch return;
        };

    if (chunk.mesh.?.ibo != 0) {
        //delete ibo
        zgl.deleteBuffers(1, &chunk.mesh.?.ibo);
    }

    chunk.mesh.?.num_elements = @intCast(i32, new_ibo.items.len);
    std.debug.print("ibo {}\n", .{new_ibo.items.len});

    //generate and attach ibo
    zgl.genBuffers(1, &chunk.mesh.?.ibo);
    zgl.bindBuffer(zgl.ELEMENT_ARRAY_BUFFER, chunk.mesh.?.ibo);
    zgl.bufferData(zgl.ELEMENT_ARRAY_BUFFER, @intCast(isize, @sizeOf(u32) * new_ibo.items.len), @ptrCast(?*const anyopaque, new_ibo.items), zgl.STATIC_DRAW);
}

fn terrainMeshResolutionSubRun(chunk: *chk.Chunk, focal_point: *fcs.Focus, new_ibo: *std.ArrayList(u32), cur_x: usize, cur_y: usize, stride: usize, ring_index: i32) void {
    const width = 1025;

    for (0..4) |y|
        for (0..4) |x| {
            const dist = (focal_point.position.squareDistance(pst.Position.init(chunk.index, .{ .x = @intToFloat(f32, cur_x + x * stride), .y = @intToFloat(f32, cur_x + y * stride), .z = 0 })));

            const index = cur_x + x * stride + cur_y + y * stride * width;
            const valid_inner = if (ring_index < 0) false else (dist < terrain_mesh_res_rings[@intCast(usize, ring_index)].x *
                terrain_mesh_res_rings[@intCast(usize, ring_index)].x);
            const valid_outer = if (ring_index < 0) true else (dist > terrain_mesh_res_rings[@intCast(usize, ring_index)].y *
                terrain_mesh_res_rings[@intCast(usize, ring_index)].y);

            if (valid_inner)
                terrainMeshResolutionSubRun(chunk, focal_point, new_ibo, cur_x + x * stride, cur_y + y * stride, stride / 4, ring_index - 1);

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
