//! XML Parser for GIR Schema

const Parser = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Reader = std.Io.Reader;
const StaticStringMap = std.StaticStringMap;
const Writer = std.Io.Writer;
const assert = std.debug.assert;
const fatal = std.process.fatal;
const Scanner = @import("Scanner.zig");
const gi = @import("../../gi.zig");
const fmt = @import("../../fmt.zig");
const CallbackFormatter = fmt.CallbackFormatter;

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

fn discardAttr(_: Scanner.Attribute) void {}

fn parseAttrBool(value: []const u8) bool {
    return 0 != @as(u1, @intCast(parseAttrInt(value)));
}

fn parseAttrInt(value: []const u8) usize {
    return std.fmt.parseInt(usize, value, 10) catch unreachable;
}

fn parseAttrEnum(comptime T: type, value: []const u8) T {
    return std.meta.stringToEnum(T, value).?;
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

fn parseName(self: *Parser, allocator: Allocator) Error![]const u8 {
    var name: []const u8 = &.{};
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => return name,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    name = try allocator.dupe(u8, attr.value);
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
                if (std.mem.eql(u8, attr.name, "filename") or std.mem.eql(u8, attr.name, "line")) {
                    discardAttr(attr);
                } else if (std.mem.startsWith(u8, attr.name, "xml:")) {
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

fn generateFullDoc(base: *gi.Base, allocator: Allocator, config: struct {
    version: []const u8,
    deprecated_version: []const u8,
    deprecated_doc: []const u8,
}) Allocator.Error!void {
    var aw: Writer.Allocating = .initOwnedSlice(allocator, @constCast(base.doc));
    defer aw.deinit();
    base.doc = &.{};
    if (config.version.len != 0) {
        if (aw.written().len != 0) aw.writer.writeAll("\n") catch return error.OutOfMemory;
        aw.writer.print("@since {s}", .{config.version}) catch return error.OutOfMemory;
    }
    if (base.deprecated) {
        if (aw.written().len != 0) aw.writer.writeAll("\n") catch return error.OutOfMemory;
        aw.writer.writeAll("@deprecated") catch return error.OutOfMemory;
        if (config.deprecated_version.len != 0) aw.writer.print("(since = {s})", .{config.deprecated_version}) catch return error.OutOfMemory;
        aw.writer.print(" {s}", .{config.deprecated_doc}) catch return error.OutOfMemory;
    }
    base.doc = try aw.toOwnedSlice();
}

// -----

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
                    errdefer allocator.free(dep);
                    try namespace.dependencies.append(allocator, dep);
                } else if (std.mem.eql(u8, tag.name, "namespace")) {
                    try self.parseNamespace(allocator, &namespace);
                } else if (std.mem.eql(u8, tag.name, "package")) {
                    try self.discardTag();
                } else if (std.mem.startsWith(u8, tag.name, "c:") or std.mem.startsWith(u8, tag.name, "doc:")) {
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
                    // TODO: namespace version
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
                } else if (std.mem.eql(u8, attr.name, "shared-library")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    // TODO: namespace version
                } else if (std.mem.startsWith(u8, attr.name, "c:")) {
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
                    var alias = try self.parseAlias(allocator);
                    errdefer alias.deinit(allocator);
                    try namespace.infos.append(allocator, .{ .alias = alias });
                } else if (std.mem.eql(u8, tag.name, "bitfield") or std.mem.eql(u8, tag.name, "enumeration")) {
                    const is_flag = std.mem.eql(u8, tag.name, "bitfield");
                    var _enum = try self.parseEnum(allocator);
                    errdefer _enum.deinit(allocator);
                    if (is_flag) {
                        try namespace.infos.append(allocator, .{ .flags = .{ .base = _enum } });
                    } else {
                        try namespace.infos.append(allocator, .{ .@"enum" = _enum });
                    }
                } else if (std.mem.eql(u8, tag.name, "callback")) {
                    var callable = (try self.parseCallable(allocator)).?;
                    errdefer callable.deinit(allocator);
                    try namespace.infos.append(allocator, .{ .callback = .{ .callable = callable } });
                } else if (std.mem.eql(u8, tag.name, "class")) {
                    var object = try self.parseClass(allocator);
                    errdefer object.deinit(allocator);
                    try namespace.infos.append(allocator, .{ .object = object });
                } else if (std.mem.eql(u8, tag.name, "constant")) {
                    var constant = try self.parseConstant(allocator);
                    errdefer constant.deinit(allocator);
                    try namespace.infos.append(allocator, .{ .constant = constant });
                } else if (std.mem.eql(u8, tag.name, "function")) {
                    var _callable = try self.parseCallable(allocator);
                    if (_callable) |*callable| {
                        errdefer callable.deinit(allocator);
                        try namespace.infos.append(allocator, .{ .function = .{ .callable = callable.* } });
                    }
                } else if (std.mem.eql(u8, tag.name, "interface")) {
                    var interface = try self.parseInterface(allocator);
                    errdefer interface.deinit(allocator);
                    try namespace.infos.append(allocator, .{ .interface = interface });
                } else if (std.mem.eql(u8, tag.name, "record") or std.mem.eql(u8, tag.name, "glib:boxed")) {
                    var _struct = try self.parseRecord(allocator, namespace, "");
                    errdefer _struct.deinit(allocator);
                    try namespace.infos.append(allocator, .{ .@"struct" = _struct });
                } else if (std.mem.eql(u8, tag.name, "union")) {
                    var _union = try self.parseUnion(allocator, namespace, "");
                    errdefer _union.deinit(allocator);
                    try namespace.infos.append(allocator, .{ .@"union" = _union });
                } else if (std.mem.eql(u8, tag.name, "docsection")) {
                    try self.discardTag();
                } else if (std.mem.eql(u8, tag.name, "function-inline") or std.mem.eql(u8, tag.name, "function-macro")) {
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
    var alias: gi.Alias = try .init(allocator, "");
    errdefer alias.deinit(allocator);
    var deprecated_doc: []const u8 = &.{};
    defer allocator.free(deprecated_doc);
    var deprecated_version: []const u8 = &.{};
    defer allocator.free(deprecated_version);
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    alias.base.name = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    alias.base.deprecated = parseAttrBool(attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    deprecated_version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.startsWith(u8, attr.name, "c:")) {
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
                if (std.mem.eql(u8, tag.name, "doc")) {
                    alias.base.doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    deprecated_doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    var _type = try self.parseType(allocator);
                    errdefer _type.deinit(allocator);
                    alias.type_info = try allocator.create(gi.Type);
                    alias.type_info.?.* = _type;
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    try generateFullDoc(&alias.base, allocator, .{
        .version = "",
        .deprecated_version = deprecated_version,
        .deprecated_doc = deprecated_doc,
    });
    return alias;
}

fn parseArg(self: *Parser, allocator: Allocator) Error!struct { gi.Arg, bool } {
    var arg: gi.Arg = try .init(allocator, "");
    errdefer arg.deinit(allocator);
    var skip = false;
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    arg.base.name = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "allow-none")) {
                    if (parseAttrBool(attr.value)) {
                        arg.may_be_null = true;
                        arg.optional = true;
                    }
                } else if (std.mem.eql(u8, attr.name, "caller-allocates")) {
                    arg.caller_allocates = parseAttrBool(attr.value);
                } else if (std.mem.eql(u8, attr.name, "closure")) {
                    arg.closure_index = parseAttrInt(attr.value);
                } else if (std.mem.eql(u8, attr.name, "direction")) {
                    arg.direction = parseAttrEnum(gi.Direction, attr.value);
                } else if (std.mem.eql(u8, attr.name, "destroy")) {
                    arg.destroy_index = parseAttrInt(attr.value);
                } else if (std.mem.eql(u8, attr.name, "nullable")) {
                    arg.may_be_null = parseAttrBool(attr.value);
                } else if (std.mem.eql(u8, attr.name, "optional")) {
                    arg.optional = parseAttrBool(attr.value);
                } else if (std.mem.eql(u8, attr.name, "scope")) {
                    arg.scope = parseAttrEnum(gi.ScopeType, attr.value);
                } else if (std.mem.eql(u8, attr.name, "skip")) {
                    skip = parseAttrBool(attr.value);
                } else if (std.mem.eql(u8, attr.name, "transfer-ownership")) {
                    arg.ownership_transfer = parseAttrEnum(gi.Transfer, attr.value);
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
                    arg.base.doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    var _type = try self.parseType(allocator);
                    errdefer _type.deinit(allocator);
                    arg.type_info = try allocator.create(gi.Type);
                    if (arg.direction == .out) {
                        if (_type.pointer_level) |l| {
                            if (l > 1) {
                                _type.pointer_level = l - 1;
                            } else {
                                _type.pointer = false;
                                _type.pointer_level = null;
                                if (_type.tag == .utf8) _type.tag = .uint8;
                            }
                        }
                    }
                    arg.type_info.?.* = _type;
                } else if (std.mem.eql(u8, tag.name, "array")) {
                    var _type = try self.parseArray(allocator);
                    errdefer _type.deinit(allocator);
                    arg.type_info = try allocator.create(gi.Type);
                    arg.type_info.?.* = _type;
                } else if (std.mem.eql(u8, tag.name, "attribute")) {
                    try self.parseAttribute(allocator);
                } else if (std.mem.eql(u8, tag.name, "varargs")) {
                    try self.discardTag();
                    var _type: gi.Type = try .init(allocator, "type");
                    errdefer _type.deinit(allocator);
                    _type.tag = .va_args;
                    arg.type_info = try allocator.create(gi.Type);
                    arg.type_info.?.* = _type;
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    return .{ arg, skip };
}

fn parseArgs(self: *Parser, allocator: Allocator, callable: *gi.Callable) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            else => return fail(token),
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "instance-parameter")) {
                    try self.discardTag();
                    callable.is_method = true;
                } else if (std.mem.eql(u8, tag.name, "parameter")) {
                    var arg, _ = try self.parseArg(allocator);
                    errdefer arg.deinit(allocator);
                    try callable.args.append(allocator, arg);
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
    var length_inited = false;
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
                    _type.array_fixed_size = parseAttrInt(attr.value);
                    length_inited = true;
                } else if (std.mem.eql(u8, attr.name, "length")) {
                    _type.array_length_index = parseAttrInt(attr.value);
                    length_inited = true;
                } else if (std.mem.eql(u8, attr.name, "zero-terminated")) {
                    _type.zero_terminated = parseAttrBool(attr.value);
                    length_inited = true;
                } else if (std.mem.eql(u8, attr.name, "c:type")) {
                    discardAttr(attr);
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    if (_type.array_fixed_size == null) _type.pointer = true;
    if (!length_inited) _type.zero_terminated = true;
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "array")) {
                    var subtype = try self.parseArray(allocator);
                    errdefer subtype.deinit(allocator);
                    if (_type.param_type == null) {
                        _type.param_type = try allocator.create(gi.Type);
                        _type.param_type.?.* = subtype;
                    } else unreachable;
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    var subtype = try self.parseType(allocator);
                    errdefer subtype.deinit(allocator);
                    if (_type.param_type == null) {
                        _type.param_type = try allocator.create(gi.Type);
                        _type.param_type.?.* = subtype;
                    } else unreachable;
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
                    // TODO: attribute
                } else if (std.mem.eql(u8, attr.name, "value")) {
                    // TODO: attribute
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
}

