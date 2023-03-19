const std = @import("std");
const msh = @import("../coaltypes/mesh.zig");
const euc = @import("../coaltypes/euclid.zig");
const ogd = @import("../coaltypes/ogd.zig");
const pst = @import("../coaltypes/position.zig");

pub const Setpiece = struct 
{
    euclid : euc.Euclid = .{},
    mesh : msh.Mesh = undefined   
};

pub fn getSetpiece(obj_gen_data : ogd.OGD) Setpiece
{


    //parse ogd go here
    var setpiece : Setpiece =.{};
    setpiece.euclid.position = pst.Position.init(.{}, .{.x = 1.0, .y = 1.0, .z = 0.0});
    //TODO parse out the fun bits
    
    //for all fallback: return debug cube(all hail)
    
    setpiece.mesh = msh.checkoutMesh(@truncate(u32, (obj_gen_data.base >> 8))).?;
    return setpiece;
}