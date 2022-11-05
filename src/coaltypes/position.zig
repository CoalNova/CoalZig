pub const pnt = @import("../simpletypes/points.zig");
pub const vct = @import("../simpletypes/vectors.zig");

/// Worldspace position struct, contains the dimensional
/// index and the intradimensional axial coordinates
/// TODO SIMD implementation
/// TODO integral/autorounding of axial -> index
pub const Position = struct
{
    raw : @Vector(3,u64),
    /// The dimensional index of the position
    pub inline fn index(self : Position) pnt.Point3
    {
        return 
            .{ 
                .x = @intCast(i32, (self.raw[0] >> 28) & ((1 << 16) - 1)), 
                .y = @intCast(i32, (self.raw[1] >> 28) & ((1 << 16) - 1)), 
                .z = @intCast(i32, (self.raw[2] >> 32) & ((1 << 16) - 1))  
            };
    }
    pub inline fn axial(self : Position) vct.Vector3
    {
        return 
            .{ 
                .x = @intToFloat(f32, (self.raw[0] & ((1 << 28) - 1))) / @intToFloat(f32, (1 << 18)), 
                .y = @intToFloat(f32, (self.raw[1] & ((1 << 28) - 1))) / @intToFloat(f32, (1 << 18)), 
                .z = @intToFloat(f32, (self.raw[2] & ((1 << 28) - 1))) / @intToFloat(f32, (1 << 18)), 
            };
    }
    pub fn init(_index : pnt.Point3, _axial : vct.Vector3) Position
    {
        var x = @intCast(u64, _index.x) << 28;
        var y = @intCast(u64, _index.y) << 28;
        var z = @intCast(u64, _index.z) << 32;

        x += @floatToInt(u64, _axial.x * @intToFloat (f32, (1 << 18)));
        y += @floatToInt(u64, _axial.y * @intToFloat (f32, (1 << 18)));
        z += @floatToInt(u64, _axial.z * @intToFloat (f32, (1 << 18)));
        
        return .{.raw = @Vector(3, u64){x, y, z}};
    }
};

// It seems the inveitable solution to this system will be an integral per-axis coordinate;
// using u64 the layout would require alotment for three portions: dimensional, positional, and decimal

// The Dimenisional portion is rather explanatory and would be the axial dimension
//     36 bits are used for the dimensional projection, allowing for over 70 billion km, 
//     at over 5 times the diameter of the solar system, that should be enough space
//     currently spec for Point2/3/4 is i32, so only 16 bits are used, still should be enough at >66,000km

// The positional portion is used for the whole-number per-unit position as it relates to euclidean space
//     10 bits is necessity, as each chunk is designed to be one square kibimeter (1024 * 1024)

// The decimal portion is the sub-unit position of the position in euclidean space
//     18 bits for decimal precision alots 0.00000381469726562, or for 1 unit = 1 meter, three microns per step
//     DDDD_DDDD_DDDD_DDDD_DDDD_DDDD_DDDD_DDDD_DDDD_pppp_pppp_ppdd_dddd_dddd_dddd_dddd

// The Z axis (vertical) operates seperately, as there is no vertical dimensionality at this time
//     vertical dimensional traversal may ease some on height data, but would need rules in rendering, getheight, etc
//     Z dimensions are currently planned to house intradimensional spaces
//     DDDD_DDDD_DDDD_DDDD_DDDD_DDDD_DDDD_DDDD_pppp_pppp_pppp_ppdd_dddd_dddd_dddd_dddd

// Portals (windows? gates?) Can act as stationary, possibly non-stationary, intra-dimensional hopping points
// and will be covered at a later date
