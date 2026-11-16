const std = @import("std");
const Io = std.Io;

const c = @import("c");

const json = @import("json.zig");
const profiler = @import("profiler.zig");

const EARTH_RADIUS = 6372.8;

pub fn main(init: std.process.Init) !void {
    profiler.init();

    const io = init.io;
    const gpa = init.gpa;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    const arena: std.mem.Allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);

    if (args.len == 1 or args.len > 3) {
        try stdout_writer.print("Usage: haversine-processor <path/to/json> [<path/to/answers>]\n", .{});
        try stdout_writer.flush();
        return;
    }

    const path = args[1];
    const answers_path = if (args.len == 3) args[2] else null;

    var read_timer = profiler.startNamedTimer(@src(), "Read");

    const json_data = try std.Io.Dir.cwd().readFileAlloc(
        io,
        path,
        gpa,
        .limited(1024 * 1024 * 1024),
    );

    read_timer.stop();

    var data = try json.parseJSON(json_data, arena);
    data = try json.parseJSON(json_data, arena);

    gpa.free(json_data);

    const answers_data = if (answers_path) |answers|
        try std.Io.Dir.cwd().readFileAlloc(
            io,
            answers,
            gpa,
            .limited(1024 * 1024 * 1024),
        )
    else
        null;

    var sum_timer = profiler.startNamedTimer(@src(), "Sum");

    var sum: f64 = 0.0;
    var count: f64 = 0.0;

    for (data.Object.get("pairs").?.Array, 0..) |pair, i| {
        const x0 = pair.Object.get("x0").?.Float;
        const y0 = pair.Object.get("y0").?.Float;
        const x1 = pair.Object.get("x1").?.Float;
        const y1 = pair.Object.get("y1").?.Float;

        const haversine: f64 = c.ReferenceHaversine(x0, y0, x1, y1, EARTH_RADIUS);

        if (answers_data) |answers| {
            const offset = i * 8;

            const answer = @as(f64, @bitCast(std.mem.readInt(u64, answers[offset..][0..8], .little)));
            const difference = @abs(answer - haversine);

            if (difference > 1e-6) {
                try stdout_writer.print(
                    "Difference ({d}): {d:.16}\n  Haversine: {:.16}\n  Reference: {:.16}\n",
                    .{
                        i,
                        difference,
                        haversine,
                        answer,
                    },
                );
            }
        }

        sum += haversine;
        count += 1;
    }

    sum_timer.stop();

    const average = sum / count;

    if (answers_data) |answers| {
        const reference_average = @as(f64, @bitCast(std.mem.readInt(u64, answers[answers.len - 8 ..][0..8], .little)));
        const difference = @abs(reference_average - average);
        try stdout_writer.print(
            "Difference:  {d:.16}\n  Average:   {:.16}\n  Reference: {:.16}\n",
            .{
                difference,
                average,
                reference_average,
            },
        );
        gpa.free(answers);
    } else {
        try stdout_writer.print("Average: {d:.16}\n", .{average});
    }

    try profiler.print(stdout_writer);

    try stdout_writer.flush();
}
