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
//! Xn = 8 bits for normal x [0..256] as float * (1 / 256) - 128 [-1.0..1.0]
//! Yn = 8 bits for normal y [0..256] as float * (1 / 256) - 128 [-1.0..1.0]
//! x = 11 bits for vertex x position [0..1025]
//! y = 11 bits for vertex y position [0..1025]
//!
//! [0] szzz_zzzz_zzzz_zzzz_zzZo_ZoZo_ZoXn_XnXn
//! [1] XnYn_YnYn_Ynxx_xxxx_xxxx_xyyy_yyyy_yyyy
//!
//! For consistancy's sake the names of these are
//! [0] super_zone/superZone
//! [1] super_vert/superVert
//!
//!     The unpacking of the data must match the sequence in both the mesh
//! generation and shader program. Doing otherwise will obviously cause faults.
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
//! *[1]The data is packed as a u32 buffered 32bit Floats. However, with a lack
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
const sys = @import("../coalsystem/coalsystem.zig");
const alc = @import("../coalsystem/allocationsystem.zig");
const pst = @import("../coaltypes/position.zig");
const fcs = @import("../coaltypes/focus.zig");
const stp = @import("../coaltypes/setpiece.zig");
const ogd = @import("../coaltypes/ogd.zig");
const msh = @import("../coaltypes/mesh.zig");
const cms = @import("../coalsystem/coalmathsystem.zig");
const fio = @import("../coalsystem/fileiosystem.zig");
const rpt = @import("../coaltypes/report.zig");

/// The container struct for world chunk
/// will contain references to create/destroy/move setpieces and objects
/// based on OGD
pub const Chunk = struct {
    index: pst.pnt.Point3 = .{ .x = 0, .y = 0, .z = 0 },
    heights: []u16 = undefined,
    height_mod: u8 = 0,
    zones: ?[]u8 = null,
    setpieces: std.ArrayList(*stp.Setpiece) = undefined,
    mesh: ?*msh.Mesh = null,
};

/// Chunk map
var chunk_map: []Chunk = undefined;
var map_bounds: pst.pnt.Point3 = .{ .x = 0, .y = 0, .z = 0 };

pub fn initializeChunkMap(allocator: std.mem.Allocator, bounds: pst.pnt.Point3) !void {
    map_bounds = bounds;
    const b_x = @intCast(usize, bounds.x);
    const b_y = @intCast(usize, bounds.y);
    chunk_map = try allocator.alloc(Chunk, @intCast(usize, bounds.x * bounds.y));
    for (0..b_y) |y| {
        for (0..b_x) |x| {
            chunk_map[x + y * b_x] = .{
                .index = .{ .x = @intCast(i32, x), .y = @intCast(i32, y), .z = 0 },
                .heights = undefined,
                .height_mod = 0,
                .setpieces = undefined,
                .mesh = null,
            };
        }
    }
}

pub inline fn indexIsMapValid(index: pst.pnt.Point3) bool {
    return (index.x >= 0 and index.x < map_bounds.x and
        index.y >= 0 and index.y < map_bounds.y and
        index.z >= 0 and index.z < map_bounds.z);
}

pub fn getMapBounds() pst.pnt.Point3 {
    return map_bounds;
}

const ChunkError = error{OutofBoundsChunkMapAccess};

/// Returns Chunk at provided Point3 index
///     or an Out of Bounds Chunk Access error if the index is so
/// The z axis of the Point3 is unused for chunk access at this time
///     and is implemented to avoid needing to downcast
pub fn getChunk(index: pst.pnt.Point3) ?*Chunk {
    if (!indexIsMapValid(index))
        return null;

    return &chunk_map[@intCast(usize, index.x + index.y * map_bounds.x)];
}

pub fn loadChunk(index: pst.pnt.Point3) void {
    var chunk: *Chunk = getChunk(index) orelse {
        return rpt.logReportInit(
            @enumToInt(rpt.ReportCatagory.level_warning) |
                @enumToInt(rpt.ReportCatagory.chunk_system),
            9,
            .{ index.x, index.y, map_bounds.x, map_bounds.y },
        );
    };

    //TODO use CAT
    chunk.height_mod = 0;
    chunk.heights = alc.gpa_allocator.alloc(u16, 512 * 512) catch |err| {
        std.debug.print("{}\n", .{err});
        return;
    };

    //TODO chunk map name needs a centralized location
    fio.loadChunkHeights(&chunk.heights, &chunk.height_mod, index, "dawn") catch |err| {
        std.debug.print("{!}\n", .{err});
        return;
    };
    errdefer alc.gpa_allocator.free(chunk.heights);

    //initialize (and eventually load) zones
    chunk.zones = alc.gpa_allocator.alloc(u8, 1024 * 1024) catch |err| {
        const cat = @enumToInt(rpt.ReportCatagory.chunk_system) |
            @enumToInt(rpt.ReportCatagory.memory_allocation) |
            @enumToInt(rpt.ReportCatagory.level_error);
        rpt.logReportInit(cat, 101, [_]i32{ index.x, index.y, 0, 0 });
        std.debug.print("{!}\n", .{err});
        return;
    };
    errdefer {
        alc.gpa_allocator.free(chunk.zones);
        chunk.zones = null;
    }

    chunk.setpieces = std.ArrayList(*stp.Setpiece).init(alc.gpa_allocator);
    errdefer chunk.setpieces.?.deinit();
    //TODO handle setpiece loading

    //TODO find more elegant solution to cleaning mesh
    chunk.mesh = null;
}

