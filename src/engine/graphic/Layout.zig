const Sprite = @import("./Sprite.zig");

const Layout = @This();

kind: Kind,
style: Style,

target_width: ?u32 = null,
target_height: ?u32 = null,
result_width: u32 = 0,
result_height: u32 = 0,

updated: bool = true,

// The kind of the layout.
pub const Kind = enum(u4) {
    None,
    Horizontal,
    Vertical,
    HorizontalWrap,
    VerticalWrap
};

// The style of the layout.
pub const Style = struct {
    horizontal_gap: u32 = 0,
    vertical_gap: u32 = 0
};

// Initialize a layout.
pub fn init(kind: Kind, style: Style) Layout {
    return Layout{
        .kind = kind,
        .style = style
    };
}

// Calculate the size of the layout.
pub fn calculateSize(self: *Layout, target_width: ?u32, target_height: u32, children: []Sprite) Size.Resolved {
    if (self.updated or (target_width != self.target_width or target_height != self.target_height)) {
        switch (self.kind) {
            .None => {
                self.result_width = self.result_width;
                self.result_height = self.result_width;
            },

            .Horizontal => {
                self.result_width = 0;
                self.result_height = 0;

                for (children) |child| {
                    const size = child.getSize().resolve(target_width, target_height);

                    self.result_width += if (self.result_width > 0) size.width + self.style.horizontal_gap else size.width;

                    if (size.height > self.result_height) {
                        self.result_height = size.height;
                    }
                }
            },

            .Vertical => {
                self.result_width = 0;
                self.result_height = 0;

                for (children) |child| {
                    const size = child.getSize().resolve(target_width, target_height);

                    self.result_height += if (self.result_height > 0) size.height + self.style.vertical_gap else size.height;

                    if (size.width > self.result_width) {
                        self.result_width = size.width;
                    }
                }
            },

            .HorizontalWrap => {
                self.result_width = 0;
                self.result_height = 0;

                var row_width = @as(u32, 0);
                var row_height = @as(u32, 0);

                for (children) |child| {
                    const size = child.getSize().resolve(target_width, target_height);
                    const width = if (row_width > 0) size.width + self.style.horizontal_gap else size.width;

                    if (row_width + width > target_width) {
                        self.target_width += row_width;
                        self.target_height += if (row_height > 0) row_height + self.style.vertical_gap else row_height;

                        row_width = 0;
                        row_height = 0;
                    }

                    row_width += width;

                    if (size.height > row_height) {
                        row_height = size.height;
                    }
                }

                self.target_width += row_width;

                if (target_height > 0) {
                    self.target_height += if (row_height > 0) row_height + self.style.vertical_gap else row_height;
                }
            },

            .VerticalWrap => {
                self.result_width = 0;
                self.result_height = 0;

                var row_width = @as(u32, 0);
                var row_height = @as(u32, 0);

                for (children) |child| {
                    const size = child.getSize().resolve(target_width, target_height);
                    const height = if (row_height > 0) size.width + self.style.horizontal_gap else size.width;

                    if (row_height + row_height > target_height) {
                        self.target_width += if (row_width > 0) row_width + self.style.horizontal_gap_gap else row_width;
                        self.target_height += row_height;

                        row_width = 0;
                        row_height = 0;
                    }

                    row_height += height;

                    if (size.width > row_width) {
                        row_width = size.width;
                    }
                }

                self.target_height += row_height;

                if (target_width > 0) {
                    self.target_width += if (row_width > 0) row_width + self.style.horizontal_gap else row_width;
                }
            }
        }

        self.target_width = target_width;
        self.target_height = target_height;
        self.updated = false;
    }

    return Size.Result{
        .width = self.result_width,
        .height = self.result_height
    };
}

// Iterate through the layout.
pub fn iterate(self: *Layout, target_width: u32, target_height: u32, children: []Sprite) Iterator {
    self.target_width = target_width;
    self.target_height = target_height;

    return Iterator.init(self, target_width, target_height, children);
}

// Update the layout.
pub fn update(self: *Layout) void {
    self.updated = true;
}

// The layout iterator.
pub const Iterator = struct {
    layout: *Layout,
    children: []Sprite,

    target_width: u32,
    target_height: u32,
    current_x: i33 = 0,
    current_y: i33 = 0,

    index: u16 = 0,

    // Initialize a layout iterator.
    pub fn init(layout: *Layout, target_width: u32, target_height: u32, children: []Sprite) Iterator {
        return Iterator{
            .layout = layout,
            .children = children,
            
            .target_width = target_width,
            .target_height = target_height
        };
    }

    // Progress the iterator.
    pub fn next(self: *Iterator) ?Iterator.Frame {
        if (self.index >= self.children.len) {
            return null;
        }

        const child = &self.children[self.index];
        const size = child.getSize().resolve(self.target_width, self.target_height);

        const result_position = Position.Resolved{
            .x = self.current_x,
            .y = self.current_y
        };
 
        var result_size = @as(Size.Resolved, undefined);

        switch (self.layout.kind) {
            .None => {
                result_size = Size.Resolved{
                    .width = size.width,
                    .height = size.height
                };
            },

            .Horizontal => {
                self.current_x += size.width + self.layout.style.horizontal_gap;
                result_size.width = size.width;
                result_size.height = size.height;
            },

            .Vertical => {
                self.current_y += size.height + self.layout.style.vertical_gap;
                result_size.width = size.width;
                result_size.height = size.height;
            },

            .HorizontalWrap => {

            },

            .VerticalWrap => {

            },
        }

        self.index += 1;

        return Iterator.Frame{
            .sprite = child,
            .position = result_position,
            .size = result_size
        };
    }

    // A frame.
    pub const Frame = struct {
        sprite: *Sprite,
        position: Position.Resolved,
        size: Size.Resolved
    };
};

