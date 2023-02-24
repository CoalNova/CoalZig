pub const pnt = @import("../simpletypes/points.zig");
pub const vct = @import("../simpletypes/vectors.zig");

/// Worldspace position, contains the dimensional index and the intradimensional axial coordinates
/// stores position as a packed signed 64 bit integers, per axis
///
pub const Position = struct {
    x: i64 = 0,
    y: i64 = 0,
    z: i64 = 0,
    /// The dimensional index of the position
    pub inline fn index(self: Position) pnt.Point3 {
        return .{ .x = @intCast(i32, (self.x >> 28)), .y = @intCast(i32, (self.y >> 28)), .z = @intCast(i32, (self.z >> 32)) };
    }

    pub inline fn axial(self: Position) vct.Vector3 {
        return .{
            .x = @intToFloat(f32, (self.x & ((1 << 28) - 1))) / @intToFloat(f32, (1 << 18)),
            .y = @intToFloat(f32, (self.y & ((1 << 28) - 1))) / @intToFloat(f32, (1 << 18)),
            .z = @intToFloat(f32, (self.z & ((1 << 28) - 1))) / @intToFloat(f32, (1 << 18)),
        };
    }

    pub inline fn init(_index: pnt.Point3, _axial: vct.Vector3) Position {
        var x = @intCast(i64, _index.x) << 28;
        var y = @intCast(i64, _index.y) << 28;
        var z = @intCast(i64, _index.z) << 32;

        x += @floatToInt(i64, _axial.x * @intToFloat(f32, (1 << 18)));
        y += @floatToInt(i64, _axial.y * @intToFloat(f32, (1 << 18)));
        z += @floatToInt(i64, _axial.z * @intToFloat(f32, (1 << 18)));

        return .{ .x = x, .y = y, .z = z };
    }
};
