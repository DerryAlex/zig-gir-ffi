//! XML Parser for GIR Schema

const Parser = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const Reader = std.Io.Reader;
const StaticStringMap = std.StaticStringMap;
const Writer = std.Io.Writer;
const assert = std.debug.assert;
const fatal = std.process.fatal;
const Scanner = @import("Scanner.zig");
const gi = @import("../../gi.zig");

scanner: *Scanner,

pub fn init(scanner: *Scanner) Parser {
    return .{
        .scanner = scanner,
    };
}

pub const Error = Scanner.Error || Allocator.Error || error{ParseGirFailed};

fn fail(token: Scanner.Token) error{ParseGirFailed} {
    std.log.err("unexpected token {f}", .{token});
    return error.ParseGirFailed;
}

fn discardTag(self: *Parser) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => return,
            .opening_tag_end => break,
            .attribute => {},
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => return,
            .opening_tag => try self.discardTag(),
            .text => {},
            .comment => {},
            else => return fail(token),
        }
    }
}

fn discardAttr(_: Scanner.Attribute) void {}

fn parseXmlProlog(self: *Parser) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "version")) {
                    discardAttr(attr);
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
}

fn parseDoc(self: *Parser, allocator: Allocator) Error![]const u8 {
    var aw: Writer.Allocating = .init(allocator);
    errdefer aw.deinit();
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.startsWith(u8, attr.name, "xml:") or std.mem.eql(u8, attr.name, "filename") or std.mem.eql(u8, attr.name, "line")) {
                    discardAttr(attr);
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .text => |t| aw.writer.writeAll(t) catch return error.OutOfMemory,
            .comment => {},
            else => return fail(token),
        }
    }
    const doc = try aw.toOwnedSlice();
    errdefer allocator.free(doc);
    var reader: Reader = .fixed(doc);
    while (true) {
        _ = reader.streamDelimiterEnding(&aw.writer, '&') catch |err| switch (err) {
            error.WriteFailed => return error.OutOfMemory,
            else => |e| return e,
        };
        _ = reader.peekByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };
        const esc_seq = try reader.takeDelimiterInclusive(';');
        if (std.mem.eql(u8, esc_seq, "&lt;")) {
            aw.writer.writeAll("<") catch return error.OutOfMemory;
        } else if (std.mem.eql(u8, esc_seq, "&gt;")) {
            aw.writer.writeAll(">") catch return error.OutOfMemory;
        } else if (std.mem.eql(u8, esc_seq, "&amp;")) {
            aw.writer.writeAll("&") catch return error.OutOfMemory;
        } else if (std.mem.eql(u8, esc_seq, "&quot;")) {
            aw.writer.writeAll("\"") catch return error.OutOfMemory;
        } else if (std.mem.eql(u8, esc_seq, "&apos;")) {
            aw.writer.writeAll("'") catch return error.OutOfMemory;
        } else if (std.mem.startsWith(u8, esc_seq, "&#x")) {
            const unicode = std.fmt.parseInt(u21, esc_seq[3 .. esc_seq.len - 1], 16) catch unreachable;
            aw.writer.printUnicodeCodepoint(unicode) catch return error.OutOfMemory;
        } else return fail(.{ .text = esc_seq });
    }
    return try aw.toOwnedSlice();
}

pub fn parse(self: *Parser, allocator: Allocator) Error!gi.Namespace {
    var namespace: gi.Namespace = .{ .name = &.{} };
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "xml")) {
                    try self.parseXmlProlog();
                } else if (std.mem.eql(u8, tag.name, "repository")) {
                    namespace = try self.parseRepository(allocator);
                } else return fail(token);
            },
            .comment => {},
            .end_of_document => return namespace,
            else => return fail(token),
        }
    }
}

