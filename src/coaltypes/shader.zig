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
    for (shaders.items, 0..) |shader, index|
        if (shader.id == shader_id)
        {
            shaders.items[index].subscribers += 1;
            return shader;
        }; 

    //std.process.exit(0);

    return if (shader_id == 0) loadDebugCubeShader() 
        else loadShader(shader_id) catch |err|
    {
        std.debug.print("{}\n", .{err});
        return checkoutShader(0);
    };
}

pub fn checkinShader(shader : Shader) void 
{
    shader.subscribers -= 1;
    //unkown if shader program removal would be necessaary.
}

fn loadShaderModule(shader_name : []u8, program : u32, module_type : u32) !u32
{
    var vert_file = try std.fs.cwd().openFile(shader_name, .{});
    defer vert_file.close();

    var shader_source = try alc.gpa_allocator.alloc(u8, (try vert_file.stat()).size + 1);
    defer alc.gpa_allocator.free(shader_source);
    for(0..shader_source.len - 1) |index|
        shader_source[index] = try vert_file.reader().readByte();    
    shader_source[shader_source.len - 1] = '\x00';

    var module : u32 = zgl.createShader(module_type);
    zgl.shaderSource(module, 1, @ptrCast([*c]const [*c]const i8, &shader_source.ptr), null);
    zgl.compileShader(module);
    zgl.attachShader(program, module);

    return module;
}

fn loadShader(shader_id : u32) !Shader
{
    var shader : Shader = .{};
    shader.id = shader_id;
    shader.subscribers = 1;
    shader.program = zgl.createProgram();

    var filename : std.ArrayList(u8) = std.ArrayList(u8).init(alc.gpa_allocator);
    defer filename.deinit();

    try filename.appendSlice("./shaders/");
    try filename.appendSlice(getShaderName(shader_id));

    var vert_filename : std.ArrayList(u8) = try filename.clone();
    defer vert_filename.deinit();
    try vert_filename.appendSlice(".v.shader");
    const vertex_module = try loadShaderModule(vert_filename.items, shader.program, zgl.VERTEX_SHADER);
    defer zgl.deleteShader(vertex_module);

    var geom_filename : std.ArrayList(u8) = try filename.clone();
    defer geom_filename.deinit();
    try geom_filename.appendSlice(".g.shader");
    const geometry_module = try loadShaderModule(geom_filename.items, shader.program, zgl.GEOMETRY_SHADER);
    defer zgl.deleteShader(geometry_module);
    
    var frag_filename : std.ArrayList(u8) = try filename.clone();
    defer frag_filename.deinit();
    try frag_filename.appendSlice(".f.shader");
    const fragment_module = try loadShaderModule(frag_filename.items, shader.program, zgl.FRAGMENT_SHADER);
    defer zgl.deleteShader(fragment_module);

    zgl.linkProgram(shader.program);
    zgl.useProgram(shader.program);

    shader.mtx_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "matrix\x00"));
    shader.mdl_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "model\x00"));
    shader.cam_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "camera\x00"));
    shader.rot_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "rotation\x00"));
    shader.bnd_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "bounds\x00"));
    shader.ind_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "index\x00"));
    shader.str_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "stride\x00"));
    shader.bse_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "base\x00"));
    shader.ran_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "range\x00"));
    shader.sun_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "sun\x00"));
    shader.aml_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "ambientLuminance\x00"));
    shader.amc_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "ambientChroma\x00"));
    shader.tx0_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "tex0\x00"));
    shader.tx1_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "tex1\x00"));
    shader.tx2_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "tex2\x00"));
    shader.tx3_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "tex3\x00"));
    shader.to0_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "texOffset0\x00"));
    shader.to1_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "texOffset1\x00"));
    shader.to2_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "texOffset2\x00"));
    shader.to3_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "texOffest3\x00"));

    try shaders.append(shader);
    return shader;
}

fn getShaderName(shader_id : u32) []const u8
{
    return switch (shader_id) {
        0 => "debug_cube",
        else => "",
    };
}


