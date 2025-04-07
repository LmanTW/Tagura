const std = @import("std");
const sdl = @import("sdl");

const Container = @import("./engine/graphic/sprites/Container.zig");

const init_flags = sdl.init.Flags{
    .video = true,
    .events = true
};

const window_flags = sdl.video.WindowFlags{
    .resizable = true
};

// The main function :3
pub fn main() !void {
    var debug = std.heap.DebugAllocator(.{}).init;
    defer _ = debug.deinit();

    // Yes sir, the allocator.
    const allocator = debug.allocator();

    try sdl.init.init(init_flags);
    defer sdl.init.quit(init_flags);

    const window = try sdl.video.Window.init("Tagura", 1280, 720, window_flags);
    defer window.deinit();

    var container = Container.new(.relative(0), .relative(0), .fixed(256), .fixed(256), .{}).init(allocator);
    defer Container.deinit(&container);

    _ = try container.add(Container.new(.relative(0), .relative(0), .fixed(64), .fixed(64), .{}));
    _ = try container.add(Container.new(.relative(0), .relative(0), .fixed(64), .fixed(64), .{}));

    main: while (true) {
        const timestamp = sdl.timer.getMillisecondsSinceInit();

        while (sdl.events.poll()) |event| {
            switch (event) {
                .quit => break :main,
                .terminating => break :main,

                else => {}
            }
        }

        if (!window.getFlags().minimized) {
            
        }

        sdl.timer.delayMilliseconds(@as(u32, @intCast((1000 / 60) -| (sdl.timer.getMillisecondsSinceInit() - timestamp))));
    }
}

// https://coolors.co/0a4142-0e5b5c-127475-e8fbfb-dd245e