fn parseCallable(self: *Parser, allocator: Allocator) Error!?gi.Callable {
    var callable: gi.Callable = try .init(allocator, "");
    errdefer callable.deinit(allocator);
    var deprecated_doc: []const u8 = &.{};
    defer allocator.free(deprecated_doc);
    var version: []const u8 = &.{};
    defer allocator.free(version);
    var deprecated_version: []const u8 = &.{};
    defer allocator.free(deprecated_version);
    var shadowed = false;
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    callable.base.name = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    callable.base.deprecated = parseAttrBool(attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    deprecated_version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "introspectable")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "invoker")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "moved-to")) {
                    shadowed = true;
                } else if (std.mem.eql(u8, attr.name, "shadowed-by")) {
                    shadowed = true;
                } else if (std.mem.eql(u8, attr.name, "shadows")) {
                    allocator.free(callable.base.name);
                    callable.base.name = &.{};
                    callable.base.name = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "throws")) {
                    callable.can_throw_gerror = parseAttrBool(attr.value);
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "c:identifier")) {
                    callable.symbol = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "c:type")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "glib:async-func")) {
                    // TODO: async
                } else if (std.mem.eql(u8, attr.name, "glib:finish-func")) {
                    // TODO: async
                    callable.flags.is_async = true;
                } else if (std.mem.eql(u8, attr.name, "glib:sync-func")) {
                    // TODO: async
                } else if (std.mem.eql(u8, attr.name, "glib:get-property")) {
                    callable.flags.is_getter = true;
                } else if (std.mem.eql(u8, attr.name, "glib:set-property")) {
                    callable.flags.is_setter = true;
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
                    callable.base.doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "doc-deprecated") or std.mem.eql(u8, tag.name, "doc-version")) {
                    deprecated_doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "attribute")) {
                    try self.parseAttribute(allocator);
                } else if (std.mem.eql(u8, tag.name, "return-value")) {
                    var arg, const skip = try self.parseArg(allocator);
                    defer arg.deinit(allocator);
                    callable.return_type = arg.type_info;
                    arg.type_info = null;
                    callable.may_return_null = arg.may_be_null;
                    callable.skip_return = skip;
                } else if (std.mem.eql(u8, tag.name, "parameters")) {
                    try self.parseArgs(allocator, &callable);
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    try generateFullDoc(&callable.base, allocator, .{
        .version = version,
        .deprecated_version = deprecated_version,
        .deprecated_doc = deprecated_doc,
    });
    if (shadowed) {
        callable.deinit(allocator);
        return null;
    }
    return callable;
}

