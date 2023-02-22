const std = @import("std");
const alc = @import("../coalsystem/allocationsystem.zig");
const str = @import("../coaltypes/coalstring.zig");

/// A bitmaskable flag series for report classification
pub const ReportCatagory = enum(u16) {
    /// General information, not bad
    level_information = 0b0000_0000_0000_0001,
    /// Something that should not happen, did not happen, or should have happened and didn't
    level_warning = 0b0000_0000_0000_0010,
    /// Something that should never happen, happened
    level_error = 0b0000_0000_0000_0100,
    /// Something bad which prevents execution happened
    level_terminal = 0b0000_0000_0000_1000,
    /// CoalStar system related or catch all
    coal_system = 0b0000_0000_0001_0000,
    /// File IO related
    file_io = 0b0000_0000_0010_0000,
    /// SDL system related
    sdl_system = 0b0000_0000_0100_0000,
    /// Window-specific related
    window_system = 0b0000_0000_1000_0000,
    /// Render engine related
    renderer = 0b0000_0001_0000_0000,
    /// focus/focalpoint related
    focalpoint = 0b0000_0010_0000_0000,
    /// External script related
    scripting = 0b0000_0100_0000_0000,
    /// System memory or allocation related
    memory_allocation = 0b0000_1000_0000_0000,
    /// Asset management or handling related
    asset_system = 0b0001_0000_0000_0000,
    /// Chunk or chunk management related
    chunk_system = 0b0010_0000_0000_0000,
    /// Audio related
    audio_system = 0b0100_0000_0000_0000,
    /// Physics-related
    physics_system = 0b1000_0000_0000_0000,
};

/// Report struct, used to log engine events
pub const Report = struct 
{
    catagory: u16 = 0,
    message: u32 = 0,
    relevant_data: [4]i32 = [_]i32{0} ** 4,
    engine_tick: usize = 0,
    pub fn init(cat: ReportCatagory, mssg: u32, rel_data: [4]i32, e_tick: usize) Report {
        return .{ .catagory = cat, .message = mssg, .relevant_data = rel_data, .engine_tick = e_tick };
    }
};

// bitmask filter for what issues to print to output stream
pub var report_print_mask : u32 = 14;
var report_log: *Report = alc.gpa_allocator.alloc(Report, 32);
var report_count: usize = 0;


pub fn logReport(report: Report) void 
{
    if (report_count >= report_log.len) {
        var new_log: *Report = try alc.gpa_allocator.alloc(Report, report_log.len * 2) catch {};
        for (report_log) |r, i| new_log[i] = r;
        alc.gpa_allocator.free(report_log);
        report_log = new_log;
    }
    report_log[report_count] = report;
    report_count += 1;
    if ((report.catagory & report_print_mask) != 0)
        try alc.stdout.print("", .{}) catch
            std.debug.print("Unable to print to stream writer", .{});
    
    
}

pub fn printReport(report : Report) void
{
    var i : u4 = 0;
    while(i < 16)
    {
        if ((report & (1 << i)) != 0)
            try alc.stdout.print("%s", .{ getCatagoryString(report & (1 << i))}) catch
                std.debug.print("Unable to print to stream writer", .{});
        i += 1;
    }
    
}

pub fn getMessageString(message_index : u16) []u8
{
    switch(message_index)
    {
        0 => return "Praise be the debug cube!",
        2 => return "CoalStar Initialized Successfully",
        3 => return "CoalStar Initialization Failed",
        10 => return "SDL Initialized Succesfully",
        11 => return "SDL Initialization Failed",
        12 => return "SDL Audio Initialized Successfully",
        13 => return "SDL Audio Initialization Failed",
        14 => return "SDL Image Initialized Successfully",
        15 => return "SDL Image Initialization Failed",
        else => return ""
    }
    unreachable;
}

pub fn getCatagoryString(category : u16) []u8
{
    switch(category)
    {
        0b0000_0000_0000_0001 => return "Information",
        0b0000_0000_0000_0010 => return "Warning",
        0b0000_0000_0000_0100 => return "Error",
        0b0000_0000_0000_1000 => return "Terminal",
        0b0000_0000_0001_0000 => return "CoalStar",
        0b0000_0000_0010_0000 => return "File IO",
        0b0000_0000_0100_0000 => return "SDL",
        0b0000_0000_1000_0000 => return "Window",
        0b0000_0001_0000_0000 => return "Rendering",
        0b0000_0010_0000_0000 => return "Focal Point",
        0b0000_0100_0000_0000 => return "External Script(s)",
        0b0000_1000_0000_0000 => return "Memory Allocation",
        0b0001_0000_0000_0000 => return "Asset Management",
        0b0010_0000_0000_0000 => return "Chunk",
        0b0100_0000_0000_0000 => return "Audio",
        0b1000_0000_0000_0000 => return "Physics", 
        else => return "" 
    }
    unreachable;
}