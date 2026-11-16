const std = @import("std");
const c = @import("c");

const max_anchors = 4096;

var anchors: [max_anchors]ProfileAnchor = undefined;
var anchor_count: usize = 0;
var cpu_freq: u64 = 0;
var start_time: u64 = 0;

pub fn init() void {
    anchor_count = 0;
    cpu_freq = c.EstimateCPUFrequency(100);
    start_time = c.GetRDTSC();
}

const ProfileAnchor = struct {
    src: std.builtin.SourceLocation,
    name: ?[]const u8,
    elapsed: u64,
    hits: u64,
    depth: u32,
};

pub const Timer = struct {
    index: usize,
    start_time: u64,

    pub fn stop(self: Timer) void {
        const now = c.GetRDTSC();
        const anchor = &anchors[self.index];

        anchor.depth -= 1;
        if (anchor.depth == 0) {
            anchor.elapsed += now - self.start_time;
        }

        anchor.hits += 1;
    }
};

pub fn startTimer(src: std.builtin.SourceLocation) Timer {
    return start(src, null);
}

pub fn startNamedTimer(src: std.builtin.SourceLocation, name: []const u8) Timer {
    return start(src, name);
}

fn getIndex(src: std.builtin.SourceLocation, name: ?[]const u8) usize {
    for (anchors[0..anchor_count], 0..) |*anchor, i| {
        if (anchor.src.file.ptr == src.file.ptr and anchor.src.line == src.line and anchor.src.column == src.column) return i;
    }

    std.debug.assert(anchor_count < max_anchors);

    const i = anchor_count;
    anchor_count += 1;
    anchors[i] = .{
        .src = src,
        .name = name,
        .elapsed = 0,
        .hits = 0,
        .depth = 0,
    };

    return i;
}

fn start(src: std.builtin.SourceLocation, name: ?[]const u8) Timer {
    const i = getIndex(src, name);
    anchors[i].depth += 1;
    return Timer{ .index = i, .start_time = c.GetRDTSC() };
}

pub fn print(writer: *std.Io.Writer) !void {
    const total = c.GetRDTSC() - start_time;

    try writer.print("\nTotal time: {d:.4}ms (CPU freq {d})\n", .{
        @as(f64, @floatFromInt(total)) / (@as(f64, @floatFromInt(cpu_freq)) / 1000),
        cpu_freq,
    });

    for (anchors[0..anchor_count]) |anchor| {
        try writer.print("  {s}[{d}] ({s} {d}:{d}): {d} ({d:.2}%)\n", .{
            anchor.name orelse anchor.src.fn_name,
            anchor.hits,
            anchor.src.file,
            anchor.src.line,
            anchor.src.column,
            anchor.elapsed,
            @as(f64, @floatFromInt(anchor.elapsed)) / @as(f64, @floatFromInt(total)) * 100,
        });
    }
}
