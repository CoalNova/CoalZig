const std = @import("std");
const zmt = @import("zmt");
const alc = @import("../coalsystem/allocationsystem.zig");
const pst = @import("../coaltypes/position.zig");
const fcs = @import("../coaltypes/focus.zig");
const stp = @import("../coaltypes/setpiece.zig");
const ogd = @import("../simpletypes/ogd.zig");

/// The container struct for world chunk
/// will contain references to create/destroy/move setpieces and objects
/// based on OGD
pub const Chunk = struct {
    index: pst.pnt.Point3 = .{ .x = 0, .y = 0, .z = 0 },
    heights: ?[]u16 = null,
    height_mod: u8 = 0,
    setpieces: []stp.Setpiece = undefined,
    loaded: bool = false,
};

/// Chunk map
var chunk_map: []Chunk = undefined;
var map_bounds: pst.pnt.Point3 = .{ .x = 0, .y = 0, .z = 0 };

pub fn initializeChunkMap(allocator: std.mem.Allocator, bounds: pst.pnt.Point3) !void {
    map_bounds = bounds;
    chunk_map = try allocator.alloc(Chunk, @intCast(usize, bounds.x * bounds.y));
}

pub fn getMapBounds() pst.pnt.Point3
{
    return map_bounds;
}

const ChunkError = error{ OutofBoundsChunkMapAccess };

/// Returns Chunk at provided Point3 index
///     or an Out of Bounds Chunk Access error if the index is so
/// The z axis of the Point3 is unused for chunk access at this time
///     and is implemented to avoid needing to downcast
pub fn getChunk(index: pst.pnt.Point3) !*Chunk {
    var chunk: *Chunk = undefined;
    if (index.x >= map_bounds.x or index.x < 0 or
        index.y >= map_bounds.y or index.y < 0)
    {
        return ChunkError.OutofBoundsChunkMapAccess;
    }
    chunk = &chunk_map[@intCast(usize,index.x + index.y * map_bounds.x)];
    return chunk;
}

pub fn loadChunk(chunk_index : pst.pnt.Point3) void
{
    var chunk = getChunk(chunk_index) catch
    {
        std.debug.print("index ({d}, {d}) is an invalid index", .{chunk_index.x, chunk_index.y});
        return;
    };

    //TODO use CAT
    chunk.height_mod = 0;
    chunk.heights = alc.gpa_allocator.alloc(u16, 512*512) catch |err|
    {
        std.debug.print("{}\n", .{err});
        return;
    };

    //TODO handle setpiece loading 
    chunk.setpieces = alc.gpa_allocator.alloc(stp.Setpiece, 32) catch |err|
    {
        std.debug.print("{}\n", .{err});
        return;
    };
        
    chunk.loaded = true;
}

pub fn unloadChunk(chunk_index : pst.pnt.Point3) void
{
    var chunk = getChunk(chunk_index) catch
    {
        std.debug.print("index ({d}, {d}) is an invalid index", .{chunk_index.x, chunk_index.y});
        return;
    };

    alc.gpa_allocator.free(chunk.*.heights.?);

    chunk.height_mod = 0;

    chunk.setpieces = undefined;

    chunk.loaded = false;
}

pub fn constructBaseMesh(chunk: *Chunk) ?[]u8 {
    _ = chunk;
    return null;
}

pub fn updateMeshIBO(chunk: *Chunk, focal_point: fcs.Focus) ?[]u8 {
    _ = chunk;
    _ = focal_point;
    return null;
}

// this is where the fun begins
pub fn getHeight(position : pst.Position) f32 {
    
    //check if requested position is rounded
    if (position.isX_Rounded() and position.isY_Rounded())
    {
        //if even on both axis then dig in and return value at index (if chunk invalid/unloaded return 0.0) 
        if ((position.x & (1 << 24)) == 0 and (position.y & (1 << 24)) == 0)
        {
            const chunk = getChunk(position.index()) catch
                return 0.0;

            if (!chunk.loaded)
                return 0.0;

            return @as(f32, chunk.heights[(position.x >> 1) + (position.y >> 1) * 512]) * 0.1 + @as(f32, (chunk.height_mod * 1024)) ; 
        }
        else if ((position.y & (1 << 24)) == 0)
        {
            //if x is the odd one
            const p_a = position.addAxial(.{.x = 1, .y = 0, .z = 0});
            const p_b = position.addAxial(.{.x = -1, .y = 0, .z = 0});
            return (getHeight(p_a) + getHeight(p_b)) * 0.5;
        } 
        else if ((position.x & (1 << 24)) == 0)
        {
            //if y is the odd one
            const p_a = position.addAxial(.{.x = 0, .y = 1, .z = 0});
            const p_b = position.addAxial(.{.x = 0, .y = -1, .z = 0});
            return (getHeight(p_a) + getHeight(p_b)) * 0.5;
        }
        else 
        {
            //if both are odd
            const p_a = position.addAxial(.{.x = -1, .y = 1, .z = 0});
            const p_b = position.addAxial(.{.x = 1, .y = -1, .z = 0});
            return (getHeight(p_a) + getHeight(p_b)) * 0.5;
        }
    }    

    //else, break out the ray/plane intercept
    const p_1 : pst.Position = getHeight(position.round());
    const p_3 : pst.Position = getHeight(position.round().addAxial(.{.x = 1, .y = 1, .z = 0}));
    const p_2 : pst.Position = if(position.xMinorGreater())
            getHeight(position.round().addAxial(.{.x = 1, .y = 0, .z = 0}))
        else
            getHeight(position.round().addAxial(.{.x = 0, .y = 1, .z = 0}));

    //normalish the values
    var v_a = pst.vct.Vector3.init(0, 0, 0).simd();
    var v_b = (pst.Position{.x = p_2.x - p_1.x, .y = p_2.y - p_1.y, .z = p_2.z - p_1.z}).axial().simd();
    var v_c = (pst.Position{.x = p_3.x - p_1.x, .y = p_3.y - p_1.y, .z = p_3.z - p_1.z}).axial().simd();

    var normal : @Vector(3, f32) = zmt.cross3(v_b - v_a, v_b - v_c);

    const direction = pst.vct.Vector3.init(0.0, 0.0, -1.0).simd();
    const origin = pst.vct.Vector3.init(0.0, 0.0, 1.0).simd();

    const denom : f32 = zmt.dot3(normal, direction);
    if (zmt.abs(denom) == 0.0) //in cases of negative zero
        return p_1.axial().z; // better to float(burn out) than to drop to 0(fade away)
    
    var height = zmt.dot3((v_a - origin), normal) / denom;
    return p_1.axial().z + height;
}
