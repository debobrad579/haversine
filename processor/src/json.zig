const std = @import("std");
const builtin = @import("builtin");

const profiler = @import("profiler.zig");

pub const JSONParseError = error{
    Value,
    Null,
    True,
    False,
    Number,
    String,
    Array,
    Object,
};

pub const Data = union(enum) {
    Null,
    Bool: bool,
    Int: i64,
    Float: f64,
    String: []const u8,
    Array: []const Data,
    Object: Object,
};

const Number = union(enum) {
    Int: i64,
    Float: f64,
};

pub const Object = struct {
    entries: []const Entry,

    pub const Entry = struct {
        key: []const u8,
        value: Data,
    };

    pub fn get(self: *const Object, key: []const u8) ?Data {
        for (self.entries) |entry| {
            if (std.mem.eql(u8, entry.key, key)) {
                return entry.value;
            }
        }

        return null;
    }
};

pub const Parser = struct {
    json: []const u8,
    position: usize,
    allocator: std.mem.Allocator,
};

pub fn parseJSON(json: []const u8, allocator: std.mem.Allocator) JSONParseError!Data {
    var parser = Parser{
        .json = json,
        .position = 0,
        .allocator = allocator,
    };

    if (builtin.is_test) {
        return parseValue(&parser);
    }

    var timer = profiler.startTimer(@src());
    defer timer.stop();

    return parseValue(&parser);
}

fn parseValue(parser: *Parser) JSONParseError!Data {
    if (parser.position >= parser.json.len) {
        return JSONParseError.Value;
    }

    const char = parser.json[parser.position];

    return switch (char) {
        'n', 'N' => Data{ .Null = try parseNull(parser) },
        't', 'T' => Data{ .Bool = try parseTrue(parser) },
        'f', 'F' => Data{ .Bool = try parseFalse(parser) },
        '-', '0'...'9' => switch (try parseNumber(parser)) {
            .Int => |number| Data{ .Int = number },
            .Float => |number| Data{ .Float = number },
        },
        '"' => Data{ .String = try parseString(parser) },
        '[' => Data{ .Array = try parseArray(parser) },
        '{' => Data{ .Object = try parseObject(parser) },
        ' ', '\n', '\t', '\r' => {
            parser.position += 1;
            return parseValue(parser);
        },
        else => return JSONParseError.Value,
    };
}

fn parseNull(parser: *Parser) JSONParseError!void {
    if (parser.position + 4 > parser.json.len) {
        return JSONParseError.Null;
    }

    const value = parser.json[parser.position .. parser.position + 4];

    if (!std.ascii.eqlIgnoreCase(value, "null")) {
        return JSONParseError.Null;
    }

    parser.position += 4;
}

fn parseTrue(parser: *Parser) JSONParseError!bool {
    if (parser.position + 4 > parser.json.len) {
        return JSONParseError.True;
    }

    const value = parser.json[parser.position .. parser.position + 4];

    if (!std.ascii.eqlIgnoreCase(value, "true")) {
        return JSONParseError.True;
    }

    parser.position += 4;
    return true;
}

fn parseFalse(parser: *Parser) JSONParseError!bool {
    if (parser.position + 5 > parser.json.len) {
        return JSONParseError.False;
    }

    const value = parser.json[parser.position .. parser.position + 5];

    if (!std.ascii.eqlIgnoreCase(value, "false")) {
        return JSONParseError.False;
    }

    parser.position += 5;
    return false;
}