fn parseClass(self: *Parser, allocator: Allocator) Error!gi.Object {
    var object: gi.Object = try .init(allocator, "");
    errdefer object.deinit(allocator);
    var deprecated_doc: []const u8 = &.{};
    defer allocator.free(deprecated_doc);
    var version: []const u8 = &.{};
    defer allocator.free(version);
    var deprecated_version: []const u8 = &.{};
    defer allocator.free(deprecated_version);
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    object.base.base.name = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "abstract")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    object.base.base.deprecated = parseAttrBool(attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    deprecated_version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "parent")) {
                    var parent: gi.Base = try .init(allocator, attr.value);
                    errdefer parent.deinit(allocator);
                    object.parent = try allocator.create(gi.Base);
                    object.parent.?.* = parent;
                } else if (std.mem.eql(u8, attr.name, "glib:fundamental")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "glib:get-value-func") or std.mem.eql(u8, attr.name, "glib:set-value-func")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "glib:get-type")) {
                    object.base.type_init = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "glib:ref-func") or std.mem.eql(u8, attr.name, "glib:unref-func")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "glib:type-name")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "glib:type-struct")) {
                    var class: gi.Base = try .init(allocator, attr.value);
                    errdefer class.deinit(allocator);
                    object.class_struct = try allocator.create(gi.Base);
                    object.class_struct.?.* = class;
                } else if (std.mem.startsWith(u8, attr.name, "c:")) {
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
                if (std.mem.eql(u8, tag.name, "doc")) {
                    object.base.base.doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    deprecated_doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "constructor") or std.mem.eql(u8, tag.name, "function") or std.mem.eql(u8, tag.name, "method") or std.mem.eql(u8, tag.name, "virtual-method")) {
                    const is_constructor = std.mem.eql(u8, tag.name, "constructor");
                    const is_method = std.mem.eql(u8, tag.name, "method");
                    const is_virtual = std.mem.eql(u8, tag.name, "virtual-method");
                    var _callable = try self.parseCallable(allocator);
                    if (_callable) |*callable| {
                        errdefer callable.deinit(allocator);
                        if (is_constructor) callable.flags.is_constructor = true;
                        if (is_method) callable.flags.is_method = true;
                        if (is_virtual) {
                            try object.vfuncs.append(allocator, .{ .callable = callable.* });
                        } else {
                            try object.methods.append(allocator, .{ .callable = callable.* });
                        }
                    }
                } else if (std.mem.eql(u8, tag.name, "field")) {
                    var field = try self.parseField(allocator);
                    errdefer field.deinit(allocator);
                    try object.fields.append(allocator, field);
                } else if (std.mem.eql(u8, tag.name, "implements")) {
                    const name = try self.parseName(allocator);
                    defer allocator.free(name);
                    var interface: gi.Interface = try .init(allocator, name);
                    errdefer interface.deinit(allocator);
                    try object.interfaces.append(allocator, interface);
                } else if (std.mem.eql(u8, tag.name, "property")) {
                    var property = try self.parseProperty(allocator);
                    errdefer property.deinit(allocator);
                    try object.properties.append(allocator, property);
                } else if (std.mem.eql(u8, tag.name, "glib:signal")) {
                    var signal = try self.parseSignal(allocator);
                    errdefer signal.deinit(allocator);
                    try object.signals.append(allocator, signal);
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    try generateFullDoc(&object.base.base, allocator, .{
        .version = version,
        .deprecated_version = deprecated_version,
        .deprecated_doc = deprecated_doc,
    });
    return object;
}

