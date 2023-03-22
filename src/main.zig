//! The main entry point of the CoalStar Engine
//! 
//!     Any ops here should be abstract calls. Testing here must be temporary, 
//! and moved out once complete. Avoid cluttering with multiple test codes to 
//! avoid an ugly mess.
//! 
//!     File/Folder layout is such that: 
//! - 'Simpltypes' refers to files with types that have only member functions, 
//!    and do not utilize Imports.
//! - 'CoalTypes' are files which contain structs and many utility functions,
//!    both member and external. Each file should contain and implement info 
//!    relevant to that struct's operation. If ambiguity exists between 
//!    ownership of functions and systems, (such as with mesh implementation)
//!    the owner should be seen as the commonality (mesh owns functions).
//! - 'CoalSystem' contain no structs, or no struct is the focus of the file.
//!    Instead, the focus is on function implementations and systems. Systems
//!    focus on facilitation and providing solutions to structs or engine. The 
//!    suffix of 'system' is appended to denote useage, and prevent ambiguity 
//!    between itself and any implemented element (such as event).
//!        
//!     Imported files/libraries use a three-digit name to easily identify and
//! to not cause ambiguity by overlaping with any implemented... elements? 
//!     
//! 
//! 
const std = @import("std");
const zmt = @import("zmt");
const sys = @import("coalsystem/coalsystem.zig");
const stp = @import("coaltypes/setpiece.zig");
const wnd = @import("coaltypes/window.zig");
const chk = @import("coaltypes/chunk.zig");
const pnt = @import("simpletypes/points.zig");
const cam = @import("coaltypes/camera.zig");

pub fn main() void 
{
    // Start system,
    sys.ignite();
    // Defer closing of system
    defer (sys.douse());


    const cube = stp.getSetpiece(.{});
    var camera : cam.Camera = undefined;
    const window = wnd.getWindow(wnd.WindowCategory.hardware).?;

    stp_blk : for (window.focal_point.active_chunks) |index|
    {
        const focal_index : pnt.Point3 = window.focal_point.position.index();
        if (index.equals(focal_index))
        {
            var chunk = chk.getChunk(index);
            if (chunk != null)
            {
                chunk.?.setpieces.?.append(cube) catch |err|
                    std.debug.print("{}\n", .{err});
                camera = window.camera;
                break : stp_blk;
            }
        }
    }
    

    //main loop
    while(sys.runEngine())
    {
        camera.euclid.quaternion = zmt.qmul(
            camera.euclid.quaternion, 
            zmt.quatFromRollPitchYaw(0, 0, 0.1));
                
        const angles = convMatToEul(camera.euclid.quaternion);
        std.debug.print("x:{d:.4}, y:{d:.4}, z:{d:.4}\n", 
            .{angles[0] / (std.math.pi * 0.5), angles[1] / (std.math.pi * 0.5), angles[2] * (90.0 / (std.math.pi * 0.5))});
    }
}

fn convMatToEul(q : @Vector(4, f32)) @Vector(3, f32)
{
    var angles = @Vector(3, f32){0,0,0};    //yaw pitch roll
    const x = q[0];
    const y = q[1];
    const z = q[2];
    const w = q[3];

    // roll (x-axis rotation)
    const sinr_cosp = 2 * (w * x + y * z);
    const cosr_cosp = 1 - 2 * (x * x + y * y);
    angles[0] = std.math.atan2(f32, sinr_cosp, cosr_cosp);

    // pitch (y-axis rotation)
    var sinp : f32 = 2 * (w * y - z * x);
    if ( @fabs(sinp) >= 1)
    {
        angles[1] = std.math.copysign(@as(f32, std.math.pi / 2.0), sinp); // use 90 degrees if out of range
    }
    else
        angles[1] = std.math.asin(sinp);

    // yaw (z-axis rotation)
    const siny_cosp = 2 * (w * z + x * y);
    const cosy_cosp = 1 - 2 * (y * y + z * z);
    angles[2] = std.math.atan2(f32, siny_cosp, cosy_cosp);
    return angles;
}
