const std = @import("std");

/// Catchall string writer.
/// TODO divert string printing to contextual output
/// e.g. console, textware window, console
/// will probably need some sort of nullable context or callback
pub fn print(string: []u8) void {
    std.debug.print("{s}\n", .{string});
}
