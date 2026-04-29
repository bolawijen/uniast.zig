const std = @import("std");

pub fn needOpenParenBracket(parser: anytype) !void {
    parser.allowWhitespace();
    if (!parser.eat("(")) return error.ExpectedOpenParen;
}

pub fn needCloseParenBracket(parser: anytype) !void {
    parser.allowWhitespace();
    if (!parser.eat(")")) return error.ExpectedCloseParen;
}

pub fn needOpenCurlyBracket(parser: anytype) !void {
    parser.allowWhitespace();
    if (!parser.eat("{")) return error.ExpectedOpenCurly;
}

pub fn needCloseCurlyBracket(parser: anytype) !void {
    parser.allowWhitespace();
    if (!parser.eat("}")) return error.ExpectedCloseCurly;
}

pub fn needOpenSquareBracket(parser: anytype) !void {
    parser.allowWhitespace();
    if (!parser.eat("[")) return error.ExpectedOpenSquare;
}

pub fn needCloseSquareBracket(parser: anytype) !void {
    parser.allowWhitespace();
    if (!parser.eat("]")) return error.ExpectedCloseSquare;
}

pub fn eatOpenParenBracket(parser: anytype) bool {
    parser.allowWhitespace();
    return parser.eat("(");
}

pub fn eatCloseParenBracket(parser: anytype) bool {
    parser.allowWhitespace();
    return parser.eat(")");
}

pub fn eatCloseCurlyBracket(parser: anytype) bool {
    parser.allowWhitespace();
    return parser.eat("}");
}

pub fn matchOpen(parser: anytype) bool {
    parser.allowWhitespace();
    return parser.match("{");
}

pub fn matchClose(parser: anytype) bool {
    parser.allowWhitespace();
    return parser.match("}");
}

pub fn braceBlock(parser: anytype, ast: anytype, node: anytype) anyerror!void {
    try needOpenCurlyBracket(parser);
    
    if (comptime !@hasField(@TypeOf(parser.plugin.*), "parent_node")) {
        @compileError("Plugin must have a 'parent_node' field to use braceBlock");
    }

    const old_parent = parser.plugin.parent_node;
    parser.plugin.parent_node = node;
    defer parser.plugin.parent_node = old_parent;

    while (parser.peek() != null and !parser.match("}")) {
        parser.plugin.step(parser, ast) catch |err| {
            if (err == error.BlokBerakhir) break;
            return err;
        };
    }
    
    try needCloseCurlyBracket(parser);
}
