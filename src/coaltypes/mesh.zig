const std = @import("std");
const shd = @import("../coaltypes/shader.zig");
const alc = @import("../coalsystem/allocationsystem.zig");

pub const Mesh = struct {
    id : u32 = 0,
    shader : *shd.Shader = undefined,
    subscribers : u32 = 0,
    vao : u32 = 0,
    vbo : u32 = 0,
    ibo : u32 = 0,
    vio : u32 = 0
};

var meshes : []Mesh = undefined;
var mesh_count : u32 = 0;

pub fn getMesh(mesh_id : u32) !*Mesh
{
    
    for(0..mesh_count) |index|
        if (mesh_id == meshes[index].id)
        {
            return &meshes[index];
        };
    return try loadMesh(mesh_id); 
} 

fn loadMesh(mesh_id : u32) !*Mesh
{
    var mesh : Mesh = .{.id = mesh_id};
    //shader lookup, or bundled into mesh ID... somehow
    mesh.shader = shd.getShader(mesh_id);

    //check to resize mesh collection
    if (mesh_count >= meshes.len)
    {   
        var new_mesh_size : usize = if (meshes.len == 0) 4 else meshes.len * 2;
        var new_meshes : []Mesh = undefined;
        new_meshes = try alc.gpa_allocator.alloc(Mesh, new_mesh_size);

        for (meshes, 0..) |m, i| new_meshes[i] = m;
        if (meshes.len > 0)
            alc.gpa_allocator.free(meshes);
        meshes = new_meshes;
    }
    meshes[mesh_count] = mesh;
    mesh_count += 1;
    return &meshes[mesh_count - 1];
}