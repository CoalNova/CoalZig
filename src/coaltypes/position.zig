pub const pnt = @import("../simpletypes/points.zig");
pub const vct = @import("../simpletypes/vectors.zig");

const AxialDivisor : f32 = 1.0 / (1 << 24);
const AxialFilter : i64 = ((1 << 34) - 1);
const MajorFilter : i64 = (((1 << 39) - 1) << 24);
const MinorFilter : i64 = ((1 << 24) - 1);

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
        return .{ .x = @truncate(i32, (self.x >> 24)), .y = @truncate(i32, (self.y >> 28)), .z = @truncate(i32, (self.z >> 32)) };
    }

    pub inline fn isX_Rounded(self : Position) bool {return (self.x & ((1<<24) - 1)) == 0;}
    pub inline fn isY_Rounded(self : Position) bool {return (self.y & ((1<<24) - 1)) == 0;}
    pub inline fn isZ_Rounded(self : Position) bool {return (self.z & ((1<<24) - 1)) == 0;}

    pub inline fn round(self : Position) Position
    {
        var p = .{};
        p.x = self.x ^ (self.x & MinorFilter);
        p.y = self.y ^ (self.y & MinorFilter);
        p.z = self.z ^ (self.z & MinorFilter);
        return p;
    }

    pub inline fn addAxial(self : Position, _axial : vct.Vector3) Position
    {
        var p : Position = self;
        p.x += @floatToInt(i64, @intToFloat(f32, _axial.x) / AxialDivisor);
        p.y += @floatToInt(i64, @intToFloat(f32, _axial.y) / AxialDivisor);
        p.z += @floatToInt(i64, @intToFloat(f32, _axial.z) / AxialDivisor);
        return p;
    }

    pub inline fn axial(self: Position) vct.Vector3 {
        return .{
            .x = @intToFloat(f32, (self.x & AxialFilter)) / AxialDivisor,
            .y = @intToFloat(f32, (self.y & AxialFilter)) / AxialDivisor,
            .z = @intToFloat(f32, (self.z & AxialFilter)) / AxialDivisor,
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

    ///Returns if the remainder of x is greater than the raminder of y
    pub inline fn xMinorGreater(self : Position) bool
    {
        return (self.x & MinorFilter) > (self.y & MinorFilter);
    }

    pub inline fn squareDistance(self : Position, to_dist : Position) f32
    {
        var _a = self.axial();
        var _b = self.axial() + .{.x = (self.index().x - to_dist.index().x) * 1024.0, .y = (self.index().y - to_dist.index().y) * 1024.0, .z = 0};
        return (_a.x - _b.x) * (_a.x - _b.x) + (_a.y - _b.y) * (_a.y - _b.y);
    }
};
