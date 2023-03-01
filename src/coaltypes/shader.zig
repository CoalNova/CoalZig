const std = @import("std");
const sys = @import("../coalsystem/coalsystem.zig");
const glw = sys.glw;
const alc = @import("../coalsystem/allocationsystem.zig");
const rpt = @import("../coaltypes/report.zig");

pub const Shader = struct 
{
    program_name : u32 = 0,
    tex_name : u8 = 8,
    tex_index : u8 = 0,
    
    mtx_name : i32 = -1, // "matrix"
    mdl_name : i32 = -1, // "model"
    cam_name : i32 = -1, // "camera"
    rot_name : i32 = -1, // "rotation"
    bnd_name : i32 = -1, // "bounds"
    ind_name : i32 = -1, // "index"
    str_name : i32 = -1, // "stride"
    bse_name : i32 = -1, // "base"
    ran_name : i32 = -1, // "range"
    sun_name : i32 = -1, // "sun"
    aml_name : i32 = -1, // "ambientLuminance"
    amc_name : i32 = -1, // "ambientChroma"
    tx0_name : i32 = -1, // "tex0"
    tx1_name : i32 = -1, // "tex1"
    tx2_name : i32 = -1, // "tex2"
    tx3_name : i32 = -1, // "tex3"
    to0_name : i32 = -1, // "texOffset0"
    to1_name : i32 = -1, // "texOffset1"
    to2_name : i32 = -1, // "texOffset2"
    to3_name : i32 = -1, // "texOffest3"
};