fn parseRepository(self: *Parser, allocator: Allocator) Error!gi.Namespace {
    var namespace: gi.Namespace = .{ .name = &.{} };
    errdefer namespace.deinit(allocator);
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.startsWith(u8, attr.name, "xmlns") or std.mem.eql(u8, attr.name, "version")) {
                    discardAttr(attr);
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "include")) {
                    const dep = try self.parseInclude(allocator);
                    try namespace.dependencies.append(allocator, dep);
                } else if (std.mem.eql(u8, tag.name, "namespace")) {
                    try self.parseNamespace(allocator, &namespace);
                } else if (std.mem.eql(u8, tag.name, "package") or std.mem.startsWith(u8, tag.name, "c:") or std.mem.startsWith(u8, tag.name, "doc:")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    return namespace;
}

fn parseInclude(self: *Parser, allocator: Allocator) Error![]const u8 {
    var name: []const u8 = &.{};
    errdefer allocator.free(name);
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    name = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    discardAttr(attr); // TODO
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    return name;
}

fn parseNamespace(self: *Parser, allocator: Allocator, namespace: *gi.Namespace) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    namespace.name = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    discardAttr(attr); // TODO
                } else if (std.mem.startsWith(u8, attr.name, "c:") or std.mem.eql(u8, attr.name, "shared-library")) {
                    discardAttr(attr);
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "alias")) {
                    const alias = try self.parseAlias(allocator);
                    try namespace.infos.append(allocator, .{ .alias = alias });
                } else if (std.mem.eql(u8, tag.name, "bitfield") or std.mem.eql(u8, tag.name, "enumeration")) {
                    try self.parseEnum(allocator);
                } else if (std.mem.eql(u8, tag.name, "callback")) {
                    try self.parseCallable(allocator);
                } else if (std.mem.eql(u8, tag.name, "class")) {
                    try self.parseClass(allocator);
                } else if (std.mem.eql(u8, tag.name, "constant")) {
                    try self.parseConstant(allocator);
                } else if (std.mem.eql(u8, tag.name, "function")) {
                    try self.parseCallable(allocator);
                } else if (std.mem.eql(u8, tag.name, "interface")) {
                    try self.parseInterface(allocator);
                } else if (std.mem.eql(u8, tag.name, "record") or std.mem.eql(u8, tag.name, "glib:boxed")) {
                    try self.parseRecord(allocator);
                } else if (std.mem.eql(u8, tag.name, "union")) {
                    try self.parseUnion(allocator);
                } else if (std.mem.eql(u8, tag.name, "docsection") or std.mem.eql(u8, tag.name, "function-inline") or std.mem.eql(u8, tag.name, "function-macro")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

// -----

fn parseAlias(self: *Parser, allocator: Allocator) Error!gi.Alias {
    var name: []const u8 = &.{};
    defer allocator.free(name);
    var doc: []const u8 = &.{};
    defer allocator.free(doc);
    var deprecated_doc: []const u8 = &.{};
    defer allocator.free(deprecated_doc);
    var deprecated = false;
    var deprecated_version: f32 = 0.0;
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    name = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    if (std.mem.eql(u8, attr.value, "1")) {
                        deprecated = true;
                    } else return fail(token);
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    deprecated_version = std.fmt.parseFloat(f32, attr.value) catch unreachable;
                } else if (std.mem.startsWith(u8, attr.name, "c:")) {
                    discardAttr(attr);
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    var alias: gi.Alias = try .init(allocator, name);
    errdefer alias.deinit(allocator);
    alias.base.deprecated = deprecated;
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "doc")) {
                    doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    deprecated_doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    alias.type_info = try allocator.create(gi.Type);
                    alias.type_info.?.* = try self.parseType(allocator);
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    if (deprecated) {
        alias.base.doc = try std.fmt.allocPrint(allocator,
            \\{s}
            \\
            \\@deprecated(since = {}) {s}
        , .{ doc, deprecated_version, deprecated_doc });
    } else {
        alias.base.doc = doc;
        doc = &.{};
    }
    return alias;
}

