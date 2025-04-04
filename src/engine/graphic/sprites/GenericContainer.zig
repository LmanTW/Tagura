const std = @import("std");

const Sprite = @import("../Sprite.zig");
const Layout = @import("../Layout.zig");

const GenericContainer = @This();

allocator: std.mem.Allocator,
children: std.ArrayList(Sprite),

x: i32,
y: i32,
width: ?u32,
height: ?u32,

// The style of the container.
pub const Style = struct {
    anchor: Layout.Alignment = .TopLeft,
    origin: Layout.Alignment = .TopLeft
};

// The vtable.
pub const VTable = Sprite.VTable{
    .getPosition = getPosition,
    .getSize = getSize,

    .setPosition = setPosition,
    .setSize = setSize,

    .deinit = deinit
};

// Create a generic container template.
pub fn new(x: i32, y: i32, width: ?u32, height: ?u32) Template {
     return Template{
         .x = x,
         .y = y,
         .width = width,
         .height = height
     };
}

// Template for the generic container.
pub const Template = struct {
    x: i32,
    y: i32,
    width: ?u32,
    height: ?u32,

    // Initialize a generic container.
    pub fn init(template: Template, allocator: std.mem.Allocator) GenericContainer {
        return GenericContainer{
            .allocator = allocator,
            .children = std.ArrayList(Sprite).init(allocator),

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

    var anonymous = try Sprite.init(template.init(self.allocator), self.allocator);
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
pub fn getPosition(ptr: *anyopaque) Sprite.Position {
    const self = @as(*GenericContainer, @ptrCast(@alignCast(ptr)));

    return Sprite.Position{
        .x = self.x,
        .y = self.y
    };
}

// Get the size of the generic container.
pub fn getSize(ptr: *anyopaque) Sprite.Size {
    const self = @as(*GenericContainer, @ptrCast(@alignCast(ptr)));

    return Sprite.Size{
        .width = self.width,
        .height = self.height
    };
}

// Set the position of the generic container.
pub fn setPosition(ptr: *anyopaque, x: i32, y: i32) void {
    const self = @as(*GenericContainer, @ptrCast(@alignCast(ptr)));

    self.x = x;
    self.y = y;
}

// Set the size of the generic container.
pub fn setSize(ptr: *anyopaque, width: ?u32, height: ?u32) void {
    const self = @as(*GenericContainer, @ptrCast(@alignCast(ptr)));

    self.width = width;
    self.height = height;
}
