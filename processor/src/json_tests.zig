const std = @import("std");
const json = @import("json.zig");

test "parse null" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json("null", arena.allocator());

    try std.testing.expectEqual({}, value.Null);
}

test "parse null caps" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json("NULL", arena.allocator());

    try std.testing.expectEqual({}, value.Null);
}

test "parse true" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json("true", arena.allocator());

    try std.testing.expectEqual(true, value.Bool);
}

test "parse true caps" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json("TRUE", arena.allocator());

    try std.testing.expectEqual(true, value.Bool);
}

test "parse false" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json("false", arena.allocator());

    try std.testing.expectEqual(false, value.Bool);
}

test "parse false caps" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json("FALSE", arena.allocator());

    try std.testing.expectEqual(false, value.Bool);
}

test "parse integer" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json("1234", arena.allocator());

    try std.testing.expectEqual(1234, value.Int);
}

test "parse negative integer" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json("-1234", arena.allocator());

    try std.testing.expectEqual(-1234, value.Int);
}

test "parse float" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json("2.72", arena.allocator());

    try std.testing.expectEqual(2.72, value.Float);
}

test "parse negative float" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json("-2.72", arena.allocator());

    try std.testing.expectEqual(-2.72, value.Float);
}

test "parse scientific notation" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json("1e+9", arena.allocator());

    try std.testing.expectEqual(1e9, value.Float);
}

test "parse scientific notation negative exponent" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json("1e-9", arena.allocator());

    try std.testing.expectEqual(1e-9, value.Float);
}

test "parse string" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json("\"Hello, World!\"", arena.allocator());

    try std.testing.expectEqualStrings("Hello, World!", value.String);
}
