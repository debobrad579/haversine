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

test "parse bool true" {
    const value = try json.parse_json("true ");

    try std.testing.expectEqual(json.Data{ .Bool = true }, value);
}

test "parse bool true caps" {
    const value = try json.parse_json("TRUE ");

    try std.testing.expectEqual(json.Data{ .Bool = true }, value);
}

test "parse bool false" {
    const value = try json.parse_json("false ");

    try std.testing.expectEqual(json.Data{ .Bool = false }, value);
}

test "parse bool false caps" {
    const value = try json.parse_json("FALSE ");

    try std.testing.expectEqual(json.Data{ .Bool = false }, value);
}
