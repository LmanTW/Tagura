pub const PositionQuery = struct {
    x: ?i32,
    y: ?i32
};

pub const SizeQuery = struct {
    width: ?u32,
    height: ?u32
};

pub const ResolvedPosition = struct {
    x: i32,
    y: i32,
};

pub const ResolvedSize = struct {
    width: u32,
    height: u32,
};

pub const Parent = struct {
    x: i32,
    y: i32,
    width: u32,
    height: u32
};