pub fn unloadChunk(chunk_index: pst.pnt.Point3) void {
    var chunk: *Chunk = getChunk(chunk_index) orelse {
        std.debug.print("index ({}, {}) is an invalid index\n", .{ chunk_index.x, chunk_index.y });
        return;
    };

    alc.gpa_allocator.free(chunk.heights);

    chunk.height_mod = 0;

    chunk.setpieces.deinit();
}

/// Centralized method to save all chunk data
pub fn saveChunk(chunk_index: pst.pnt.Point3) void {
    const chunk: *Chunk = getChunk(chunk_index) orelse {
        const cat = @enumToInt(rpt.ReportCatagory.level_warning) | @enumToInt(rpt.ReportCatagory.chunk_system);
        rpt.logReportInit(cat, 9, .{ 0, 0, chunk_index.x, chunk_index.y });
        return;
    };

    // this might crash bad if metaheader is not loaded
    fio.saveChunkHeights(chunk.heights, chunk.height_mod, chunk.index, sys.getMetaHeader().map_name) catch |err| {
        std.debug.print("{!}\n", .{err});
    };
}

// this is where the fun begins
pub fn getHeight(position: pst.Position) f32 {
    const pos_axial = position.axial();
    const pos_absol = pst.pnt.Point3{
        .x = @floatToInt(i32, pos_axial.x),
        .y = @floatToInt(i32, pos_axial.y),
        .z = @floatToInt(i32, pos_axial.z),
    };
    //const pos_index = position.index();

    //check if requested position is rounded
    if (position.isX_Rounded() and position.isY_Rounded()) {
        //if even on both axis then dig in and return value at index (if chunk invalid/unloaded return 0.0)
        if ((position.x & (1 << 24)) == 0 and (position.y & (1 << 24)) == 0) {
            if (getChunk(position.index()) == null)
                return 0.0;

            const chunk = getChunk(position.index()).?;

            if (chunk.heights.len == 0)
                return 0.0;

            const index = @intCast(usize, ((pos_absol.x + 512) >> 1) + ((pos_absol.y + 512) >> 1) * 512);

            if (chunk.heights.len == 0) {
                return 0.0;
            }

            return @intToFloat(f32, chunk.heights[index]) * 0.1 +
                @intToFloat(f32, (@as(u32, chunk.height_mod) * 1024));
        } else if ((position.y & (1 << 24)) == 0) {
            //if x is the odd one
            const p_a = position.addAxial(.{ .x = 1, .y = 0, .z = 0 });
            const p_b = position.addAxial(.{ .x = -1, .y = 0, .z = 0 });
            return (getHeight(p_a) + getHeight(p_b)) * 0.5;
        } else if ((position.x & (1 << 24)) == 0) {
            //if y is the odd one
            const p_a = position.addAxial(.{ .x = 0, .y = 1, .z = 0 });
            const p_b = position.addAxial(.{ .x = 0, .y = -1, .z = 0 });
            return (getHeight(p_a) + getHeight(p_b)) * 0.5;
        } else {
            //if both are odd
            const p_a = position.addAxial(.{ .x = -1, .y = 1, .z = 0 });
            const p_b = position.addAxial(.{ .x = 1, .y = -1, .z = 0 });
            return (getHeight(p_a) + getHeight(p_b)) * 0.5;
        }
    }

    //else, break out the ray/plane intercept
    const rounded = position.round();
    const x_great = position.xMinorGreater();
    const p_0 = getHeight(rounded);
    const p_1 = if (x_great)
        getHeight(rounded.addAxial(.{ .x = 1, .y = 0, .z = 0 }))
    else
        getHeight(rounded.addAxial(.{ .x = 0, .y = 1, .z = 0 }));
    const p_2 = getHeight(rounded.addAxial(.{ .x = 1, .y = 1, .z = 0 }));

    const v_0 = cms.Vec3{ 0, 0, 0 };
    const v_2 = cms.Vec3{ 1, 1, p_2 - p_0 };

    const v_1 = if (x_great) cms.Vec3{ 1, 0, p_1 - p_0 } else cms.Vec3{ 0, 1, p_1 - p_0 };

    //normalish the values
    const normal = if (x_great)
        cms.cross(-v_1, v_2 - v_1)
    else
        cms.cross(v_1, v_2);

    const direction = cms.Vec3{ 0.0, 0.0, -1.0 };
    const origin = cms.Vec3{
        pos_axial.x - @intToFloat(f32, pos_absol.x),
        pos_axial.y - @intToFloat(f32, pos_absol.y),
        1.0,
    };

    var height: f32 = 0.0;

    const worked = (cms.rayPlane(v_0, normal, origin, direction, &height));

    std.debug.print("height: [{d:.3}, {d:.3}]({d:.3}, {d:.3}) {d:.6}\n", .{
        origin[0],
        origin[1],

        pos_axial.x - @intToFloat(f32, pos_absol.x),
        pos_axial.y - @intToFloat(f32, pos_absol.y),

        height,
    });

    return if (worked)
        p_0 + height
    else
        p_0;
}
