pub const Index32_4 = packed struct {
    w: u8 = 0,
    x: u8 = 0,
    y: u8 = 0,
    z: u8 = 0,
};

pub inline fn extract(index: type) u32 {
    switch (@TypeOf(index)) {
        Index32_4 => return @ptrCast(u32, &index).*,
        else => unreachable,
    }
}