fn parseConstant(self: *Parser, allocator: Allocator) Error!gi.Constant {
    var constant: gi.Constant = try .init(allocator, "");
    errdefer constant.deinit(allocator);
    var deprecated_doc: []const u8 = &.{};
    defer allocator.free(deprecated_doc);
    var version: []const u8 = &.{};
    defer allocator.free(version);
    var deprecated_version: []const u8 = &.{};
    defer allocator.free(deprecated_version);
    var value_raw_str: []const u8 = &.{};
    defer allocator.free(value_raw_str);
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    constant.base.name = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    constant.base.deprecated = parseAttrBool(attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    deprecated_version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "value")) {
                    value_raw_str = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.startsWith(u8, attr.name, "c:")) {
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
                if (std.mem.eql(u8, tag.name, "doc")) {
                    constant.base.doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    deprecated_doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    var _type = try self.parseType(allocator);
                    defer _type.deinit(allocator);
                    switch (_type.tag) {
                        .boolean => {
                            constant.type_tag = .boolean;
                            if (std.ascii.eqlIgnoreCase(value_raw_str, "true")) {
                                constant.value = .{ .v_boolean = true };
                            } else if (std.ascii.eqlIgnoreCase(value_raw_str, "false")) {
                                constant.value = .{ .v_boolean = false };
                            } else return fail(token);
                        },
                        .int8, .int16, .int32, .int64 => {
                            constant.type_tag = .int64;
                            constant.value = .{ .v_int64 = std.fmt.parseInt(i64, value_raw_str, 10) catch unreachable };
                        },
                        .uint8, .uint16, .uint32, .uint64 => {
                            constant.type_tag = .uint64;
                            constant.value = .{ .v_uint64 = std.fmt.parseInt(u64, value_raw_str, 10) catch unreachable };
                        },
                        .float, .double => {
                            constant.type_tag = .double;
                            constant.value = .{ .v_double = std.fmt.parseFloat(f64, value_raw_str) catch unreachable };
                        },
                        .utf8 => {
                            constant.type_tag = .utf8;
                            constant.value = .{ .v_string = try allocator.dupeZ(u8, value_raw_str) };
                        },
                        .interface => {
                            constant.type_tag = .interface;
                            if (std.fmt.parseInt(i64, value_raw_str, 10)) |v| {
                                constant.type_tag = .int64;
                                constant.value = .{ .v_int64 = v };
                            } else |_| if (std.ascii.eqlIgnoreCase(value_raw_str, "null")) {
                                constant.value = .{ .v_pointer = null };
                            } else return fail(token);
                        },
                        else => unreachable,
                    }
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    try generateFullDoc(&constant.base, allocator, .{
        .version = version,
        .deprecated_version = deprecated_version,
        .deprecated_doc = deprecated_doc,
    });
    return constant;
}

fn parseEnum(self: *Parser, allocator: Allocator) Error!gi.Enum {
    var _enum: gi.Enum = try .init(allocator, "");
    errdefer _enum.deinit(allocator);
    _enum.storage_type = .int32;
    var deprecated_doc: []const u8 = &.{};
    defer allocator.free(deprecated_doc);
    var version: []const u8 = &.{};
    defer allocator.free(version);
    var deprecated_version: []const u8 = &.{};
    defer allocator.free(deprecated_version);
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    _enum.base.base.name = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    _enum.base.base.deprecated = parseAttrBool(attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    deprecated_version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "introspectable")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "glib:error-domain")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "glib:get-type")) {
                    _enum.base.type_init = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "glib:type-name")) {
                    discardAttr(attr);
                } else if (std.mem.startsWith(u8, attr.name, "c:")) {
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
                if (std.mem.eql(u8, tag.name, "doc")) {
                    _enum.base.base.doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    deprecated_doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "function")) {
                    var callable = (try self.parseCallable(allocator)).?;
                    errdefer callable.deinit(allocator);
                    try _enum.methods.append(allocator, .{ .callable = callable });
                } else if (std.mem.eql(u8, tag.name, "member")) {
                    var value = try self.parseMember(allocator);
                    errdefer value.deinit(allocator);
                    try _enum.values.append(allocator, value);
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    try generateFullDoc(&_enum.base.base, allocator, .{
        .version = version,
        .deprecated_version = deprecated_version,
        .deprecated_doc = deprecated_doc,
    });
    return _enum;
}

