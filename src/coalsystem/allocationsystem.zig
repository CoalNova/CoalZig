const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
/// Currently just a static handle for use as a readily accessable allocator
/// TODO create more complex List structures
pub const gpa_allocator = gpa.allocator();


const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
/// Stream Writeable Comparable 
pub const stdout = bw.writer();
    //try bw.flush(); // don't forget to flush!