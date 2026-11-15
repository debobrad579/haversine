const std = @import("std");
const Io = std.Io;

const c = @import("c");

const json = @import("json.zig");

const EARTH_RADIUS = 6372.8;

pub fn main(init: std.process.Init) !void {
    const rdtsc_start = c.GetRDTSC();

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

    const rdtsc_read = c.GetRDTSC();

    const json_data = try std.Io.Dir.cwd().readFileAlloc(
        io,
        path,
        gpa,
        .limited(1024 * 1024 * 1024),
    );

    const rdtsc_parse = c.GetRDTSC();

    const data = try json.parse_json(json_data, arena);

    const rdtsc_misc_setup = c.GetRDTSC();

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

    const rdtsc_sum = c.GetRDTSC();

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

    const rdtsc_misc_output = c.GetRDTSC();

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

    const rdtsc_end = c.GetRDTSC();

    const cpu_freq = c.EstimateCPUFrequency(100);

    const rdtsc_difference = rdtsc_end - rdtsc_start;
    const startup_time = rdtsc_read - rdtsc_start;
    const read_time = rdtsc_parse - rdtsc_read;
    const parse_time = rdtsc_misc_setup - rdtsc_parse;
    const misc_setup_time = rdtsc_sum - rdtsc_misc_setup;
    const sum_time = rdtsc_misc_output - rdtsc_sum;
    const misc_output_time = rdtsc_end - rdtsc_misc_output;

    try stdout_writer.print(
        \\
        \\Total time: {d:.4}ms (CPU freq {d})
        \\  Startup: {d} ({d:.2}%)
        \\  Read: {d} ({d:.2}%)
        \\  Parse: {d} ({d:.2}%)
        \\  MiscSetup: {d} ({d:.2}%)
        \\  Sum: {d} ({d:.2}%)
        \\  MiscOutput: {d} ({d:.2}%)
        \\
    , .{
        @as(f64, @floatFromInt(rdtsc_difference)) / (@as(f64, @floatFromInt(cpu_freq)) / 1000),
        cpu_freq,
        startup_time,
        get_percentage(startup_time, rdtsc_difference),
        read_time,
        get_percentage(read_time, rdtsc_difference),
        parse_time,
        get_percentage(parse_time, rdtsc_difference),
        misc_setup_time,
        get_percentage(misc_setup_time, rdtsc_difference),
        sum_time,
        get_percentage(sum_time, rdtsc_difference),
        misc_output_time,
        get_percentage(misc_output_time, rdtsc_difference),
    });

    try stdout_writer.flush();
}

fn get_percentage(part: u64, total: u64) f64 {
    return @as(f64, @floatFromInt(part)) / @as(f64, @floatFromInt(total)) * 100;
}