fn parseField(self: *Parser, allocator: Allocator) Error!gi.Field {
    var field: gi.Field = try .init(allocator, "");
    errdefer field.deinit(allocator);
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    field.base.name = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "bits")) {
                    field.size = parseAttrInt(attr.value);
                } else if (std.mem.eql(u8, attr.name, "introspectable")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "private") or std.mem.eql(u8, attr.name, "readable") or std.mem.eql(u8, attr.name, "writable")) {
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
                if (std.mem.eql(u8, tag.name, "doc")) {
                    field.base.doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    var _type = try self.parseType(allocator);
                    errdefer _type.deinit(allocator);
                    field.type_info = try allocator.create(gi.Type);
                    field.type_info.?.* = _type;
                } else if (std.mem.eql(u8, tag.name, "array")) {
                    var _type = try self.parseArray(allocator);
                    errdefer _type.deinit(allocator);
                    field.type_info = try allocator.create(gi.Type);
                    field.type_info.?.* = _type;
                } else if (std.mem.eql(u8, tag.name, "callback")) {
                    var callable = (try self.parseCallable(allocator)).?;
                    defer callable.deinit(allocator);
                    var callback: gi.Callback = .{ .callable = callable };
                    var aw: Writer.Allocating = .init(allocator);
                    defer aw.deinit();
                    aw.writer.print("{f}", .{CallbackFormatter{ .callback = &callback }}) catch return error.OutOfMemory;
                    const name = try aw.toOwnedSlice();
                    var _type: gi.Type = try .init(allocator, "type");
                    errdefer _type.deinit(allocator);
                    var _interface: gi.Base = try .init(allocator, name);
                    errdefer _interface.deinit(allocator);
                    _type.tag = .interface;
                    _type.interface = try allocator.create(gi.Base);
                    _type.interface.?.* = _interface;
                    _type.interface_is_callback = true;
                    field.type_info = try allocator.create(gi.Type);
                    field.type_info.?.* = _type;
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    return field;
}

fn parseInterface(self: *Parser, allocator: Allocator) Error!gi.Interface {
    var interface: gi.Interface = try .init(allocator, "");
    errdefer interface.deinit(allocator);
    var deprecated_doc: []const u8 = &.{};
    defer allocator.free(deprecated_doc);
    var version: []const u8 = &.{};
    defer allocator.free(version);
    var deprecated_version: []const u8 = &.{};
    defer allocator.free(deprecated_version);
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    interface.base.base.name = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    interface.base.base.deprecated = parseAttrBool(attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    deprecated_version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "glib:get-type")) {
                    interface.base.type_init = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "glib:type-struct")) {
                    var iface: gi.Base = try .init(allocator, attr.value);
                    errdefer iface.deinit(allocator);
                    interface.iface = try allocator.create(gi.Base);
                    interface.iface.?.* = iface;
                } else if (std.mem.eql(u8, attr.name, "glib:type-name")) {
                    discardAttr(attr);
                } else if (std.mem.startsWith(u8, attr.name, "c:")) {
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
                if (std.mem.eql(u8, tag.name, "doc")) {
                    interface.base.base.doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    deprecated_doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "function") or std.mem.eql(u8, tag.name, "method") or std.mem.eql(u8, tag.name, "virtual-method")) {
                    const is_method = std.mem.eql(u8, tag.name, "method");
                    const is_virtual = std.mem.eql(u8, tag.name, "virtual-method");
                    var _callable = try self.parseCallable(allocator);
                    if (_callable) |*callable| {
                        errdefer callable.deinit(allocator);
                        if (is_method) callable.flags.is_method = true;
                        if (is_virtual) {
                            try interface.vfuncs.append(allocator, .{ .callable = callable.* });
                        } else {
                            try interface.methods.append(allocator, .{ .callable = callable.* });
                        }
                    }
                } else if (std.mem.eql(u8, tag.name, "field")) {
                    try self.discardTag(); // TODO
                } else if (std.mem.eql(u8, tag.name, "prerequisite")) {
                    const name = try self.parseName(allocator);
                    defer allocator.free(name);
                    var preq: gi.Interface = try .init(allocator, name);
                    errdefer preq.deinit(allocator);
                    try interface.prerequisites.append(allocator, .{ .interface = preq });
                } else if (std.mem.eql(u8, tag.name, "property")) {
                    var property = try self.parseProperty(allocator);
                    errdefer property.deinit(allocator);
                    try interface.properties.append(allocator, property);
                } else if (std.mem.eql(u8, tag.name, "glib:signal")) {
                    var signal = try self.parseSignal(allocator);
                    errdefer signal.deinit(allocator);
                    try interface.signals.append(allocator, signal);
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    try generateFullDoc(&interface.base.base, allocator, .{
        .version = version,
        .deprecated_version = deprecated_version,
        .deprecated_doc = deprecated_doc,
    });
    return interface;
}

