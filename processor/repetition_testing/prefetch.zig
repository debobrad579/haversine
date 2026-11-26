const std = @import("std");

const t = @import("tester.zig").Tester;

extern fn PeriodicRead(outer_count: u64, ptr: [*]u8, inner_count: u64) void;
extern fn PeriodicPrefetchedRead(outer_count: u64, ptr: [*]u8, inner_count: u64) void;

pub fn testPrefetching(tester: *t, buffer: []u8, writer: *std.Io.Writer) !void {
    const outer_loop_count = 1024 * 1024;
    const cache_line_size = 64;
    const cache_line_count = buffer.len / cache_line_size;

    var prng = std.Random.DefaultPrng.init(12345);
    var random = prng.random();

    @memset(buffer, 0);

    var jump_offset: usize = 0;

    for (0..outer_loop_count) |outer_loop_index| {
        var next_offset: usize = 0;
        var found = false;

        const random_value = random.int(usize);

        for (0..cache_line_count) |search_index| {
            next_offset = (random_value + search_index) % cache_line_count;

            const next_pointer = buffer.ptr + next_offset * cache_line_size;
            const next_value: *u64 = @ptrCast(@alignCast(next_pointer));

            if (next_value.* == 0) {
                found = true;
                break;
            }
        }

        if (!found) {
            return error.UnableToCreatePointerChain;
        }

        const jump_pointer = buffer.ptr + jump_offset * cache_line_size;

        const jump_data: *u64 = @ptrCast(@alignCast(jump_pointer));
        jump_data.* = @intFromPtr(buffer.ptr + next_offset * cache_line_size);

        const jump_index: *u64 = @ptrCast(@alignCast(jump_pointer + 8));
        jump_index.* = outer_loop_index;

        jump_offset = next_offset;
    }

    try writer.writeAll("PeriodicRead:\n");
    try writer.flush();

    tester.reset();

    while (try tester.isTesting()) {
        tester.begin();
        PeriodicRead(outer_loop_count, buffer.ptr, 512);
        tester.end();
        tester.addBytes(buffer.len);
    }

    try writer.writeAll("PeriodicPrefetchedRead:\n");
    try writer.flush();

    tester.reset();

    while (try tester.isTesting()) {
        tester.begin();
        PeriodicPrefetchedRead(outer_loop_count, buffer.ptr, 512);
        tester.end();
        tester.addBytes(buffer.len);
    }
}
