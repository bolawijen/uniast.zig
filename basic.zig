const std = @import("std");

pub fn allowWhitespace(parser: anytype) void {
    while (parser.peek()) |c| {
        if (c == ' ' or c == '\t' or c == '\n' or c == '\r')
            parser.index += 1
        else
            break;
    }
}

fn isWhitespace(parser: anytype) bool {
    return parser.peek() == null or !std.ascii.isWhitespace(parser.source[parser.index]);
}

pub fn needWhitespace(parser: anytype) void {
    if (!isWhitespace(parser))
        return error.ExpectedWhitespace;
    parser.allowWhitespace(parser);
}

pub fn readWord(parser: anytype) []const u8 {
    const start = parser.index;
    while (parser.index < parser.source.len and
        (std.ascii.isAlphabetic(parser.source[parser.index]) or
            parser.source[parser.index] == '_' or
            (parser.index > start and std.ascii.isDigit(parser.source[parser.index]))))
        parser.index += 1;
    return parser.source[start..parser.index];
}

pub fn readIdentifier(parser: anytype) []const u8 {
    const start = parser.index;
    while (parser.index < parser.source.len and
        (std.ascii.isAlphabetic(parser.source[parser.index]) or
            parser.source[parser.index] == '_' or
            (parser.index > start and std.ascii.isDigit(parser.source[parser.index]))))
        parser.index += 1;
    return parser.source[start..parser.index];
}

pub fn eatPunctuation(parser: anytype, chars: []const u8) ?[]const u8 {
    if (parser.index >= parser.source.len) return null;
    const c = parser.source[parser.index];
    for (chars) |p| {
        if (c == p) {
            parser.index += 1;
            return parser.source[parser.index - 1 .. parser.index];
        }
    }
    return null;
}
