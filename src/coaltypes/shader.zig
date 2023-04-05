const std = @import("std");
const sys = @import("../coalsystem/coalsystem.zig");
const zgl = @import("zgl");
const alc = @import("../coalsystem/allocationsystem.zig");
const rpt = @import("../coaltypes/report.zig");
const wrt = @import("../coalsystem/writersystem.zig");

pub const Shader = struct {
    id: u32 = 0,
    subscribers: u32 = 0,

    program: u32 = 0,
    tex_name: u8 = 8,
    tex_index: u8 = 0,

    mtx_name: i32 = -1, // "matrix"
    mdl_name: i32 = -1, // "model"
    vpm_name: i32 = -1, // "viewproj"
    pst_name: i32 = -1, // "position"
    cam_name: i32 = -1, // "camera"
    rot_name: i32 = -1, // "rotation"
    bnd_name: i32 = -1, // "bounds"
    ind_name: i32 = -1, // "index"
    str_name: i32 = -1, // "stride"
    bse_name: i32 = -1, // "base"
    ran_name: i32 = -1, // "range"
    sun_name: i32 = -1, // "sun"
    aml_name: i32 = -1, // "ambientLuminance"
    amc_name: i32 = -1, // "ambientChroma"
    tx0_name: i32 = -1, // "tex0"
    tx1_name: i32 = -1, // "tex1"
    tx2_name: i32 = -1, // "tex2"
    tx3_name: i32 = -1, // "tex3"
    to0_name: i32 = -1, // "texOffset0"
    to1_name: i32 = -1, // "texOffset1"
    to2_name: i32 = -1, // "texOffset2"
    to3_name: i32 = -1, // "texOffest3"
};

var shaders: std.ArrayList(Shader) = undefined;

const ShaderSystemError = error{
    VertexShaderCompilationError,
    GeometryShaderCompilationError,
    FragmentShaderCompilationError,
    ShaderProgramLinkError,
};

pub fn initializeShaders() void {
    shaders = std.ArrayList(Shader).init(alc.gpa_allocator);
}

pub fn deinitializeShaders() void {
    for (shaders.items) |shader|
        zgl.deleteProgram(shader.program);
    shaders.deinit();
}

pub fn checkoutShader(shader_id: u32) Shader {
    for (shaders.items, 0..) |shader, index|
        if (shader.id == shader_id) {
            shaders.items[index].subscribers += 1;
            return shader;
        };

    return if (shader_id == 0) loadDebugCubeShader() else loadShader(shader_id) catch |err|
        {
        std.debug.print("{}\n", .{err});
        return checkoutShader(0);
    };
}

pub fn checkinShader(shader: Shader) void {
    shader.subscribers -= 1;
    //unkown if shader program removal would be necessaary.
}

fn loadShaderModule(file_prefix: std.ArrayList(u8), file_suffix: []const u8, program: u32, module_type: u32) !u32 {
    var filename: std.ArrayList(u8) = try file_prefix.clone();
    defer filename.deinit();
    try filename.appendSlice(file_suffix);

    var vert_file = try std.fs.cwd().openFile(filename.items, .{});
    defer vert_file.close();

    var shader_source = try alc.gpa_allocator.alloc(u8, (try vert_file.stat()).size + 1);
    defer alc.gpa_allocator.free(shader_source);
    for (0..shader_source.len - 1) |index|
        shader_source[index] = try vert_file.reader().readByte();
    shader_source[shader_source.len - 1] = '\x00';

    var module: u32 = zgl.createShader(module_type);
    zgl.shaderSource(module, 1, @ptrCast([*c]const [*c]const i8, &shader_source.ptr), null);
    zgl.compileShader(module);
    zgl.attachShader(program, module);

    return module;
}

