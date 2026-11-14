const std = @import("std");
const Io = std.Io;

const c = @import("c");

const json = @import("json.zig");

const EARTH_RADIUS = 6372.8;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

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

    const haversine: f64 = c.ReferenceHaversine(-74.0060, 40.7128, -118.2437, 34.0522, EARTH_RADIUS);

    try stdout_writer.print("Haversine: {d:.16}\n", .{haversine});

    // const path = args[1];
    // const answers_path = if (args.len == 3) args[2] else null;

    try stdout_writer.flush();
}
