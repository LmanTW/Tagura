const std = @import("std");

const BasicContainer = @import("./BasicContainer.zig");
const Sprite = @import("../Sprite.zig");

const StaticContainer = @This();

allocator: std.mem.Allocator,
children: ?Children,

x: i32,
y: i32,
width: u32,
height: u32,
style: BasicContainer.Style,

// The children list.
pub const Children = struct {
    array: []Sprite,
    index: u16
};

// Create a container template.
pub fn new(x: i32, y: i32, width: u32, height: u32, style: BasicContainer.Style) Template {
    return Template{
        .x = x,
        .y = y,
        .width = width,
        .height = height,
        .style = style
    };
}

// The container tempalte.
pub const Template = struct {
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    style: BasicContainer.Style,

    // Initialize a container from the template.
    pub fn init(self: *const Template, allocator: std.mem.Allocator) StaticContainer {
        return StaticContainer{
            .allocator = allocator,
            .children = null,

            .x = self.x,
            .y = self.y,
            .width = self.width,
            .height = self.height,

            .style = self.style
        };
    }
};

// Deinitialize the container.
pub fn deinit(unmanaged: *anyopaque) void {
    const self = @as(*StaticContainer, @ptrCast(@alignCast(unmanaged)));

    if (self.children) |children| {
        self.allocator.free(children);
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

// Render the container.
pub fn render(_: *anyopaque, _: Sprite.Size) void {
}

// Update the container.
pub fn update(_: *anyopaque) void {
}