fn checkShaderError(
    module: u32,
    status: u32,
    getIV: *const fn (c_uint, c_uint, [*c]c_int) callconv(.C) void,
    getIL: *const fn (c_uint, c_int, [*c]c_int, [*c]i8) callconv(.C) void,
) bool {
    var is_error = false;
    var result: i32 = 0;
    var length: i32 = 0;
    var info_log: []u8 = undefined;

    getIV(module, status, &result);
    getIV(module, zgl.INFO_LOG_LENGTH, &length);

    if (length > 0) {
        is_error = true;
        info_log = alc.gpa_allocator.alloc(u8, @intCast(usize, length + 1)) catch {
            rpt.logReportInit(@enumToInt(rpt.ReportCatagory.level_error) & @enumToInt(rpt.ReportCatagory.renderer) & @enumToInt(rpt.ReportCatagory.memory_allocation), 101, [4]i32{ @intCast(i32, module), result, 0, 0 });
            return true;
        };
        defer alc.gpa_allocator.free(info_log);
        getIL(module, length, null, @ptrCast([*c]i8, &info_log[0]));
        wrt.print(info_log);
    }

    return is_error;
}

fn loadShader(shader_id: u32) !Shader {
    var shader: Shader = .{};
    shader.id = shader_id;
    shader.subscribers = 1;
    shader.program = zgl.createProgram();

    var filename: std.ArrayList(u8) = std.ArrayList(u8).init(alc.gpa_allocator);
    defer filename.deinit();

    try filename.appendSlice("./shaders/");
    try filename.appendSlice(getShaderName(shader_id));

    const vert_module = try loadShaderModule(filename, ".v.shader", shader.program, zgl.VERTEX_SHADER);
    defer zgl.deleteShader(vert_module);
    if (checkShaderError(vert_module, zgl.COMPILE_STATUS, zgl.getShaderiv, zgl.getShaderInfoLog)) {
        rpt.logReportInit(@enumToInt(rpt.ReportCatagory.level_error) & @enumToInt(rpt.ReportCatagory.renderer), 151, [4]i32{ 0, 0, 0, 0 });
        return ShaderSystemError.VertexShaderCompilationError;
    }

    const geom_module = try loadShaderModule(filename, ".g.shader", shader.program, zgl.GEOMETRY_SHADER);
    defer zgl.deleteShader(geom_module);
    if (checkShaderError(geom_module, zgl.COMPILE_STATUS, zgl.getShaderiv, zgl.getShaderInfoLog)) {
        rpt.logReportInit(@enumToInt(rpt.ReportCatagory.level_error) & @enumToInt(rpt.ReportCatagory.renderer), 153, [4]i32{ 0, 0, 0, 0 });
        return ShaderSystemError.GeometryShaderCompilationError;
    }

    const frag_module = try loadShaderModule(filename, ".f.shader", shader.program, zgl.FRAGMENT_SHADER);
    defer zgl.deleteShader(frag_module);
    if (checkShaderError(frag_module, zgl.COMPILE_STATUS, zgl.getShaderiv, zgl.getShaderInfoLog)) {
        rpt.logReportInit(@enumToInt(rpt.ReportCatagory.level_error) & @enumToInt(rpt.ReportCatagory.renderer), 155, [4]i32{ 0, 0, 0, 0 });
        return ShaderSystemError.FragmentShaderCompilationError;
    }

    zgl.linkProgram(shader.program);

    if (checkShaderError(shader.program, zgl.LINK_STATUS, zgl.getProgramiv, zgl.getProgramInfoLog)) {
        rpt.logReportInit(@enumToInt(rpt.ReportCatagory.level_error) & @enumToInt(rpt.ReportCatagory.renderer), 157, [4]i32{ 0, 0, 0, 0 });
        return ShaderSystemError.ShaderProgramLinkError;
    }

    zgl.useProgram(shader.program);
    std.debug.print("program: {} err: {}\n", .{ shader.program, zgl.getError() });

    shader.mtx_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "matrix\x00"));
    shader.mdl_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "model\x00"));
    shader.mdl_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "viewproj\x00"));
    shader.cam_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "camera\x00"));
    shader.rot_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "rotation\x00"));
    shader.pst_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "position\x00"));
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

fn getShaderName(shader_id: u32) []const u8 {
    return switch (shader_id) {
        0 => "debug_cube",
        65535 => "terrain",
        else => "",
    };
}

