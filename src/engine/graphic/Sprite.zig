const std = @import("std");

const Sprite = @This();

allocator: std.mem.Allocator,
size: usize,
alignment: usize,

ptr: *anyopaque,
vtable: *const VTable,

// The vtable.
pub const VTable = struct {
    getPosition: *const fn (ptr: *anyopaque) Position,
    getSize: *const fn (ptr: *anyopaque) Size,

    setPosition: ?*const fn (ptr: *anyopaque, x: i32, y: i32) void = null,
    setSize: ?*const fn (ptr: *anyopaque, width: ?u32, height: ?u32) void = null,

    render: ?*const fn (ptr: *anyopaque, parent: Dimension) void = null,
    update: ?*const fn (ptr: *anyopaque) void = null,

    deinit: ?*const fn (ptr: *anyopaque) void = null
};

// Initialize a sprite.
pub fn init(sprite: anytype, allocator: std.mem.Allocator) !Sprite {
    if (!@hasField(@TypeOf(sprite), "VTable")) {
        return error.SpriteMissingVTable;
    }

    const size = @sizeOf(@TypeOf(sprite));
    const alignment = @alignOf(@TypeOf(sprite));

    const ptr = @as(*@TypeOf(sprite), @ptrCast(@constCast(&(allocator.rawAlloc(size, .fromByteUnits(alignment), @returnAddress()) orelse return error.OutOfMemory))));
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

    self.allocator.rawFree(@as(*[]u8, @ptrCast(@alignCast(self.ptr))).*, .fromByteUnits(self.alignment), @returnAddress());
}

// Get the position of the sprite.
pub fn getPosition(self: *Sprite) Position {
    return self.vtable.getPosition(self.ptr);
}

// Get the size of the sprite.
pub fn getSize(self: *Sprite) Size {
    return self.vtable.getSize(self.ptr);
}

// Set the position of the sprite.
pub fn setPosition(self: *Sprite, x: i32, y: i32) void {
    if (self.vtable.setPosition) |hook| {
        hook(self.ptr, x, y);
    }
}

// Set the size of the sprite.
pub fn setSize(self: *Sprite, width: ?u32, height: ?u32) void {
    if (self.vtable.setSize) |hook| {
        hook(self.ptr, width, height);
    }
}

// Render the sprite.
pub fn render(self: *Sprite, parent: Dimension) void {
    if (self.vtable.render) |hook| {
        hook(self.ptr, parent);
    }
}

// Update the sprite.
pub fn update(self: *Sprite) void {
    if (self.vtable.update) |hook| {
        hook(self.ptr);
    }
}

// The position of the sprite.
pub const Position = struct {
    x: i32,
    y: i32,
};

// The size of the sprite.
pub const Size = struct {
    width: ?u32,
    height: ?u32
};

// The dimension.
pub const Dimension = struct {
    x: i32,
    y: i32,
    width: u32,
    height: u32
};
