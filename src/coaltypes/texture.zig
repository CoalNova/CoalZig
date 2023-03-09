const std = @import("std");
const sys = @import("../coalsystem/coalsystem.zig");
const alc = @import("../coalsystem/allocationsystem.zig");

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
    stack : std.ArrayList(Texture) = undefined,
    object_name : u32 = 0,
    binding_point: u32 = 0  
};

var stack_map : []TextureStack = undefined;

pub fn initStackMap(max_bind_points : usize) !void
{
    stack_map = try alc.gpa_allocator.alloc(TextureStack, max_bind_points);
    for (&stack_map, 0..) |*stack, index|
    {
        stack.stack = std.ArrayList(Texture);
        stack.stack.init(alc.gpa_allocator);
        stack.binding_point = index;
    }
    
    
    

}

pub fn destroyStackMap() void
{
    for (&stack_map) |*stack|
        stack.stack.deinit();
    
    alc.gpa_allocator.free(stack_map);
}