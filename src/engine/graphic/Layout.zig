const std = @import("std");

const Sprite = @import("./Sprite.zig");

const Layout = @This();

kind: Kind,
style: Style,

width: u32,
height: u32,

// The kind of the layout.
pub const Kind = enum(u4) {
    None,
    Horizontal,
    Vertical,
    HorizontalWrap,
    VerticalWrap,
    HorizontalFlex,
    VerticalFlex
};

// The style of the layout.
pub const Style = struct {
    horizontal_gap: u32 = 0,
    vertical_gap: u32 = 0,

    minimum_flex_width: ?u32 = null,
    minimum_flex_height: ?u32 = null,
    maximum_flex_width: ?u32 = null,
    maximum_flex_height: ?u32 = null
};

// Initialize a layout.
pub fn init(kind: Kind, width: u32, height: u32, style: Style) Layout {
    return Layout{
        .kind = kind,
        .style = style,

        .width = width,
        .height = height
    };
}

// Calculate the position.
pub fn calculatePosition(parent: Sprite.Dimension, dimension: Sprite.Dimension, anchor: Alignment, origin: Alignment) Sprite.Position {
    var result_x = @as(i32, 0);
    var result_y = @as(i32, 0);

    switch (anchor) {
        .TopCenter => {
            result_x = @divFloor(parent.width, 2);
            result_y = 0;
        },

        .TopRight => {
            result_x = parent.width;
            result_y = 0;
        },

        .Left => {
            result_x = 0;
            result_y = @divFloor(parent.height, 2);
        },

        .Center => {
            result_x = @divFloor(parent.width, 2);
            result_y = @divFloor(parent.height, 2);
        },

        .Right => {
            result_x = parent.width;
            result_y = @divFloor(parent.height, 2);
        },

        .BottomLeft => {
            result_x = 0;
            result_y = parent.height;
        },

        .BottomCenter => {
            result_x = @divFloor(parent.width, 2);
            result_y = parent.height;
        },

        .BottomRight => {
            result_x = parent.width;
            result_y = parent.height;
        },

        else => {}
    }

    switch (origin) {
        .TopCenter => {
            result_x -= @divFloor(dimension.width, 2);
        },

        .TopRight => {
            result_x -= dimension.width;
        },

        .Left => {
            result_y -= @divFloor(dimension.height, 2);
        },

        .Center => {
            result_x -= @divFloor(dimension.width, 2);
            result_y -= @divFloor(dimension.height, 2);
        },

        .Right => {
            result_x -= dimension.width;
            result_y -= @divFloor(dimension.height, 2);
        },

        .BottomLeft => {
            result_y -= dimension.height;
        },

        .BottomCenter => {
            result_x -= @divFloor(dimension.width, 2);
            result_y -= dimension.height;
        },

        .BottomRight => {
            result_x -= dimension.width;
            result_y -= dimension.height;
        },

        else => {}
    }

    return Sprite.Position{
        .x = result_x,
        .y = result_y
    };
}

// Calculate the size of the layout.
pub fn calculateSize(self: *Layout, comptime T: type, children: []T) Size {
    switch (self.kind) {
        .None => {
            return Size{
                .width = self.width,
                .height = self.height
            };
        },

        .Horizontal => {
            var total_width = @as(u32, 0);

            for (children) |child| {
                const size = child.getSize();

                if (size.width) |width| {
                    total_width += if (total_width > 0) width + self.style.horizontal_gap else width;
                }
            }

            return Size{
                .width = total_width,
                .height = self.height
            };
        },

        .Vertical => {
            var total_height = @as(u32, 0);

            for (children) |child| {
                const size = child.getSize();
                
                if (size.height) |height| {
                    total_height += if (total_height > 0) height + self.style.vertical_gap else height;
                }
            }

            return Size{
                .width = self.width,
                .height = total_height
            };
        },

        .HorizontalWrap => {
            var total_height = @as(u32, 0);
            var row_width = @as(u32, 0);
            var row_height = @as(u32, 0);

            for (children) |child| {
                const size = child.getSize();

                if (size.width) |width|
                    row_width += if (row_width > 0) width + self.style.horizontal_gap else width;
                if (size.height and size.height.? > row_height)
                    row_height = size.height.?;

                if (row_width > self.width) {
                    total_height += if (total_height > 0) row_height + self.style.vertical_gap else row_height;

                    row_width = 0;
                    row_height = 0;
                }
            }

            if (row_height > 0) {
                total_height += if (total_height > 0) row_height + self.style.vertical_gap else row_height;
            }

            return Size{
                .width = self.width,
                .height = total_height
            };
        },

        .VerticalWrap => {
            var total_width = @as(u32, 0);
            var row_width = @as(u32, 0);
            var row_height = @as(u32, 0);

            for (children) |child| {
                const size = child.getSize();

                if (size.height) |height|
                    row_height += if (row_height > 0) height + self.style.vertical_gap else height;
                if (size.width and size.width.? > row_width)
                    row_width = size.width.?; 

                if (row_height > self.height) {
                    total_width += if (total_width > 0) row_width + self.style.horizontal_gap else row_width;

                    row_width = 0;
                    row_height = 0;
                }
            }

            if (row_width > 0) {
                total_width += if (total_width > 0) row_width + self.style.horizontal_gap else row_width;
            }

            return Size{
                .width = total_width,
                .height = self.height
            };
        },

        .HorizontalFlex => {
            var used_space = @as(u32, 0);
            var flex_children = @as(u16, 0);

            for (children) |child| {
                const size = child.getSize();

                if (size.width) |width| {
                    used_space += width;
                } else {
                    flex_children += 1;
                }
            }

            const total_gap = if (children.len > 1) self.style.horizontal_gap * (children.len - 1) else 0;
            const flex_space = self.width -| (used_space + total_gap);
            const minimum_width = self.style.minimum_flex_width * flex_children;
            const maximum_width = self.style.maximum_flex_width * flex_children;

            return Size{
                .width = used_space + std.math.clamp(flex_space, minimum_width, maximum_width),
                .height = self.height
            };
        },

        .VerticalFlex => {
            var used_space = @as(u32, 0);
            var flex_children = @as(u16, 0);

            for (children) |child| {
                const size = child.getSize();

                if (size.height) |height| {
                    used_space += height;
                } else {
                    flex_children += 1;
                }
            }

            const total_gap = if (children.len > 1) self.style.vertical_gap * (children.len - 1) else 0;
            const flex_space = self.height -| (used_space + total_gap);
            const minimum_height = self.style.minimum_flex_height * flex_children;
            const maximum_height = self.style.maximum_flex_height * flex_children;

            return Size{
                .width = self.width,
                .height = used_space + std.math.clamp(flex_space, minimum_height, maximum_height)
            };
        }
    }
}

