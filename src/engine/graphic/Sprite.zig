const std = @import("std");

const Layout = @import("./Layout.zig");

const Sprite = @This();

allocator: std.mem.Allocator,
size: usize,
alignment: usize,

ptr: *anyopaque,
vtable: *const VTable,

// The vtable.
pub const VTable = struct {
    getPosition: *const fn(ptr: *anyopaque) Layout.Position,
    getSize: *const fn(ptr: *anyopaque) Layout.Size,

    render: ?*const fn(ptr: *anyopaque, global: Layout.Dimension, parent: Layout.Dimension) void = null,
    update: ?*const fn(ptr: *anyopaque) void = null,

    deinit: ?*const fn(ptr: *anyopaque) void = null
};

// Initialize a sprite.
pub fn init(sprite: anytype, allocator: std.mem.Allocator) !Sprite {
    const size = @sizeOf(@TypeOf(sprite));
    const alignment = @alignOf(@TypeOf(sprite));

    const ptr = @as(*@TypeOf(sprite), @ptrCast(@alignCast(allocator.rawAlloc(size, .fromByteUnits(alignment), @returnAddress()) orelse return error.OutOfMemory)));
    ptr.* = sprite;

    return Sprite{
        .allocator = allocator,
        .size = size,
        .alignment = alignment,

        .ptr = ptr,
        .vtable = &@TypeOf(sprite).VTable
    };
}

// Deinitialize the sprite.
pub fn deinit(self: *Sprite) void {
    if (self.vtable.deinit) |hook| {
        hook(self.ptr);
    } 

    self.allocator.rawFree(@as([*]u8, @ptrCast(self.ptr))[0..self.size], .fromByteUnits(self.alignment), @returnAddress());
}

// Get the position of the sprite.
pub fn getPosition(self: *Sprite) Layout.Position {
    return self.vtable.getPosition(self.ptr);
}

// Get the size of the sprite.
pub fn getSize(self: *Sprite) Layout.Size {
    return self.vtable.getSize(self.ptr);
}
