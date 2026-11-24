const std = @import("std");
const metrics = @import("metrics.h");

const t = @import("tester.zig").Tester;

extern fn MOVAllBytes(count: u64, data: [*]u8) void;

const asm_ns = struct {
    // pub extern fn CMPAllBytes(count: u64) void;
    // pub extern fn DECAllBytes(count: u64) void;
    pub extern fn NOP3x1AllBytes(count: u64) void;
    pub extern fn NOP1x3AllBytes(count: u64) void;
    pub extern fn NOP1x9AllBytes(count: u64) void;
};

const AsmFn = *const fn (u64) callconv(.c) void;

const SIZE = 1024 * 1024 * 1024;

pub fn testLoops(writer: *std.Io.Writer) !void {
    var tester = t.init(metrics.EstimateCPUFrequency(100), 1, SIZE, writer);

    const buffer = try std.posix.mmap(
        null,
        SIZE,
        .{ .READ = true, .WRITE = true },
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );
    defer std.posix.munmap(buffer);

    // try movAllBytes(&tester, buffer, writer);

    inline for (comptime std.meta.declarations(asm_ns)) |decl| {
        try runASM(&tester, buffer, writer, decl, @field(asm_ns, decl));
    }
}

fn movAllBytes(tester: *t, buffer: []u8, writer: *std.Io.Writer) !void {
    try writer.print("{s}:\n", .{"MOVAllBytes"});
    try writer.flush();

    while (try tester.isTesting()) {
        tester.begin();
        MOVAllBytes(buffer.len, buffer.ptr);
        tester.end();
        tester.addBytes(buffer.len);
    }

    tester.reset();
}

fn runASM(
    tester: *t,
    buffer: []u8,
    writer: *std.Io.Writer,
    name: []const u8,
    asm_fn: AsmFn,
) !void {
    try writer.print("{s}:\n", .{name});
    try writer.flush();

    while (try tester.isTesting()) {
        tester.begin();
        asm_fn(buffer.len);
        tester.end();
        tester.addBytes(buffer.len);
    }

    tester.reset();
}
