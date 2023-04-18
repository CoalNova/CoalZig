//! FileIOSystem manages IO disk ops in a single location
//!
//!     FIO operations will manage compression and decompression, to prevent
//! confusion on data state.
//!
//!
//!     ChunkHeightData is collapsed in a process of u16->u8 steps. Initial u16
//! height is saved, with each subsequent height as a delta. The height delta's
//! maximum variance is +- 6.4 units. At variances greater than that bounds, a
//! new u16 height is used, prefixed with a 255 byte. It is then compressed
//! using the compression systems in the Zig std. Individual files are then
//! combined into a master file for distribution. Certain OSs don't seem to
//! like working with over ten thousand tiny files.
//!
//!     ChunkOGDdata is a raw list of OGDs, separated by unit placement. It
//! iterates over whole x/y cords, and then it keeps OGDs grouped based on OGD
//! prefix. The prefix is 2bits:
//! 1_ = contains element
//! _1 = element group continues, is not final element
//! If lead bit is 0, then the entry is read as 2byte integer denoting steps to
//! next element entry. Effectively thought of as an i16 to prevent falsely
//! marking the lead bit.
//!
//!     ChunkZoneData will be a pair value list. The first value is the zone
//! byte, the second is a u16 for how many steps. As with all other chunk systems,
//! data is traversed with a mainscan/subscan of x/y. In the future it may be
//! worth checking on cost savings of ping-ponging the x scans to keep possible
//! congruity.
//!
//!
//!     SetpieceContructionData will have metadata regarding a position in a
//! library file for material lookups, mesh, LOD, and any other asset lookup
//! data. It will also contain data on model offsets, physics data, scripted
//! connections, etc.
//!
//!
//!     Meshes will be converted from OBJ files. The OBJ will have its uv's
//! parsed out to different vertices. Once the vertex data (position, normal,
//! and uv) is set, the outermost bounds will be checked for axis of the
//! vertex positions. From there each vertex axis will be assigned a 0-255
//! value, added to the lowest axial position, to the greatest, in increments
//! of difference of the outer bounds.
//!
//!
//!

const std = @import("std");
const sys = @import("../coalsystem/coalsystem.zig");
const alc = @import("../coalsystem/allocationsystem.zig");
const chk = @import("../coaltypes/chunk.zig");
const wnd = @import("../coaltypes/window.zig");
const rpt = @import("../coaltypes/report.zig");
const pnt = @import("../simpletypes/points.zig");
const stp = @import("../coaltypes/setpiece.zig");

const chunk_file_path = "./assets/map/000_000_000.cshf";
const chunk_filename: []const u8 = "./assets/world//00000000._hf";

pub const BMP = struct {
    px: []u8,
    width: u32,
    height: u32,
    color_profile: u32,
};

pub fn loadBMP(filename: []const u8) !BMP {
    // TODO accept filename as input
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    // header containers
    var header_data: [14]u8 = [_]u8{0} ** 14;
    _ = try file.read(&header_data);

    var info_data: [40]u8 = [_]u8{0} ** 40;
    _ = try file.read(&info_data);

    // check that file is bitmap
    const file_type: u16 = @bitCast(u16, header_data[0..2].*);
    std.debug.assert(file_type == 0x4D42);
    if (file_type != 0x4d42) {
        //log error
        return error.WrongFileType;
    }

    // acquire header data
    var offset: u32 = @bitCast(u32, header_data[10..14].*);

    // generate the bmp struct to contain the data for returning
    var bmp: BMP =
        .{ .px = undefined, .width = @bitCast(u32, info_data[4..8].*), .height = @bitCast(u32, info_data[8..12].*), .color_profile = @divFloor(@bitCast(u32, info_data[14..18].*), 8) };

    bmp.px = try alc.gpa_allocator.alloc(u8, bmp.width * bmp.height * bmp.color_profile);

    std.debug.assert(bmp.px.len == bmp.width * bmp.height * bmp.color_profile);

    // TODO perhaps load whole file into memory if small enough?
    //      will need to decide what is 'small enough'
    try file.seekTo(0);
    try file.seekTo(offset);

    _ = try file.read(bmp.px);
    return bmp;
}

/// Returns the path and filename of chunk of provided world and index
/// or else returns allocator error
/// TODO verify useage on older windows systems: "\\" vs "/"
fn getChunkFilename(allocator: std.mem.Allocator, index: pnt.Point3, map_name: []const u8) ![]u8 {
    var filename = std.ArrayList(u8).init(alc.gpa_allocator);
    defer filename.deinit();

    try filename.appendSlice("./assets/world/");
    try filename.appendSlice(map_name);
    try filename.append('/');
    try filename.append(@intCast(u8, @divTrunc(index.x, 1000)) + 48);
    try filename.append(@intCast(u8, @divTrunc(@mod(index.x, 1000), 100)) + 48);
    try filename.append(@intCast(u8, @divTrunc(@mod(index.x, 100), 10)) + 48);
    try filename.append(@intCast(u8, @mod(index.x, 10)) + 48);
    try filename.append(@intCast(u8, @divTrunc(index.y, 1000)) + 48);
    try filename.append(@intCast(u8, @divTrunc(@mod(index.y, 1000), 100)) + 48);
    try filename.append(@intCast(u8, @divTrunc(@mod(index.y, 100), 10)) + 48);
    try filename.append(@intCast(u8, @mod(index.y, 10)) + 48);
    try filename.append('.');
    try filename.append('_');
    try filename.append('h');
    try filename.append('f');

    var name = try allocator.alloc(u8, filename.items.len);
    for (filename.items, 0..) |c, i| name[i] = c;

    return name;
}

