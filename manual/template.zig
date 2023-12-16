const std = @import("std");
const meta = std.meta;
const assert = std.debug.assert;
const Gtk = @import("Gtk.zig");
const core = Gtk.core;
const WidgetClass = Gtk.WidgetClass;

pub const BindingZ = struct {
    name: [:0]const u8,
    symbol: ?[]const u8 = null,
    internal: bool = false,
};

pub fn bindChild(class: *WidgetClass, comptime Object: type, comptime bindings: ?[]const BindingZ, comptime private_bindings: ?[]const BindingZ) void {
    if (bindings) |some| {
        inline for (some) |binding| {
            const name = binding.name;
            const symbol = binding.symbol orelse binding.name;
            class.bindTemplateChildFull(name.ptr, binding.internal, @offsetOf(Object, symbol));
        }
    }
    if (private_bindings) |some| {
        inline for (some) |binding| {
            const name = binding.name;
            const symbol = binding.symbol orelse binding.name;
            class.bindTemplateChildFull(name.ptr, binding.internal, @offsetOf(Object.Private, symbol) + core.typeTag(Object).private_offset);
        }
    }
}

pub fn bindCallback(class: *WidgetClass, comptime Class: type, comptime bindings: []const BindingZ) void {
    inline for (bindings) |binding| {
        const name = binding.name;
        const symbol = binding.symbol orelse binding.name;
        class.bindTemplateCallbackFull(name.ptr, @ptrCast(&@field(Class, symbol)));
    }
}
