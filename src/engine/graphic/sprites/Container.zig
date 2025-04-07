const std = @import("std");

const Sprite = @import("../Sprite.zig");
const Layout = @import("../Layout.zig");

const Container = @This();

allocator: std.mem.Allocator,
children: std.ArrayList(Sprite),

x: Layout.Position,
y: Layout.Position,
width: Layout.Size,
height: Layout.Size,

style: Style,

// The style of the container.
pub const Style = struct {
    anchor: Layout.Alignment = .TopLeft,
    origin: Layout.Alignment = .TopLeft
};

// The vtable.
pub const VTable = Sprite.VTable{
    .deinit = deinit
};

// Create a container template.
pub fn new(x: Layout.Position, y: Layout.Position, width: Layout.Size, height: Layout.Size, style: Style) Template {
    return Template{
        .x = x,
        .y = y,
        .width = width,
        .height = height,
        .style = style
    };
}

// The container template.
pub const Template = struct {
    x: Layout.Position,
    y: Layout.Position,
    width: Layout.Size,
    height: Layout.Size,
    style: Style,

    // Initialize a container from the template.
    pub fn init(self: Template, allocator: std.mem.Allocator) Container {
        return Container.init(self, allocator);
    }
};

// Initialize a container.
pub fn init(template: Template, allocator: std.mem.Allocator) Container {
    return Container{
        .allocator = allocator,
        .children = std.ArrayList(Sprite).init(allocator),

        .x = template.x,
        .y = template.y,
        .width = template.width,
        .height = template.height,
        .style = template.style
    };
}

// Deinitialize the container.
pub fn deinit(ptr: *anyopaque) void {
    const self = @as(*Container, @ptrCast(@alignCast(ptr)));

    for (self.children.items) |*child| {
        child.deinit();
    }

    self.children.deinit();
}

// Get the capacity of the container.
pub fn getCapacity(self: *Container) usize {
    return self.children.capacity;
}

// Set the capacity of the container.
pub fn setCapacity(self: *Container, capacity: usize) !void {
    try self.children.ensureTotalCapacityPrecise(capacity);
}

// Get a child sprite.
pub fn get(self: *Container, index: usize, comptime T: type) ?*T {
    if (index < self.children.items.len) {
        return @as(*T, @ptrCast(@alignCast(self.children.items[index].ptr)));
    }

    return null;
}

// Find a child sprite.
pub fn find(self: *Container, sprite: *anyopaque) ?usize {
    for (self.children.items, 0..) |children, index| {
        if (children.ptr == sprite) {
            return index;
        }
    }

    return null;
}

// Initialize a sprite and then add it to the container.
pub fn add(self: *Container, template: anytype) !*ResolveSpriteType(@TypeOf(template)) {
    var sprite = try Sprite.init(template.init(self.allocator), self.allocator);
    errdefer sprite.deinit();
 
    try self.children.append(sprite);

    return @as(*ResolveSpriteType(@TypeOf(template)), @ptrCast(@alignCast(sprite.ptr)));
}

// Resolve the type of the sprite from a template type.
fn ResolveSpriteType(template: type) type {
    return @typeInfo(@TypeOf(@field(template, "init"))).@"fn".return_type.?;
}

// Replace a child sprite.
pub fn repalce(self: *Container, index: usize, template: anytype) !*ResolveSpriteType(@TypeOf(template)) {
    if (index >= self.children.items.len) {
        return error.IndexOutOfBound;
    }

    const sprite = try Sprite.init(template.init(self.allocator), self.allocator);

    self.children.items[index].deinit();
    self.children.items[index] = sprite;

    return @as(*ResolveSpriteType(@TypeOf(template)), @ptrCast(@alignCast(sprite.ptr)));
}

// Remove a child sprite.
pub fn remove(self: *Container, index: usize) void {
    if (index < self.children.items.len) {
        self.children.orderedRemove(index).deinit();
    }
}