const ChunkFileError = error{
    ChunkIndexMismatch,
};

pub fn saveChunkHeights(heights: []u16, height_mod: u8, index: pnt.Point3, map_name: []const u8) !void {
    const filename = try getChunkFilename(alc.gpa_allocator, index, map_name);
    defer alc.gpa_allocator.free(filename);

    var bytes: std.ArrayList(u8) = std.ArrayList(u8).init(alc.gpa_allocator);
    defer bytes.deinit();

    var file = try std.fs.cwd().createFile(filename, std.fs.File.CreateFlags{
        .read = false,
        .truncate = false,
        .exclusive = false,
        .lock = .None,
        .lock_nonblocking = false,
    });
    defer file.close();

    //for now only supports 2d chunk layouts
    try bytes.append(@intCast(u8, index.x));
    try bytes.append(@intCast(u8, index.x >> 8));
    try bytes.append(@intCast(u8, index.x >> 16));
    try bytes.append(@intCast(u8, index.x >> 24));

    try bytes.append(@intCast(u8, index.y));
    try bytes.append(@intCast(u8, index.y >> 8));
    try bytes.append(@intCast(u8, index.y >> 16));
    try bytes.append(@intCast(u8, index.y >> 24));

    try bytes.append(height_mod);

    //individual height processing
    var current_height: u16 = 0;
    for (0..512) |y|
        for (0..512) |x| {
            const h_index = x + y * 512;
            const diff = @intCast(i32, heights[h_index]) - @intCast(i32, current_height) + 64;
            if (diff < 128 and diff >= 0) {
                try bytes.append(@intCast(u8, diff));
                current_height = @intCast(u16, @intCast(i32, current_height) + (diff - 64));
            } else {
                try bytes.append(255);
                current_height = heights[h_index];
                try bytes.append(@truncate(u8, current_height));
                try bytes.append(@truncate(u8, current_height >> 8));
            }
        };

    try file.writeAll(bytes.items);
}

pub fn loadChunkHeights(heights: *[]u16, height_mod: *u8, index: pnt.Point3, map_name: []const u8) !void {
    const filename = try getChunkFilename(alc.gpa_allocator, index, map_name);
    defer alc.gpa_allocator.free(filename);

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var bytes = try file.readToEndAlloc(alc.gpa_allocator, 1 << 20);
    defer alc.gpa_allocator.free(bytes);

    //for now only supports 2d chunk layouts
    var file_index: pnt.Point3 = .{
        .x = @intCast(i32, bytes[0]) + (@intCast(i32, bytes[1]) << @as(i32, 8)) + (@intCast(i32, bytes[2]) << @as(i32, 16)) + (@intCast(i32, bytes[3]) << @as(i32, 24)),
        .y = @intCast(i32, bytes[4]) + (@intCast(i32, bytes[5]) << @as(i32, 8)) + (@intCast(i32, bytes[6]) << @as(i32, 16)) + (@intCast(i32, bytes[7]) << @as(i32, 24)),
        .z = 0,
    };

    if (!file_index.equals(index))
        return ChunkFileError.ChunkIndexMismatch;

    height_mod.* = bytes[8];

    var r_index: usize = 9;
    //individual height processing
    var current_height: u16 = 0;
    for (0..512) |y|
        for (0..512) |x| {
            const h_index = x + y * 512;
            var c = bytes[r_index];
            r_index += 1;
            // check that currentheight isn't being written directly
            if (c == 255) {
                current_height = bytes[r_index] + (@intCast(u16, bytes[r_index + 1]) << 8);
                r_index += 2;
            } else {
                current_height = @intCast(u16, @intCast(i32, current_height) + @intCast(i16, c) - 64);
            }
            heights.*[h_index] = current_height;
        };
}

pub fn saveChunkSetpieces(chunk: chk.Chunk) !void {
    //sort setpiece list by placement
    _ = chunk;
}

pub fn loadChunkSetpieces(chunk: chk.Chunk) !void {
    chunk.setpieces = alc.gpa_allocator.alloc(stp.Setpiece, 1);
}

pub const MetaHeader = struct {
    map_name: []const u8 = undefined,
    map_size: pnt.Point3 = undefined,
    window_init_types: [8]wnd.WindowCategory = undefined,
};