fn parseArg(self: *Parser, allocator: Allocator) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "allow-none")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "caller-allocates")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "closure")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "direction")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "destroy")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "nullable")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "optional")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "scope")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "skip")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "transfer-ownership")) {
                    // TODO
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "doc")) {
                    _ = try self.parseDoc(allocator); // TODO
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    _ = try self.parseType(allocator);
                } else if (std.mem.eql(u8, tag.name, "array")) {
                    _ = try self.parseArray(allocator);
                } else if (std.mem.eql(u8, tag.name, "attribute")) {
                    try self.parseAttribute(allocator);
                } else if (std.mem.eql(u8, tag.name, "varargs")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseArgs(self: *Parser, allocator: Allocator) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                _ = attr;
                return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "parameter") or std.mem.eql(u8, tag.name, "instance-parameter")) {
                    try self.parseArg(allocator);
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseArray(self: *Parser, allocator: Allocator) Error!gi.Type {
    var _type: gi.Type = try .init(allocator, "type");
    errdefer _type.deinit(allocator);
    _type.tag = .array;
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    const name = attr.value;
                    if (std.mem.eql(u8, name, "GLib.Array")) {
                        _type.array_type = .array;
                    } else if (std.mem.eql(u8, name, "GLib.ByteArray")) {
                        _type.array_type = .byte_array;
                    } else if (std.mem.eql(u8, name, "GLib.PtrArray")) {
                        _type.array_type = .ptr_array;
                    } else unreachable;
                } else if (std.mem.eql(u8, attr.name, "fixed-size")) {
                    _type.array_fixed_size = std.fmt.parseInt(usize, attr.value, 10) catch unreachable;
                } else if (std.mem.eql(u8, attr.name, "length")) {
                    _type.array_length_index = std.fmt.parseInt(usize, attr.value, 10) catch unreachable;
                } else if (std.mem.eql(u8, attr.name, "zero-terminated")) {
                    _type.zero_terminated = 0 != (std.fmt.parseInt(u1, attr.value, 10) catch unreachable);
                } else if (std.mem.eql(u8, attr.name, "c:type")) {
                    discardAttr(attr);
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "array")) {
                    _ = try self.parseArray(allocator);
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    _ = try self.parseType(allocator);
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    return _type;
}

fn parseAttribute(self: *Parser, allocator: Allocator) Error!void {
    _ = allocator;
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "value")) {
                    // TODO
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
}

