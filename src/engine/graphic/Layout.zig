// The position.
pub const Position = union {
    Relative: i32,
    Absolute: i32,

    // Create a relative position.
    pub fn relative(value: i32) Position {
        return Position{ .Relative = value };
    }

    // Create a absolute position.
    pub fn absolute(value: i32) Position {
        return Position{ .Absolute = value };
    }
};

// The size.
pub const Size = union {
    Fixed: u32,
    Relative: f32,
    Unknown: void,

    // Create a fixed size.
    pub fn fixed(value: u32) Size {
        return Size{ .Fixed = value };
    }

    // Create a relative size.
    pub fn relative(value: f32) Size {
        return Size{ .Relative = value };
    }

    // Create a unknown size.
    pub fn unknown() Size {
        return Size{ .Unknown = undefined };
    }
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
