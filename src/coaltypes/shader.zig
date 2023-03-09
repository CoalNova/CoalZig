const std = @import("std");
const sys = @import("../coalsystem/coalsystem.zig");
const zgl = @import("zgl");
const alc = @import("../coalsystem/allocationsystem.zig");
const rpt = @import("../coaltypes/report.zig");

pub const Shader = struct 
{
    id : u32 = 0,
    subscribers : u32 = 0,

    program : u32 = 0,
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

var shaders : std.ArrayList(Shader) = undefined;

pub fn initializeShaders() void
{
    shaders.init(alc.gpa_allocator);
}

pub fn deinitializeShaders() void
{
    for (shaders) |shader| 
        zgl.deleteProgram(shader.program);
    shaders.deinit();
}

pub fn checkoutShader(shader_id : u32) Shader
{
    for (shaders) |shader|
        if (shader.id == shader_id)
        {
            shader.subscribers += 1;
            return &shader;
        }; 
}

pub fn checkinShader(shader : Shader) void 
{
    shader.subscribers -= 1;
    //unkown if shader program removal would be necessaary.
}

fn loadShader(shader_id : u32) !Shader
{
    var shader : Shader = .{};
    shader.id = shader_id;
    shader.subscribers = 1;

    var filename : std.ArrayList(u8) = undefined;
    filename.init(alc.gpa_allocator);
    defer filename.deinit();

    filename.appendSlice("./shaders/");
    filename.appendSlice(getShaderName(shader_id));

    var vert_filename : std.ArrayList(u8) = try filename.clone();
    vert_filename.appendSlice(".v.shader");
    defer vert_filename.deinit();
    var vert_file = try std.fs.cwd().openFile(vert_filename.items, .{});
    defer vert_file.close();
    var vert_source = try vert_file.readToEndAlloc(alc.gpa_allocator, 65536);
    defer alc.gpa_allocator.free(vert_source);
    var vert_shader : u32 = zgl.createShader(zgl.VERTEX_SHADER);
    defer zgl.deleteShader(vert_shader);
    zgl.shaderSource(vert_shader, 1, @ptrCast([*c]const [*c]const i8, &vert_source.ptr), null);
    zgl.compileShader(vert_shader);
    zgl.attachShader(shader.program, vert_shader);

    var geom_filename : std.ArrayList(u8) = try filename.clone();
    vert_filename.appendSlice(".g.shader");
    defer geom_filename.deinit();
    var geom_file = try std.fs.cwd().openFile(geom_filename.items, .{});
    defer geom_file.close();
    var geom_source = try geom_file.readToEndAlloc(alc.gpa_allocator, 65536);
    defer alc.gpa_allocator.free(geom_source);
    var geom_shader : u32 = zgl.createShader(zgl.GEOMETRY_SHADER);
    defer zgl.deleteShader(geom_shader);
    zgl.shaderSource(geom_shader, 1, @ptrCast([*c]const [*c]const i8, &geom_source.ptr), null);
    zgl.compileShader(geom_shader);
    zgl.attachShader(shader.program, geom_shader);

    var frag_filename : std.ArrayList(u8) = try filename.clone();
    vert_filename.appendSlice(".f.shader");
    defer frag_filename.deinit();
    var frag_file = try std.fs.cwd().openFile(frag_filename.items, .{});
    defer frag_file.close();
    var frag_source = try frag_file.readToEndAlloc(alc.gpa_allocator, 65536);
    defer alc.gpa_allocator.free(frag_source);
    var frag_shader : u32 = zgl.createShader(zgl.FRAGMENT_SHADER);
    defer zgl.deleteShader(frag_shader);
    zgl.shaderSource(frag_shader, 1, @ptrCast([*c]const [*c]const i8, &frag_source.ptr), null);
    zgl.compileShader(frag_shader);
    zgl.attachShader(shader.program, frag_shader);

    shader.program = zgl.createProgram();
    zgl.linkProgram(shader.program);
    zgl.useProgram(shader.program);

    shader.mtx_name = zgl.getUniformLocation(shader.program, "matrix");
    shader.mdl_name = zgl.getUniformLocation(shader.program, "model");
    shader.cam_name = zgl.getUniformLocation(shader.program, "camera");
    shader.rot_name = zgl.getUniformLocation(shader.program, "rotation");
    shader.bnd_name = zgl.getUniformLocation(shader.program, "bounds");
    shader.ind_name = zgl.getUniformLocation(shader.program, "index");
    shader.str_name = zgl.getUniformLocation(shader.program, "stride");
    shader.bse_name = zgl.getUniformLocation(shader.program, "base");
    shader.ran_name = zgl.getUniformLocation(shader.program, "range");
    shader.sun_name = zgl.getUniformLocation(shader.program, "sun");
    shader.aml_name = zgl.getUniformLocation(shader.program, "ambientLuminance");
    shader.amc_name = zgl.getUniformLocation(shader.program, "ambientChroma");
    shader.tx0_name = zgl.getUniformLocation(shader.program, "tex0");
    shader.tx1_name = zgl.getUniformLocation(shader.program, "tex1");
    shader.tx2_name = zgl.getUniformLocation(shader.program, "tex2");
    shader.tx3_name = zgl.getUniformLocation(shader.program, "tex3");
    shader.to0_name = zgl.getUniformLocation(shader.program, "texOffset0");
    shader.to1_name = zgl.getUniformLocation(shader.program, "texOffset1");
    shader.to2_name = zgl.getUniformLocation(shader.program, "texOffset2");
    shader.to3_name = zgl.getUniformLocation(shader.program, "texOffest3");

    shaders.append(shader);
    return shader;
}

fn getShaderName(shader_id : u32) []u8
{
    switch (shader_id) {
        0 => return "debug_cube",
        else => "",
    }
    unreachable;
}