fn parseCallable(self: *Parser, allocator: Allocator) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "introspectable")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "invoker")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "moved-to")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "shadowed-by")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "shadows")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "throws")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "c:identifier")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "c:type")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:async-func")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:finish-func")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:get-property")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:set-property")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:sync-func")) {
                    // TODO
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "doc") or std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    _ = try self.parseDoc(allocator); // TODO
                } else if (std.mem.eql(u8, tag.name, "attribute")) {
                    try self.parseAttribute(allocator);
                } else if (std.mem.eql(u8, tag.name, "doc-version")) {
                    try self.discardTag(); // TODO
                } else if (std.mem.eql(u8, tag.name, "return-value")) {
                    try self.parseArg(allocator);
                } else if (std.mem.eql(u8, tag.name, "parameters")) {
                    try self.parseArgs(allocator);
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseClass(self: *Parser, allocator: Allocator) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "abstract")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "parent")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:fundamental")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:get-value-func")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:get-type")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:ref-func")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:set-value-func")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:type-struct")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:unref-func")) {
                    // TODO
                } else if (std.mem.startsWith(u8, attr.name, "c:") or std.mem.eql(u8, attr.name, "glib:type-name")) {
                    // no op
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "doc") or std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    _ = try self.parseDoc(allocator); // TODO
                } else if (std.mem.eql(u8, tag.name, "constructor") or std.mem.eql(u8, tag.name, "function") or std.mem.eql(u8, tag.name, "method") or std.mem.eql(u8, tag.name, "virtual-method")) {
                    try self.parseCallable(allocator);
                } else if (std.mem.eql(u8, tag.name, "field")) {
                    try self.parseField(allocator);
                } else if (std.mem.eql(u8, tag.name, "implements")) {
                    try self.discardTag(); // TODO
                } else if (std.mem.eql(u8, tag.name, "property")) {
                    try self.parseProperty(allocator);
                } else if (std.mem.eql(u8, tag.name, "glib:signal")) {
                    try self.parseSignal(allocator);
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseConstant(self: *Parser, allocator: Allocator) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "value")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    // TODO
                } else if (std.mem.startsWith(u8, attr.name, "c:")) {
                    // no op
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "doc") or std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    _ = try self.parseDoc(allocator); // TODO
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    _ = try self.parseType(allocator);
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseEnum(self: *Parser, allocator: Allocator) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "introspectable")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:error-domain")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:get-type")) {
                    // TODO
                } else if (std.mem.startsWith(u8, attr.name, "c:") or std.mem.eql(u8, attr.name, "glib:type-name")) {
                    // no op
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "doc") or std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    _ = try self.parseDoc(allocator); // TODO
                } else if (std.mem.eql(u8, tag.name, "function")) {
                    try self.parseCallable(allocator);
                } else if (std.mem.eql(u8, tag.name, "member")) {
                    try self.parseMember(allocator);
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseField(self: *Parser, allocator: Allocator) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "bits")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "introspectable")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "private")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "readable")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "writable")) {
                    // TODO
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "doc")) {
                    _ = try self.parseDoc(allocator); // TODO
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    _ = try self.parseType(allocator);
                } else if (std.mem.eql(u8, tag.name, "array")) {
                    _ = try self.parseArray(allocator);
                } else if (std.mem.eql(u8, tag.name, "callback")) {
                    try self.parseCallable(allocator);
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseInterface(self: *Parser, allocator: Allocator) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:get-type")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:type-struct")) {
                    // TODO
                } else if (std.mem.startsWith(u8, attr.name, "c:") or std.mem.eql(u8, attr.name, "glib:type-name")) {
                    // no op
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "doc") or std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    _ = try self.parseDoc(allocator); // TODO
                } else if (std.mem.eql(u8, tag.name, "function") or std.mem.eql(u8, tag.name, "method") or std.mem.eql(u8, tag.name, "virtual-method")) {
                    try self.parseCallable(allocator);
                } else if (std.mem.eql(u8, tag.name, "field")) {
                    try self.parseField(allocator);
                } else if (std.mem.eql(u8, tag.name, "prerequisite")) {
                    try self.discardTag(); // TODO
                } else if (std.mem.eql(u8, tag.name, "property")) {
                    try self.parseProperty(allocator);
                } else if (std.mem.eql(u8, tag.name, "glib:signal")) {
                    try self.parseSignal(allocator);
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseMember(self: *Parser, allocator: Allocator) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .closing_tag => return,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "value")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    // TODO
                } else if (std.mem.startsWith(u8, attr.name, "c:") or std.mem.eql(u8, attr.name, "glib:nick") or std.mem.eql(u8, attr.name, "glib:name")) {
                    // no op
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "doc") or std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    _ = try self.parseDoc(allocator); // TODO
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseProperty(self: *Parser, allocator: Allocator) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "construct")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "construct-only")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "default-value")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "introspectable")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "getter")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "readable")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "setter")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "transfer-ownership")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "writable")) {
                    // TODO
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "doc") or std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    _ = try self.parseDoc(allocator); // TODO
                } else if (std.mem.eql(u8, tag.name, "array")) {
                    _ = try self.parseArray(allocator);
                } else if (std.mem.eql(u8, tag.name, "attribute")) {
                    try self.parseAttribute(allocator);
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    _ = try self.parseType(allocator);
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseRecord(self: *Parser, allocator: Allocator) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .closing_tag => return,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name") or std.mem.eql(u8, attr.name, "glib:name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "copy-function")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "introspectable")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "foreign")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "free-function")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "disguised")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "opaque")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "pointer")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:is-gtype-struct-for")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "glib:get-type")) {
                    // TODO
                } else if (std.mem.startsWith(u8, attr.name, "c:") or std.mem.eql(u8, attr.name, "glib:type-name")) {
                    // no op
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "doc") or std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    _ = try self.parseDoc(allocator); // TODO
                } else if (std.mem.eql(u8, tag.name, "field")) {
                    try self.parseField(allocator);
                } else if (std.mem.eql(u8, tag.name, "constructor") or std.mem.eql(u8, tag.name, "function") or std.mem.eql(u8, tag.name, "method")) {
                    try self.parseCallable(allocator);
                } else if (std.mem.eql(u8, tag.name, "union")) {
                    try self.parseUnion(allocator);
                } else if (std.mem.eql(u8, tag.name, "method-inline") or std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseSignal(self: *Parser, allocator: Allocator) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "action")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "detailed")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "introspectable")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "no-hooks")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "no-recurse")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "when")) {
                    // TODO
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "doc") or std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    _ = try self.parseDoc(allocator); // TODO
                } else if (std.mem.eql(u8, tag.name, "return-value")) {
                    try self.parseArg(allocator);
                } else if (std.mem.eql(u8, tag.name, "parameters")) {
                    try self.parseArgs(allocator);
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseType(self: *Parser, allocator: Allocator) Error!gi.Type {
    var _type: gi.Type = try .init(allocator, "type");
    errdefer _type.deinit(allocator);
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => return _type,
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    const name = attr.value;
                    if (std.mem.eql(u8, name, "none")) {
                        _type.tag = .void;
                    } else if (std.mem.eql(u8, name, "gpointer") or std.mem.eql(u8, name, "gconstpointer")) {
                        _type.tag = .void;
                        _type.pointer = true;
                    } else if (std.mem.eql(u8, name, "gboolean")) {
                        _type.tag = .boolean;
                    } else if (std.mem.eql(u8, name, "gint8")) {
                        _type.tag = .int8;
                    } else if (std.mem.eql(u8, name, "guint8")) {
                        _type.tag = .uint8;
                    } else if (std.mem.eql(u8, name, "gint16")) {
                        _type.tag = .int16;
                    } else if (std.mem.eql(u8, name, "guint16")) {
                        _type.tag = .uint16;
                    } else if (std.mem.eql(u8, name, "gint32")) {
                        _type.tag = .int32;
                    } else if (std.mem.eql(u8, name, "guint32")) {
                        _type.tag = .uint32;
                    } else if (std.mem.eql(u8, name, "gint64")) {
                        _type.tag = .int64;
                    } else if (std.mem.eql(u8, name, "guint64")) {
                        _type.tag = .uint64;
                    } else if (std.mem.eql(u8, name, "gchar")) {
                        _type.tag = .int8;
                    } else if (std.mem.eql(u8, name, "guchar")) {
                        _type.tag = .uint8;
                    } else if (std.mem.eql(u8, name, "gshort")) {
                        _type.tag = switch (@sizeOf(c_short)) {
                            2 => .int16,
                            else => unreachable,
                        };
                    } else if (std.mem.eql(u8, name, "gushort")) {
                        _type.tag = switch (@sizeOf(c_ushort)) {
                            2 => .uint16,
                            else => unreachable,
                        };
                    } else if (std.mem.eql(u8, name, "gint")) {
                        _type.tag = switch (@sizeOf(c_int)) {
                            4 => .int32,
                            else => unreachable,
                        };
                    } else if (std.mem.eql(u8, name, "guint")) {
                        _type.tag = switch (@sizeOf(c_uint)) {
                            4 => .uint32,
                            else => unreachable,
                        };
                    } else if (std.mem.eql(u8, name, "glong")) {
                        _type.tag = switch (@sizeOf(c_long)) {
                            4 => .int32,
                            8 => .int64,
                            else => unreachable,
                        };
                    } else if (std.mem.eql(u8, name, "gulong")) {
                        _type.tag = switch (@sizeOf(c_ulong)) {
                            4 => .uint32,
                            8 => .uint64,
                            else => unreachable,
                        };
                    } else if (std.mem.eql(u8, name, "gssize") or std.mem.eql(u8, name, "gintptr")) {
                        _type.tag = switch (@sizeOf(isize)) {
                            4 => .int32,
                            8 => .int64,
                            else => unreachable,
                        };
                    } else if (std.mem.eql(u8, name, "gsize") or std.mem.eql(u8, name, "guintptr")) {
                        _type.tag = switch (@sizeOf(usize)) {
                            4 => .uint32,
                            8 => .uint64,
                            else => unreachable,
                        };
                    } else if (std.mem.eql(u8, name, "time_t")) {
                        _type.tag = switch (@sizeOf(std.c.time_t)) {
                            4 => .int32,
                            8 => .int64,
                            else => unreachable,
                        };
                    } else if (std.mem.eql(u8, name, "gfloat")) {
                        _type.tag = .float;
                    } else if (std.mem.eql(u8, name, "gdouble")) {
                        _type.tag = .double;
                    } else if (std.mem.eql(u8, name, "long double")) {
                        _type.tag = .long_double;
                    } else if (std.mem.eql(u8, name, "utf8")) {
                        _type.tag = .utf8;
                    } else if (std.mem.eql(u8, name, "filename")) {
                        _type.tag = .filename;
                    } else if (std.mem.eql(u8, name, "GLib.List")) {
                        _type.tag = .glist;
                    } else if (std.mem.eql(u8, name, "GLib.SList")) {
                        _type.tag = .gslist;
                    } else if (std.mem.eql(u8, name, "GLib.HashTable")) {
                        _type.tag = .ghash;
                    } else if (std.mem.eql(u8, name, "GLib.Error") or std.mem.eql(u8, name, "Error")) {
                        _type.tag = .@"error";
                    } else if (std.mem.eql(u8, name, "gunichar")) {
                        _type.tag = .unichar;
                    } else if (std.mem.eql(u8, name, "va_list")) {
                        _type.tag = .va_list;
                    } else {
                        var type_name = name;
                        if (std.mem.indexOfScalar(u8, type_name, '.')) |pos| type_name = type_name[pos + 1 ..];
                        if (std.ascii.isLower(type_name[0]) and !std.mem.endsWith(u8, type_name, "_t")) std.log.warn("unknown type name {s}", .{name});
                        _type.tag = .interface;
                        _type.interface = try allocator.create(gi.Base);
                        _type.interface.?.* = try .init(allocator, name);
                    }
                } else if (std.mem.eql(u8, attr.name, "c:type")) {
                    const c_type = attr.value;
                    if (std.mem.endsWith(u8, c_type, "*")) {
                        _type.pointer = true;
                    }
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "array")) {
                    if (_type.param_type == null) {
                        _type.param_type = try allocator.create(gi.Type);
                        _type.param_type.?.* = try self.parseArray(allocator);
                    } else if (_type.param_type_2 == null) {
                        _type.param_type_2 = try allocator.create(gi.Type);
                        _type.param_type_2.?.* = try self.parseArray(allocator);
                    } else unreachable;
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    if (_type.param_type == null) {
                        _type.param_type = try allocator.create(gi.Type);
                        _type.param_type.?.* = try self.parseType(allocator);
                    } else if (_type.param_type_2 == null) {
                        _type.param_type_2 = try allocator.create(gi.Type);
                        _type.param_type_2.?.* = try self.parseType(allocator);
                    } else unreachable;
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    return _type;
}

fn parseUnion(self: *Parser, allocator: Allocator) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    // TODO
                } else if (std.mem.startsWith(u8, attr.name, "c:")) {
                    // no op
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "doc") or std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    _ = try self.parseDoc(allocator); // TODO
                } else if (std.mem.eql(u8, tag.name, "field")) {
                    try self.parseField(allocator);
                } else if (std.mem.eql(u8, tag.name, "constructor") or std.mem.eql(u8, tag.name, "function") or std.mem.eql(u8, tag.name, "method")) {
                    try self.parseCallable(allocator);
                } else if (std.mem.eql(u8, tag.name, "record")) {
                    try self.parseRecord(allocator);
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}
