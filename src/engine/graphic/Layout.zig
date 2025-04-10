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
pub fn calculateSize(self: *Layout, target_width: u32, target_height: u32, children: []Sprite) Size.Result {
    if (self.updated or (target_width != self.target_width or target_height != self.target_height)) {
        switch (self.kind) {
            .None => {
                self.result_width = self.result_width;
                self.result_height = self.result_width;
            },

            .Horizontal => {
                self.width_result = 0;
                self.height_result = 0;

                for (children) |child| {
                    const size = child.getSize().resolve(target_width, target_height);

                    self.result_width += if (self.result_width > 0) size.width + self.style.horizontal_gap else size.width;

                    if (size.height > self.result_height) {
                        self.result_height = size.height;
                    }
                }
            },

            .Vertical => {
                self.width_result = 0;
                self.height_result = 0;

                for (children) |child| {
                    const size = child.getSize().resolve(target_width, target_height);

                    self.result_height += if (self.result_height > 0) size.height + self.style.vertical_gap else size.height;

                    if (size.width > self.result_width) {
                        self.result_width = size.width;
                    }
                }
            },

            .HorizontalWrap => {
                self.width_result = 0;
                self.height_result = 0;

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
                self.width_result = 0;
                self.height_result = 0;

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
        .width = self.width_result,
        .height = self.height_result
    };
}

// Iterate through the layout.
pub fn iterate(self: *Layout, target_width: u32, target_height: u32, children: []Sprite) Iterator {
    self.setSize(target_width, target_height);

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
    current_x: i32 = 0,
    current_y: i32 = 0,

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
    pub fn next(self: *Iterator) ?Position.Resolved {
        if (self.index >= self.children.len) {
            return null;
        }

        const position = Position.Resolved{
            .x = self.current_x,
            .y = self.current_y
        };

        const child = self.children[self.index];
        const size = child.getSize().resolve(self.target_width, self.target_height);

        switch (self.layout.kind) {
            .Horizontal => {
                self.current_x += size.width + self.layout.style.horizontal_gap;
            },

            .Vertical => {
                self.current_y += size.height + self.layout.style.vertical_gap;
            },

            .HorizontalWrap => {

            },

            .VerticalWrap => {

            },

            else => {}
        }

        self.index += 1;

        return position;
    }
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
    pub fn resolve(self: Position, global: Layout.Dimension, parent: Layout.Dimension, _: Alignment, _: Alignment) Position.Resolved {
        var x = @as(i32, undefined);
        var y = @as(i32, undefined);
        var width = @as(u32, undefined);
        var height = @as(i32, undefined);

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

        return Position.Resolved{
            .x = x,
            .y = y
        };
    }

    // The resolved position.
    pub const Resolved = struct {
        x: i32,
        y: i32
    };
};

// The coordinate.
pub const Coordinate = union {
    Relative: i32,
    Absolute: i32,

    // Create a relative position.
    pub fn relative(value: i32) Coordinate {
        return Coordinate{ .Relative = value };
    }

    // Create a absolute position.
    pub fn absolute(value: i32) Coordinate {
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
    pub fn resolve(self: Size, parent_width: u32, parent_height: u32) Size.Result {
        return Size.Result{
            .width = switch (self.width) {
                .Fixed => |value| value,
                .Relative => |value| @as(u32, @intFromFloat(@as(f32, @floatFromInt(parent_width)) * value)),
                .Unknown => null
            },

            .height = switch (self.height) {
                .Fixed => |value| value,
                .Relative => |value| @as(u32, @intFromFloat(@as(f32, @floatFromInt(parent_height)) * value)),
                .Unknown => null
            },
        };
    }

    // The result size.
    pub const Result = struct {
        width: ?u32,
        height: ?u32,
    };

    // The resolved size.
    pub const Resolved = struct {
        width: u32,
        height: u32
    };
};

// The measurement.
pub const Measurement = union {
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
    x: i32,
    y: i32,
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
