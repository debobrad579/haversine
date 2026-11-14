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

test "parse array empty" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json("[]", arena.allocator());

    try std.testing.expectEqualSlices(
        json.Data,
        &[_]json.Data{},
        value.Array,
    );
}

test "parse array" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json(
        "[1, null, true, [1.2, \"hi\"]]",
        arena.allocator(),
    );

    try std.testing.expectEqualDeep(
        &[_]json.Data{
            json.Data{ .Int = 1 },
            json.Data{ .Null = {} },
            json.Data{ .Bool = true },
            json.Data{ .Array = &[_]json.Data{
                json.Data{ .Float = 1.2 },
                json.Data{ .String = "hi" },
            } },
        },
        value.Array,
    );
}

test "parse object empty" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json("{}", arena.allocator());

    try std.testing.expectEqualDeep(
        json.Object{ .entries = &[_]json.Object.Entry{} },
        value.Object,
    );
}

test "parse object" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse_json(
        "{\"Int\": 1, \"Null\": null, \"Bool\": true, \"Array\": [{\"Float\": 1.2}, \"hi\"]}",
        arena.allocator(),
    );

    try std.testing.expectEqualDeep(
        json.Object{ .entries = &[_]json.Object.Entry{
            json.Object.Entry{ .key = "Int", .value = json.Data{ .Int = 1 } },
            json.Object.Entry{ .key = "Null", .value = json.Data{ .Null = {} } },
            json.Object.Entry{ .key = "Bool", .value = json.Data{ .Bool = true } },
            json.Object.Entry{ .key = "Array", .value = json.Data{ .Array = &[_]json.Data{
                json.Data{
                    .Object = json.Object{
                        .entries = &[_]json.Object.Entry{
                            json.Object.Entry{
                                .key = "Float",
                                .value = json.Data{ .Float = 1.2 },
                            },
                        },
                    },
                },
                json.Data{ .String = "hi" },
            } } },
        } },
        value.Object,
    );
}