fn parseMember(self: *Parser, allocator: Allocator) Error!gi.Value {
    var value: gi.Value = try .init(allocator, "");
    errdefer value.deinit(allocator);
    var deprecated_doc: []const u8 = &.{};
    defer allocator.free(deprecated_doc);
    var version: []const u8 = &.{};
    defer allocator.free(version);
    var deprecated_version: []const u8 = &.{};
    defer allocator.free(deprecated_version);
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .closing_tag => return value,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    value.base.name = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    value.base.deprecated = parseAttrBool(attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    deprecated_version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "value")) {
                    value.value = std.fmt.parseInt(i64, attr.value, 10) catch unreachable;
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "glib:nick") or std.mem.eql(u8, attr.name, "glib:name")) {
                    discardAttr(attr);
                } else if (std.mem.startsWith(u8, attr.name, "c:")) {
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
                if (std.mem.eql(u8, tag.name, "doc")) {
                    value.base.doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    deprecated_doc = try self.parseDoc(allocator);
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    return value;
}

fn parseProperty(self: *Parser, allocator: Allocator) Error!gi.Property {
    var property: gi.Property = try .init(allocator, "");
    errdefer property.deinit(allocator);
    var deprecated_doc: []const u8 = &.{};
    defer allocator.free(deprecated_doc);
    var version: []const u8 = &.{};
    defer allocator.free(version);
    var deprecated_version: []const u8 = &.{};
    defer allocator.free(deprecated_version);
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    property.base.name = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "construct") or std.mem.eql(u8, attr.name, "construct-only") or std.mem.eql(u8, attr.name, "readable") or std.mem.eql(u8, attr.name, "writable")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "default-value")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    property.base.deprecated = parseAttrBool(attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    deprecated_version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "introspectable")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "getter") or std.mem.eql(u8, attr.name, "setter")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "transfer-ownership")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    version = try allocator.dupe(u8, attr.value);
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
                    property.base.doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    deprecated_doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "array")) {
                    var _type = try self.parseArray(allocator);
                    errdefer _type.deinit(allocator);
                    property.type_info = try allocator.create(gi.Type);
                    property.type_info.?.* = _type;
                } else if (std.mem.eql(u8, tag.name, "attribute")) {
                    try self.parseAttribute(allocator);
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    var _type = try self.parseType(allocator);
                    errdefer _type.deinit(allocator);
                    property.type_info = try allocator.create(gi.Type);
                    property.type_info.?.* = _type;
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    try generateFullDoc(&property.base, allocator, .{
        .version = version,
        .deprecated_version = deprecated_version,
        .deprecated_doc = deprecated_doc,
    });
    return property;
}

