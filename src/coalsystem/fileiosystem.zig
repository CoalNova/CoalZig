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
fn getChunkFilename(allocator : std.mem.Allocator, index : pnt.Point3, world_name : []u8) ![]u8
{
    var filename : []u8 = try allocator.alloc(u8, chunk_filename.len + world_name.len);
    for (0..16) |i| filename[i] = chunk_filename[i];
    for(0..world_name.len) |i| filename[i + 16] = world_name[i];

    filename[17 + world_name.len] = '/';

    filename[17 + world_name.len] = index.x / 1000 + 48;
    filename[18 + world_name.len] = (index.x % 1000) / 100;
    filename[19 + world_name.len] = (index.x % 100) / 10;
    filename[20 + world_name.len] = index.x % 10; 

    filename[21 + world_name.len] = index.y / 1000 + 48;
    filename[22 + world_name.len] = (index.y % 1000) / 100;
    filename[23 + world_name.len] = (index.y % 100) / 10;
    filename[24 + world_name.len] = index.y % 10; 

    filename[25 + world_name.len] = '.';
    filename[26 + world_name.len] = '_';
    filename[27 + world_name.len] = 'h';
    filename[28 + world_name.len] = 'f';

    return filename;
}

pub fn saveChunkHeights(heights : []u16, height_mod : u8, index : pnt.Point3, world_name : []u8) !void
{
    const filename = try getChunkFilename(alc.gpa_allocator, index, world_name);
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
    //TODO bit twiddle to compress heights
    //TODO also compress heights
    writer.write(height_mod);
    for(heights) |height| file.writer().writeIntLittle(u16, height);

}

pub const MetaHeader = struct
{
    map_size : pnt.Point3 = undefined,
    window_init_types : [8]wnd.WindowType = undefined,
};

pub fn loadMetaHeader(filename: []u8) MetaHeader {
    
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
