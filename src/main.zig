const std = @import("std");
const sdl = @import("sdl");
const gl = @import("gl");

const GenericContainer = @import("./engine/graphic/sprites/GenericContainer.zig");
// const StaticContainer = @import("./engine/graphic/sprites/StaticContainer.zig");

const init_flags = sdl.init.Flags{
    .video = true,
    .events = true
};

const window_flags = sdl.video.WindowFlags{
    .resizable = true
};

// The main function :3
pub fn main() !void {
    defer sdl.init.shutdown();

    var debug = std.heap.DebugAllocator(.{}).init;
    defer _ = debug.deinit();

    // Yes sir, your allocator.
    const allocator = debug.allocator();

    var container = GenericContainer.new(0, 0, 1280, 720).init(allocator);
    defer GenericContainer.deinit(&container);
    
    try sdl.init.init(init_flags);
    defer sdl.init.quit(init_flags);

    const window = try sdl.video.Window.init("Tagura", 1280, 720, window_flags);
    defer window.deinit();

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
