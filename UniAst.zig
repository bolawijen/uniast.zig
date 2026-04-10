const std = @import("std");

pub const ParseError = error{ Unexpected, OutOfMemory };

pub const NodeKind = enum {
    root,
    text,
    comment,
    element,
    expression,
    block,
    attribute,
};

pub const Attribute = struct {
    name: []const u8,
    value: ?[]const u8 = null,
    is_expression: bool = false,
};

pub const MaxChildren = 256;
pub const MaxAttrs = 32;

pub const Node = struct {
    kind: NodeKind,
    type_name: []const u8 = "",
    name: ?[]const u8 = null,
    value: ?[]const u8 = null,
    children: [MaxChildren]*Node = undefined,
    children_len: usize = 0,
    attrs: [MaxAttrs]Attribute = .{Attribute{ .name = "" }} ** MaxAttrs,
    attrs_len: usize = 0,
    meta: ?*anyopaque = null,

    pub fn addChild(self: *Node, child: *Node) void {
        if (self.children_len < MaxChildren) {
            self.children[self.children_len] = child;
            self.children_len += 1;
        }
    }

    pub fn addAttr(self: *Node, attr: Attribute) void {
        if (self.attrs_len < MaxAttrs) {
            self.attrs[self.attrs_len] = attr;
            self.attrs_len += 1;
        }
    }
};

pub const Document = struct {
    alloc: std.mem.Allocator,
    root: Node,

    pub fn init(alloc: std.mem.Allocator) Document {
        return .{
            .alloc = alloc,
            .root = .{ .kind = .root },
        };
    }

    pub fn deinit(self: *Document) void {
        freeNode(self.alloc, &self.root);
    }

    fn freeNode(alloc: std.mem.Allocator, node: *Node) void {
        var i: usize = 0;
        while (i < node.children_len) : (i += 1) {
            freeNode(alloc, node.children[i]);
        }
        alloc.destroy(node);
    }

    pub fn createNode(self: *Document, kind: NodeKind) !*Node {
        const n = try self.alloc.create(Node);
        n.* = .{ .kind = kind };
        return n;
    }

    pub fn addChild(self: *Document, n: *Node) void {
        self.root.addChild(n);
    }
};
