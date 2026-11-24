const std = @import("std");
const metrics = @import("metrics.h");

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
    // pub extern fn MOVAllBytes(count: u64, data: [*]u8) void;
    // pub extern fn CMPAllBytes(count: u64, data: [*]u8) void;
    // pub extern fn DECAllBytes(count: u64, data: [*]u8) void;

    // pub extern fn NOP3x1AllBytes(count: u64, data: [*]u8) void;
    // pub extern fn NOP1x3AllBytes(count: u64, data: [*]u8) void;
    // pub extern fn NOP1x9AllBytes(count: u64, data: [*]u8) void;

    // pub extern fn NOPAligned64(count: u64, data: [*]u8) void;
    // pub extern fn NOPAligned1(count: u64, data: [*]u8) void;
    // pub extern fn NOPAligned15(count: u64, data: [*]u8) void;
    // pub extern fn NOPAligned31(count: u64, data: [*]u8) void;
    // pub extern fn NOPAligned63(count: u64, data: [*]u8) void;

    // pub extern fn RATAdd(count: u64, data: [*]u8) void;
    // pub extern fn RATMovAdd(count: u64, data: [*]u8) void;

    // pub extern fn Read_x1(count: u64, data: [*]u8) void;
    // pub extern fn Read_x2(count: u64, data: [*]u8) void;
    // pub extern fn Read_x3(count: u64, data: [*]u8) void;
    // pub extern fn Read_x4(count: u64, data: [*]u8) void;

    // pub extern fn Write_x1(count: u64, data: [*]u8) void;
    // pub extern fn Write_x2(count: u64, data: [*]u8) void;
    // pub extern fn Write_x3(count: u64, data: [*]u8) void;
    // pub extern fn Write_x4(count: u64, data: [*]u8) void;

    // pub extern fn Read_4x2(count: u64, data: [*]u8) void;
    // pub extern fn Read_8x2(count: u64, data: [*]u8) void;
    // pub extern fn Read_16x2(count: u64, data: [*]u8) void;
    // pub extern fn Read_32x2(count: u64, data: [*]u8) void;

    // pub extern fn Write_4x2(count: u64, data: [*]u8) void;
    // pub extern fn Write_8x2(count: u64, data: [*]u8) void;
    // pub extern fn Write_16x2(count: u64, data: [*]u8) void;
    // pub extern fn Write_32x2(count: u64, data: [*]u8) void;
};

extern fn ConditionalNOP(count: u64, data: [*]u8) void;
extern fn TestCacheSizes(count: u64, data: [*]u8, amount: u64) void;

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

    inline for (comptime std.meta.declarations(asm_ns)) |decl| {
        try runASM(&tester, buffer, writer, decl, @field(asm_ns, decl));
    }

    // try testBranchPrediction(&tester, buffer, writer);
    try testCacheSizes(&tester, buffer, writer);
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

fn testCacheSizes(tester: *t, buffer: []u8, writer: *std.Io.Writer) !void {
    inline for ([_]u64{
        16,
        32,
        48,
        64,
        128,
        192,
        256,
        512,
        1024,
        2 * 1024,
        4 * 1024,
        8 * 1024,
        16 * 1024,
        32 * 1024,
    }) |amount| {
        if (amount >= 1024) {
            try writer.print("TestCacheSizes ({d}MiB):\n", .{amount / 1024});
        } else {
            try writer.print("TestCacheSizes ({d}kiB):\n", .{amount});
        }
        try writer.flush();

        tester.reset();

        while (try tester.isTesting()) {
            tester.begin();
            TestCacheSizes(buffer.len, buffer.ptr, amount * 1024 - 1);
            tester.end();
            tester.addBytes(buffer.len);
        }
    }
}
