const sdl = @import("../coalsystem/coalsystem.zig").sdl;

/// Contains the actual whole loaded image as a SDL_Surface
/// intended to be used by a Sprite struct, which references
/// the surface and includes sheet coordinates
pub const Surface = struct { sdl_surface: ?*sdl.SDL_Surface = undefined, surface_id: u32 = 999999999, subscribers: u32 = 0 };
