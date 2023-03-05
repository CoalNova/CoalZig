const std = @import("std");
const sys = @import("../coalsystem/coalsystem.zig");

const TextureError = error{
    TextureBindingFailure,
    TextureMapInitializationFailure,
    TextureBufferDataFailure
};

pub const Texture = struct {
    id : u32 = 0,
    stack_offset : u32 = 0,
    stack_index : u32 = 0,
    subscribers : u32 = 0,
    stack : *TextureStack,
};

pub const TextureStack = struct {
    stack : std.MultiArrayList(Texture) = undefined,
    object_name : u32 = 0,
    binding_point: u32 = 0  
};

var stack_map : []TextureStack = undefined;

pub fn initStackMap() !void
{

}

pub fn destroyStackMap() void
{
    
}