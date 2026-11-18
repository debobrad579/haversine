const std = @import("std");
const c = @import("c");

const Error = error{
    UnbalancedBlocks,
    ByteCountMismatch,
};

const Stats = struct {
    count: u64 = 0,
    total: u64 = 0,
    total_page_faults: u64 = 0,
    min: Trial = .{ .ticks = std.math.maxInt(u64) },
    max: Trial = .{ .ticks = std.math.minInt(u64) },

    fn add(self: *Stats, trial: Trial) bool {
        self.count += 1;
        self.total += trial.ticks;
        self.total_page_faults += trial.page_faults;

        if (trial.ticks > self.max.ticks) {
            self.max = trial;
        }

        if (trial.ticks < self.min.ticks) {
            self.min = trial;
            return true;
        }

        return false;
    }
};

const Trial = struct {
    opens: u32 = 0,
    closes: u32 = 0,
    ticks: u64 = 0,
    page_faults: u64 = 0,
    bytes: u64 = 0,
};

pub const Tester = struct {
    const State = enum { testing, completed, failed };

    cpu_freq: u64,
    expected_bytes: u64,
    timeout: u64,
    last_best_at: u64,
    state: State = .testing,
    stats: Stats = .{},
    trial: Trial = .{},
    writer: *std.Io.Writer,

    pub fn init(cpu_freq: u64, timeout_seconds: u64, expected_bytes: u64, writer: *std.Io.Writer) Tester {
        return .{
            .cpu_freq = cpu_freq,
            .expected_bytes = expected_bytes,
            .timeout = timeout_seconds * cpu_freq,
            .last_best_at = c.GetRDTSC(),
            .writer = writer,
        };
    }

    pub fn reset(self: *Tester) void {
        self.last_best_at = c.GetRDTSC();
        self.state = .testing;
        self.stats = .{};
        self.trial = .{};
    }

    pub fn begin(self: *Tester) void {
        self.trial.opens += 1;
        self.trial.ticks -%= c.GetRDTSC();
        self.trial.page_faults -%= c.ReadOSPageFaultCount();
    }

    pub fn end(self: *Tester) void {
        self.trial.closes += 1;
        self.trial.ticks +%= c.GetRDTSC();
        self.trial.page_faults +%= c.ReadOSPageFaultCount();
    }

    pub fn addBytes(self: *Tester, n: u64) void {
        self.trial.bytes += n;
    }

    pub fn isTesting(self: *Tester) !bool {
        if (self.state != .testing) return false;

        const now = c.GetRDTSC();

        if (self.trial.opens != 0) {
            self.finishTrial(now) catch |err| {
                self.state = .failed;
                return err;
            };
        }

        if (now - self.last_best_at > self.timeout) {
            self.state = .completed;
            try self.printResults();
            return false;
        }

        return true;
    }

    fn finishTrial(self: *Tester, now: u64) !void {
        if (self.trial.opens != self.trial.closes) return Error.UnbalancedBlocks;
        if (self.trial.bytes != self.expected_bytes) return Error.ByteCountMismatch;
        if (self.stats.add(self.trial)) {
            try self.printRow("Min", self.trial.ticks, self.trial.page_faults);
            try self.writer.print("\r", .{});
            try self.writer.flush();
            self.last_best_at = now;
        }
        self.trial = .{};
    }

    pub fn printResults(self: Tester) !void {
        if (self.stats.count == 0) {
            std.debug.print("No completed iterations.\n", .{});
            return;
        }

        try self.printRow("Min", self.stats.min.ticks, self.stats.min.page_faults);
        try self.writer.print("\n", .{});
        try self.printRow("Max", self.stats.max.ticks, self.stats.max.page_faults);
        try self.writer.print("\n", .{});
        try self.printRow(
            "Avg",
            self.stats.total / self.stats.count,
            self.stats.total_page_faults / self.stats.count,
        );
        try self.writer.print("\n", .{});

        try self.writer.flush();
    }

    fn printRow(self: Tester, label: []const u8, ticks: u64, page_faults: u64) !void {
        const seconds = @as(f64, @floatFromInt(ticks)) / @as(f64, @floatFromInt(self.cpu_freq));

        try self.writer.print("{s}: {d:.4}ms", .{ label, seconds * 1000.0 });

        if (self.expected_bytes != 0) {
            try self.writer.print(", {d:.2}GiB/s", .{
                @as(f64, @floatFromInt(self.expected_bytes)) / seconds / (1024.0 * 1024.0 * 1024.0),
            });
        }

        if (page_faults != 0) {
            try self.writer.print(", {d} page faults", .{page_faults});
            if (self.expected_bytes != 0) {
                try self.writer.print(" ({d:.4}kiB/fault)", .{
                    @as(f64, @floatFromInt(self.expected_bytes)) / @as(f64, @floatFromInt(page_faults)) / 1024.0,
                });
            }
        }

        try self.writer.writeAll("\x1b[K");
    }
};
