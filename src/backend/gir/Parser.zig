//! XML Parser for GIR Schema

const Parser = @This();

const std = @import("std");
const Allocator = std.mem.Allocator;
const StaticStringMap = std.StaticStringMap;
const assert = std.debug.assert;
const fatal = std.process.fatal;
const Scanner = @import("Scanner.zig");

scanner: *Scanner,

pub fn init(scanner: *Scanner) Parser {
    return .{
        .scanner = scanner,
    };
}

pub const Error = Scanner.Error || error{ParseGirFailed};

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

fn parseXmlProlog(self: *Parser) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "version")) {
                    // no op
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
}

fn parseDoc(self: *Parser) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.startsWith(u8, attr.name, "xml:") or std.mem.eql(u8, attr.name, "filename") or std.mem.eql(u8, attr.name, "line")) {
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
            .text => {
                // TODO
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

pub fn parse(self: *Parser, allocator: Allocator) Error!void {
    _ = allocator;
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag => |tag| {
                if (std.mem.eql(u8, tag.name, "xml")) {
                    try self.parseXmlProlog();
                } else if (std.mem.eql(u8, tag.name, "repository")) {
                    try self.parseRepository();
                } else return fail(token);
            },
            .comment => {},
            .end_of_document => return,
            else => return fail(token),
        }
    }
}

fn parseRepository(self: *Parser) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.startsWith(u8, attr.name, "xmlns") or std.mem.eql(u8, attr.name, "version")) {
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
                if (std.mem.eql(u8, tag.name, "include")) {
                    try self.parseInclude();
                } else if (std.mem.eql(u8, tag.name, "namespace")) {
                    try self.parseNamespace();
                } else if (std.mem.eql(u8, tag.name, "package") or std.mem.startsWith(u8, tag.name, "c:") or std.mem.startsWith(u8, tag.name, "doc:")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseInclude(self: *Parser) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    // TODO
                } else return fail(token);
            },
            else => return fail(token),
        }
    }
}

