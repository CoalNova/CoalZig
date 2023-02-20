const alc = @import("../coalsystem/allocationsystem");

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
pub const Report = struct {
    catagory: u16 = 0,
    message: u32 = 0,
    relevant_data: [4]i32 = [_]i32{0} ** 4,
    engine_tick: usize = 0,
    pub fn init(cat: ReportCatagory, mssg: u32, rel_data: [4]i32, e_tick: usize) Report {
        return .{ .catagory = cat, .message = mssg, .relevant_data = rel_data, .engine_tick = e_tick };
    }
};

var report_log: *Report = alc.gpa_allocator.alloc(Report, 32);
var report_count: usize = 0;

pub fn logReport(report: Report) void {
    if (report_count >= report_log.len) {
        var new_log: *Report = try alc.gpa_allocator.alloc(Report, report_log.len * 2) catch {};
        for (report_log) |r, i| new_log[i] = r;
        alc.gpa_allocator.free(report_log);
        report_log = new_log;
    }
    report_log[report_count] = report;
    report_count += 1;
}