fn parseRecord(self: *Parser, allocator: Allocator, namespace: *gi.Namespace, prefix: []const u8) Error!gi.Struct {
    var _struct: gi.Struct = try .init(allocator, "");
    errdefer _struct.deinit(allocator);
    var deprecated_doc: []const u8 = &.{};
    defer allocator.free(deprecated_doc);
    var version: []const u8 = &.{};
    defer allocator.free(version);
    var deprecated_version: []const u8 = &.{};
    defer allocator.free(deprecated_version);
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .closing_tag => return _struct,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name") or std.mem.eql(u8, attr.name, "glib:name")) {
                    if (prefix.len == 0) {
                        @branchHint(.likely);
                        _struct.base.base.name = try allocator.dupe(u8, attr.value);
                    } else {
                        _struct.base.base.name = try std.fmt.allocPrint(allocator, "{s}__{s}", .{ prefix, attr.value });
                    }
                } else if (std.mem.eql(u8, attr.name, "copy-function") or std.mem.eql(u8, attr.name, "free-function")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    _struct.base.base.deprecated = parseAttrBool(attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    deprecated_version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "introspectable")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "foreign")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "disguised")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "opaque")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "pointer")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "glib:is-gtype-struct-for")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "glib:get-type")) {
                    _struct.base.type_init = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "glib:type-name")) {
                    discardAttr(attr);
                } else if (std.mem.startsWith(u8, attr.name, "c:")) {
                    discardAttr(attr);
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    if (_struct.base.base.name.len == 0) {
        @branchHint(.unlikely);
        if (prefix.len != 0) {
            _struct.base.base.name = try std.fmt.allocPrint(allocator, "{s}__{s}", .{ prefix, "s" });
        } else {
            _struct.base.base.name = try allocator.dupe(u8, "s");
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "doc")) {
                    _struct.base.base.doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    deprecated_doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "field")) {
                    var field = try self.parseField(allocator);
                    errdefer field.deinit(allocator);
                    try _struct.fields.append(allocator, field);
                } else if (std.mem.eql(u8, tag.name, "constructor") or std.mem.eql(u8, tag.name, "function") or std.mem.eql(u8, tag.name, "method")) {
                    const is_constructor = std.mem.eql(u8, tag.name, "constructor");
                    const is_method = std.mem.eql(u8, tag.name, "method");
                    var _callable = try self.parseCallable(allocator);
                    if (_callable) |*callable| {
                        errdefer callable.deinit(allocator);
                        if (is_constructor) callable.flags.is_constructor = true;
                        if (is_method) callable.flags.is_method = true;
                        try _struct.methods.append(allocator, .{ .callable = callable.* });
                    }
                } else if (std.mem.eql(u8, tag.name, "union")) {
                    var _union = try self.parseUnion(allocator, namespace, _struct.base.base.name);
                    {
                        errdefer _union.deinit(allocator);
                        try namespace.infos.append(allocator, .{ .@"union" = _union });
                    }

                    const type_name = _union.base.base.name;
                    const field_name = type_name[_struct.base.base.name.len + 2 ..];
                    var field: gi.Field = try .init(allocator, field_name);
                    errdefer field.deinit(allocator);
                    {
                        var _type: gi.Type = try .init(allocator, "type");
                        errdefer _type.deinit(allocator);
                        {
                            var _interface: gi.Base = try .init(allocator, type_name);
                            errdefer _interface.deinit(allocator);
                            _type.tag = .interface;
                            _type.interface = try allocator.create(gi.Base);
                            _type.interface.?.* = _interface;
                        }
                        field.type_info = try allocator.create(gi.Type);
                        field.type_info.?.* = _type;
                    }
                    try _struct.fields.append(allocator, field);
                } else if (std.mem.eql(u8, tag.name, "method-inline") or std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    _struct.size = _struct.fields.items.len * @sizeOf(usize); // FIXME
    try generateFullDoc(&_struct.base.base, allocator, .{
        .version = version,
        .deprecated_version = deprecated_version,
        .deprecated_doc = deprecated_doc,
    });
    return _struct;
}