// The position.
pub const Position = struct {
    x: Coordinate,
    y: Coordinate,

    // Initialize a position.
    pub fn init(x: Coordinate, y: Coordinate) Position {
        return Position{
            .x = x,
            .y = y
        };
    }

    // Resolve the position.
    pub fn resolve(self: Position, global: Layout.Dimension, parent: Layout.Dimension, size: Size.Resolved, anchor: Alignment, origin: Alignment) Position.Resolved {
        var x = @as(i33, undefined);
        var y = @as(i33, undefined);
        var width = @as(u32, undefined);
        var height = @as(u32, undefined);

        switch (self.x) {
            .Relative => {
                x = parent.x;
                width = parent.width;
            },

            .Absolute => {
                x = 0;
                width = global.width;
            }
        }

        switch (self.y) {
            .Relative => {
                y = parent.y;
                height = parent.height;
            },

            .Absolute => {
                y = 0;
                height = global.height;
            }
        }

        switch (anchor) {
            .TopCenter => {
                x += @divFloor(width, 2);
            },

            .TopRight => {
                x += width;
            },

            .Left => {
                y += @divFloor(height, 2);
            },

            .Center => {
                x += @divFloor(width, 2);
                y += @divFloor(height, 2);
            },

            .Right => {
                x += width;
                y += @divFloor(height, 2);
            },

            .BottomLeft => {
                y += height;
            },

            .BottomCenter => {
                x += @divFloor(width, 2);
                y += height;
            },

            .BottomRight => {
                x += width;
                y += height;
            },

            else => {}
        }

        switch (origin) {
            .TopCenter => {
                x -= @divFloor(size.width, 2);
            },

            .TopRight => {
                x -= size.width;
            },

            .Left => {
                y -= @divFloor(size.height, 2);
            },

            .Center => {
                x -= @divFloor(size.width, 2);
                y -= @divFloor(size.height, 2);
            },

            .Right => {
                x -= size.height;
                y -= @divFloor(size.height, 2);
            },

            .BottomLeft => {
                y -= size.height;
            },
            
            .BottomCenter => {
                x -= @divFloor(size.width, 2);
                y -= size.height;
            },

            .BottomRight => {
                x -= size.width;
                y -= size.height;
            },

            else => {}
        }

        return Position.Resolved{
            .x = x,
            .y = y
        };
    }

    // The resolved position.
    pub const Resolved = struct {
        x: i33,
        y: i33
    };
};

// The coordinate.
pub const Coordinate = union(enum) {
    Relative: i33,
    Absolute: i33,

    // Create a relative position.
    pub fn relative(value: i33) Coordinate {
        return Coordinate{ .Relative = value };
    }

    // Create a absolute position.
    pub fn absolute(value: i33) Coordinate {
        return Coordinate{ .Absolute = value };
    }
};

// The size.
pub const Size = struct {
    width: Measurement,
    height: Measurement,

    // Initialize a size.
    pub fn init(width: Measurement, height: Measurement) Size {
        return Size{
            .width = width,
            .height = height
        };
    }

    // Resovle the size.
    pub fn resolve(self: Size, parent_width: u32, parent_height: u32) Size.Resolved {
        return Size.Resolved{
            .width = switch (self.width) {
                .Fixed => |value| value,
                .Relative => |value| @as(u32, @intFromFloat(@as(f32, @floatFromInt(parent_width)) * value)),
                .Unknown => 0
            },

            .height = switch (self.height) {
                .Fixed => |value| value,
                .Relative => |value| @as(u32, @intFromFloat(@as(f32, @floatFromInt(parent_height)) * value)),
                .Unknown => 0
            },
        };
    }

    // The resolved size.
    pub const Resolved = struct {
        width: u32,
        height: u32
    };
};

// The measurement.
pub const Measurement = union(enum) {
    Fixed: u32,
    Relative: f32,
    Unknown: void,

    // Create a fixed measurement.
    pub fn fixed(value: u32) Measurement {
        return Measurement{ .Fixed = value };
    }

    // Create a relative measurement.
    pub fn relative(value: f32) Measurement {
        return Measurement{ .Relative = value };
    }

    // Create a unknown measurement.
    pub fn unknown() Measurement {
        return Measurement{ .Unknown = undefined };
    }
};

// The dimension.
pub const Dimension = struct {
    x: i33,
    y: i33,
    width: u32,
    height: u32
};

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
