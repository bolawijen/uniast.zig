const std = @import("std");
const UniAst = @import("UniAst.zig");

pub fn parser(comptime Plugin: type) type {
    return struct {
        source: []const u8,
        index: usize = 0,
        plugin: *Plugin,

        pub fn init(source: []const u8, plugin: *Plugin) @This() {
            return .{ .source = source, .plugin = plugin };
        }

        pub fn parse(self: *@This(), document: *UniAst.Document) anyerror!void {
            while (self.index < self.source.len) {
                try self.plugin.step(self, document);
            }
        }

        pub fn match(self: *@This(), s: []const u8) bool {
            if (self.index + s.len > self.source.len) return false;
            return std.mem.eql(u8, self.source[self.index .. self.index + s.len], s);
        }

        pub fn eat(self: *@This(), s: []const u8) bool {
            if (self.match(s)) { self.index += s.len; return true; }
            return false;
        }

        pub fn peek(self: *@This()) ?u8 {
            if (self.index >= self.source.len) return null;
            return self.source[self.index];
        }

        pub fn allowWhitespace(self: *@This()) void {
            while (self.peek()) |c| {
                if (c == ' ' or c == '\t' or c == '\n' or c == '\r') self.index += 1 else break;
            }
        }

        pub fn requireWhitespace(self: *@This()) void {
            if (self.peek() == null or !std.ascii.isWhitespace(self.source[self.index]))
                @panic("expected whitespace");
            self.allowWhitespace();
        }

        pub fn readUntil(self: *@This(), delimiter: []const u8) []const u8 {
            const start = self.index;
            while (self.index < self.source.len and !self.match(delimiter)) self.index += 1;
            return self.source[start..self.index];
        }

        pub fn readUntilChar(self: *@This(), char: u8) []const u8 {
            const start = self.index;
            while (self.index < self.source.len and self.source[self.index] != char) self.index += 1;
            return self.source[start..self.index];
        }

        pub fn readIdentifier(self: *@This()) []const u8 {
            const start = self.index;
            while (self.index < self.source.len and
                (std.ascii.isAlphabetic(self.source[self.index]) or
                self.source[self.index] == '_' or self.source[self.index] == '$' or
                (self.index > start and std.ascii.isDigit(self.source[self.index]))))
                self.index += 1;
            return self.source[start..self.index];
        }

        pub fn slice(self: *@This(), start: usize, end: usize) []const u8 {
            return self.source[start..end];
        }

        pub fn isClose(self: *@This(), keyword: []const u8) bool {
            if (self.index + 3 + keyword.len > self.source.len) return false;
            return self.source[self.index] == '{' and
                self.source[self.index + 1] == '/' and
                self.source[self.index + 2 + keyword.len] == '}' and
                std.mem.eql(u8, self.slice(self.index + 2, self.index + 2 + keyword.len), keyword);
        }

        pub fn isNext(self: *@This()) bool {
            return self.match("{:else") or self.match("{:then") or self.match("{:catch");
        }
    };
}

// Re-exports
pub const NodeKind = UniAst.NodeKind;
pub const Attribute = UniAst.Attribute;
pub const Node = UniAst.Node;
pub const Document = UniAst.Document;
pub const MaxChildren = UniAst.MaxChildren;
pub const MaxAttrs = UniAst.MaxAttrs;
pub const ParseError = UniAst.ParseError;