fn parseSignal(self: *Parser, allocator: Allocator) Error!gi.Signal {
    var signal: gi.Signal = try .init(allocator, "");
    errdefer signal.deinit(allocator);
    var deprecated_doc: []const u8 = &.{};
    defer allocator.free(deprecated_doc);
    var version: []const u8 = &.{};
    defer allocator.free(version);
    var deprecated_version: []const u8 = &.{};
    defer allocator.free(deprecated_version);
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    signal.callable.base.name = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "action")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    signal.callable.base.deprecated = parseAttrBool(attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    deprecated_version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "detailed")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "introspectable")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "no-hooks")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "no-recurse")) {
                    discardAttr(attr);
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.eql(u8, attr.name, "when")) {
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
                if (std.mem.eql(u8, tag.name, "doc")) {
                    signal.callable.base.doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    deprecated_doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "return-value")) {
                    var arg, const skip = try self.parseArg(allocator);
                    defer arg.deinit(allocator);
                    signal.callable.return_type = arg.type_info;
                    arg.type_info = null;
                    signal.callable.may_return_null = arg.may_be_null;
                    signal.callable.skip_return = skip;
                    // patch for signal
                    signal.callable.is_method = true;
                } else if (std.mem.eql(u8, tag.name, "parameters")) {
                    try self.parseArgs(allocator, &signal.callable);
                    // FIXME: enum will be wrongly mark as pointer
                    // patch for signal
                    for (signal.callable.args.items) |*arg| {
                        var _type = arg.type_info.?;
                        if (_type.tag == .interface) _type.pointer = true;
                    }
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    try generateFullDoc(&signal.callable.base, allocator, .{
        .version = version,
        .deprecated_version = deprecated_version,
        .deprecated_doc = deprecated_doc,
    });
    return signal;
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
                    } else if (std.mem.eql(u8, name, "gfloat")) {
                        _type.tag = .float;
                    } else if (std.mem.eql(u8, name, "gdouble")) {
                        _type.tag = .double;
                    } else if (std.mem.eql(u8, name, "long double")) {
                        _type.tag = .long_double;
                    } else if (std.mem.eql(u8, name, "GType")) {
                        _type.tag = .gtype;
                    } else if (std.mem.eql(u8, name, "utf8")) {
                        _type.tag = .utf8;
                        _type.pointer = true;
                    } else if (std.mem.eql(u8, name, "filename")) {
                        _type.tag = .filename;
                        _type.pointer = true;
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
                    } else if (std.mem.eql(u8, name, "time_t")) {
                        _type.tag = .time_t;
                    } else if (std.mem.eql(u8, name, "pid_t")) {
                        _type.tag = .pid_t;
                    } else if (std.mem.eql(u8, name, "uid_t")) {
                        _type.tag = .uid_t;
                    } else {
                        var type_name = name;
                        if (std.mem.indexOfScalar(u8, type_name, '.')) |pos| type_name = type_name[pos + 1 ..];
                        if (std.ascii.isLower(type_name[0]) and !std.mem.endsWith(u8, type_name, "_t")) std.log.warn("unknown type name {s}", .{name});
                        var _interface: gi.Base = try .init(allocator, name);
                        errdefer _interface.deinit(allocator);
                        _type.tag = .interface;
                        _type.interface = try allocator.create(gi.Base);
                        _type.interface.?.* = _interface;
                        if (std.mem.endsWith(u8, type_name, "Func") or std.mem.endsWith(u8, type_name, "Notify")) _type.interface_is_callback = true;
                    }
                } else if (std.mem.eql(u8, attr.name, "c:type")) {
                    const c_type = attr.value;
                    var pointer_level = std.mem.count(u8, c_type, "*");
                    if (std.mem.containsAtLeast(u8, c_type, 1, "pointer")) pointer_level += 1;
                    if (pointer_level > 0) {
                        _type.pointer = true;
                        _type.pointer_level = pointer_level;
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
                    var subtype = try self.parseArray(allocator);
                    errdefer subtype.deinit(allocator);
                    if (_type.param_type == null) {
                        _type.param_type = try allocator.create(gi.Type);
                        _type.param_type.?.* = subtype;
                    } else if (_type.param_type_2 == null) {
                        _type.param_type_2 = try allocator.create(gi.Type);
                        _type.param_type_2.?.* = subtype;
                    } else unreachable;
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    var subtype = try self.parseType(allocator);
                    errdefer subtype.deinit(allocator);
                    if (_type.param_type == null) {
                        _type.param_type = try allocator.create(gi.Type);
                        _type.param_type.?.* = subtype;
                    } else if (_type.param_type_2 == null) {
                        _type.param_type_2 = try allocator.create(gi.Type);
                        _type.param_type_2.?.* = subtype;
                    } else unreachable;
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    return _type;
}

fn parseUnion(self: *Parser, allocator: Allocator, namespace: *gi.Namespace, prefix: []const u8) Error!gi.Union {
    var _union: gi.Union = try .init(allocator, "");
    errdefer _union.deinit(allocator);
    var deprecated_doc: []const u8 = &.{};
    defer allocator.free(deprecated_doc);
    var deprecated_version: []const u8 = &.{};
    defer allocator.free(deprecated_version);
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    if (prefix.len == 0) {
                        @branchHint(.likely);
                        _union.base.base.name = try allocator.dupe(u8, attr.value);
                    } else {
                        _union.base.base.name = try std.fmt.allocPrint(allocator, "{s}__{s}", .{ prefix, attr.value });
                    }
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    _union.base.base.deprecated = parseAttrBool(attr.value);
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    deprecated_version = try allocator.dupe(u8, attr.value);
                } else if (std.mem.startsWith(u8, attr.name, "c:")) {
                    discardAttr(attr);
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
    if (_union.base.base.name.len == 0) {
        @branchHint(.unlikely);
        if (prefix.len != 0) {
            _union.base.base.name = try std.fmt.allocPrint(allocator, "{s}__{s}", .{ prefix, "u" });
        } else {
            _union.base.base.name = try allocator.dupe(u8, "u");
        }
    }
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "doc")) {
                    _union.base.base.doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "doc-deprecated")) {
                    deprecated_doc = try self.parseDoc(allocator);
                } else if (std.mem.eql(u8, tag.name, "field")) {
                    var field = try self.parseField(allocator);
                    errdefer field.deinit(allocator);
                    try _union.fields.append(allocator, field);
                } else if (std.mem.eql(u8, tag.name, "constructor") or std.mem.eql(u8, tag.name, "function") or std.mem.eql(u8, tag.name, "method")) {
                    const is_constructor = std.mem.eql(u8, tag.name, "constructor");
                    const is_method = std.mem.eql(u8, tag.name, "method");
                    var callable = (try self.parseCallable(allocator)).?;
                    errdefer callable.deinit(allocator);
                    if (is_constructor) callable.flags.is_constructor = true;
                    if (is_method) callable.flags.is_method = true;
                    try _union.methods.append(allocator, .{ .callable = callable });
                } else if (std.mem.eql(u8, tag.name, "record")) {
                    var _struct = try self.parseRecord(allocator, namespace, _union.base.base.name);
                    {
                        errdefer _struct.deinit(allocator);
                        try namespace.infos.append(allocator, .{ .@"struct" = _struct });
                    }

                    const type_name = _struct.base.base.name;
                    const field_name = type_name[_union.base.base.name.len + 2 ..];
                    var field: gi.Field = try .init(allocator, field_name);
                    errdefer field.deinit(allocator);
                    {
                        var _type: gi.Type = try .init(allocator, "type");
                        errdefer _type.deinit(allocator);
                        {
                            var _interface: gi.Base = try .init(allocator, type_name);
                            errdefer _interface.deinit(allocator);
                            _type.tag = .interface;
                            _type.interface = try allocator.create(gi.Base);
                            _type.interface.?.* = _interface;
                        }
                        field.type_info = try allocator.create(gi.Type);
                        field.type_info.?.* = _type;
                    }
                    try _union.fields.append(allocator, field);
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
    try generateFullDoc(&_union.base.base, allocator, .{
        .version = "",
        .deprecated_version = deprecated_version,
        .deprecated_doc = deprecated_doc,
    });
    return _union;
}
