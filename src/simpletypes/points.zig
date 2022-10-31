/// Two-part integral vector, good for indexing
pub const Point2 = struct
{
    x : i32 = 0,
    y : i32 = 0,
    /// Inline Initializer
    pub inline fn init(x : i32, y : i32) Point2
    {
        return .{.x = x, .y = y};
    }
};

/// Two-part integral vector, good for indexing
pub const Point3 = struct
{
    x : i32 = 0,
    y : i32 = 0,
    z : i32 = 0,
    /// Inline Initializer
    pub inline fn init(x : i32, y : i32, z : i32) Point3
    {
        return .{.x = x, .y = y, .z = z};
    }
};

/// Two-part integral vector, good for indexing
pub const Point4 = struct
{
    w : i32 = 0,
    x : i32 = 0,
    y : i32 = 0,
    z : i32 = 0,
    /// Inline Initializer
    pub inline fn init(w : i32, x : i32, y : i32, z : i32) Point4
    {
        return .{.w = w, .x = x, .y = y, .z = z};
    }
};