fn parseNumber(parser: *Parser) JSONParseError!Number {
    if (parser.position >= parser.json.len) {
        return JSONParseError.Number;
    }

    const sign: i64 = if (parser.json[parser.position] == '-')
        -1
    else
        1;

    if (sign == -1) {
        parser.position += 1;
    }

    var integer_part: i64 = 0;
    var float_part: f64 = 0.0;

    var is_float = false;
    var float_scale: f64 = 0.1;

    var is_exponent = false;
    var exponent_part: usize = 0;
    var exponent_negative = false;

    while (parser.position < parser.json.len) {
        const char = parser.json[parser.position];

        switch (char) {
            '0'...'9' => {
                const digit = char - '0';

                if (is_exponent) {
                    exponent_part *= 10;
                    exponent_part += @as(usize, digit);
                } else if (is_float) {
                    float_part += @as(f64, @floatFromInt(digit)) * float_scale;
                    float_scale /= 10.0;
                } else {
                    integer_part *= 10;
                    integer_part += @as(i64, digit);
                }

                parser.position += 1;
            },
            '.' => {
                is_float = true;
                parser.position += 1;
            },
            'e', 'E' => {
                is_float = true;
                is_exponent = true;
                parser.position += 1;

                if (parser.position == parser.json.len) {
                    return JSONParseError.Number;
                }

                switch (parser.json[parser.position]) {
                    '+' => parser.position += 1,
                    '-' => {
                        exponent_negative = true;
                        parser.position += 1;
                    },
                    else => {},
                }
            },
            else => break,
        }
    }

    if (is_float) {
        var float = @as(f64, @floatFromInt(sign)) * (@as(f64, @floatFromInt(integer_part)) + float_part);

        var multiplier: f64 = 1.0;
        for (0..exponent_part) |_| {
            multiplier *= 10.0;
        }

        if (exponent_negative) {
            float /= multiplier;
        } else {
            float *= multiplier;
        }

        return Number{ .Float = float };
    }

    return Number{ .Int = sign * integer_part };
}

fn parseString(parser: *Parser) JSONParseError![]const u8 {
    if (parser.position >= parser.json.len or parser.json[parser.position] != '"') {
        return JSONParseError.String;
    }

    parser.position += 1;

    var string: std.ArrayList(u8) = .empty;

    while (parser.position < parser.json.len) {
        const char = parser.json[parser.position];
        parser.position += 1;

        if (char == '"') {
            return string.toOwnedSlice(parser.allocator) catch JSONParseError.String;
        }

        string.append(parser.allocator, char) catch {
            return JSONParseError.String;
        };
    }

    return JSONParseError.String;
}

fn parseArray(parser: *Parser) JSONParseError![]const Data {
    if (parser.position >= parser.json.len or parser.json[parser.position] != '[') {
        return JSONParseError.Array;
    }

    parser.position += 1;

    var array: std.ArrayList(Data) = .empty;

    while (parser.position < parser.json.len) {
        const char = parser.json[parser.position];

        if (char == ',' or char == ' ' or char == '\n' or char == '\t' or char == '\r') {
            parser.position += 1;
            continue;
        }

        if (char == ']') {
            parser.position += 1;
            return array.toOwnedSlice(parser.allocator) catch JSONParseError.Array;
        }

        array.append(parser.allocator, try parseValue(parser)) catch {
            return JSONParseError.Array;
        };
    }

    return JSONParseError.Array;
}

fn parseObject(parser: *Parser) JSONParseError!Object {
    if (parser.position >= parser.json.len or parser.json[parser.position] != '{') {
        return JSONParseError.Object;
    }

    parser.position += 1;

    var entries: std.ArrayList(Object.Entry) = .empty;

    while (parser.position < parser.json.len) {
        const char = parser.json[parser.position];

        if (char == ',' or char == ' ' or char == '\n' or char == '\t' or char == '\r') {
            parser.position += 1;
            continue;
        }

        if (char == '}') {
            parser.position += 1;
            return Object{ .entries = entries.toOwnedSlice(parser.allocator) catch {
                return JSONParseError.Object;
            } };
        }

        const key = parseString(parser) catch {
            return JSONParseError.Object;
        };

        if (parser.position >= parser.json.len or parser.json[parser.position] != ':') {
            return JSONParseError.Object;
        }

        parser.position += 1;

        const value = parseValue(parser) catch {
            return JSONParseError.Object;
        };

        entries.append(parser.allocator, Object.Entry{ .key = key, .value = value }) catch {
            return JSONParseError.Object;
        };
    }

    return JSONParseError.Object;
}
