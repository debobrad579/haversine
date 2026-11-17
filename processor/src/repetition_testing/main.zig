const std = @import("std");
const c = @import("c");

const tester = @import("tester.zig").Tester;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    var rep_tester = tester.init(c.EstimateCPUFrequency(100), 10, 959655557, stdout_writer);
    while (try rep_tester.isTesting()) {
        rep_tester.begin();
        const file = try std.Io.Dir.cwd().readFileAlloc(
            io,
            "../data/10_000_000.json",
            gpa,
            .limited(1024 * 1024 * 1024),
        );
        rep_tester.addBytes(file.len);
        rep_tester.end();
        gpa.free(file);
    }

    try stdout_writer.flush();
}
