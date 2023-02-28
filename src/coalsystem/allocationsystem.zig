const std = @import("std");
const chk = @import("../coaltypes/chunk.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
/// Currently just a static handle for use as a readily accessable allocator
/// TODO create more complex List structures
pub const gpa_allocator = gpa.allocator();

// Chunk Allocation Table
var cat : []u16 = undefined;

const CATError = error {
    CATAllocationError,
    CATOverflowError,
    CATUnderflowError
};

pub fn initializeCAT() !void
{

}

pub fn addToCAT() !void
{

}