const std = @import("std");
const metrics = @import("metrics.h");

const t = @import("tester.zig").Tester;

extern fn MOVAllBytesASM(count: u64, data: [*]u8) void;
extern fn NOPAllBytesASM(count: u64) void;
extern fn CMPAllBytesASM(count: u64) void;
extern fn DECAllBytesASM(count: u64) void;

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

    try writeToAllBytes(&tester, buffer, writer);
    try movAllBytes(&tester, buffer, writer);
    try nopAllBytes(&tester, buffer, writer);
    try cmpAllBytes(&tester, buffer, writer);
    try decAllBytes(&tester, buffer, writer);
}

fn writeToAllBytes(tester: *t, buffer: []u8, writer: *std.Io.Writer) !void {
    try writer.print("{s}:\n", .{@src().fn_name});
    try writer.flush();

    while (try tester.isTesting()) {
        tester.begin();
        for (0..buffer.len) |i| {
            buffer[i] = @truncate(i);
        }
        tester.end();
        tester.addBytes(buffer.len);
    }

    tester.reset();
}

fn movAllBytes(tester: *t, buffer: []u8, writer: *std.Io.Writer) !void {
    try writer.print("{s}:\n", .{@src().fn_name});
    try writer.flush();

    while (try tester.isTesting()) {
        tester.begin();
        MOVAllBytesASM(buffer.len, buffer.ptr);
        tester.end();
        tester.addBytes(buffer.len);
    }

    tester.reset();
}

fn nopAllBytes(tester: *t, buffer: []u8, writer: *std.Io.Writer) !void {
    try writer.print("{s}:\n", .{@src().fn_name});
    try writer.flush();

    while (try tester.isTesting()) {
        tester.begin();
        NOPAllBytesASM(buffer.len);
        tester.end();
        tester.addBytes(buffer.len);
    }

    tester.reset();
}

fn cmpAllBytes(tester: *t, buffer: []u8, writer: *std.Io.Writer) !void {
    try writer.print("{s}:\n", .{@src().fn_name});
    try writer.flush();

    while (try tester.isTesting()) {
        tester.begin();
        CMPAllBytesASM(buffer.len);
        tester.end();
        tester.addBytes(buffer.len);
    }

    tester.reset();
}

fn decAllBytes(tester: *t, buffer: []u8, writer: *std.Io.Writer) !void {
    try writer.print("{s}:\n", .{@src().fn_name});
    try writer.flush();

    while (try tester.isTesting()) {
        tester.begin();
        DECAllBytesASM(buffer.len);
        tester.end();
        tester.addBytes(buffer.len);
    }

    tester.reset();
}