pub fn loadMetaHeader(allocator: std.mem.Allocator) MetaHeader {
    var meta_header: MetaHeader = .{
        .map_name = "dawn",
        .map_size = .{ .x = 128, .y = 128, .z = 4 },
        .window_init_types = [_]wnd.WindowCategory{
            wnd.WindowCategory.hardware,
            wnd.WindowCategory.unused,
            wnd.WindowCategory.unused,
            wnd.WindowCategory.unused,
            wnd.WindowCategory.unused,
            wnd.WindowCategory.unused,
            wnd.WindowCategory.unused,
            wnd.WindowCategory.unused,
        },
    };

    //open file
    var file = std.fs.cwd().openFile("./assets/metahead.cmh", .{}) catch |err|
        {
        //if failed to open, fall back to a default op
        const cat = rpt.ReportCatagory;
        std.debug.print("{}\n", .{err});
        rpt.logReportInit(@enumToInt(cat.level_error) | @enumToInt(cat.file_io), 23, [4]i32{ 0, 0, 0, 0 });
        return meta_header;
    };
    defer file.close();

    //read file
    var data = file.readToEndAlloc(alc.gpa_allocator, 16384) catch |err|
        {
        const cat = rpt.ReportCatagory;
        std.debug.print("{}\n", .{err});
        rpt.logReportInit(@enumToInt(cat.level_error) | @enumToInt(cat.memory_allocation), 101, [4]i32{ 0, 0, 0, 0 });
        return meta_header;
    };
    defer alc.gpa_allocator.free(data);

    var mapname = allocator.alloc(u8, data[0]) catch |err| {
        std.debug.print("{!}\n", .{err});
        return meta_header;
    };

    for (0..data[0]) |i| mapname[i] = data[i + 1];
    meta_header.map_name = mapname;

    var b_index = meta_header.map_name.len + 1;

    meta_header.map_size.x = @intCast(i32, data[b_index]) +
        (@intCast(i32, data[b_index + 1]) << 8) +
        (@intCast(i32, data[b_index + 2]) << 16) +
        (@intCast(i32, data[b_index + 3]) << 24);
    b_index += 4;

    meta_header.map_size.y = @intCast(i32, data[b_index]) +
        (@intCast(i32, data[b_index + 1]) << 8) +
        (@intCast(i32, data[b_index + 2]) << 16) +
        (@intCast(i32, data[b_index + 3]) << 24);
    b_index += 4;

    meta_header.map_size.z = @intCast(i32, data[b_index]) +
        (@intCast(i32, data[b_index + 1]) << 8) +
        (@intCast(i32, data[b_index + 2]) << 16) +
        (@intCast(i32, data[b_index + 3]) << 24);
    b_index += 4;

    for (0..8) |i| meta_header.window_init_types[i] = @intToEnum(wnd.WindowCategory, data[i + b_index]);

    return meta_header;
}

pub fn saveMetaHeader(metaheader: MetaHeader) void {
    const cat = @enumToInt(rpt.ReportCatagory.level_warning) |
        @enumToInt(rpt.ReportCatagory.file_io);

    var file = std.fs.cwd().createFile("./assets/metahead.cmh", std.fs.File.CreateFlags) catch |err| {
        rpt.logReportInit(cat, 21, .{ 0, 0, 0, 0 });
        std.debug.print("{!}\n}", .{err});
        return;
    };
    defer file.close;
    var writer = file.writer();

    writer.writeByte(metaheader.map_name.len) catch |err| {
        rpt.logReportInit(cat, 21, .{ 0, 0, 0, 0 });
        std.debug.print("{!}\n}", .{err});
        return;
    };

    for (metaheader.map_name) |c|
        writer.writeByte(c) catch |err| {
            rpt.logReportInit(cat, 21, .{ 0, 0, 0, 0 });
            std.debug.print("{!}\n}", .{err});
            return;
        };

    writer.writeIntLittle(i32, metaheader.map_size.x) catch |err| {
        rpt.logReportInit(cat, 21, .{ 0, 0, 0, 0 });
        std.debug.print("{!}\n}", .{err});
        return;
    };

    writer.writeIntLittle(i32, metaheader.map_size.y) catch |err| {
        rpt.logReportInit(cat, 21, .{ 0, 0, 0, 0 });
        std.debug.print("{!}\n}", .{err});
        return;
    };

    writer.writeIntLittle(i32, metaheader.map_size.z) catch |err| {
        rpt.logReportInit(cat, 21, .{ 0, 0, 0, 0 });
        std.debug.print("{!}\n}", .{err});
        return;
    };

    for (0..8) |i| {
        writer.writeByte(metaheader.window_init_types[i]) catch |err| {
            rpt.logReportInit(cat, 21, .{ 0, 0, 0, 0 });
            std.debug.print("{!}\n}", .{err});
            return;
        };
    }

    rpt.logReportInit(@enumToInt(rpt.ReportCatagory.level_information) |
        @enumToInt(rpt.ReportCatagory.file_io), 20, .{ 0, 0, 0, 0 });
}
