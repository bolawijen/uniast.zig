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

pub fn readFunctionCallArguments(parser: anytype, alloc: std.mem.Allocator, reader_ptr: anytype, readArg: anytype) !std.ArrayListUnmanaged([]const u8) {
    var args: std.ArrayListUnmanaged([]const u8) = .empty;
    errdefer args.deinit(alloc);

    parser.allowWhitespace();
    while (true) {
        parser.allowWhitespace();
        if (parser.index >= parser.source.len) break;
        if (parser.source[parser.index] == ')') {
            parser.index += 1;
            break;
        }
        if (try readArg(reader_ptr)) |arg| {
            try args.append(alloc, arg);
        }
        parser.allowWhitespace();
        if (parser.index < parser.source.len and parser.source[parser.index] == ',') {
            parser.index += 1;
        } else if (parser.index < parser.source.len and parser.source[parser.index] == ')') {
            parser.index += 1;
            break;
        } else {
            break;
        }
    }
    return args;
}

pub fn needIdentifier(parser: anytype) ![]const u8 {
    const start = parser.index;
    while (parser.index < parser.source.len and
        (std.ascii.isAlphabetic(parser.source[parser.index]) or
        parser.source[parser.index] == '_' or
        (parser.index > start and std.ascii.isDigit(parser.source[parser.index]))))
        parser.index += 1;
    
    const id = parser.source[start..parser.index];
    if (id.len == 0) return error.UnexpectedToken;
    return id;
}
