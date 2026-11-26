const std = @import("std");
const metrics = @import("metrics.h");
const cache = @import("cache.zig");
const prefetch = @import("prefetch.zig");

const t = @import("tester.zig").Tester;

const FillPattern = enum {
    NeverTaken,
    AlwaysTaken,
    Every2,
    Every3,
    Every4,
    Random,
};

const asm_ns = struct {
    // pub extern fn MOVAllBytes(len: u64, ptr: [*]u8) void;
    // pub extern fn CMPAllBytes(len: u64, ptr: [*]u8) void;
    // pub extern fn DECAllBytes(len: u64, ptr: [*]u8) void;

    // pub extern fn NOP3x1AllBytes(len: u64, ptr: [*]u8) void;
    // pub extern fn NOP1x3AllBytes(len: u64, ptr: [*]u8) void;
    // pub extern fn NOP1x9AllBytes(len: u64, ptr: [*]u8) void;

    // pub extern fn NOPAligned64(len: u64, ptr: [*]u8) void;
    // pub extern fn NOPAligned1(len: u64, ptr: [*]u8) void;
    // pub extern fn NOPAligned15(len: u64, ptr: [*]u8) void;
    // pub extern fn NOPAligned31(len: u64, ptr: [*]u8) void;
    // pub extern fn NOPAligned63(len: u64, ptr: [*]u8) void;

    // pub extern fn RATAdd(len: u64, ptr: [*]u8) void;
    // pub extern fn RATMovAdd(len: u64, ptr: [*]u8) void;

    // pub extern fn Read_x1(len: u64, ptr: [*]u8) void;
    // pub extern fn Read_x2(len: u64, ptr: [*]u8) void;
    // pub extern fn Read_x3(len: u64, ptr: [*]u8) void;
    // pub extern fn Read_x4(len: u64, ptr: [*]u8) void;

    // pub extern fn Write_x1(len: u64, ptr: [*]u8) void;
    // pub extern fn Write_x2(len: u64, ptr: [*]u8) void;
    // pub extern fn Write_x3(len: u64, ptr: [*]u8) void;
    // pub extern fn Write_x4(len: u64, ptr: [*]u8) void;

    // pub extern fn Read_4x2(len: u64, ptr: [*]u8) void;
    // pub extern fn Read_8x2(len: u64, ptr: [*]u8) void;
    // pub extern fn Read_16x2(len: u64, ptr: [*]u8) void;
    // pub extern fn Read_32x2(len: u64, ptr: [*]u8) void;

    // pub extern fn Write_4x2(len: u64, ptr: [*]u8) void;
    // pub extern fn Write_8x2(len: u64, ptr: [*]u8) void;
    // pub extern fn Write_16x2(len: u64, ptr: [*]u8) void;
    // pub extern fn Write_32x2(len: u64, ptr: [*]u8) void;

    // pub extern fn WriteEvery256Read(len: u64, ptr: [*]u8) void;
    // pub extern fn WriteEvery256ReadNT(len: u64, ptr: [*]u8) void;

};

extern fn MOVAllBytes(len: u64, ptr: [*]u8) void;
extern fn ConditionalNOP(len: u64, ptr: [*]u8) void;

const AsmFn = *const fn (u64, [*]u8) callconv(.c) void;

const SIZE = 1024 * 1024 * 1024;

pub fn testAsm(writer: *std.Io.Writer) !void {
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

    MOVAllBytes(buffer.len, buffer.ptr);

    inline for (comptime std.meta.declarations(asm_ns)) |decl| {
        try runASM(&tester, buffer, writer, decl, @field(asm_ns, decl));
    }

    // try testBranchPrediction(&tester, buffer, writer);
    // try cache.testCacheSizes(&tester, buffer, writer);
    // try cache.testCacheSizesNonPowerOf2(&tester, buffer, writer);
    // try cache.testCacheLineAlignment(&tester, buffer, writer);
    // try cache.testCacheIndexing(&tester, buffer, writer);
    try prefetch.testPrefetching(&tester, buffer, writer);
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

    tester.reset();

    while (try tester.isTesting()) {
        tester.begin();
        asm_fn(buffer.len, buffer.ptr);
        tester.end();
        tester.addBytes(buffer.len);
    }
}

fn testBranchPrediction(tester: *t, buffer: []u8, writer: *std.Io.Writer) !void {
    inline for (std.meta.tags(FillPattern)) |fill_pattern| {
        var prng = std.Random.DefaultPrng.init(12345);

        try writer.print("Filling buffer with {s} pattern\r", .{@tagName(fill_pattern)});
        try writer.flush();

        for (0..buffer.len) |i| {
            const value: u8 = switch (fill_pattern) {
                .NeverTaken => 0,
                .AlwaysTaken => 1,
                .Every2 => if (i % 2 == 0) 1 else 0,
                .Every3 => if (i % 3 == 0) 1 else 0,
                .Every4 => if (i % 4 == 0) 1 else 0,
                .Random => prng.random().int(u8),
            };

            buffer[i] = value;
        }

        try writer.print("ConditionalNOP ({s}):", .{@tagName(fill_pattern)});
        try writer.writeAll("\x1b[K\n");
        try writer.flush();

        tester.reset();

        while (try tester.isTesting()) {
            tester.begin();
            ConditionalNOP(buffer.len, buffer.ptr);
            tester.end();
            tester.addBytes(buffer.len);
        }
    }
}
