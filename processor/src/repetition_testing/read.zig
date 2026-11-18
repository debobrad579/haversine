const std = @import("std");
const c = @import("c");

const t = @import("tester.zig").Tester;

const PATH = "../data/10_000_000.json";

pub fn readFileAlloc(io: std.Io, allocator: std.mem.Allocator, writer: *std.Io.Writer) !void {
    const dir = std.Io.Dir.cwd();
    const stat = try dir.statFile(io, PATH, .{});

    var tester = t.init(c.EstimateCPUFrequency(100), 1, stat.size, writer);

    try writer.writeAll("readFileAlloc:\n");
    try writer.flush();

    while (try tester.isTesting()) {
        tester.begin();
        const file = try dir.readFileAlloc(
            io,
            PATH,
            allocator,
            .limited(1024 * 1024 * 1024),
        );
        tester.end();
        tester.addBytes(file.len);
        allocator.free(file);
    }
}

pub fn readSliceShortAlloc(io: std.Io, allocator: std.mem.Allocator, writer: *std.Io.Writer) !void {
    const dir = std.Io.Dir.cwd();
    const stat = try dir.statFile(io, PATH, .{});

    var tester = t.init(c.EstimateCPUFrequency(100), 1, stat.size, writer);

    try writer.writeAll("readSliceShort (alloc inside loop):\n");
    try writer.flush();

    while (try tester.isTesting()) {
        const file = try std.Io.Dir.cwd().openFile(
            io,
            PATH,
            .{},
        );
        defer file.close(io);

        const buffer = try allocator.alloc(u8, 1024 * 1024 * 1024);
        defer allocator.free(buffer);

        var reader = file.reader(io, buffer);

        while (true) {
            tester.begin();
            const bytes_read = try reader.interface.readSliceShort(buffer);
            tester.end();
            tester.addBytes(bytes_read);
            if (bytes_read == 0) break;
        }
    }
}

pub fn readSliceShort(io: std.Io, allocator: std.mem.Allocator, writer: *std.Io.Writer) !void {
    const dir = std.Io.Dir.cwd();
    const stat = try dir.statFile(io, PATH, .{});

    var tester = t.init(c.EstimateCPUFrequency(100), 1, stat.size, writer);

    try writer.writeAll("readSliceShort (alloc outside loop):\n");
    try writer.flush();

    const file = try std.Io.Dir.cwd().openFile(
        io,
        PATH,
        .{},
    );
    defer file.close(io);

    const buffer = try allocator.alloc(u8, 1024 * 1024 * 1024);
    defer allocator.free(buffer);

    while (try tester.isTesting()) {
        var reader = file.reader(io, buffer);

        while (true) {
            tester.begin();
            const bytes_read = try reader.interface.readSliceShort(buffer);
            tester.end();
            tester.addBytes(bytes_read);
            if (bytes_read == 0) break;
        }
    }
}
