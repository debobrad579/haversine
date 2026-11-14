const std = @import("std");
const json = @import("json.zig");

test "parse null" {
    const value = try json.parse_json("null");

    try std.testing.expectEqual(json.Data{ .Null = {} }, value);
}

test "parse null caps" {
    const value = try json.parse_json("NULL");

    try std.testing.expectEqual(json.Data{ .Null = {} }, value);
}

test "parse true" {
    const value = try json.parse_json("true");

    try std.testing.expectEqual(json.Data{ .Bool = true }, value);
}

test "parse true caps" {
    const value = try json.parse_json("TRUE");

    try std.testing.expectEqual(json.Data{ .Bool = true }, value);
}

test "parse false" {
    const value = try json.parse_json("false");

    try std.testing.expectEqual(json.Data{ .Bool = false }, value);
}

test "parse false caps" {
    const value = try json.parse_json("FALSE");

    try std.testing.expectEqual(json.Data{ .Bool = false }, value);
}

test "parse integer" {
    const value = try json.parse_json("1234");

    try std.testing.expectEqual(json.Data{ .Int = 1234 }, value);
}

test "parse negative integer" {
    const value = try json.parse_json("-1234");

    try std.testing.expectEqual(json.Data{ .Int = -1234 }, value);
}

test "parse float" {
    const value = try json.parse_json("2.72");

    try std.testing.expectEqual(json.Data{ .Float = 2.72 }, value);
}

test "parse negative float" {
    const value = try json.parse_json("-2.72");

    try std.testing.expectEqual(json.Data{ .Float = -2.72 }, value);
}

test "parse scientific notation" {
    const value = try json.parse_json("1e+9");

    try std.testing.expectEqual(json.Data{ .Float = 1e9 }, value);
}

test "parse scientific notation negative exponent" {
    const value = try json.parse_json("1e-9");

    try std.testing.expectEqual(json.Data{ .Float = 1e-9 }, value);
}
