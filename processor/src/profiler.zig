const std = @import("std");
const c = @import("c");

pub const enabled = if (@import("builtin").is_test) false else @import("build_options").profile;

const max_anchors = 4096;
const no_parent = std.math.maxInt(usize);

var anchors: [max_anchors]ProfileAnchor = undefined;
var anchor_count: usize = 0;
var current_parent: usize = no_parent;
var cpu_freq: u64 = 0;
var start_time: u64 = 0;
var stack_depth: usize = 0;

pub fn init() void {
    anchor_count = 0;
    current_parent = no_parent;
    cpu_freq = c.EstimateCPUFrequency(100);
    start_time = c.GetRDTSC();
}

const ProfileAnchor = struct {
    src: std.builtin.SourceLocation,
    name: ?[]const u8,
    elapsed_exclusive: u64,
    elapsed_inclusive: u64,
    hits: u64,
    processed_byte_count: u64,
};

const ActiveTimer = struct {
    index: usize,
    parent: usize,
    start_time: u64,
    old_inclusive: u64,
    depth: usize,

    pub fn stop(self: ActiveTimer) void {
        const now = c.GetRDTSC();

        if (stack_depth != self.depth + 1) {
            const anchor = &anchors[self.index];
            std.debug.panic(
                "profiler: timer '{s}' ({s}:{d}) was stopped out of order or multiple times",
                .{ anchor.name orelse anchor.src.fn_name, anchor.src.file, anchor.src.line },
            );
        }

        stack_depth = self.depth;

        const elapsed = now - self.start_time;

        current_parent = self.parent;

        if (self.parent != no_parent) {
            anchors[self.parent].elapsed_exclusive -%= elapsed;
        }

        const anchor = &anchors[self.index];
        anchor.elapsed_exclusive +%= elapsed;

        anchor.elapsed_inclusive = self.old_inclusive + elapsed;
    }
};

const NoopTimer = struct {
    pub fn stop(_: NoopTimer) void {}
};

pub const Timer = if (enabled) ActiveTimer else NoopTimer;

pub fn startTimer(src: std.builtin.SourceLocation) Timer {
    if (!enabled) return .{};

    return start(src, null, 0);
}

pub fn startTimerNamed(src: std.builtin.SourceLocation, name: []const u8) Timer {
    if (!enabled) return .{};

    return start(src, name, 0);
}

pub fn startTimerBandwidth(
    src: std.builtin.SourceLocation,
    name: ?[]const u8,
    processed_byte_count: u64,
) Timer {
    if (!enabled) return .{};

    return start(src, name, processed_byte_count);
}

fn getIndex(src: std.builtin.SourceLocation, name: ?[]const u8, processed_byte_count: u64) usize {
    for (anchors[0..anchor_count], 0..) |*anchor, i| {
        if (anchor.src.file.ptr == src.file.ptr and anchor.src.line == src.line and anchor.src.column == src.column) {
            anchor.hits += 1;
            anchor.processed_byte_count += processed_byte_count;
            return i;
        }
    }

    std.debug.assert(anchor_count < max_anchors);

    const i = anchor_count;
    anchor_count += 1;
    anchors[i] = .{
        .src = src,
        .name = name,
        .elapsed_exclusive = 0,
        .elapsed_inclusive = 0,
        .hits = 0,
        .processed_byte_count = processed_byte_count,
    };

    return i;
}

fn start(src: std.builtin.SourceLocation, name: ?[]const u8, processed_byte_count: u64) Timer {
    const i = getIndex(src, name, processed_byte_count);

    const parent = current_parent;
    current_parent = i;

    const depth = stack_depth;
    stack_depth += 1;

    return Timer{
        .index = i,
        .parent = parent,
        .old_inclusive = anchors[i].elapsed_inclusive,
        .depth = depth,
        .start_time = c.GetRDTSC(),
    };
}

pub fn print(writer: *std.Io.Writer) !void {
    const total = c.GetRDTSC() - start_time;

    try writer.print("\nTotal time: {d:.4}ms (CPU freq {d})\n", .{
        @as(f64, @floatFromInt(total)) / (@as(f64, @floatFromInt(cpu_freq)) / 1000),
        cpu_freq,
    });

    if (!enabled) return;

    for (anchors[0..anchor_count]) |anchor| {
        try writer.print("  {s}[{d}] ({s} {d}:{d}): {d} ({d:.2}%)", .{
            anchor.name orelse anchor.src.fn_name,
            anchor.hits,
            anchor.src.file,
            anchor.src.line,
            anchor.src.column,
            anchor.elapsed_exclusive,
            @as(f64, @floatFromInt(anchor.elapsed_exclusive)) / @as(f64, @floatFromInt(total)) * 100,
        });

        if (anchor.elapsed_inclusive != anchor.elapsed_exclusive) {
            try writer.print(", {d} w/ children ({d:.2}%)", .{
                anchor.elapsed_inclusive,
                @as(f64, @floatFromInt(anchor.elapsed_inclusive)) / @as(f64, @floatFromInt(total)) * 100,
            });
        }

        if (anchor.processed_byte_count != 0) {
            const seconds = @as(f64, @floatFromInt(anchor.elapsed_inclusive)) / @as(f64, @floatFromInt(cpu_freq));
            const bytes_per_second = @as(f64, @floatFromInt(anchor.processed_byte_count)) / seconds;

            try writer.print(", {d:.3}MiB at {d:.2}GiB/s", .{
                @as(f64, @floatFromInt(anchor.processed_byte_count)) / (1024.0 * 1024.0),
                bytes_per_second / (1024.0 * 1024.0 * 1024.0),
            });
        }

        try writer.print("\n", .{});
    }
}
