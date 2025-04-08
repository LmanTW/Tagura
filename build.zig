const std = @import("std");

const release_targets = @as([]const std.Target.Query, &.{
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .gnu },

    .{ .cpu_arch = .x86_64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .macos },

    .{ .cpu_arch = .x86_64, .os_tag = .windows },
    .{ .cpu_arch = .aarch64, .os_tag = .windows }
});

// Build the project.
pub fn build(b: *std.Build) !void {
    b.sysroot = b.path("./system/macos/sdk").getPath(b);

    const test_exe = b.addExecutable(.{
        .name = "tagura",
        .root_source_file = b.path("./src/main.zig"),
        
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{})
    });

    addDependencies(b, test_exe.root_module);

    const run_exe = b.addRunArtifact(test_exe);
    const run_step = b.step("run", "Run the project");
    run_step.dependOn(&run_exe.step);

    for (release_targets) |release_target| {
        const release_exe = b.addExecutable(.{
            .name = "tagura",
            .root_source_file = b.path("./src/main.zig"),

            .target = b.resolveTargetQuery(release_target),
            .optimize = .ReleaseSafe,

            .strip = true
        });

        addDependencies(b, release_exe.root_module);

        const os_name = @tagName(release_target.os_tag.?);
        const arch_name = switch (release_target.cpu_arch.?) {
            .x86_64 => "amd64",
            .aarch64 => "arm64",

            else => @panic("Unsupported CPU Architecture")
        };

        const release_output = b.addInstallArtifact(release_exe, .{
            .dest_dir = .{
                .override = .{
                    .custom = ""
                }
            },

            .dest_sub_path = switch (release_target.os_tag.?) {
                .linux, .macos => try std.fmt.allocPrint(b.allocator, "tagura-{s}-{s}", .{os_name, arch_name}),
                .windows => try std.fmt.allocPrint(b.allocator, "tagura-{s}-{s}.exe", .{os_name, arch_name}),

                else => @panic("Unsupported OS")
            }
        });

        b.getInstallStep().dependOn(&release_output.step);
    }
}

// Add the dependencies.
pub fn addDependencies(b: *std.Build, module: *std.Build.Module) void {
    const target = module.resolved_target.?;
    const optimize = module.optimize.?; 

    const sdl3 = b.dependency("sdl3", .{
        .target = target,
        .optimize = optimize
    });

    module.addImport("sdl", sdl3.module("sdl3"));

    switch (target.result.os.tag) {
        .macos => {
            module.addSystemIncludePath(b.path("./system/macos/sdk/usr/include"));
            module.addSystemFrameworkPath(b.path("./system/macos/sdk/System/Library/Frameworks"));
        },

        else => {}
    }
}
