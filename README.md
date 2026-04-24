# UniAst

Universal AST (Abstract Syntax Tree) engine for Zig. Designed for high performance, memory efficiency, and cross-language flexibility.

## Available APIs

### `Tree` (AST Container)
The `Tree` struct manages memory allocation and serves as the entry point for your AST.

- **`init(allocator: Allocator, root_type: NodeType) Tree`**
  Initializes a new AST tree with a root node of the specified type.
- **`deinit() void`**
  Recursively frees all nodes and memory associated with the tree.
- **`addChild(node_type: NodeType, props: anytype) !*Node`**
  Allocates a new node and adds it as a direct child of the root node.

### `Node` (AST Element)
Individual elements within the tree.

- **`addChild(allocator: Allocator, node_type: NodeType, props: anytype) !*Node`**
  Allocates a new node and adds it as a child of the current node.
- **`.type`** (Field)
  The identity of the node (enum value defined by `NodeType`).
- **`.props`** (Field)
  A struct containing node-specific metadata (defined by `Props`).
- **`.children`** (Field)
  An `ArrayListUnmanaged(*Node)` containing references to child nodes.

## Key Features

- **Lightweight Nodes**: Minimized memory footprint by separating metadata (`props`) from hierarchy (`children`).
- **Standardized Schema**: Uses the `.type` pattern for node identity, aligning with industry standards like Estree.
- **ArrayListUnmanaged**: Efficient child management without storing redundant allocator pointers in every node.

## Plugin System

UniAst supports a plugin-based architecture for parsing. Plugins only need to define `NodeType` and `Props`, and implement a `step` function to populate the `Tree`.

For a real-world implementation, see [**uniast-svelte**](https://github.com/bolawijen/uniast-svelte.zig), a plugin that parses Svelte 5 templates into a `UniAst` tree.
