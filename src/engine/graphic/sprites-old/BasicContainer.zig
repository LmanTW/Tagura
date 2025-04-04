const std = @import("std");

const Sprite = @import("../Sprite.zig");

const BasicContainer = @This();

allocator: std.mem.Allocator,
children: std.ArrayList(Sprite),

x: i32,
y: i32,
width: u32,
height: u32,
style: Style,

// The style of the container.
pub const Style = struct {
    anchor: Sprite.Alignment = .TopLeft,
    origin: Sprite.Alignment = .TopLeft,

    layout: Layout = .None,
    horizontal_padding: u32 = 0,
    vertical_padding: u32 = 0,

    overflow: Overflow = .Hidden,
    horizontal_scroll: bool = true,
    vertical_scroll: bool = true,

    opacity: f32 = 1
};


// The layout of the container.
pub const Layout = enum(u4) {
    None,
    Horizontal,
    Vertical,
    HorizontalWrap,
    VerticalWrap
};

// The behavior of overflow of the container.
pub const Overflow = enum(u4) {
    Hidden,
    Scroll
};

// Create a container template.
pub fn new(x: i32, y: i32, width: u32, height: u32, style: Style) Template {
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
    style: Style,

    // Initialize a container from the template.
    pub fn init(self: *const Template, allocator: std.mem.Allocator) BasicContainer {
        return BasicContainer{
            .allocator = allocator,
            .children = std.ArrayList(Sprite).init(allocator),

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
    const self = @as(*BasicContainer, @ptrCast(@alignCast(unmanaged)));

    for (self.children.items) |*sprite| {
        sprite.deinit();
    }

    self.children.deinit();
}

// Get a child sprite.
pub fn get(self: *BasicContainer, index: u16, comptime T: type) ?*T {
    if (index < self.children.items.len) {
        return @as(*T, @ptrCast(@alignCast(self.children.items[index].unmanaged)));
    }

    return null;
}

// Initialize a sprite and add it to the container.
pub fn add(self: *BasicContainer, template: anytype) !@typeInfo(@TypeOf(@field(template, "init"))).@"fn".return_type.? {
    const sprite = template.init(self.allocator);
    errdefer sprite.deinit();

    try self.children.append(sprite);

    return sprite;
}

// Deinitialize a child sprite and remove it from the sprite.
pub fn remove(self: *BasicContainer, index: u16) void {
    if (index < self.children.items.len) {
        self.children.orderedRemove(index).deinit();
    }
}

// Delete all the children sprite and remove them.
pub fn clean(self: *BasicContainer) void {
    for (self.children.items) |sprite| {
        sprite.deinit();
    }

    self.children.clearAndFree();
}

// Get the position of the container.
pub fn getPosition(unmanaged: *anyopaque) Sprite.Position {
    const self = @as(*BasicContainer, @ptrCast(@alignCast(unmanaged)));

    return Sprite.Position{
        .x = self.x,
        .y = self.y
    };
}

// Get the size of the container.
pub fn getSize(unmanaged: *anyopaque) Sprite.Size {
    const self = @as(*BasicContainer, @ptrCast(@alignCast(unmanaged)));

    var layout = LayoutCalculator{
        .width = self.width,
        .height = self.height,

        .style = self.style,
        .children = self.children.items
    };

    return layout.calculateSize();
}

// Render the container.
pub fn render(_: *anyopaque, _: Sprite.Size) void {
}

// Update the container.
pub fn update(_: *anyopaque) void {
}

// The layout calculator.
pub const LayoutCalculator = struct {
    width: u16,
    height: u16,

    style: Style,
    children: []Sprite,

    x: u16 = 0,
    y: u16 = 0,

    // Reset the layout.
    pub fn resetLayout(self: *LayoutCalculator) void {
        self.x = 0;
        self.y = 0;
    }

    // Progress the layout.
    pub fn progressLayout(self: *LayoutCalculator, index: u16) Sprite.Position {
        if (index < self.children.len) {
            switch (self.style.layout) {
                .None => {
                    return Sprite.Position{
                        .x = 0,
                        .y = 0
                    };
                },

                .Horizontal, .HorizontalWrap => {
                    const position = Sprite.Position{
                        .x = self.x,
                        .y = self.y
                    };

                    const size = self.children[index].getSize();
                    self.x += size.width + self.style.horizontal_padding;

                    if (self.style.layout == .HorizontalWrap and self.x > self.width) {
                        self.x = 0;
                        self.y += size.height + self.style.vertical_padding;
                    }

                    return position;
                },

                .Vertical, .VerticalWrap => {
                    const position = Sprite.Position{
                        .x = self.x,
                        .y = self.y
                    };

                    const size = self.children[index].getSize();
                    self.y += size.height + self.style.vertical_padding;

                    if (self.style.layout == .HorizontalWrap and self.x > self.width) {
                        self.x += size.width + self.style.horizontal_scroll;
                        self.y = 0;
                    }

                    return position;
                }
            }
        }
    }

    // Calculate the full size.
    pub fn calculateFullSize(self: *LayoutCalculator) Sprite.Size {
        switch (self.style.layout) {
            .None => {
                return Sprite.Size{
                    .width = self.width,
                    .height = self.height
                };
            },

            .Horizontal, .HorizontalWrap => {
                var width = @as(u16, 0);
                var height = self.height;

                for (self.children) |sprite| {
                    const size = sprite.getSize();
                    width += if (width > 0) size.width + self.style.horizontal_padding else size.width;

                    if (self.style.layout == .HorizontalWrap and width > self.width) {
                        width = 0;
                        height += size.height + self.style.vertical_padding;
                    }
                }

                return Sprite.Size{
                    .width = width,
                    .height = height
                };
            },

            .Vertical, .VerticalWrap => {
                var width = self.width;
                var height = @as(u16, 0);

                for (self.children) |sprite| {
                    const size = sprite.getSize();
                    height += if (height > 0) size.width + self.style.horizontal_padding else size.width;

                    if (self.style.layout == .VerticalWrap and height > self.height) {
                        width += size.width + self.style.horizontal_padding;
                        height = 0;
                    }
                }

                return Sprite.Size{
                    .width = width,
                    .height = height
                };
            }
        }
    }
};
