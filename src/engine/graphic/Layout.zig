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
