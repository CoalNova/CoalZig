//! The Chunk and associated systems for CoalStar
//! 
//!     Chunk, as a struct, contains the index, height data, mesh, setpieces 
//! list, and a bool to track if the chunk is loaded. At a later time setpiece 
//! mesh call data may be referenced through the chunk. This, as an all-in-one 
//! solution to drawing the chunk-bound objects through matrix-casting.
//! 
//! 
//! Height Data:
//!     The height data is a combination of two values: an array of u16's as
//! heights, and a u8 heightmod offset. The heightmod is an unsigned char that 
//! is multiplied by 10240 and applied to all height values, after being added 
//! to a height value it is multiplied by 0.1f to create the height. Only even
//! whole units have height values in the array, odd values are derive from 
//! adjacent heights
//! 
//!     Height requests between rounded positions are derived with a ray/plane
//! intercept formula from the heights as associated by the drawn tri. So:
//! +---+
//! | / |
//! +---+
//! 
//! Mesh:
//!     A chunk's terrain mesh will be a once-written vertex buffer object(VBO)
//! containing all heights. Updates to terrain resolution, based on focal point, 
//! will be through updating the IBO, iterating granularly. Each vertex will  
//! consist of 8 bytes, passed and read as two 4 byte integers, kindof*[1]. 
//! 
//!     The packed structure layout of the chunk vertex is as follows:
//! s = 1 bit for discard vertex
//! z = 17 bits for vertex z pos [0..131072] as float * 0.1f []
//! Zo = Zone, 8 bits for terrain texture and auto-generation data
//! Xn = 8 bits for normal x [0..256] as float * (1 / 512) - 1.0 [-1.0..1.0]
//! Yn = 8 bits for normal y [0..256] as float * (1 / 512) - 1.0 [-1.0..1.0]
//! x = 11 bits for vertex x position [0..1025] 
//! y = 11 bits for vertex y position [0..1025] 
//! 
//! [0] szzz_zzzz_zzzz_zzzz_zzZo_ZoZo_ZoXn_XnXn
//! [1] XnYn_YnYn_Ynxx_xxxx_xxxx_xyyy_yyyy_yyyy
//! 
//!     Iteration of the IBO is performed from major to minor, in steps. It will 
//! first iterate over the largest stride, checking distance to focus. If the 
//! distance is closer than a defined bounds then it iterates the next stride
//! within the larger stride. Within that it performs the stride-per-stride 
//! iteration and checks range. This should perform smooth updates even on the 
//! main thread. Any existing IBO is removed and the data is then pushed to the 
//! GPU and bound appropriately. 
//! 
//! 
//! 
//! *[1]The data is packed as a u32 buffered 32 bit floats. However, with a lack
//! of typechecking in the process of data buffering, the system is instructed 
//! to read that memory as two 32 bit integers. In experimentation, the gpu 
//! driver seems to fiddle with integral data types when sent as such. Nvidia's
//! NSite GPU profiler reported the data as being accurate, but operations were 
//! clearly broken. I assume this is a result of reducing RAM utilization, by 
//! stacking or referencing partial values elsewhere, but I am entirely 
//! uncertain. I am only aware of the results. 
//! 
const std = @import("std");
const zmt = @import("zmt");
const alc = @import("../coalsystem/allocationsystem.zig");
const pst = @import("../coaltypes/position.zig");
const fcs = @import("../coaltypes/focus.zig");
const stp = @import("../coaltypes/setpiece.zig");
const ogd = @import("../coaltypes/ogd.zig");
const msh = @import("../coaltypes/mesh.zig");

/// The container struct for world chunk
/// will contain references to create/destroy/move setpieces and objects
/// based on OGD
pub const Chunk = struct {
    index: pst.pnt.Point3 = .{ .x = 0, .y = 0, .z = 0 },
    heights: ?[]u16 = null,
    height_mod: u8 = 0,
    setpieces: ?std.ArrayList(stp.Setpiece) = null,
    mesh : *msh.Mesh = undefined,
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
pub fn getChunk(index: pst.pnt.Point3) ?*Chunk {
    if (index.x >= map_bounds.x or index.x < 0 or
        index.y >= map_bounds.y or index.y < 0)
    {
        return null;
    }
    return &chunk_map[@intCast(usize,index.x + index.y * map_bounds.x)];
}

pub fn loadChunk(chunk_index : pst.pnt.Point3) void
{
    var chunk : *Chunk = getChunk(chunk_index) orelse
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
    errdefer alc.gpa_allocator.free(chunk.heights);

    chunk.setpieces = std.ArrayList(stp.Setpiece).init(alc.gpa_allocator);
    errdefer chunk.setpieces.?.deinit();
    //TODO handle setpiece loading 
            
    chunk.loaded = true;
}

pub fn unloadChunk(chunk_index : pst.pnt.Point3) void
{
    var chunk : *Chunk = getChunk(chunk_index) orelse {
        std.debug.print("index ({}, {}) is an invalid index", .{chunk_index.x, chunk_index.y});
        return;
    };

    alc.gpa_allocator.free(chunk.heights.?);

    chunk.height_mod = 0;

    if (chunk.setpieces != null)
    {
        chunk.setpieces.?.deinit();
        chunk.setpieces = null;
    }

    chunk.loaded = false;
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

            return @intToFloat(f32, chunk.heights[(position.x >> 1) + (position.y >> 1) * 512]) * 0.1 + 
                @intToFloat(f32, (chunk.height_mod * 1024)); 
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
