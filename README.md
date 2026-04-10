# UniAst

Universal AST types and parser factory for Zig.

## Modules

### UniAst

Generic AST node and document structure:

```zig
const uniast = @import("uniast");

var doc = uniast.Document.init(alloc);
const node = try doc.createNode(.element);
node.name = "div";
doc.addChild(node);
```

### Parser

Generic parser factory — pass a plugin with a `step()` method:

```zig
const uniast = @import("uniast");

const MyPlugin = struct {
    pub fn step(self: *MyPlugin, parser: *uniast.parser(MyPlugin), doc: *uniast.Document) anyerror!void {
        // parse one token at parser.index
    }
};

var plugin = MyPlugin{};
var parser = uniast.parser(MyPlugin).init(source, &plugin);
try parser.parse(&doc);
```

## Node Structure

| Field | Type | Description |
|---|---|---|
| `kind` | `NodeKind` | `.text`, `.element`, `.expression`, `.block`, etc |
| `type_name` | `[]const u8` | Language-specific type ("IfBlock", "SnippetBlock") |
| `name` | `?[]const u8` | Tag name, snippet name, etc |
| `value` | `?[]const u8` | Text content, expression text |
| `children` | `[256]*Node` | Child nodes |
| `attrs` | `[32]Attribute` | Attributes |
