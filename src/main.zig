const sdl = @import("sdl");

const init_flags = sdl.init.Flags{
    .video = true,
    .events = true
};

const window_flags = sdl.video.WindowFlags{
    .resizable = true
};

// The main function :3
pub fn main() !void {
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
