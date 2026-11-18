const std = @import("std");
const c = @import("c");

const t = @import("tester.zig").Tester;

const SIZE = 1024 * 1024 * 1024;

pub fn mmapWriteForward(writer: *std.Io.Writer) !void {
    var tester = t.init(c.EstimateCPUFrequency(100), 1, SIZE, writer);

    try writer.writeAll("mmapWriteForward:\n");
    try writer.flush();

    while (try tester.isTesting()) {
        const memory = try std.posix.mmap(
            null,
            SIZE,
            .{ .READ = true, .WRITE = true },
            .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
            -1,
            0,
        );
        defer std.posix.munmap(memory);

        tester.begin();
        for (memory) |*byte| {
            byte.* = ' ';
        }
        tester.end();
        tester.addBytes(SIZE);
    }
}

pub fn mmapWriteBackward(writer: *std.Io.Writer) !void {
    var tester = t.init(c.EstimateCPUFrequency(100), 1, SIZE, writer);

    try writer.writeAll("mmapWriteBackward:\n");
    try writer.flush();

    while (try tester.isTesting()) {
        const memory = try std.posix.mmap(
            null,
            SIZE,
            .{ .READ = true, .WRITE = true },
            .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
            -1,
            0,
        );
        defer std.posix.munmap(memory);

        var bytes_left: usize = SIZE;
        tester.begin();
        while (bytes_left > 0) : (bytes_left -= 1) {
            memory[bytes_left - 1] = ' ';
        }
        tester.end();
        tester.addBytes(SIZE);
    }
}

pub fn mmapWriteConverge(writer: *std.Io.Writer) !void {
    var tester = t.init(c.EstimateCPUFrequency(100), 1, SIZE, writer);

    try writer.writeAll("mmapWriteConverge:\n");
    try writer.flush();

    while (try tester.isTesting()) {
        const memory = try std.posix.mmap(
            null,
            SIZE,
            .{ .READ = true, .WRITE = true },
            .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
            -1,
            0,
        );
        defer std.posix.munmap(memory);

        var left: usize = 0;
        var right: usize = SIZE;

        tester.begin();
        while (left < right) {
            left += 1;
            memory[left - 1] = ' ';

            if (left < right) {
                right -= 1;
                memory[right] = ' ';
            }
        }
        tester.end();
        tester.addBytes(SIZE);
    }
}
