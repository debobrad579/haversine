const std = @import("std");

pub const JSONParseError = error{
    Value,
    Null,
    Bool,
    Number,
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
            if (entry.key == key) {
                return entry.value;
            }
        }

        return null;
    }
};

pub const Parser = struct {
    json: []const u8,
    position: usize,
};

pub fn parse_json(json: []const u8) !Data {
    var parser = Parser{
        .json = json,
        .position = 0,
    };

    return parse_value(&parser);
}

fn parse_value(parser: *Parser) !Data {
    if (parser.position >= parser.json.len) {
        return JSONParseError.Value;
    }

    const char = parser.json[parser.position];

    return switch (char) {
        'n', 'N' => Data{ .Null = try parse_null(parser) },
        't', 'T', 'f', 'F' => Data{ .Bool = try parse_bool(parser) },
        '0'...'9' => switch (try parse_number(parser)) {
            .Int => |number| Data{ .Int = number },
            .Float => |number| Data{ .Float = number },
        },
        // '"' => Data{ .String = try parse_string(parser) },
        // '[' => Data{ .Array = try parse_array(parser) },
        // '{' => Data{ .Object = try parse_object(parser) },
        ' ' | '\n' => {
            parser.position += 1;
            return parse_value(parser);
        },
        else => return JSONParseError.Value,
    };
}

fn parse_null(parser: *Parser) !void {
    if (parser.position + 4 > parser.json.len) {
        return JSONParseError.Null;
    }

    const value = parser.json[parser.position .. parser.position + 4];

    if (!std.ascii.eqlIgnoreCase(value, "null")) {
        return JSONParseError.Null;
    }

    parser.position += 4;
}

fn parse_bool(parser: *Parser) !bool {
    if (parser.position >= parser.json.len) {
        return JSONParseError.Bool;
    }

    const char = parser.json[parser.position];

    if (char == 't' or char == 'T') {
        if (parser.position + 4 > parser.json.len) {
            return JSONParseError.Bool;
        }

        const value = parser.json[parser.position .. parser.position + 4];

        if (!std.ascii.eqlIgnoreCase(value, "true")) {
            return JSONParseError.Bool;
        }

        parser.position += 4;
        return true;
    }

    if (char == 'f' or char == 'F') {
        if (parser.position + 5 > parser.json.len) {
            return JSONParseError.Bool;
        }

        const value = parser.json[parser.position .. parser.position + 5];

        if (!std.ascii.eqlIgnoreCase(value, "false")) {
            return JSONParseError.Bool;
        }

        parser.position += 5;
        return false;
    }

    return JSONParseError.Bool;
}

fn parse_number(_: *Parser) !Number {
    return Number{ .Int = 1 };
}

fn parse_string(_: *Parser) ![]const u8 {}

fn parse_array(_: *Parser) ![]const Data {}

fn parse_object(_: *Parser) !Object {}
