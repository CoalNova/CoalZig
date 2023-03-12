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

const chunk_file_path = "./assets/map/000_000_000.cshf";
const chunk_filename : []u8 = "./assets/world//00000000._hf";

pub const BMP = struct { px: []u8, width: u32, height: u32, color_profile: u32 };

pub fn loadBMP() !BMP {
    // TODO accept filename as input
    var file = try std.fs.cwd().openFile("./assets/map.bmp", .{});
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
fn getChunkFilename(allocator : std.mem.Allocator, index : pnt.Point3, map_name : []u8) ![]u8
{
    var filename : []u8 = try allocator.alloc(u8, chunk_filename.len + map_name.len);
    for (0..16) |i| filename[i] = chunk_filename[i];
    for(0..map_name.len) |i| filename[i + 16] = map_name[i];

    filename[17 + map_name.len] = '/';

    filename[17 + map_name.len] = index.x / 1000 + 48;
    filename[18 + map_name.len] = (index.x % 1000) / 100 + 48;
    filename[19 + map_name.len] = (index.x % 100) / 10 + 48;
    filename[20 + map_name.len] = index.x % 10 + 48; 

    filename[21 + map_name.len] = index.y / 1000 + 48;
    filename[22 + map_name.len] = (index.y % 1000) / 100 + 48;
    filename[23 + map_name.len] = (index.y % 100) / 10 + 48;
    filename[24 + map_name.len] = index.y % 10 + 48; 

    filename[25 + map_name.len] = '.';
    filename[26 + map_name.len] = '_';
    filename[27 + map_name.len] = 'h';
    filename[28 + map_name.len] = 'f';

    return filename;
}

const ChunkFileError = error
{
    ChunkIndexMismatch
};

pub fn saveChunkHeights(heights : []u16, height_mod : u8, index : pnt.Point3, map_name : []u8) !void
{
    const filename = try getChunkFilename(alc.gpa_allocator, index, map_name);
    defer alc.gpa_allocator.free(filename);

    var file = try std.fs.cwd().createFile(filename, std.fs.File.CreateFlags{
        .read = false, 
        .truncate = false, 
        .exclusive = false, 
        .lock = .None, 
        .lock_nonblocking = false,
        });
    defer file.close();

    var writer = file.writer();


    //for now only supports 2d chunk layouts
    writer.writeIntLittle(i32, index.x);
    writer.writeIntLittle(i32, index.y);
    writer.writeByte(height_mod);

    //individual height processing
    var current_height : u16 = 0;
    for(0..512) |y|
        for(0..512) |x|
        {
            const h_index  = x + y * 512;
            const diff = @intCast(i32, heights[h_index]) - @intCast(i32, current_height) + 64;
            if (diff < 128 or diff >= 0)
            {
                writer.writeByte(diff);
                current_height =  @intCast(u16, @intCast(i32, current_height) + (diff - 64)); 
            }
            else 
            {
                writer.writeByte(255);
                current_height = heights[h_index];
                writer.writeIntLittle(u16, current_height);
            }
        };
}

pub fn loadChunkHeights(heights : *[]u16, height_mod : *u8, index : pnt.Point3, map_name : []u8) !void
{
    const filename = try getChunkFilename(alc.gpa_allocator, index, map_name);
    defer alc.gpa_allocator.free(filename);

    var file = try std.fs.cwd().createFile(filename, std.fs.File.CreateFlags{
        .read = false, 
        .truncate = false, 
        .exclusive = false, 
        .lock = .None, 
        .lock_nonblocking = false,
        });
    defer file.close();

    var reader = file.reader();
    
    var file_index : pnt.Point2 = .{};

    //for now only supports 2d chunk layouts
    file_index.x = try reader.readIntLittle(i32);
    file_index.y = try reader.readIntLittle(i32);
    
    if (file_index.x != index.x or file_index.y != index.y)
        return ChunkFileError.ChunkIndexMismatch;

    height_mod = try reader.readByte();

    //individual height processing
    var current_height : u16 = 0;
    for(0..512) |y|
        for(0..512) |x|
        {
            const h_index  = x + y * 512;
            const diff = @intCast(i32, heights[h_index]) - @intCast(i32, current_height) + 64;
            if (diff < 128 or diff >= 0)
            {
                reader.readByte(diff);
                current_height =  @intCast(u16, @intCast(i32, current_height) + (diff - 64)); 
            }
            else 
            {
                reader.readByte(255);
                current_height = heights[h_index];
                reader.readIntLittle(u16, current_height);
            }
        };
}


pub const MetaHeader = struct
{
    map_size : pnt.Point3 = undefined,
    window_init_types : [8]wnd.WindowType = undefined,
};

pub fn loadMetaHeader(filename: []u8) MetaHeader 
{
    
    var meta_header : MetaHeader = .{
        .map_size=.{.x = 8,.y = 8,.z = 4}, 
        .window_init_types = [_]wnd.WindowType{
            wnd.WindowType.hardware, 
            wnd.WindowType.unused, 
            wnd.WindowType.unused, 
            wnd.WindowType.unused, 
            wnd.WindowType.unused, 
            wnd.WindowType.unused, 
            wnd.WindowType.unused, 
            wnd.WindowType.unused, 
        }
    };
    
    //open file
    var file = std.fs.cwd().openFile(filename, .{}) catch |err|
    {
        //if failed to open, fall back to a default op
        const cat = rpt.ReportCatagory;
        std.debug.print("{}\n", .{err});
        rpt.logReportInit(@enumToInt(cat.level_error) | @enumToInt(cat.file_io), 41, [4]i32{0,0,0,0});
        return meta_header;
    };
    defer file.close();

    //read file
    var data = file.readToEndAlloc(alc.gpa_allocator, 16384) catch |err|
    {
        const cat = rpt.ReportCatagory;
        std.debug.print("{}\n", .{err});
        rpt.logReportInit(@enumToInt(cat.level_error) | @enumToInt(cat.memory_allocation), 101, [4]i32{0,0,0,0});
        return meta_header;
    };
    defer alc.gpa_allocator.free(data);
    
    var loaded_header : MetaHeader = meta_header;

    //parse data
    var lines = std.mem.split(u8, data, "|");
    loaded_header.map_size = pnt.Point3.init(0, 0, 0);
    for (lines.buffer) |x|
        loaded_header.map_size.x = loaded_header.map_size.x * 10 + (x - 48);
    for (lines.buffer) |y|
        loaded_header.map_size.y = loaded_header.map_size.y * 10 + (y - 48);
    for (lines.buffer) |z|
        loaded_header.map_size.z = loaded_header.map_size.z * 10 + (z - 48);

    meta_header = loaded_header;
    return meta_header;
}
