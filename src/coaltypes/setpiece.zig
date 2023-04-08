const std = @import("std");
const zmt = @import("zmt");
const alc = @import("../coalsystem/allocationsystem.zig");
const msh = @import("../coaltypes/mesh.zig");
const euc = @import("../coaltypes/euclid.zig");
const ogd = @import("../coaltypes/ogd.zig");
const pst = @import("../coaltypes/position.zig");
const chk = @import("../coaltypes/chunk.zig");
const rpt = @import("../coaltypes/report.zig");
const evs = @import("../coalsystem/eventsystem.zig");

/// Setpiece Object
/// The Setpiece is CoalStar Engine's struct for all worldspace items. It
/// contains positional data, a renderable mesh with associated data, and
/// an optional executor.
pub const Setpiece = struct {
    euclid: euc.Euclid = .{},
    mesh: msh.Mesh = undefined,
    executor: evs.IExecutor,
    //TODO figure out how to ascribe variations of function injections into executor
    pub fn init(self: Setpiece, _euclid: euc.Euclid, _mesh: msh.Mesh) void {
        self.euclid = _euclid;
        self.mesh = _mesh;
        self.executor = .{ .executeFn = self.execute };
    }
    pub fn execute() void {}
};

pub fn getSetpiece(obj_gen_data: ogd.OGD) Setpiece {

    //parse ogd go here

    var setpiece: Setpiece = .{};
    setpiece.euclid.position = pst.Position.init(.{}, .{ .x = 1.0, .y = 1.0, .z = 0.0 });
    //TODO parse out the fun bits

    //for all fallback: return debug cube(all hail)

    setpiece.mesh = msh.checkoutMesh(@truncate(u32, (obj_gen_data.base >> 8))).?;
    return setpiece;
}

pub fn generateSetPiece(gen_data: ogd.OGD, chunk: *chk.Chunk) ?*Setpiece {
    var setpiece = alc.setpiece_allocator.create(Setpiece) catch |err| {
        std.debug.print("{!}\n", .{err});
        const cat = @enumToInt(rpt.ReportCatagory.level_error) | @enumToInt(rpt.ReportCatagory.memory_allocation);
        rpt.logReportInit(cat, 101, [4]i32{ gen_data.index.x, gen_data.index.y, gen_data.index.z, gen_data.uid });
        return null;
    };
    chunk.setpieces.append(setpiece) catch |err| {
        std.debug.print("{!}\n", .{err});
        const cat = @enumToInt(rpt.ReportCatagory.level_error) | @enumToInt(rpt.ReportCatagory.memory_allocation) | @enumToInt(rpt.ReportCatagory.chunk_system);
        rpt.logReportInit(cat, 101, [4]i32{ gen_data.index.x, gen_data.index.y, gen_data.index.z, gen_data.uid });
        return null;
    };

    setpiece.euclid.quaternion = zmt.Quat{ 0, 0, 0, 1 };
    setpiece.euclid.position = pst.Position.init(chunk.index, .{ .x = 1.0, .y = 1.0, .z = 0 });
    setpiece.euclid.scale = .{ .x = 1.0, .y = 1.0, .z = 1.0 };

    setpiece.mesh = msh.checkoutMesh(@truncate(u32, (gen_data.base >> 8))).?;
    return setpiece;
}
