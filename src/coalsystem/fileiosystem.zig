const std = @import("std");
const sys = @import("coalsystem.zig");
const alc = @import("allocationsystem.zig");
const chk = @import("../coaltypes/chunk.zig");
const pnt = @import("../simpletypes/points.zig");

const chunk_file_path = "./assets/map/000_000_000.cshf";

pub const BMP = struct
{
    px : []u8,
    width : u32, 
    height : u32, 
    color_profile : u32	
};

pub fn loadBMP() !BMP
{
    // TODO accept filename as input
    var file = try std.fs.cwd().openFile("./assets/map.bmp", .{});
    defer file.close();
    
    // header containers
	var header_data : [14]u8 = [_]u8{0} ** 14;
    _ = try file.read(&header_data);
    
    var info_data : [40]u8 = [_]u8{0} ** 40;
    _ = try file.read(&info_data);

    // check that file is bitmap
    const file_type : u16 = @bitCast(u16, header_data[0..2].*);
    std.debug.assert(file_type == 0x4D42);
    if (file_type != 0x4d42)
    {
        //log error
        return error.WrongFileType;
    }

    // acquire header data
    var offset : u32 = @bitCast(u32, header_data[10..14].*);

    // generate the bmp struct to contain the data for returning
    var bmp : BMP = 
        .{
            .px = undefined,
            .width = @bitCast(u32, info_data[4..8].*),
            .height = @bitCast(u32, info_data[8..12].*),
            .color_profile = @divFloor(@bitCast(u32, info_data[14..18].*), 8)
        };

    bmp.px = try alc.gpa_allocator.alloc(u8, bmp.width * bmp.height * bmp.color_profile);

    std.debug.assert(bmp.px.len == bmp.width * bmp.height * bmp.color_profile);

    // TODO perhaps load whole file into memory if small enough?
    //      will need to decide what is 'small enough'
    try file.seekTo(0);
    try file.seekTo(offset);

    _ = try file.read(bmp.px);
    return bmp;
}

pub fn getChunkFileName(chunk : *chk.Chunk, filename: []u8) void
{    
    for(chunk_file_path) |c , i|
    {
        filename[i] = c;
    }
    filename[13] = @intCast(u8, @divFloor(chunk.index.x, 100) + 48);
    filename[14] = @intCast(u8, @mod(@divFloor(chunk.index.x, 10) , 10)) + 48;
    filename[15] = @intCast(u8, @mod(chunk.index.x , 10)) + 48;

    filename[17] = @intCast(u8, @divFloor(chunk.index.y, 100) + 48);
    filename[18] = @intCast(u8, @mod(@divFloor(chunk.index.y, 10) , 10)) + 48;
    filename[19] = @intCast(u8, @mod(chunk.index.y , 10)) + 48;
    
    filename[21] = @intCast(u8, @divFloor(chunk.index.z, 100) + 48);
    filename[22] = @intCast(u8, @mod(@divFloor(chunk.index.z, 10), 10)) + 48;
    filename[23] = @intCast(u8, @mod(chunk.index.z, 10)) + 48;
}

pub fn saveChunkHeightFile(chunk : *chk.Chunk) !*chk.Chunk
{

    // TODO internalize allocation and destruction into getname
    var filename : []u8 = try alc.gpa_allocator.alloc(u8, chunk_file_path.len);
    defer alc.gpa_allocator.free(filename);

    getChunkFileName(chunk, filename);
    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();

    _ = try file.write(&@bitCast([@sizeOf(i32)]u8, chunk.index.x));
    _ = try file.write(&@bitCast([@sizeOf(i32)]u8, chunk.index.y));
    _ = try file.write(&@bitCast([@sizeOf(i32)]u8, chunk.index.z));
    _ = try file.write(&@bitCast([1]u8, chunk.height_mod));
    const heights = std.mem.sliceAsBytes(chunk.heights[0..chunk.heights.len]);
    _ = try file.write(heights);


    return chunk;
}

pub fn loadChunkHeightFile(chunk : *chk.Chunk) !*chk.Chunk
{
    var filename : []u8 = try alc.gpa_allocator.alloc(u8, chunk_file_path.len);
    defer alc.gpa_allocator.free(filename);

    getChunkFileName(chunk, filename);
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var index : pnt.Point3 = pnt.Point3.init(0, 0, 0);
    var temp_array = [_]u8{0} ** 4;

    _ = try file.read(&temp_array);
    index.x = @bitCast(i32, temp_array);
    _ = try file.read(&temp_array);
    index.y = @bitCast(i32, temp_array);
    _ = try file.read(&temp_array);
    index.y = @bitCast(i32, temp_array);

    if (index.x != chunk.index.x or index.y != chunk.index.z)
    {
        std.debug.print("Temp debug error, heightfile mismatch for ({d}, {d}, {d})\n", .{chunk.index.x, chunk.index.y, chunk.index.z});
        return chunk;
    }
    var other_temp = [_]u8{0};
    _ = try file.read(&other_temp);


    var temp_heights = try  alc.gpa_allocator.alloc(u8, 512 * 512 * 2);
    defer alc.gpa_allocator.free(temp_heights);
    chunk.heights = try alc.gpa_allocator.alloc(u16, 512 * 512);

    _ = try file.read(temp_heights);
    

    return chunk;
}