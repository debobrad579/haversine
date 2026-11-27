const std = @import("std");
const metrics = @import("metrics.h");

const t = @import("tester.zig").Tester;

const PATH = "../data/10_000_000.json";

pub fn readFileAlloc(io: std.Io, allocator: std.mem.Allocator, writer: *std.Io.Writer) !void {
    const dir = std.Io.Dir.cwd();
    const stat = try dir.statFile(io, PATH, .{});

    var tester = t.init(metrics.EstimateCPUFrequency(100), 1, stat.size, writer);

    try writer.print("{s}:\n", .{@src().fn_name});
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

    var tester = t.init(metrics.EstimateCPUFrequency(100), 1, stat.size, writer);

    try writer.print("{s}:\n", .{@src().fn_name});
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

    var tester = t.init(metrics.EstimateCPUFrequency(100), 1, stat.size, writer);

    try writer.print("{s}:\n", .{@src().fn_name});
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

pub fn mmap(io: std.Io, writer: *std.Io.Writer) !void {
    const dir = std.Io.Dir.cwd();
    const stat = try dir.statFile(io, PATH, .{});

    var tester = t.init(metrics.EstimateCPUFrequency(100), 1, stat.size, writer);

    try writer.print("{s}:\n", .{@src().fn_name});
    try writer.flush();

    const file = try std.Io.Dir.cwd().openFile(
        io,
        PATH,
        .{},
    );
    defer file.close(io);

    const memory = try std.posix.mmap(
        null,
        stat.size,
        .{ .READ = true, .WRITE = true },
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );
    defer std.posix.munmap(memory);

    while (try tester.isTesting()) {
        var reader = file.reader(io, memory);

        while (true) {
            tester.begin();
            const bytes_read = try reader.interface.readSliceShort(memory);
            tester.end();
            tester.addBytes(bytes_read);
            if (bytes_read == 0) break;
        }
    }
}

pub fn mmapAlloc(io: std.Io, writer: *std.Io.Writer) !void {
    const dir = std.Io.Dir.cwd();
    const stat = try dir.statFile(io, PATH, .{});

    var tester = t.init(metrics.EstimateCPUFrequency(100), 1, stat.size, writer);

    try writer.print("{s}:\n", .{@src().fn_name});
    try writer.flush();

    const file = try std.Io.Dir.cwd().openFile(
        io,
        PATH,
        .{},
    );
    defer file.close(io);

    while (try tester.isTesting()) {
        const memory = try std.posix.mmap(
            null,
            stat.size,
            .{ .READ = true, .WRITE = true },
            .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
            -1,
            0,
        );
        defer std.posix.munmap(memory);
        var reader = file.reader(io, memory);

        while (true) {
            tester.begin();
            const bytes_read = try reader.interface.readSliceShort(memory);
            tester.end();
            tester.addBytes(bytes_read);
            if (bytes_read == 0) break;
        }
    }
}

pub fn mmapAllocPopulate(io: std.Io, writer: *std.Io.Writer) !void {
    const dir = std.Io.Dir.cwd();
    const stat = try dir.statFile(io, PATH, .{});

    var tester = t.init(metrics.EstimateCPUFrequency(100), 1, stat.size, writer);

    try writer.print("{s}:\n", .{@src().fn_name});
    try writer.flush();

    const file = try std.Io.Dir.cwd().openFile(
        io,
        PATH,
        .{},
    );
    defer file.close(io);

    while (try tester.isTesting()) {
        const memory = try std.posix.mmap(
            null,
            stat.size,
            .{ .READ = true, .WRITE = true },
            .{ .TYPE = .PRIVATE, .ANONYMOUS = true, .POPULATE = true },
            -1,
            0,
        );
        defer std.posix.munmap(memory);
        var reader = file.reader(io, memory);

        while (true) {
            tester.begin();
            const bytes_read = try reader.interface.readSliceShort(memory);
            tester.end();
            tester.addBytes(bytes_read);
            if (bytes_read == 0) break;
        }
    }
}

fn readChunked(tester: *t, io: std.Io, allocator: std.mem.Allocator, writer: *std.Io.Writer, chunk_size: usize) !void {
    tester.reset();

    if (chunk_size >= 1024 * 1024 * 1024) {
        try writer.print("CacheSizes ({d}GiB):\n", .{chunk_size / 1024 / 1024 / 1024});
    } else if (chunk_size >= 1024 * 1024) {
        try writer.print("CacheSizes ({d}MiB):\n", .{chunk_size / 1024 / 1024});
    } else {
        try writer.print("CacheSizes ({d}kiB):\n", .{chunk_size / 1024});
    }
    try writer.flush();

    const file = try std.Io.Dir.cwd().openFile(
        io,
        PATH,
        .{},
    );
    defer file.close(io);

    const buffer = try allocator.alloc(u8, chunk_size);
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

pub fn testReadChunked(io: std.Io, allocator: std.mem.Allocator, writer: *std.Io.Writer) !void {
    const dir = std.Io.Dir.cwd();
    const stat = try dir.statFile(io, PATH, .{});
    var tester = t.init(metrics.EstimateCPUFrequency(100), 1, stat.size, writer);

    for (12..31) |power| {
        var chunk_size: usize = 2;
        for (0..power - 1) |_| {
            chunk_size *= 2;
        }

        try readChunked(&tester, io, allocator, writer, chunk_size);
    }
}