fn loadDebugCubeShader() Shader
{

    var info_log : []u8 = undefined;
    var result : i32 = 0;
    var info_length : i32 = 0;
    
    var shader : Shader = .{};
    shader.program = zgl.createProgram();
    zgl.useProgram(shader.program);

    var vert_module : u32 = zgl.createShader(zgl.VERTEX_SHADER);
    zgl.shaderSource(vert_module, 1, @ptrCast([*c]const [*c]const i8, &debug_cube_v), null);
    defer zgl.deleteShader(vert_module);
    zgl.compileShader(vert_module);
    zgl.attachShader(shader.program, vert_module);

    zgl.getShaderiv(vert_module, zgl.COMPILE_STATUS, &result);
    zgl.getShaderiv(vert_module, zgl.INFO_LOG_LENGTH, &info_length);
    log_blk :
    {
        if (info_length > 0) 
        {
            info_log = alc.gpa_allocator.alloc(u8, @intCast(usize, info_length + 1)) catch |err| 
            {
                std.debug.print("{}\n", .{err}); 
                break : log_blk;
            };
            defer alc.gpa_allocator.free(info_log);
            zgl.getShaderInfoLog(vert_module, info_length, null, @ptrCast([*c]i8, &info_log[0]));
            std.debug.print("Vertex: {} {} \n{s}\n", .{vert_module, info_length, info_log});
            result = 0;
            info_length = 0;
        }
    }

    var geom_module : u32 = zgl.createShader(zgl.GEOMETRY_SHADER);
    zgl.shaderSource(geom_module, 1, @ptrCast([*c]const [*c]const i8, &debug_cube_g), null);
    defer zgl.deleteShader(geom_module);
    zgl.compileShader(geom_module);
    zgl.attachShader(shader.program, geom_module);

    zgl.getShaderiv(geom_module, zgl.COMPILE_STATUS, &result);
    zgl.getShaderiv(geom_module, zgl.INFO_LOG_LENGTH, &info_length);
    log_blk :
    {
        if (info_length > 0) 
        {
            info_log = alc.gpa_allocator.alloc(u8, @intCast(usize, info_length + 1)) catch |err| 
            {
                std.debug.print("{}\n", .{err}); 
                break : log_blk;
            };
            defer alc.gpa_allocator.free(info_log);
            zgl.getShaderInfoLog(geom_module, info_length, null, @ptrCast([*c]i8, &info_log[0]));
            std.debug.print("Geometry: {} {} \n{s}\n", .{geom_module, info_length, info_log});
            result = 0;
            info_length = 0;
        }
    }

    var frag_module : u32 = zgl.createShader(zgl.FRAGMENT_SHADER);
    zgl.shaderSource(frag_module, 1, @ptrCast([*c]const [*c]const i8, &debug_cube_f), null);
    defer zgl.deleteShader(frag_module);
    zgl.compileShader(frag_module);
    zgl.attachShader(shader.program, frag_module);
    zgl.getShaderiv(frag_module, zgl.COMPILE_STATUS, &result);
    zgl.getShaderiv(frag_module, zgl.INFO_LOG_LENGTH, &info_length);
    log_blk :
    {
        if (info_length > 0) 
        {
            info_log = alc.gpa_allocator.alloc(u8, @intCast(usize, info_length + 1)) catch |err| 
            {
                std.debug.print("{}\n", .{err}); 
                break : log_blk;
            };
            defer alc.gpa_allocator.free(info_log);
            zgl.getShaderInfoLog(frag_module, info_length, null, @ptrCast([*c]i8, &info_log[0]));
            std.debug.print("Fragment: {} {} \n{s}\n", .{frag_module, info_length, info_log});
            result = 0;
            info_length = 0;
        }
    }

    zgl.linkProgram(shader.program);
    zgl.getProgramiv(shader.program, zgl.LINK_STATUS, &result);
    zgl.getProgramiv(shader.program, zgl.INFO_LOG_LENGTH, &info_length);
    log_blk :
    {
        if (info_length > 0) 
        {
            info_log = alc.gpa_allocator.alloc(u8, @intCast(usize, info_length + 1)) catch |err| 
            {
                std.debug.print("{}\n", .{err}); 
                break : log_blk;
            };
            defer alc.gpa_allocator.free(info_log);
            zgl.getProgramInfoLog(shader.program, info_length, null, @ptrCast([*c]i8, &info_log[0]));
            std.debug.print("{} {} \n{s}\n", .{result, info_length, info_log});
            result = 0;
            info_length = 0;
        }
    }

    zgl.useProgram(shader.program);

    shader.mtx_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "matrix\x00"));

    return shader;
}

const debug_cube_v : []const u8 = 
"#version 330 core\n layout (location = 0) in vec3 inPos;" ++
"out vec4 pos;\n void main() { pos = vec4(inPos, 1.0f);} \x00";
const debug_cube_g : []const u8 = 
"#version 330 core\n  layout(points) in; layout(triangle_strip, max_vertices = 36) out; out vec4 fPos;\n uniform mat4 matrix; vec3 verts[8] = vec3[]( vec3(-0.5f, -0.5f, -0.5f),\n vec3(0.5f, -0.5f, -0.5f), vec3(-0.5f, -0.5f, 0.5f),\n vec3(0.5f, -0.5f, 0.5f), vec3(0.5f, 0.5f, -0.5f),\n vec3(-0.5f, 0.5f, -0.5f), vec3(0.5f, 0.5f, 0.5f),\n vec3(-0.5f, 0.5f, 0.5f)); void BuildFace(int fir, int sec, int thr, int frt){ fPos = matrix * vec4(verts[fir], 1.0f);\n gl_Position = fPos; \n EmitVertex(); fPos = matrix * vec4(verts[sec], 1.0f);\n gl_Position = fPos; \n EmitVertex(); fPos = matrix * vec4(verts[thr], 1.0f);\n gl_Position = fPos; \n EmitVertex(); EndPrimitive(); fPos = matrix * vec4(verts[fir], 1.0f);\n gl_Position = fPos;\n EmitVertex(); fPos = matrix * vec4(verts[frt], 1.0f);\n gl_Position = fPos;\n EmitVertex(); fPos = matrix * vec4(verts[sec], 1.0f);\n gl_Position = fPos;\n EmitVertex(); EndPrimitive(); } \n void main(){ BuildFace(0, 3, 2, 1);\n  BuildFace(5, 2, 7, 0); BuildFace(1, 6, 3, 4);\n  BuildFace(2, 6, 7, 3); BuildFace(5, 1, 0, 4);\n  BuildFace(4, 7, 6, 5);} \x00";

const debug_cube_f : []const u8 = 
"#version 330 core\n in vec4 fPos;\n out vec4 fColor;" ++
"void main(){fColor = vec4(sin(fPos.x) * 0.4f + 1.2f, " ++
"sin(fPos.y) * 0.4f + 1.2f, 0.8f, 1.0f); } \x00";