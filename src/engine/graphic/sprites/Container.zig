const std = @import("std");

const Sprite = @import("../Sprite.zig");
const Layout = @import("../Layout.zig");

const Container = @This();

allocator: std.mem.Allocator,
children: std.ArrayList(Sprite),

x: Layout.Coordinate,
y: Layout.Coordinate,
width: Layout.Measurement,
height: Layout.Measurement,

layout: Layout,
style: Style,

// The style of the container.
pub const Style = struct {
    anchor: Layout.Alignment = .TopLeft,
    origin: Layout.Alignment = .TopLeft,

    layout: Layout.Kind = .None,
    layout_style: Layout.Style = .{} 
};

// The vtable.
pub const VTable = Sprite.VTable{
    .getPosition = getPosition,
    .getSize = getSize,

    .render = render,
    .update = update,

    .deinit = deinit
};

// Create a container template.
pub fn new(position: Layout.Position, size: Layout.Size, style: Style) Template {
    return Template{
        .position = position,
        .size = size,
        .style = style
    };
}

// The container template.
pub const Template = struct {
    position: Layout.Position,
    size: Layout.Size,
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

        .x = template.position.x,
        .y = template.position.y,
        .width = template.size.width,
        .height = template.size.height,

        .layout = Layout.init(template.style.layout, template.style.layout_style),
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
pub fn setCapacity(self: *Container, capacity: u16) !void {
    try self.children.ensureTotalCapacityPrecise(capacity);
}

// Get a child sprite.
pub fn get(self: *Container, index: u16, comptime T: type) ?*T {
    if (index < self.children.items.len) {
        return @as(*T, @ptrCast(@alignCast(self.children.items[index].ptr)));
    }

    return null;
}

// Find a child sprite.
pub fn find(self: *Container, sprite: *anyopaque) ?u16 {
    for (self.children.items, 0..) |children, index| {
        if (children.ptr == sprite) {
            return @as(u16, @intCast(index));
        }
    }

    return null;
}

// Initialize a sprite and then add it to the container.
pub fn add(self: *Container, template: anytype) !*ResolveSpriteType(@TypeOf(template)) {
    if (self.children.items.len >= std.math.maxInt(u16) - 1) {
        return error.MaxCapacityExceed;
    }

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
pub fn repalce(self: *Container, index: u16, template: anytype) !*ResolveSpriteType(@TypeOf(template)) {
    if (index >= self.children.items.len) {
        return error.IndexOutOfBound;
    }

    const sprite = try Sprite.init(template.init(self.allocator), self.allocator);

    self.children.items[index].deinit();
    self.children.items[index] = sprite;

    return @as(*ResolveSpriteType(@TypeOf(template)), @ptrCast(@alignCast(sprite.ptr)));
}

// Remove a child sprite.
pub fn remove(self: *Container, index: u16) void {
    if (index < self.children.items.len) {
        self.children.orderedRemove(index).deinit();
    }
}

// Remove all the chidlren sprites.
pub fn clear(self: *Container, free: bool) void {
    for (self.children.items) |*child| {
        child.deinit();
    }

    if (free) {
        self.children.clearAndFree();
    } else {
        self.children.clearRetainingCapacity();
    }
}

// Get the position of the container.
pub fn getPosition(ptr: *anyopaque) Layout.Position {
    const self = @as(*Container, @ptrCast(@alignCast(ptr)));

    return Layout.Position{
        .x = self.x,
        .y = self.y
    };
}

// Get the size of the container.
pub fn getSize(ptr: *anyopaque) Layout.Size {
    const self = @as(*Container, @ptrCast(@alignCast(ptr)));

    return Layout.Size{
        .width = self.width,
        .height = self.height
    };
}

// Render the container.
pub fn render(ptr: *anyopaque, global: Layout.Dimension, parent: Layout.Dimension) void {
    const self = @as(*Container, @ptrCast(@alignCast(ptr)));

    const container_size = Layout.Size.init(self.width, self.height).resolve(parent.width, parent.height);
    const container_position = Layout.Position.init(self.x, self.y).resolve(global, parent, container_size, self.style.anchor, self.style.origin);

    var iterator = self.layout.iterate(container_size.width, container_size.height, self.children.items);

    while (iterator.next()) |frame| {
        frame.sprite.render(global, Layout.Dimension{
            .x = container_position.x + frame.position.x,
            .y = container_position.y + frame.position.y,
            .width = frame.size.width,
            .height = frame.size.height
        });
    }
}

// Update the container.
pub fn update(_: *anyopaque) void {
    
}
