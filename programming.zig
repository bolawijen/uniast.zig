const std = @import("std");

pub const ParseError = error{
    UnexpectedToken,
    UnterminatedString,
};

pub fn needString(parser: anytype) ![]const u8 {
    if (parser.index >= parser.source.len) return error.UnexpectedToken;

    const quote_mark = parser.source[parser.index];
    if (quote_mark != '"' and quote_mark != '\'') return error.UnexpectedToken;

    parser.index += 1; // Skip opening quote
    const content_start = parser.index;

    while (parser.index < parser.source.len) {
        const char = parser.source[parser.index];
        
        if (char == '\\') {
            parser.index += 1;
            if (parser.index < parser.source.len) {
                parser.index += 1;
            }
            continue;
        }

        if (char == quote_mark) {
            break;
        }
        
        parser.index += 1;
    }

    if (parser.index >= parser.source.len) return error.UnterminatedString;

    const content = parser.source[content_start..parser.index];
    parser.index += 1; // Skip closing quote
    return content;
}

pub fn matchStringDelimiter(parser: anytype) bool {
    if (parser.index >= parser.source.len) return false;
    const ch = parser.source[parser.index];
    return ch == '"' or ch == '\'';
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
