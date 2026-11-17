const std = @import("std");
const json = @import("json.zig");

test "parse null" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse("null", arena.allocator());

    try std.testing.expectEqual({}, value.data.Null);
}

test "parse null caps" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse("NULL", arena.allocator());

    try std.testing.expectEqual({}, value.data.Null);
}

test "parse true" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse("true", arena.allocator());

    try std.testing.expectEqual(true, value.data.Bool);
}

test "parse true caps" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse("TRUE", arena.allocator());

    try std.testing.expectEqual(true, value.data.Bool);
}

test "parse false" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse("false", arena.allocator());

    try std.testing.expectEqual(false, value.data.Bool);
}

test "parse false caps" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse("FALSE", arena.allocator());

    try std.testing.expectEqual(false, value.data.Bool);
}

test "parse integer" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse("1234", arena.allocator());

    try std.testing.expectEqual(1234, value.data.Int);
}

test "parse negative integer" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse("-1234", arena.allocator());

    try std.testing.expectEqual(-1234, value.data.Int);
}

test "parse float" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse("2.72", arena.allocator());

    try std.testing.expectEqual(2.72, value.data.Float);
}

test "parse negative float" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse("-2.72", arena.allocator());

    try std.testing.expectEqual(-2.72, value.data.Float);
}

test "parse scientific notation" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse("1e+9", arena.allocator());

    try std.testing.expectEqual(1e9, value.data.Float);
}

test "parse scientific notation negative exponent" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse("1e-9", arena.allocator());

    try std.testing.expectEqual(1e-9, value.data.Float);
}

test "parse string" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse("\"Hello, World!\"", arena.allocator());

    try std.testing.expectEqualStrings("Hello, World!", value.data.String);
}

test "parse array empty" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse("[]", arena.allocator());

    try std.testing.expectEqualSlices(
        json.Data,
        &[_]json.Data{},
        value.data.Array,
    );
}

test "parse array" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse(
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
        value.data.Array,
    );
}

test "parse object empty" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse("{}", arena.allocator());

    try std.testing.expectEqualDeep(
        json.Object{ .entries = &[_]json.Object.Entry{} },
        value.data.Object,
    );
}

test "parse object" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const value = try json.parse(
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
        value.data.Object,
    );
}
