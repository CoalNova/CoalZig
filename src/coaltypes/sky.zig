//! The Sky object is a framebuffer drawn to procedurally.
//!
//!     Mie and Rayleigh scattering will be bypassed entirely for the sake of
//! performance. Instead, a referenced Color selection will be used, and
//! directional color splatter simulated. Weather will need to be known and
//! referenced for haze density, sun direction, and time-of-day.
//!
//!     Stars are TBD, possibly casting a repeating texture, or procedural.
const gls = @import("../coalsystem/glsystem.zig");
const zgl = @import("zgl");
const cms = @import("../coalsystem/coalmathsystem.zig");

const Sky = struct {
    fbo: u32 = 0,
    sky_color: cms.Vec3 = undefined,
    sun_color: cms.Vec3 = undefined,
    haze_color: cms.Vec3 = undefined,
    haze_density: f32 = 0.5,
};
