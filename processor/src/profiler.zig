const std = @import("std");
const c = @import("c");

var global_profiler: ?*Profiler = null;

pub fn init(allocator: std.mem.Allocator) !void {
    global_profiler = try Profiler.new(allocator);
}

pub fn deinit() void {
    global_profiler.?.deinit();
    global_profiler = null;
}

pub fn start(name: []const u8) Timer {
    return global_profiler.?.start(name);
}

pub fn print(writer: *std.Io.Writer) !void {
    try global_profiler.?.print(writer);
}

const Timer = struct {
    profiler: *Profiler,
    name: []const u8,
    start_time: u64,
    end_time: u64,

    pub fn stop(self: *Timer) void {
        self.end_time = c.GetRDTSC();
        self.profiler.timers.append(self.profiler.allocator, self.*) catch unreachable;
    }
};

const Profiler = struct {
    allocator: std.mem.Allocator,
    timers: std.ArrayList(Timer),
    cpu_freq: u64,
    start_time: u64,

    fn new(allocator: std.mem.Allocator) !*Profiler {
        const profiler = try allocator.create(Profiler);

        profiler.* = Profiler{
            .allocator = allocator,
            .timers = .empty,
            .cpu_freq = c.EstimateCPUFrequency(100),
            .start_time = c.GetRDTSC(),
        };

        return profiler;
    }

    fn start(self: *Profiler, name: []const u8) Timer {
        return Timer{
            .profiler = self,
            .name = name,
            .start_time = c.GetRDTSC(),
            .end_time = 0.0,
        };
    }

    fn print(self: *Profiler, writer: *std.Io.Writer) !void {
        const total_time = c.GetRDTSC() - self.start_time;
        try writer.print("\nTotal time: {d:.4}ms (CPU freq {d})\n", .{
            @as(f64, @floatFromInt(total_time)) / (@as(f64, @floatFromInt(self.cpu_freq)) / 1000),
            self.cpu_freq,
        });

        for (self.timers.items) |timer| {
            const time = timer.end_time - timer.start_time;
            try writer.print("  {s}: {d} ({d:.2}%)\n", .{
                timer.name,
                time,
                @as(f64, @floatFromInt(time)) / @as(f64, @floatFromInt(total_time)) * 100,
            });
        }
    }

    fn deinit(self: *Profiler) void {
        self.timers.deinit(self.allocator);
    }
};
