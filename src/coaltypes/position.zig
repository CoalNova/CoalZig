pub const std = @import("std");
pub const pnt = @import("../simpletypes/points.zig");
pub const vct = @import("../simpletypes/vectors.zig");

//lat eral
//vrt ical
const lat_minor = 24;
const lat_major = 10;
const vrt_minor = 24;
const vrt_major = 20;
const lat_index = 63 - (lat_major + lat_minor);
const vrt_index = 63 - (vrt_major + vrt_minor);

const lat_axial_divisor: f32 = @as(f32, (1 << lat_minor));
const vrt_axial_divisor: f32 = @as(f32, (1 << vrt_minor));
const lat_axial_filter: i64 = ((1 << (lat_minor + lat_major)) - 1);
const vrt_axial_filter: i64 = ((1 << (vrt_minor + vrt_major)) - 1);

const lat_index_filter = ((1 << lat_index) - 1) << (lat_minor + lat_major);
const vrt_index_filter = ((1 << vrt_index) - 1) << (vrt_minor + vrt_major);

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

    pub inline fn isX_Rounded(self: Position) bool {
        return (self.x & ((1 << 24) - 1)) == 0;
    }
    pub inline fn isY_Rounded(self: Position) bool {
        return (self.y & ((1 << 24) - 1)) == 0;
    }
    pub inline fn isZ_Rounded(self: Position) bool {
        return (self.z & ((1 << 24) - 1)) == 0;
    }

    pub inline fn round(self: Position) Position {
        var p = .{};
        p.x = self.x ^ (self.x & (((1 << lat_major) - 1) << lat_minor));
        p.y = self.y ^ (self.y & (((1 << lat_major) - 1) << lat_minor));
        p.z = self.z ^ (self.z & (((1 << vrt_major) - 1) << vrt_minor));
        return p;
    }

    pub inline fn addAxial(self: Position, _axial: vct.Vector3) Position {
        var p: Position = self;
        p.x += @floatToInt(i64, (_axial.x) * lat_axial_divisor);
        p.y += @floatToInt(i64, (_axial.y) * lat_axial_divisor);
        p.z += @floatToInt(i64, (_axial.z) * vrt_axial_divisor);
        return p;
    }

    /// The dimensional index of the position
    pub inline fn index(self: Position) pnt.Point3 {
        return .{
            .x = @truncate(i32, (((1 << lat_index) - 1) & (self.x >> (lat_major + lat_minor)))),
            .y = @truncate(i32, (((1 << lat_index) - 1) & (self.y >> (lat_major + lat_minor)))),
            .z = @truncate(i32, (((1 << vrt_index) - 1) & (self.z >> (vrt_major + vrt_minor)))),
        };
    }

    pub inline fn axial(self: Position) vct.Vector3 {
        return .{
            .x = (@intToFloat(f32, (self.x & lat_axial_filter)) / lat_axial_divisor) - 512.0,
            .y = (@intToFloat(f32, (self.y & lat_axial_filter)) / lat_axial_divisor) - 512.0,
            .z = (@intToFloat(f32, (self.z & vrt_axial_filter)) / vrt_axial_divisor) - 512.0,
        };
    }

    pub inline fn init(_index: pnt.Point3, _axial: vct.Vector3) Position {
        var x = @intCast(i64, _index.x) << (lat_minor + lat_major);
        var y = @intCast(i64, _index.y) << (lat_minor + lat_major);
        var z = @intCast(i64, _index.z) << (vrt_minor + vrt_major);

        x += @floatToInt(i64, (_axial.x + 512) * lat_axial_divisor);
        y += @floatToInt(i64, (_axial.y + 512) * lat_axial_divisor);
        z += @floatToInt(i64, (_axial.z + 512) * vrt_axial_divisor);

        return .{ .x = x, .y = y, .z = z };
    }

    ///Returns if the remainder of x is greater than the raminder of y
    pub inline fn xMinorGreater(self: Position) bool {
        return (self.x & ((1 << lat_minor) - 1)) > (self.y & ((1 << lat_minor) - 1));
    }

    pub inline fn squareDistance(self: Position, to_dist: Position) f32 {
        var _a = self.axial();
        var _b = self.axial() + .{ .x = (self.index().x - to_dist.index().x) * 1024.0, .y = (self.index().y - to_dist.index().y) * 1024.0, .z = 0 };
        return (_a.x - _b.x) * (_a.x - _b.x) + (_a.y - _b.y) * (_a.y - _b.y);
    }
};