fn loadDebugCubeShader() Shader {
    var shader: Shader = .{};
    shader.program = zgl.createProgram();
    //zgl.useProgram(shader.program);
    //std.debug.print("program {}, err {}\n", .{ shader.program, zgl.getError() });

    var vert_module: u32 = zgl.createShader(zgl.VERTEX_SHADER);
    zgl.shaderSource(vert_module, 1, @ptrCast([*c]const [*c]const i8, &debug_cube_v), null);
    defer zgl.deleteShader(vert_module);
    zgl.compileShader(vert_module);
    zgl.attachShader(shader.program, vert_module);

    _ = checkShaderError(vert_module, zgl.COMPILE_STATUS, zgl.getShaderiv, zgl.getShaderInfoLog);

    var geom_module: u32 = zgl.createShader(zgl.GEOMETRY_SHADER);
    zgl.shaderSource(geom_module, 1, @ptrCast([*c]const [*c]const i8, &debug_cube_g), null);
    defer zgl.deleteShader(geom_module);
    zgl.compileShader(geom_module);
    zgl.attachShader(shader.program, geom_module);

    _ = checkShaderError(geom_module, zgl.COMPILE_STATUS, zgl.getShaderiv, zgl.getShaderInfoLog);

    var frag_module: u32 = zgl.createShader(zgl.FRAGMENT_SHADER);
    zgl.shaderSource(frag_module, 1, @ptrCast([*c]const [*c]const i8, &debug_cube_f), null);
    defer zgl.deleteShader(frag_module);
    zgl.compileShader(frag_module);
    zgl.attachShader(shader.program, frag_module);

    _ = checkShaderError(frag_module, zgl.COMPILE_STATUS, zgl.getShaderiv, zgl.getShaderInfoLog);

    zgl.linkProgram(shader.program);

    _ = checkShaderError(shader.program, zgl.LINK_STATUS, zgl.getProgramiv, zgl.getProgramInfoLog);

    zgl.useProgram(shader.program);
    std.debug.print("program: {} err: {}\n", .{ shader.program, zgl.getError() });

    shader.mtx_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "matrix\x00"));
    shader.pst_name = zgl.getUniformLocation(shader.program, @ptrCast([*c]const i8, "position\x00"));

    return shader;
}

const debug_cube_v: []const u8 =
    "#version 330 core\n void main() { } \x00";

const debug_cube_g: []const u8 =
    "#version 330 core\nlayout(points) in;\nlayout(triangle_strip, max_vertices = 36) out;\n" ++
    "uniform mat4 matrix;\nvec3 verts[8] = vec3[](\nvec3(-0.5f, -0.5f, -0.5f),\nvec3(0.5f, -0.5f, -0.5f),\n" ++
    "vec3(-0.5f, -0.5f, 0.5f), vec3(0.5f, -0.5f, 0.5f),\nvec3(0.5f, 0.5f, -0.5f), vec3(-0.5f, 0.5f, -0.5f),\n" ++
    "vec3(0.5f, 0.5f, 0.5f), vec3(-0.5f, 0.5f, 0.5f)\n);\nvoid BuildFace(int fir, int sec, int thr, int frt){\n" ++
    "gl_Position = matrix * vec4(verts[fir], 1.0f);\nEmitVertex();" ++
    "gl_Position = matrix * vec4(verts[sec], 1.0f);\nEmitVertex();" ++
    "gl_Position = matrix * vec4(verts[thr], 1.0f);\nEmitVertex();\nEndPrimitive();" ++
    "gl_Position = matrix * vec4(verts[fir], 1.0f);\nEmitVertex();\n" ++
    "gl_Position = matrix * vec4(verts[frt], 1.0f);\nEmitVertex();\n" ++
    "gl_Position = matrix * vec4(verts[sec], 1.0f);\nEmitVertex();\n" ++
    "EndPrimitive();\n}\nvoid main(){\n" ++
    "BuildFace(0, 3, 2, 1);\nBuildFace(5, 2, 7, 0);\nBuildFace(1, 6, 3, 4);\n" ++
    "BuildFace(2, 6, 7, 3);\nBuildFace(5, 1, 0, 4);\nBuildFace(4, 7, 6, 5);}\x00";

const debug_cube_f: []const u8 =
    "#version 330 core\nout vec4 fColor;\nuniform vec3 position;\nvoid main(){\n" ++
    "fColor = vec4(sin(gl_FragCoord.x * 0.008f + position.x) * 0.4f + 0.8f,\n" ++
    "sin(gl_FragCoord.y * 0.008f + position.y) * 0.4f + 0.8f, sin(position.z) * 0.5f + 0.5f, 1.0f);}\x00";
