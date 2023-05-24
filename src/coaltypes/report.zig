//! Report handles the internal engine logging
//!
//!     For now it only recieves reports and stores them, will eventually
//! output a log file on exit.

const std = @import("std");
const alc = @import("../coalsystem/allocationsystem.zig");
const str = @import("../coaltypes/string.zig");
const sys = @import("../coalsystem/coalsystem.zig");

/// A bitmaskable flag series for report classification
pub const ReportCatagory = enum(u32) {
    /// General information
    level_information = 0b0000_0000_0000_0000_0000_0000_0000_0001,
    /// Something that should not, or should have and didn't, happened
    level_warning = 0b0000_0000_0000_0000_0000_0000_0000_0010,
    /// Something that should never happen, happened
    level_error = 0b0000_0000_0000_0000_0000_0000_0000_0100,
    /// Something bad which prevents engine stability, happened
    level_terminal = 0b0000_0000_0000_0000_0000_0000_0000_1000,
    /// CoalStar system related or catch all
    coal_system = 0b0000_0000_0000_0000_0000_0000_0001_0000,
    /// File IO related
    file_io = 0b0000_0000_0000_0000_0000_0000_0010_0000,
    /// SDL system related
    sdl_system = 0b0000_0000_0000_0000_0000_0000_0100_0000,
    /// Window-specific related
    window_system = 0b0000_0000_0000_0000_0000_0000_1000_0000,
    /// Render engine related
    renderer = 0b0000_0000_0000_0000_0000_0001_0000_0000,
    /// focus/focalpoint related
    focalpoint = 0b0000_0000_0000_0000_0000_0010_0000_0000,
    /// External script related
    scripting = 0b0000_0000_0000_0000_0000_0100_0000_0000,
    /// System memory or allocation related
    memory_allocation = 0b0000_0000_0000_0000_0000_1000_0000_0000,
    /// Asset management or handling related
    asset_system = 0b0000_0000_0000_0000_0001_0000_0000_0000,
    /// Chunk or chunk management related
    chunk_system = 0b0000_0000_0000_0000_0010_0000_0000_0000,
    /// Audio related
    audio_system = 0b0000_0000_0000_0000_0100_0000_0000_0000,
    /// Physics related
    physics_system = 0b0000_0000_0000_0000_1000_0000_0000_0000,
    /// Mesh related
    mesh = 0b0000_0000_0000_0001_0000_0000_0000_0000,
    /// Shader related
    shader = 0b0000_0000_0000_0010_0000_0000_0000_0000,
    /// GL system related
    gl_system = 0b0000_0000_0000_0100_0000_0000_0000_0000,
    /// Actor related
    actor = 0b0000_0000_0000_1000_0000_0000_0000_0000,
    /// Setpiece related
    setpiece = 0b0000_0000_1000_0000_0000_0000_0000_0000,
    /// Executor related
    executor = 0b0000_0001_0000_0000_0000_0000_0000_0000,
    /// GPU related
    gpu_related = 0b0001_0000_0000_0000_0000_0000_0000_0000,
    /// Hardware environment related
    hardware = 0b0010_0000_0000_0000_0000_0000_0000_0000,
    /// Operating System related
    operating_system = 0b0100_0000_0000_0000_0000_0000_0000_0000,
    /// General system operation related (not to be used as a catch-all)
    system = 0b1000_0000_0000_0000_0000_0000_0000_0000,
    /// Unused flag
    /// Setting the bitmask will output all messages
    _unused__debugall = 0b1111_1111_1111_1111_1111_1111_1111_1111,
};
//TODO add: setpiece, mesh, update, catching over/underflow, catching worldspace OOB, event

/// Report struct, used to log engine events
pub const Report = struct {
    catagory: u32 = 0,
    message: u32 = 0,
    relevant_data: [4]i32 = [_]i32{0} ** 4,
    engine_tick: usize = 0,
    pub fn init(cat: u32, mssg: u32, rel_data: [4]i32, e_tick: usize) Report {
        return .{ .catagory = cat, .message = mssg, .relevant_data = rel_data, .engine_tick = e_tick };
    }
};

// bitmask filter for what issues to print to output stream
pub var report_print_mask: u32 = 14;
var report_log: []Report = undefined;
var report_count: usize = 0;

pub fn initLog() !void {
    report_log = try alc.gpa_allocator.alloc(Report, 32);
}

pub fn logReport(report: Report) void {
    if (report_count >= report_log.len) {
        var new_log: []Report = alc.gpa_allocator.alloc(Report, report_log.len * 2) catch
            {
            std.debug.print("Unable to print to stream writer\n", .{});
            return;
        };
        for (report_log, 0..) |r, i| new_log[i] = r;
        alc.gpa_allocator.free(report_log);
        report_log = new_log;
    }
    report_log[report_count] = report;
    report_count += 1;
    if ((report.catagory & report_print_mask) != 0)
        printReport(report);
}

