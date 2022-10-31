const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
/// Currently just a static handle for use as a readily accessable allocator
/// TODO create more complex List structures
pub const gpa_allocator = gpa.allocator();

