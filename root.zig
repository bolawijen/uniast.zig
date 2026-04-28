const std = @import("std");

pub const Parser = @import("Parser.zig");
pub const UniAst = @import("UniAst.zig").UniAst;
pub const programming = @import("programming.zig");
pub const blocks = @import("blocks.zig");
pub const ParseError = @import("UniAst.zig").ParseError;

pub fn parser(comptime Plugin: type) type {
    return Parser.parser(Plugin);
}
