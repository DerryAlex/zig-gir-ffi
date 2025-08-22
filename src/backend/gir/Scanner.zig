//! Simple XML Parsing
//!
//! Produces `Token`s from input

const Scanner = @This();

const std = @import("std");
const Reader = std.Io.Reader;
const assert = std.debug.assert;

reader: *Reader,
state: State = .init,

pub const Token = union(enum) {
    /// `<NAME`
    opening_tag: Tag,
    /// `>`
    opening_tag_end,
    /// `</NAME>` or `/>`
    closing_tag: Tag,
    /// `NAME="VALUE"`
    attribute: Attribute,
    /// `TEXT`
    text: []const u8,
    /// `<!--COMMENT-->`
    comment: []const u8,
    end_of_document,

    pub fn format(self: Token, writer: *std.Io.Writer) !void {
        if (self == .opening_tag) {
            try writer.print("tag {s}", .{self.opening_tag.name});
        } else if (self == .attribute) {
            try writer.print("attr {s}=\"{s}\"", .{ self.attribute.name, self.attribute.value });
        } else {
            try writer.print("{t}", .{self});
        }
    }
};

pub const Tag = struct {
    name: []const u8,
    is_prolog: bool,
};

pub const Attribute = struct {
    name: []const u8,
    value: []const u8,
};

const State = enum {
    init,
    element,
};

pub fn init(reader: *Reader) Scanner {
    return .{
        .reader = reader,
    };
}

pub const Error = Reader.DelimiterError;

/// Returns next `Token`.
///
/// Invalidate previous values from `next`.
pub fn next(self: *Scanner) Error!Token {
    switch (self.state) {
        .init => {
            const text = self.reader.peekDelimiterExclusive('<') catch |err| switch (err) {
                error.EndOfStream => return .end_of_document,
                error.StreamTooLong => self.reader.peekGreedy(1) catch unreachable,
                else => return err,
            };
            // EndOfStream is treated as delimiter
            if (self.reader.seek == self.reader.end) return .end_of_document;
            self.reader.toss(text.len);
            // text
            for (text) |c| {
                if (!std.ascii.isWhitespace(c)) {
                    return .{ .text = text };
                }
            }
            // StreamTooLong must be text
            assert(text.len != self.reader.end - self.reader.seek);

            // element
            self.reader.toss(1); // skip '<'
            self.state = .element;
            var is_prolog = false;
            switch (try self.reader.peekByte()) {
                '/' => {
                    // closing
                    self.state = .init;
                    const name = try self.reader.takeDelimiterInclusive('>');
                    return .{ .closing_tag = .{
                        .name = name[1 .. name.len - 1],
                        .is_prolog = is_prolog,
                    } };
                },
                '!' => {
                    // comment
                    const comment = try self.reader.takeDelimiterInclusive('>');
                    assert(std.mem.eql(u8, "--", comment[1..3]));
                    assert(std.mem.eql(u8, "--", comment[comment.len - 3 ..][0..2]));
                    return .{ .comment = comment[3 .. comment.len - 3] };
                },
                '?' => {
                    is_prolog = true;
                    self.reader.toss(1);
                },
                else => {},
            }
            const name = try self.reader.peekDelimiterExclusive(' ');
            self.reader.toss(name.len);
            return .{ .opening_tag = .{
                .name = name,
                .is_prolog = is_prolog,
            } };
        },
        .element => {
            const attributes = try self.reader.peekDelimiterInclusive('>');
            // attribute
            if (std.mem.indexOfScalar(u8, attributes, '=')) |eq_index| {
                const quote_index = std.mem.indexOfScalarPos(u8, attributes, eq_index + 2, '"').?;
                self.reader.toss(quote_index + 1);
                const name = std.mem.trimStart(u8, attributes[0..eq_index], " \t\n\r");
                const value = attributes[eq_index + 2 .. quote_index];
                return .{ .attribute = .{
                    .name = name,
                    .value = value,
                } };
            }

            // element end
            self.state = .init;
            self.reader.toss(attributes.len);
            var is_closing = false;
            var is_prolog = false;
            if (attributes.len >= 2) {
                switch (attributes[attributes.len - 2]) {
                    '/' => {
                        is_closing = true;
                    },
                    '?' => {
                        is_closing = true;
                        is_prolog = true;
                    },
                    else => {},
                }
            }
            if (is_closing) {
                return .{ .closing_tag = .{
                    .name = "",
                    .is_prolog = is_prolog,
                } };
            }
            return .opening_tag_end;
        },
    }
}