pub fn logReportInit(cat: u32, mssg: u32, rel_data: [4]i32) void {
    logReport(Report.init(cat, mssg, rel_data, sys.getEngineTick()));
}

pub fn printReport(report: Report) void {
    std.debug.print(
        "{} {} {s} data: [{},{},{},{}]\n",
        .{
            report.catagory,
            report.engine_tick,
            getMessageString(report.message),
            report.relevant_data[0],
            report.relevant_data[1],
            report.relevant_data[2],
            report.relevant_data[3],
        },
    );
    //TODO
}

pub fn getMessageString(message_index: u32) []const u8 {
    switch (message_index) {
        0 => return "Praise be the cube!",
        1 => return "Not yet implemented",
        2 => return "CoalStar Initialized Successfully",
        3 => return "CoalStar Initialization Failed",
        9 => return "Chunk request index out of bounds",
        10 => return "SDL Initialized Succesfully",
        11 => return "SDL Initialization Failed",
        12 => return "SDL Audio Initialized Successfully",
        13 => return "SDL Audio Initialization Failed",
        14 => return "SDL Image Initialized Successfully",
        15 => return "SDL Image Initialization Failed",
        20 => return "Metaheader file written successfully",
        21 => return "Metaheader file failed to be written",
        22 => return "Metaheader file read successfully",
        23 => return "Metaheader file failed to be read",
        30 => return "Window created successfully",
        31 => return "Window group collection failed",
        33 => return "Window exists outside of group",
        61 => return "GLEW failed initialization",
        81 => return "Failed appending mesh",
        101 => return "Unable to allocate memory",
        151 => return "Vertex Shader compilation error",
        153 => return "Geometry Shader compilation error",
        155 => return "Fragment Shader compilation error",
        157 => return "Shader program link error",
        201 => return "Attempted to render a chunk whose mesh is null",
        301 => return "Attempted to remove an executor which was not subscribed",
        401 => return "Unable to open chunk file for saving",
        403 => return "Unable to open setpiece file for saving",
        405 => return "Unable to open actor file for saving",
        407 => return "Unable to open LODWorld file for saving",
        501 => return "Regionmap.bmp could not be loaded for zone processing",
        else => return "Report text not yet implemented",
    }
    unreachable;
}

pub fn getCatagoryString(category: u16) []const u8 {
    switch (category) {
        0b0000_0000_0000_0000_0000_0000_0000_0001 => return "Information",
        0b0000_0000_0000_0000_0000_0000_0000_0010 => return "Warning",
        0b0000_0000_0000_0000_0000_0000_0000_0100 => return "Error",
        0b0000_0000_0000_0000_0000_0000_0000_1000 => return "Terminal",
        0b0000_0000_0000_0000_0000_0000_0001_0000 => return "CoalStar",
        0b0000_0000_0000_0000_0000_0000_0010_0000 => return "File IO",
        0b0000_0000_0000_0000_0000_0000_0100_0000 => return "SDL",
        0b0000_0000_0000_0000_0000_0000_1000_0000 => return "Window",
        0b0000_0000_0000_0000_0000_0001_0000_0000 => return "Rendering",
        0b0000_0000_0000_0000_0000_0010_0000_0000 => return "Focal Point",
        0b0000_0000_0000_0000_0000_0100_0000_0000 => return "External Script(s)",
        0b0000_0000_0000_0000_0000_1000_0000_0000 => return "Memory Allocation",
        0b0000_0000_0000_0000_0001_0000_0000_0000 => return "Asset Management",
        0b0000_0000_0000_0000_0010_0000_0000_0000 => return "Chunk",
        0b0000_0000_0000_0000_0100_0000_0000_0000 => return "Audio",
        0b0000_0000_0000_0000_1000_0000_0000_0000 => return "Physics",
        0b0000_0000_0000_0001_0000_0000_0000_0000 => return "Mesh",
        0b0000_0000_0000_0010_0000_0000_0000_0000 => return "Shader",
        0b0000_0000_0000_0100_0000_0000_0000_0000 => return "OpenGL",
        0b0000_0000_0000_1000_0000_0000_0000_0000 => return "Actor",
        0b0000_0000_1000_0000_0000_0000_0000_0000 => return "Setpiece",
        0b0000_0001_0000_0000_0000_0000_0000_0000 => return "Executor",
        else => return "Unknown",
    }
    unreachable;
}
