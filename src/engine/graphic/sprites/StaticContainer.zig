const std = @import("std");

const GenericContainer = @import("./GenericContainer.zig");
const Sprite = @import("../Sprite.zig");
const Layout = @import("../Layout.zig");

const StaticContainer = @This();

allocator: std.mem.Allocator,
children: ?Children,

x: i32,
y: i32,
width: ?u32,
height: ?u32,
style: GenericContainer.Style,

// The children list.
pub const Children = struct {
    array: []Sprite,
    index: u16
};

// The vtable.
pub const VTable = Sprite.VTable{
    .getPosition = getPosition,
    .getSize = getSize,

    .setPosition = setPosition,
    .setSize = setSize,

    .deinit = deinit
};

// Create a static container template.
pub fn new(x: i32, y: i32, width: ?u32, height: ?u32, style: GenericContainer.Style) Template {
     return Template{
         .x = x,
         .y = y,
         .width = width,
         .height = height,
         .style = style
     };
}

// Template for the static container.
pub const Template = struct {
    x: i32,
    y: i32,
    width: ?u32,
    height: ?u32,
    style: GenericContainer.Style,

    // Initialize a generic container.
    pub fn init(template: Template, allocator: std.mem.Allocator) StaticContainer {
        return StaticContainer{
            .allocator = allocator,
            .children = null,

            .x = template.x,
            .y = template.y,
            .width = template.width,
            .height = template.height,
            .style = template.style
        };
    }
};

// Deinitialize the container.
pub fn deinit(ptr: *anyopaque) void {
    const self = @as(*StaticContainer, @ptrCast(@alignCast(ptr)));

    if (self.children) |children| {
        for (children.array) |*child| {
            child.deinit();
        }

        self.allocator.free(children.array);
    }
}


// Get the capacity of the container.
pub fn getCapacity(self: *StaticContainer) u16 {
    if (self.children) |children| {
        return children.len;
    }

    return 0;
}

// Set the capacity of the container.
pub fn setCapacity(self: *StaticContainer, size: u16) !void {
    self.clean();

    self.children = Children{
        .array = try self.allocator.alloc(Sprite, size),
        .index = 0
    };
}

// Increase the capacity of the container.
pub fn addCapacity(self: *StaticContainer, size: u16) !void {
    if (self.children) |children| {
        const array = try self.allocator.alloc(Sprite, children.array.len + size);
        @memcpy(array, children.array);

        self.allocator.free(children.array);
        children.array = array;
    } else {
        self.children = Children{
            .array = try self.allocator.alloc(Sprite, size),
            .index = 0
        };
    }
}

// Get a child sprite.
pub fn get(self: *StaticContainer, index: u16, comptime T: type) ?*T {
    if (index < self.children.items.len) {
        return @as(*T, @ptrCast(@alignCast(self.children.items[index].unmanaged)));
    }

    return null;
}

// Initialize a sprite and add it to the container.
pub fn add(self: *StaticContainer, template: anytype) !@typeInfo(@TypeOf(@field(template, "init"))).@"fn".return_type.? {
    if (self.children) |children| {
        if (children.index >= children.array.len) {
            return error.NotEnoughCapacity;
        }

        const sprite = template.init(self.allocator);

        children.array[children.index];
        children.index += 1;

        return sprite;
    }

    return error.NoCapacityAllocated;
}

// Delete all the children sprite and remove them.
pub fn clean(self: *StaticContainer) void {
    if (self.children) |children| {
        for (children.array) |sprite| {
            sprite.deinit();
        }

        children.index = 0;
    }
}

// Get the position of the container.
pub fn getPosition(ptr: *anyopaque) Sprite.Position {
    const self = @as(*GenericContainer, @ptrCast(@alignCast(ptr)));

    return Sprite.Position{
        .x = self.x,
        .y = self.y
    };
}

// Get the size of the container.
pub fn getSize(ptr: *anyopaque) Sprite.Size {
    const self = @as(*GenericContainer, @ptrCast(@alignCast(ptr)));

    return Sprite.Size{
        .width = self.width,
        .height = self.height
    };
}

// Set the position of the container.
pub fn setPosition(ptr: *anyopaque, x: i32, y: i32) void {
    const self = @as(*GenericContainer, @ptrCast(@alignCast(ptr)));

    self.x = x;
    self.y = y;
}

// Set the size of the container.
pub fn setSize(ptr: *anyopaque, width: ?u32, height: ?u32) void {
    const self = @as(*GenericContainer, @ptrCast(@alignCast(ptr)));

    self.width = width;
    self.height = height;
}