fn parseNamespace(self: *Parser) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "version")) {
                    // TODO
                } else if (std.mem.startsWith(u8, attr.name, "c:") or std.mem.eql(u8, attr.name, "shared-library")) {
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
                if (std.mem.eql(u8, tag.name, "alias")) {
                    try self.parseAlias();
                } else if (std.mem.eql(u8, tag.name, "bitfield") or std.mem.eql(u8, tag.name, "enumeration")) {
                    try self.parseEnum();
                } else if (std.mem.eql(u8, tag.name, "callback")) {
                    try self.parseCallable();
                } else if (std.mem.eql(u8, tag.name, "class")) {
                    try self.parseClass();
                } else if (std.mem.eql(u8, tag.name, "constant")) {
                    try self.parseConstant();
                } else if (std.mem.eql(u8, tag.name, "function")) {
                    try self.parseCallable();
                } else if (std.mem.eql(u8, tag.name, "interface")) {
                    try self.parseInterface();
                } else if (std.mem.eql(u8, tag.name, "record") or std.mem.eql(u8, tag.name, "glib:boxed")) {
                    try self.parseRecord();
                } else if (std.mem.eql(u8, tag.name, "union")) {
                    try self.parseUnion();
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

fn parseAlias(self: *Parser) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
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
                if (std.mem.eql(u8, tag.name, "doc")) {
                    try self.parseDoc();
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    try self.parseType();
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseArg(self: *Parser) Error!void {
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
                    try self.parseDoc();
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    try self.parseType();
                } else if (std.mem.eql(u8, tag.name, "array")) {
                    try self.parseArray();
                } else if (std.mem.eql(u8, tag.name, "attribute")) {
                    try self.parseAttribute();
                } else if (std.mem.eql(u8, tag.name, "varargs")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseArgs(self: *Parser) Error!void {
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
                    try self.parseArg();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseArray(self: *Parser) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "fixed-size")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "length")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "zero-terminated")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "c:type")) {
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
                if (std.mem.eql(u8, tag.name, "array")) {
                    try self.parseArray();
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    try self.parseType();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseAttribute(self: *Parser) Error!void {
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

fn parseCallable(self: *Parser) Error!void {
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
                    try self.parseDoc();
                } else if (std.mem.eql(u8, tag.name, "attribute")) {
                    try self.parseAttribute();
                } else if (std.mem.eql(u8, tag.name, "return-value")) {
                    try self.parseArg();
                } else if (std.mem.eql(u8, tag.name, "parameters")) {
                    try self.parseArgs();
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseClass(self: *Parser) Error!void {
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
                    try self.parseDoc();
                } else if (std.mem.eql(u8, tag.name, "constructor") or std.mem.eql(u8, tag.name, "function") or std.mem.eql(u8, tag.name, "method") or std.mem.eql(u8, tag.name, "virtual-method")) {
                    try self.parseCallable();
                } else if (std.mem.eql(u8, tag.name, "field")) {
                    try self.parseField();
                } else if (std.mem.eql(u8, tag.name, "implements")) {
                    try self.discardTag(); // TODO
                } else if (std.mem.eql(u8, tag.name, "property")) {
                    try self.parseProperty();
                } else if (std.mem.eql(u8, tag.name, "glib:signal")) {
                    try self.parseSignal();
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseConstant(self: *Parser) Error!void {
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
                    try self.parseDoc();
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    try self.parseType();
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseEnum(self: *Parser) Error!void {
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
                    try self.parseDoc();
                } else if (std.mem.eql(u8, tag.name, "function")) {
                    try self.parseCallable();
                } else if (std.mem.eql(u8, tag.name, "member")) {
                    try self.parseMember();
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseField(self: *Parser) Error!void {
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
                    try self.parseDoc();
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    try self.parseType();
                } else if (std.mem.eql(u8, tag.name, "array")) {
                    try self.parseArray();
                } else if (std.mem.eql(u8, tag.name, "callback")) {
                    try self.parseCallable();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseInterface(self: *Parser) Error!void {
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
                    try self.parseDoc();
                } else if (std.mem.eql(u8, tag.name, "function") or std.mem.eql(u8, tag.name, "method") or std.mem.eql(u8, tag.name, "virtual-method")) {
                    try self.parseCallable();
                } else if (std.mem.eql(u8, tag.name, "field")) {
                    try self.parseField();
                } else if (std.mem.eql(u8, tag.name, "prerequisite")) {
                    try self.discardTag(); // TODO
                } else if (std.mem.eql(u8, tag.name, "property")) {
                    try self.parseProperty();
                } else if (std.mem.eql(u8, tag.name, "glib:signal")) {
                    try self.parseSignal();
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseMember(self: *Parser) Error!void {
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
                    try self.parseDoc();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseProperty(self: *Parser) Error!void {
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
                    try self.parseDoc();
                } else if (std.mem.eql(u8, tag.name, "array")) {
                    try self.parseArray();
                } else if (std.mem.eql(u8, tag.name, "attribute")) {
                    try self.parseAttribute();
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    try self.parseType();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseRecord(self: *Parser) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name") or std.mem.eql(u8, attr.name, "glib:name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "deprecated-version")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "disguised")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "opaque")) {
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
                    try self.parseDoc();
                } else if (std.mem.eql(u8, tag.name, "field")) {
                    try self.parseField();
                } else if (std.mem.eql(u8, tag.name, "constructor") or std.mem.eql(u8, tag.name, "function") or std.mem.eql(u8, tag.name, "method")) {
                    try self.parseCallable();
                } else if (std.mem.eql(u8, tag.name, "union")) {
                    try self.parseUnion();
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseSignal(self: *Parser) Error!void {
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
                    try self.parseDoc();
                } else if (std.mem.eql(u8, tag.name, "return-value")) {
                    try self.parseArg();
                } else if (std.mem.eql(u8, tag.name, "parameters")) {
                    try self.parseArgs();
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseType(self: *Parser) Error!void {
    while (true) {
        const token = try self.scanner.next();
        switch (token) {
            .closing_tag => return,
            .opening_tag_end => break,
            .attribute => |attr| {
                if (std.mem.eql(u8, attr.name, "name")) {
                    // TODO
                } else if (std.mem.eql(u8, attr.name, "c:type")) {
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
                if (std.mem.eql(u8, tag.name, "array")) {
                    try self.parseArray();
                } else if (std.mem.eql(u8, tag.name, "type")) {
                    try self.parseType();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}

fn parseUnion(self: *Parser) Error!void {
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
                    try self.parseDoc();
                } else if (std.mem.eql(u8, tag.name, "field")) {
                    try self.parseField();
                } else if (std.mem.eql(u8, tag.name, "constructor") or std.mem.eql(u8, tag.name, "function") or std.mem.eql(u8, tag.name, "method")) {
                    try self.parseCallable();
                } else if (std.mem.eql(u8, tag.name, "record")) {
                    try self.parseRecord();
                } else if (std.mem.eql(u8, tag.name, "source-position")) {
                    try self.discardTag();
                } else return fail(token);
            },
            .comment => {},
            else => return fail(token),
        }
    }
}
