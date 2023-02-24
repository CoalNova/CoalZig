const std = @import("std");

pub const String = struct {
    data: *u8 = undefined,
    data_len: usize = 0,
    data_cap: usize = 0,

    pub fn init(str: String, allocator: std.mem.Allocator, char_array: []u8) !void {
        if (str.data_cap > 0)
            delete(str);

        str.data_cap = 8;
        while (str.data_cap < char_array.len)
            str.data_cap <<= 1;

        str.data = try allocator.alloc(u8, str.data_cap);
        str.data_len = char_array.len;
        for (char_array, 0..) |c, i| str.data[i] = c;
    }

    pub fn concat(str: String, allocator: std.mem.Allocator, to_concat: []u8) !void {
        if (to_concat.len > str.data_cap - str.data_len) {
            while (str.data_cap < str.data_len + to_concat.len)
                str.data_cap <<= 1;

            var new_data = try allocator.alloc(u8, str.data_cap);
            for (str.data, 0..) |c, i| new_data[i] = c;
            allocator.free(str.data);
            str.data = new_data;
        }
        for (str.to_concat, 0..) |c, i| str.data[i + str.data_len] = c;
        str.data_len += to_concat.len;
    }

    pub fn flush(str: String, allocator: std.mem.Allocator) !void {
        allocator.free(str.data);
        str.data_cap = 16;
        str.data = try allocator.alloc(u8, str.data_cap);
        str.data_len = 0;
    }

    pub fn delete(str: String, allocator: std.mem.Allocator) void {
        allocator.free(str.data);
        str.data_cap = 0;
        str.data_len = 0;
    }
};