// The layout iterator.
pub fn iterator(self: *Layout, comptime T: type, children: []T) Iterator(T) {
    return Iterator(T).init(self, children);
}

// The layout iterator.
pub fn Iterator(comptime T: type) type {
    return struct {
        const Self = @This();

        kind: Kind,
        style: Style,

        width: u32,
        height: u32,

        children: []T,
        index: u16,

        x: i32 = 0,
        y: i32 = 0,
        row_width: u32 = 0,
        row_height: u32 = 0,
        flex_size: u32 = 0,

        // Initialize a layout iterator.
        pub fn init(layout: *Layout, children: []T) Self {
            var flex_size = @as(u32, 0);

            if (layout.kind == .HorizontalFlex or layout.kind == .VerticalFlex) {
                var used_space = @as(u32, 0);
                var flex_children = @as(u16, 0);

                for (children) |child| {
                    const size = child.getSize();

                    if (layout.kind == .HorizontalFlex) {
                        if (size.width) |width| {
                            used_space += width;
                        } else {
                            flex_children += 1;
                        }
                    } else {
                        if (size.height) |height| {
                            used_space += height;
                        } else {
                            flex_children += 1;
                        }
                    }
                }

                if (layout.kind == .HorizontalFlex) {
                    const total_gap = if (children.len > 1) layout.style.horizontal_gap * (children.len - 1) else 0;

                    flex_size = std.clamp(
                        @divFloor(layout.width -| (used_space + total_gap), flex_children),
                        layout.style.minimum_flex_width,
                        layout.style.maximum_flex_width
                    );
                } else {
                    const total_gap = if (children.len > 1) layout.style.vertical_gap * (children.len - 1) else 0;

                    flex_size = std.clamp(
                        @divFloor(layout.height -| (used_space + total_gap), flex_children),
                        layout.style.minimum_flex_height,
                        layout.style.maximum_flex_height
                    );
                }
            }

            return Self{
                .kind = layout.kind,
                .style = layout.style,

                .width = layout.width,
                .height = layout.height,

                .children = children,
                .index = 0,

                .flex_size = flex_size
            };
        }

        // Iterate the layout.
        pub fn next(self: *Self) ?Sprite.Position {
            if (self.index < self.children) {
                const position = Sprite.Position{
                    .x = self.x,
                    .y = self.y
                };

                switch (self.kind) {
                    .Horizontal => {
                        self.x += self.children[self.index].getSize().width + self.style.horizontal_gap;
                    },

                    .Vertical => {
                        self.y += self.children[self.index].getSize().height + self.style.vertical_gap;
                    },

                    .HorizontalWrap => {
                        const size = self.children[self.index].getSize();

                        if (size.width) |width|
                            self.x += width + self.style.horizontal_gap;
                        if (size.height and size.height.? > self.row_height)
                            self.row_height = size.height.?;

                        if (self.x > self.width) {
                            self.x = 0;
                            self.y += self.row_height + self.style.vertical_gap;
                        }
                    },

                    .VerticalWrap => {
                        const size = self.children[self.index].getSize();

                        if (size.height) |height|
                            self.y += height + self.style.vertical_gap;
                        if (size.width and size.width.? > self.row_width)
                            self.row_width = size.width.?;

                        if (self.y > self.height) {
                            self.x += self.row_width + self.style.horizontal_gap;
                            self.y = 0;
                        }
                    },

                    .HorizontalFlex => {
                        if (self.children[self.index].getSize().width) |width| {
                            self.x = width + self.style.horizontal_gap;
                        } else {
                            self.x = self.flex_size + self.style.horizontal_gap;
                        }
                    },

                    .VerticalFlex => {
                        if (self.children[self.index].getSize().height) |height| {
                            self.y = height + self.style.vertical_gap;
                        } else {
                            self.y = self.flex_size + self.style.vertical_gap;
                        }
                    }
                }

                self.index += 1;

                return position;
            }

            return null;
        }
    };
}

// The alignment.
pub const Alignment = enum(u4) {
    TopLeft,
    TopCenter,
    TopRight,
    Left,
    Center,
    Right,
    BottomLeft,
    BottomCenter,
    BottomRight
};

// The size.
pub const Size = struct {
    width: u32,
    height: u32
};
