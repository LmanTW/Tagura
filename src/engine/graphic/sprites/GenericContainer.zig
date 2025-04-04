const std = @import("std");

const Layout = @import("../Layout.zig");

const GenericContainer = @This();

allocator: std.mem.Allocator,
children: std.ArrayList(Anonymous),

x: ?i32,
y: ?i32,
width: ?u32,
height: ?u32,

// The vtable.
pub const VTable = Anonymous.VTable{
    .getPosition = getPosition,
    .getSize = getSize,

    .setPosition = setPosition,
    .setSize = setSize,

    .deinit = deinit
};

// Create a generic container template.
pub fn new(x: ?i32, y: ?i32, width: ?u32, height: ?u32) Template {
     return Template{
         .x = x,
         .y = y,
         .width = width,
         .height = height
     };
}

// Template for the generic container.
pub const Template = struct {
    x: ?i32,
    y: ?i32,
    width: ?u32,
    height: ?u32,

    // Initialize a generic container.
    pub fn init(template: Template, allocator: std.mem.Allocator) GenericContainer {
        return GenericContainer{
            .allocator = allocator,
            .children = std.ArrayList(Anonymous).init(allocator),

            .x = template.x,
            .y = template.y,
            .width = template.width,
            .height = template.height,
        };
    }
};

// Deinitialize the generic container.
pub fn deinit(ptr: *anyopaque) void {
    const self = @as(*GenericContainer, @ptrCast(@alignCast(ptr)));

    for (self.children.items) |*child| {
        child.deinit();
    }

    self.children.deinit();
}

// Get a child sprite.
pub fn get(self: *GenericContainer, index: u16, comptime T: type) ?*T {
    if (index < self.children.items.len) {
        return @as(*T, @ptrCast(@alignCast(self.children.items[index].ptr)));
    }

    return null;
}

// Initialize a sprite and then add to the generic container.
pub fn add(self: *GenericContainer, template: anytype) !*ResolveSpriteType(@TypeOf(template)) {
    if (self.children.items.len >= std.math.maxInt(u16) - 1) {
        return error.ReachedMaxCapacity;
    }

    var anonymous = try Anonymous.init(template.init(self.allocator), self.allocator);
    errdefer anonymous.deinit();

    try self.children.append(anonymous);

    return @as(*ResolveSpriteType(@TypeOf(template)), @ptrCast(@alignCast(anonymous.ptr)));
}

// Resolve the type of the sprite from a template type.
pub fn ResolveSpriteType(template: type) type {
    return @typeInfo(@TypeOf(@field(template, "init"))).@"fn".return_type.?;
}

// Deinitialize a child sprite and then remove it from the generic container.
pub fn remove(self: *GenericContainer, index: u16) void {
    if (index < self.children.items.len) {
        self.children.orderedRemove(index).deinit();
    }
}

// Get the position of the generic container.
pub fn getPosition(ptr: *anyopaque) Layout.PositionQuery {
    const self = @as(*GenericContainer, @ptrCast(@alignCast(ptr)));

    return Layout.PositionQuery{
        .x = self.x,
        .y = self.y
    };
}

// Get the size of the generic container.
pub fn getSize(ptr: *anyopaque) Layout.SizeQuery {
    const self = @as(*GenericContainer, @ptrCast(@alignCast(ptr)));

    return Layout.SizeQuery{
        .width = self.width,
        .height = self.height
    };
}

// Set the position of the generic container.
pub fn setPosition(ptr: *anyopaque, position: Layout.PositionQuery) void {
    const self = @as(*GenericContainer, @ptrCast(@alignCast(ptr)));

    self.x = position.x;
    self.y = position.y;
}

// Set the size of the generic container.
pub fn setSize(ptr: *anyopaque, size: Layout.SizeQuery) void {
    const self = @as(*GenericContainer, @ptrCast(@alignCast(ptr)));

    self.width = size.width;
    self.height = size.height;
}

// Anonymous sprite.
pub const Anonymous = struct {
    allocator: std.mem.Allocator,
    size: usize,
    alignment: usize,

    ptr: *anyopaque,
    vtable: *const Anonymous.VTable,

    // The vtable.
    pub const VTable = struct {
        getPosition: *const fn (ptr: *anyopaque) Layout.PositionQuery,
        getSize: *const fn (ptr: *anyopaque) Layout.SizeQuery,

        setPosition: ?*const fn (ptr: *anyopaque, position: Layout.PositionQuery) void = null,
        setSize: ?*const fn (ptr: *anyopaque, size: Layout.SizeQuery) void = null,

        render: ?*const fn (ptr: *anyopaque, parent: Layout.Parent) void = null,
        update: ?*const fn (ptr: *anyopaque) void = null,

        deinit: ?*const fn (ptr: *anyopaque) void = null
    };

    // Initialize an anonymous sprite.
    pub fn init(sprite: anytype, allocator: std.mem.Allocator) !Anonymous {
        if (!@hasField(@TypeOf(sprite), "VTable")) {
            return error.SpriteMissingVTable;
        }

        const size = @sizeOf(@TypeOf(sprite));
        const alignment = @alignOf(@TypeOf(sprite));

        const ptr = @as(*@TypeOf(sprite), @ptrCast(@constCast(&(allocator.rawAlloc(size, .fromByteUnits(alignment), @returnAddress()) orelse return error.OutOfMemory))));
        ptr.* = sprite;

        return Anonymous{
            .allocator = allocator,
            .size = size,
            .alignment = alignment,

            .ptr = ptr,
            .vtable = &@TypeOf(sprite).VTable
        };
    }

    // Deinitialize the anonymous sprite.
    pub fn deinit(self: *Anonymous) void {
        if (self.vtable.deinit) |hook| {
            hook(self.ptr);
        }

        self.allocator.rawFree(@as(*[]u8, @ptrCast(@alignCast(self.ptr))).*, .fromByteUnits(self.alignment), @returnAddress());
    }

    // Get the position of the anonymous sprite.
    pub fn getPosition(self: *Anonymous) Layout.PositionQuery {
        return self.vtable.getPosition(self.ptr);
    }

    // Get the size of the anonymous sprite.
    pub fn getSize(self: *Anonymous) Layout.SizeQuery {
        return self.vtable.getSize(self.ptr);
    }

    // Set the position of the anonymous sprite.
    pub fn setPosition(self: *Anonymous, position: Layout.PositionQuery) void {
        if (self.vtable.setPosition) |hook| {
            hook(self.ptr, position);
        }
    }

    // Set the size of the anonymous sprite.
    pub fn setSize(self: *Anonymous, size: Layout.SizeQuery) void {
        if (self.vtable.setSize) |hook| {
            hook(self.ptr, size);
        }
    }

    // Render the anonymous sprite.
    pub fn render(self: *Anonymous, parent: Layout.Parent) void {
        if (self.vtable.render) |hook| {
            hook(self.ptr, parent);
        }
    }

    // Update the anonymous sprite.
    pub fn update(self: *Anonymous) void {
        if (self.vtable.update) |hook| {
            hook(self.ptr);
        }
    }
};
