/// Two-part integral vector, good for indexing
pub const Point2 = struct {
    x: i32 = 0,
    y: i32 = 0,
    /// Inline Initializer
    pub inline fn init(x: i32, y: i32) Point2 {
        return .{ .x = x, .y = y };
    }
    pub inline fn add(point: Point2) Point2 {
        return init(.x + point.x, .y + point.y);
    }
    pub inline fn equals(point: Point2) bool {
        return .x == point.x and .y == point.y;
    }
};

/// Three-part integral vector, good for indexing
pub const Point3 = struct {
    x: i32 = 0,
    y: i32 = 0,
    z: i32 = 0,
    /// Inline Initializer
    pub inline fn init(x: i32, y: i32, z: i32) Point3 {
        return .{ .x = x, .y = y, .z = z };
    }
    pub inline fn add(self: Point3, point: Point3) Point3 {
        return init(self.x + point.x, self.y + point.y, self.z + point.z);
    }
    pub inline fn equals(self: Point3, point: Point3) bool {
        return self.x == point.x and self.y == point.y and self.z == point.z;
    }
};

/// Four-part integral vector, good for indexing
pub const Point4 = struct {
    w: i32 = 0,
    x: i32 = 0,
    y: i32 = 0,
    z: i32 = 0,
    /// Inline Initializer
    pub inline fn init(w: i32, x: i32, y: i32, z: i32) Point4 {
        return .{ .w = w, .x = x, .y = y, .z = z };
    }
    pub inline fn add(point: Point4) Point4 {
        return init(.w + point.w, .x + point.x, .y + point.y, .z + point.z);
    }
    pub inline fn equals(point: Point4) bool {
        return .w == point.w and .x == point.x and .y == point.y and .z == point.z;
    }
};
