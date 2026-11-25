const std = @import("std");

const t = @import("tester.zig").Tester;

extern fn MOVAllBytes(len: u64, ptr: [*]u8) void;
extern fn ConditionalNOP(len: u64, ptr: [*]u8) void;
extern fn TestCacheSizesPowerOf2(len: u64, ptr: [*]u8, mask: u64) void;
extern fn TestCacheSizes(len: u64, ptr: [*]u8, amount: u64) void;

const CSVRow = struct {
    kb: u64,
    throughput: f64,
};

pub fn testCacheSizesPowerOf2(tester: *t, buffer: []u8, writer: *std.Io.Writer) !void {
    MOVAllBytes(buffer.len, buffer.ptr);

    var csv: [21]CSVRow = undefined;

    for (10..31) |power| {
        const bytes = (@as(u64, 1) << @as(u6, @intCast(power)));

        if (bytes >= 1024 * 1024 * 1024) {
            try writer.print("TestCacheSizes ({d}GiB):\n", .{bytes / 1024 / 1024 / 1024});
        } else if (bytes >= 1024 * 1024) {
            try writer.print("TestCacheSizes ({d}MiB):\n", .{bytes / 1024 / 1024});
        } else {
            try writer.print("TestCacheSizes ({d}KiB):\n", .{bytes / 1024});
        }
        try writer.flush();

        tester.reset();

        while (try tester.isTesting()) {
            tester.begin();
            TestCacheSizesPowerOf2(buffer.len, buffer.ptr, bytes - 1);
            tester.end();
            tester.addBytes(buffer.len);
        }

        const seconds = @as(f64, @floatFromInt(tester.stats.min.ticks)) / @as(f64, @floatFromInt(tester.cpu_freq));

        csv[power - 10] = CSVRow{ .kb = bytes / 1024, .throughput = @as(f64, @floatFromInt(tester.expected_bytes)) / seconds / (1024.0 * 1024.0 * 1024.0) };
    }

    try writer.writeAll("bytes\tthroughput\n");
    for (csv) |row| {
        try writer.print("{d}\t{d}\n", .{ row.kb, row.throughput });
    }
    try writer.flush();
}

pub fn testCacheSizes(tester: *t, buffer: []u8, writer: *std.Io.Writer) !void {
    MOVAllBytes(buffer.len, buffer.ptr);

    var csv: [128]CSVRow = undefined;

    var bytes: u64 = 16 * 1024;
    var delta: u64 = 2 * 1024;
    var i: usize = 0;
    while (bytes <= buffer.len) : (bytes += delta) {
        const chunk_size: u64 = 256;

        const processed = @min(
            buffer.len,
            ((buffer.len + bytes - 1) / bytes) * (bytes / chunk_size) * chunk_size,
        );

        try writer.print("TestCacheSizes ({d}KiB):\n", .{bytes / 1024});
        try writer.flush();

        var new_tester = t.init(tester.cpu_freq, 1, processed, writer);

        while (try new_tester.isTesting()) {
            new_tester.begin();
            TestCacheSizes(buffer.len, buffer.ptr, bytes);
            new_tester.end();
            new_tester.addBytes(processed);
        }

        const seconds = @as(f64, @floatFromInt(new_tester.stats.min.ticks)) / @as(f64, @floatFromInt(new_tester.cpu_freq));

        csv[i] = CSVRow{ .kb = bytes / 1024, .throughput = @as(f64, @floatFromInt(new_tester.expected_bytes)) / seconds / (1024.0 * 1024.0 * 1024.0) };

        if ((bytes - 1) & bytes == 0) {
            delta *= 2;
        }

        i += 1;
    }

    try writer.writeAll("bytes\tthroughput\n");
    for (csv, 0..) |row, csv_i| {
        if (csv_i < i) {
            try writer.print("{d}\t{d}\n", .{ row.kb, row.throughput });
        }
    }
    try writer.flush();
}
