const std = @import("std");
const c = @import("c");

const tester = @import("tester.zig").Tester;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    const path = "../data/10_000_000.json";
    const dir = std.Io.Dir.cwd();
    const stat = try dir.statFile(io, path, .{});

    var rep_tester = tester.init(c.EstimateCPUFrequency(100), 10, stat.size, stdout_writer);
    try stdout_writer.print("readFileAlloc:\n", .{});
    try stdout_writer.flush();
    while (try rep_tester.isTesting()) {
        rep_tester.begin();
        const file = try dir.readFileAlloc(
            io,
            path,
            gpa,
            .limited(1024 * 1024 * 1024),
        );
        rep_tester.end();
        rep_tester.addBytes(file.len);
        gpa.free(file);
    }

    rep_tester.reset(stat.size);
    try stdout_writer.print("readSliceShort (alloc inside loop):\n", .{});
    try stdout_writer.flush();
    while (try rep_tester.isTesting()) {
        const file = try std.Io.Dir.cwd().openFile(
            io,
            path,
            .{},
        );
        defer file.close(io);
        const buffer = try gpa.alloc(u8, 1024 * 1024 * 1024);
        defer gpa.free(buffer);
        var reader = file.reader(io, buffer);
        while (true) {
            rep_tester.begin();
            const bytes_read = try reader.interface.readSliceShort(buffer);
            rep_tester.end();
            rep_tester.addBytes(bytes_read);
            if (bytes_read == 0) break;
        }
    }

    rep_tester.reset(stat.size);
    try stdout_writer.print("readSliceShort (alloc outside loop):\n", .{});
    try stdout_writer.flush();
    const file = try std.Io.Dir.cwd().openFile(
        io,
        path,
        .{},
    );
    defer file.close(io);
    const buffer = try gpa.alloc(u8, 1024 * 1024 * 1024);
    defer gpa.free(buffer);
    while (try rep_tester.isTesting()) {
        var reader = file.reader(io, buffer);
        while (true) {
            rep_tester.begin();
            const bytes_read = try reader.interface.readSliceShort(buffer);
            rep_tester.end();
            rep_tester.addBytes(bytes_read);
            if (bytes_read == 0) break;
        }
    }
}
