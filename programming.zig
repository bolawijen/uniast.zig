const std = @import("std");

pub const ParseError = error{
    UnexpectedToken,
    UnterminatedString,
};

/// Cek apakah karakter saat ini adalah pembuka string (' atau ") tanpa consume
pub fn matchStringDelimiter(parser: anytype) bool {
    if (parser.index >= parser.source.len) return false;
    const ch = parser.source[parser.index];
    return ch == '"' or ch == '\'';
}

/// Consume pembuka string dan return char-nya, atau error kalau bukan delimiter
pub fn readStringDelimiter(parser: anytype) !u8 {
    if (!matchStringDelimiter(parser)) return error.UnexpectedToken;
    const ch = parser.source[parser.index];
    parser.index += 1;
    return ch;
}

/// Cek apakah karakter saat ini adalah escape backslash (\)
pub fn isEscaped(parser: anytype) bool {
    return parser.index < parser.source.len and parser.source[parser.index] == '\\';
}

pub fn needString(parser: anytype) ![]const u8 {
    const quote = try readStringDelimiter(parser);
    const start = parser.index;

    while (parser.index < parser.source.len) {
        if (isEscaped(parser)) {
            parser.index += 2; // skip \ dan char berikutnya (termasuk \")
            continue;
        }
        if (parser.source[parser.index] == quote) break;
        parser.index += 1;
    }

    if (parser.index >= parser.source.len) return error.UnterminatedString;

    const content = parser.source[start..parser.index];
    parser.index += 1; // skip closing quote
    return content;
}

pub fn needIdentifier(parser: anytype) ![]const u8 {
    const start_id = parser.index;
    while (parser.index < parser.source.len and
        (std.ascii.isAlphabetic(parser.source[parser.index]) or
        parser.source[parser.index] == '_' or
        (parser.index > start_id and std.ascii.isDigit(parser.source[parser.index]))))
        parser.index += 1;

    const id = parser.source[start_id..parser.index];
    if (id.len == 0) return error.UnexpectedToken;
    return id;
}

pub fn needComparisonOperator(parser: anytype) ![]const u8 {
    const start = parser.index;
    if (parser.index + 1 < parser.source.len) {
        const two = parser.source[parser.index .. parser.index + 2];
        if (std.mem.eql(u8, two, "==") or std.mem.eql(u8, two, "!=") or
            std.mem.eql(u8, two, "<=") or std.mem.eql(u8, two, ">=")) {
            parser.index += 2;
            return two;
        }
    }
    if (parser.index < parser.source.len) {
        const one = parser.source[parser.index .. parser.index + 1];
        if (std.mem.eql(u8, one, "<") or std.mem.eql(u8, one, ">")) {
            parser.index += 1;
            return one;
        }
    }
    return error.UnexpectedToken;
}

pub fn needLiteral(parser: anytype) ![]const u8 {
    if (matchStringDelimiter(parser)) {
        return try needString(parser);
    }

    const s = parser.index;
    while (parser.index < parser.source.len and std.ascii.isDigit(parser.source[parser.index])) {
        parser.index += 1;
    }

    if (parser.index < parser.source.len and parser.source[parser.index] == '.') {
        parser.index += 1;
        while (parser.index < parser.source.len and std.ascii.isDigit(parser.source[parser.index])) {
            parser.index += 1;
        }
    }

    const lit = parser.source[s..parser.index];
    if (lit.len == 0) return error.UnexpectedToken;
    return lit;
}

pub fn needOperator(parser: anytype, ops: []const []const u8) ![]const u8 {
    parser.allowWhitespace();
    for (ops) |op| {
        if (parser.eat(op)) return op;
    }
    return error.UnexpectedToken;
}

pub fn needLogicalOperator(parser: anytype) ![]const u8 {
    parser.allowWhitespace();
    if (parser.eat("dan")) return "dan";
    if (parser.eat("atau") or parser.eat("ato")) return "atau";
    return error.UnexpectedToken;
}

pub fn needComparisonExpression(parser: anytype) !void {
    // 1. Baca operand kiri
    _ = try (needIdentifier(parser) catch needLiteral(parser));
    parser.allowWhitespace();

    // 2. Baca operator (perbandingan atau logika)
    _ = try (needComparisonOperator(parser) catch needLogicalOperator(parser));
    parser.allowWhitespace();

    // 3. Baca operand kanan
    _ = try (needIdentifier(parser) catch needLiteral(parser));
}

