const std = @import("std");
const Io = std.Io;

const c = @import("c");

const json = @import("json.zig");

const EARTH_RADIUS = 6372.8;

pub fn main(init: std.process.Init) !void {
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

    const json_data = try std.Io.Dir.cwd().readFileAlloc(
        io,
        path,
        gpa,
        .limited(1024 * 1024),
    );
    defer gpa.free(json_data);

    const data = try json.parse_json(json_data, arena);

    var sum: f64 = 0.0;
    var count: f64 = 0.0;

    for (data.Object.get("pairs").?.Array) |pair| {
        const x0 = pair.Object.get("x0").?.Float;
        const y0 = pair.Object.get("y0").?.Float;
        const x1 = pair.Object.get("x1").?.Float;
        const y1 = pair.Object.get("y1").?.Float;

        const haversine: f64 = c.ReferenceHaversine(x0, y0, x1, y1, EARTH_RADIUS);

        sum += haversine;
        count += 1;
    }

    const average = sum / count;

    try stdout_writer.print("Average: {d:.16}\n", .{average});

    // const answers_path = if (args.len == 3) args[2] else null;

    try stdout_writer.flush();
}
