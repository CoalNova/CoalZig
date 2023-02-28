const std = @import("std");
const zgl = @import("zgl");
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

var shaders : [256]Shader = [_]Shader{.{}} ** 256;

const ShaderTuple = std.meta.Tuple(&.{u8, []const u8});
const shader_names : []ShaderTuple = [_]ShaderTuple
{
    .{255, "./shaders/debug_triangle."}
};

pub fn getShader(shader_program : u8) *Shader
{

    blk:{
        if (shaders[shader_program].program_name == 0)
        {
            var shader = loadShader(shader_program) catch |err|
            {
                std.debug.print("{!}\n",.{err});
                break:blk;
            };
            shaders[shader_program] = shader;
        }
    }
    return &shaders[shader_program];
}

fn loadShader(shader_program : u8) !Shader
{
    var shader : Shader = .{};  
    var vrt_shader_id : u32 = zgl.createShader(zgl.VERTEX_SHADER);
    var geo_shader_id : u32 = zgl.createShader(zgl.GEOMETRY_SHADER);
    var frg_shader_id : u32 = zgl.createShader(zgl.FRAGMENT_SHADER);

    _ = shader_program;
    var result : c_int = zgl.FALSE;
    var log_length : c_int = 0;

    var file = try std.fs.cwd().openFile("./shaders/debug_triangle.vertex.glsl", .{});
    var filetext = try file.readToEndAlloc(alc.gpa_allocator, 65536); 


    var shadertext = try alc.gpa_allocator.alloc(i8, filetext.len + 1);

    for (filetext, 0..) |c, i| 
    {
        var g = c;
        shadertext[i] = @ptrCast(*i8, &g).*;
    }
    shadertext[filetext.len] = 0x00;
    //std.debug.print("{s}\n", .{shadertext});

    std.debug.print("got here\n", .{});
    zgl.getShaderSource(vrt_shader_id, 1, shadertext.len, @ptrCast([*c]i8,shadertext));
    //zgl.shaderSource(vrt_shader_id, 1, @ptrCast([*c]const [*c]const i8,@alignCast(@sizeOf([*c]const [*c]const i8),filetext)), 0);
    zgl.compileShader(vrt_shader_id);
    zgl.getProgramiv(vrt_shader_id, zgl.COMPILE_STATUS, &result);
    zgl.getProgramiv(vrt_shader_id, zgl.INFO_LOG_LENGTH, &log_length);
    file.close();
    alc.gpa_allocator.free(filetext);

    result = zgl.FALSE;
    log_length = 0;

    file = try std.fs.cwd().openFile("./shaders/debug_triangle.geometry.glsl", .{});
    filetext = try file.readToEndAlloc(alc.gpa_allocator, 65536); 
    zgl.shaderSource(geo_shader_id, 1, @ptrCast([*c]const [*c]const i8,@alignCast(8,filetext)), 0);
    zgl.compileShader(geo_shader_id);
    zgl.getProgramiv(geo_shader_id, zgl.COMPILE_STATUS, &result);
    zgl.getProgramiv(geo_shader_id, zgl.INFO_LOG_LENGTH, &log_length);
    alc.gpa_allocator.free(filetext);


    result= zgl.FALSE;
    log_length = 0;

    file = try std.fs.cwd().openFile("./shaders/debug_triangle.fragment.glsl", .{});
    filetext = try file.readToEndAlloc(alc.gpa_allocator, 65536); 
    zgl.shaderSource(frg_shader_id, 1, @ptrCast([*c]const [*c]const i8,@alignCast(8,filetext)), 0);
    zgl.compileShader(frg_shader_id);
    zgl.getProgramiv(frg_shader_id, zgl.COMPILE_STATUS, &result);
    zgl.getProgramiv(frg_shader_id, zgl.INFO_LOG_LENGTH, &log_length);
    alc.gpa_allocator.free(filetext);

    shader.program_name = zgl.createProgram();
    zgl.attachShader(shader.program_name, vrt_shader_id);
    zgl.attachShader(shader.program_name, geo_shader_id);
    zgl.attachShader(shader.program_name, frg_shader_id);
    zgl.linkProgram(shader.program_name);

    return shader;
}