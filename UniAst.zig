const std = @import("std");

pub const ParseError = error{ Unexpected, OutOfMemory };

pub fn UniAst(comptime NodeType: type, comptime Props: type) type {
    return struct {
        pub const Node = struct {
            type: NodeType,
            props: Props = .{},
            children: std.ArrayListUnmanaged(*Node) = .empty,

            pub fn addChild(self: *Node, allocator: std.mem.Allocator, node_type: NodeType, props: anytype) !*Node {
                const child = try allocator.create(Node);
                child.* = .{ .type = node_type };
                
                inline for (std.meta.fields(@TypeOf(props))) |field| {
                    if (@hasField(Props, field.name)) {
                        @field(child.props, field.name) = @field(props, field.name);
                    }
                }
                
                try self.children.append(allocator, child);
                return child;
            }
        };

        pub const Tree = struct {
            alloc: std.mem.Allocator,
            root: Node,

            pub fn init(alloc: std.mem.Allocator, root_type: NodeType) Tree {
                return .{
                    .alloc = alloc,
                    .root = .{ .type = root_type },
                };
            }

            pub fn deinit(self: *Tree) void {
                self.freeNode(&self.root);
            }

            fn freeNode(self: *Tree, node: *Node) void {
                for (node.children.items) |child| {
                    self.freeNode(child);
                }
                node.children.deinit(self.alloc);
                
                inline for (std.meta.fields(Props)) |field| {
                    const field_value = @field(node.props, field.name);
                    const T_field = @TypeOf(field_value);
                    
                    if (@typeInfo(T_field) == .@"struct") {
                        if (@hasField(T_field, "items") and (@hasField(T_field, "capacity") or @hasField(T_field, "cap"))) {
                            @field(node.props, field.name).deinit(self.alloc);
                        }
                    }
                }
                
                if (node != &self.root) {
                    self.alloc.destroy(node);
                }
            }

            pub fn addChild(self: *Tree, node_type: NodeType, props: anytype) !*Node {
                return try self.root.addChild(self.alloc, node_type, props);
            }
        };
    };
}
