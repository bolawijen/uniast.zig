const std = @import("std");
const UniAstFactory = @import("UniAst.zig");

pub fn parser(comptime Plugin: type) type {
    const Ast = UniAstFactory.UniAst(Plugin.NodeType, Plugin.Props);
    
    return struct {
        source: []const u8,
        index: usize = 0,
        plugin: *Plugin,

        pub fn init(source: []const u8, plugin: *Plugin) @This() {
            return .{ .source = source, .plugin = plugin };
        }

        pub fn parse(self: *@This(), document: *Ast.Tree) anyerror!void {
            if (comptime @hasField(Plugin, "current_parent")) {
                self.plugin.current_parent = &document.root;
            }
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

        pub fn need(self: *@This(), s: []const u8) !void {
            if (!self.eat(s)) {
                return error.UnexpectedToken;
            }
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

        pub fn readWord(self: *@This()) []const u8 {
            const start = self.index;
            while (self.index < self.source.len and
                (std.ascii.isAlphabetic(self.source[self.index]) or
                self.source[self.index] == '_' or
                (self.index > start and std.ascii.isDigit(self.source[self.index]))))
                self.index += 1;
            return self.source[start..self.index];
        }

        pub fn readIdentifier(self: *@This()) []const u8 {
            const start = self.index;
            while (self.index < self.source.len and
                (std.ascii.isAlphabetic(self.source[self.index]) or
                self.source[self.index] == '_' or
                (self.index > start and std.ascii.isDigit(self.source[self.index]))))
                self.index += 1;
            return self.source[start..self.index];
        }

        pub fn slice(self: *@This(), start: usize, end: usize) []const u8 {
            return self.source[start..end];
        }

        pub fn eatPunctuation(self: *@This(), chars: []const u8) ?[]const u8 {
            if (self.index >= self.source.len) return null;
            const c = self.source[self.index];
            for (chars) |p| {
                if (c == p) {
                    self.index += 1;
                    return self.source[self.index - 1 .. self.index];
                }
            }
            return null;
        }
    };
}
