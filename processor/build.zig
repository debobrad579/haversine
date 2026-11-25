const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "haversine_prcessor",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "haversine.h", .module = b.addTranslateC(.{
                    .root_source_file = b.path("c/haversine.h"),
                    .target = target,
                    .optimize = optimize,
                }).createModule() },
                .{ .name = "metrics.h", .module = b.addTranslateC(.{
                    .root_source_file = b.path("c/metrics.h"),
                    .target = target,
                    .optimize = optimize,
                }).createModule() },
            },
        }),
    });

    const profile = b.option(bool, "profile", "Enable the profiler") orelse false;

    const options = b.addOptions();
    options.addOption(bool, "profile", profile);
    exe.root_module.addOptions("build_options", options);

    exe.root_module.addCSourceFile(.{
        .file = b.path("c/haversine.c"),
        .flags = &.{},
    });
    exe.root_module.addCSourceFile(.{
        .file = b.path("c/metrics.c"),
        .flags = &.{},
    });
    exe.root_module.link_libc = true;

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.addPassthruArgs();

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);

    const rt_exe = b.addExecutable(.{
        .name = "repetition_tester",
        .root_module = b.createModule(.{
            .root_source_file = b.path("repetition_testing/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "metrics.h", .module = b.addTranslateC(.{
                    .root_source_file = b.path("c/metrics.h"),
                    .target = target,
                    .optimize = optimize,
                }).createModule() },
            },
        }),
    });

    const asm_files = [_][]const u8{
        "loops.asm",
        "multi_nops.asm",
        "conditional_nop.asm",
        "alignment.asm",
        "rat.asm",
        "read_unroll.asm",
        "write_unroll.asm",
        "read_width.asm",
        "write_width.asm",
        "cache_sizes.asm",
        "cache_alignment.asm",
    };

    for (asm_files) |file_name| {
        const file = b.fmt("asm/{s}", .{file_name});
        const output_name = b.fmt("{s}.o", .{
            std.fs.path.stem(file),
        });

        const nasm = b.addSystemCommand(&.{
            "nasm",
            "-f",
            "elf64",
            "-o",
        });

        const obj = nasm.addOutputFileArg(output_name);
        nasm.addFileArg(b.path(file));
        rt_exe.root_module.addObjectFile(obj);
    }

    rt_exe.root_module.addCSourceFile(.{
        .file = b.path("c/metrics.c"),
        .flags = &.{},
    });
    rt_exe.root_module.link_libc = true;

    const rt_run_step = b.step("rt", "Run repetition tester");
    const rt_cmd = b.addRunArtifact(rt_exe);
    rt_run_step.dependOn(&rt_cmd.step);
    rt_cmd.addPassthruArgs();
}
