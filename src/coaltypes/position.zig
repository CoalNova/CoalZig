pub const pnt = @import("../simpletypes/points.zig");
pub const vct = @import("../simpletypes/vectors.zig");

const AxialDivisor : f64 = 1.0/28.0;

/// Worldspace position, contains the dimensional index and the intradimensional axial coordinates
/// stores position as a packed signed 64 bit integers, per axis the breakdown of packed data is:
/// 24 bits for sub-unit positioning allows for 0.0596 microns of granularity
/// 10 bits for whole unit positioning per x,y dimension(0 - 1024), 20 for z(0 - 1048576)
/// 29 bits for x, y dimensional index(0 - 536870912), 19 for z (0 - 524288)
/// final bit ignored to retain signed happiness
pub const Position = struct {
    x: i64 = 0,
    y: i64 = 0,
    z: i64 = 0,
    /// The dimensional index of the position
    pub inline fn index(self: Position) pnt.Point3 {
        return .{ .x = @intCast(i32, (self.x >> 24)), .y = @intCast(i32, (self.y >> 28)), .z = @intCast(i32, (self.z >> 32)) };
    }

    pub inline fn isX_Rounded(self : Position) bool {return (self.x & ((1<<24) - 1)) == 0;}
    pub inline fn isY_Rounded(self : Position) bool {return (self.y & ((1<<24) - 1)) == 0;}
    pub inline fn isZ_Rounded(self : Position) bool {return (self.z & ((1<<24) - 1)) == 0;}

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
