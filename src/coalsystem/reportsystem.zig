const std = @import("std");
const gpa = std.heap.GeneralPurposeAllocator;
const rpt = @import("../coaltypes/report.zig");

// report pool statics 
const report_pool_size = 100;
var report_pool : [report_pool_size]rpt.Report = [_]rpt.Report{.{}} ** report_pool_size;
var report_pool_indexer : usize = 0;

// a mask of when to output reports to terminal
var report_verbosity_mask : u16 = 0;

/// Logs Report and prints to console, if verbosity mask has flags set
/// TODO report string concatination for printing
/// TODO report allocation pool
/// TODO engine flag assessments, probably
pub fn logReport(report : rpt.Report) void
{
    report_pool[report_pool_indexer] = report;    
    report_pool_indexer += 1;
    if (report_pool_indexer >= report_pool_size)
    {
        dumpPoolToDisk() catch unreachable;
        report_pool_indexer = 0;
    }
}

/// Outputs report log to disk
/// TODO append to new file each run
/// TODO iterate limited logfile quantity push  1 -> 2, 2 -> 3, etcetera
pub fn dumpPoolToDisk() !void
{
    var file = try std.fs.cwd().openFile("logfile.txt", .{});
    file.close();
}