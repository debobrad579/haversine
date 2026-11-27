const std = @import("std");

const profiler = @import("profiler.zig");

pub fn readFile(io: std.Io, path: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const dir = std.Io.Dir.cwd();
    const stat = try dir.statFile(io, path, .{});

    var timer = profiler.startTimerBandwidth(@src(), null, stat.size);
    defer timer.stop();

    const file = try std.Io.Dir.cwd().openFile(
        io,
        path,
        .{},
    );
    defer file.close(io);

    const buffer = try allocator.alloc(u8, stat.size);

    var reader = file.reader(io, buffer);

    while (true) {
        if (try reader.interface.readSliceShort(buffer) == 0) break;
    }

    return buffer;
}
