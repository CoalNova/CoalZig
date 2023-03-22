const std = @import("std");
const zgl = @import("zgl");
const mtl = @import("../coaltypes/material.zig");
const alc = @import("../coalsystem/allocationsystem.zig");
const chk = @import("../coaltypes/chunk.zig");
const fcs = @import("../coaltypes/focus.zig");
const pst = @import("../coaltypes/position.zig");
const rpt = @import("../coaltypes/report.zig");

pub const Mesh = struct {
    id : u32 = 0,
    material : mtl.Material = .{},
    subscribers : u32 = 0,
    vao : u32 = 0,
    vbo : u32 = 0,
    ibo : u32 = 0,
    vio : u32 = 0,
    vertex_size : usize = 1,
    drawstyle_enum : u32 = 0,
    num_elements : i32 = 0,
    static : bool = false
};

/// Mesh global collection
/// not globally accessible
/// just remains in scope
var meshes : ?std.ArrayList(Mesh) = null;

pub fn checkoutMesh(mesh_id : u32) ?Mesh
{
    if (meshes == null)
        meshes = std.ArrayList(Mesh).init(alc.gpa_allocator);
    
    for(meshes.?.items) |mesh|
        if (mesh_id == mesh.id)
            return mesh;

    return loadMesh(mesh_id); 
} 

pub fn checkinMesh(mesh : Mesh) void
{
    for(&meshes.?.items) |*m|
    {
        if (mesh.id == m.id)
            m.subscribers -= 1;
    } 
}

fn loadMesh(mesh_id : u32) ?Mesh
{
    var mesh : Mesh = .{.id = mesh_id};
    
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
    const buff_data : u32 = 1;
    zgl.bufferData(zgl.ARRAY_BUFFER, @sizeOf(u32), &buff_data, zgl.STATIC_DRAW);
    zgl.bufferData(zgl.ELEMENT_ARRAY_BUFFER, @sizeOf(u32), &buff_data, zgl.STATIC_DRAW);
    zgl.vertexAttribPointer(1, @sizeOf(u32), zgl.FLOAT, 0, @sizeOf(u32), null);
    zgl.enableVertexAttribArray(1);



    mesh.num_elements = 1;

    meshes.?.append(mesh) catch |err| {
        std.debug.print("{}\n", .{err});
        rpt.logReportInit(@enumToInt(rpt.ReportCatagory.level_error), 
            81, [4]i32{@intCast(i32, mesh_id),0,0,0});
        return checkoutMesh(0);
    };
    return mesh;
}


const terrain_mesh_res_rings = [4]pst.vct.Vector2{
    .{.x = 18, .y = 12},
    .{.x = 72, .y = 48},
    .{.x = 388, .y = 192},
    .{.x = 1152, .y = 768}, 
};

pub fn constructBaseTerrainMesh(chunk: *chk.Chunk, focal_point : fcs.Focus) void {
    
    //probably check that mesh is not already constructed
    chunk.mesh = Mesh{};
    for (0..1025) |y|
        for (0..1025) |x|
        {
            var height = chk.getHeight(pst.Position.init(chunk.index, .{.x = x, .y = y, .z = 0}));
            _ = height;

        };
    
    terrainMeshResolutionSubRun(chunk, focal_point);
}

fn terrainMeshResolutionSubRun(
    chunk: *chk.Chunk, 
    focal_point: fcs.Focus, 
    new_ibo: *std.ArrayList(i32), 
    cur_x: usize, 
    cur_y: usize, 
    stride: usize, 
    ring_index: i32
    ) void
{
    const width = 1025;

    for (0..4) |y|
        for(0..4) |x|
        {
            const dist = (focal_point.position.squareDistance(pst.Position.init(chunk.index, .{
                .x = cur_x + x * stride, .y = cur_x + y * stride, .z = 0})));

            const index = cur_x + x * stride + cur_y + y * stride * width;
            const valid_inner = if (ring_index < 0) false 
                else (dist < @intToFloat(f32, terrain_mesh_res_rings[@intCast(usize, ring_index)].x * 
                    terrain_mesh_res_rings[@intCast(usize, ring_index)].x)); 
            const valid_outer = if (ring_index < 0) true
                else (dist > @intToFloat(f32, terrain_mesh_res_rings[@intCast(usize, ring_index)].y * 
                    terrain_mesh_res_rings[@intCast(usize, ring_index).y]));

            if (valid_inner)
                terrainMeshResolutionSubRun(chunk, focal_point, cur_x + x * stride, cur_y + y * stride, stride / 4, ring_index - 1);
            
            if (valid_outer)
            {
                new_ibo.append(index);
                new_ibo.append(index + stride);
                new_ibo.append(index + stride + stride * width);
                new_ibo.append(index);
                new_ibo.append(index + stride + stride * width);
                new_ibo.append(index + stride * width);
            }
        };
}

pub fn updateTerrainMeshResolution(chunk: *chk.Chunk, focal_point: fcs.Focus) void 
{
    
    var new_ibo = std.ArrayList(u32).init(alc.gpa_allocator);
    defer new_ibo.deinit();

    terrainMeshResolutionSubRun(chunk, focal_point, new_ibo, 0, 0, 256, 3);

    if (chunk.mesh.ibo != 0)
    {
        //delete ibo
        zgl.deleteBuffers(1, &chunk.mesh.ibo);
    }    

    //generate and attach ibo
    zgl.genBuffers(1, &chunk.mesh.ibo);
    zgl.bindBuffer(zgl.ELEMENT_ARRAY_BUFFER, chunk.mesh.ibo);
    zgl.bufferData(zgl.ELEMENT_ARRAY_BUFFER, @sizeOf(u32) * new_ibo.items.len, &new_ibo.items, zgl.STATIC_DRAW);
}
