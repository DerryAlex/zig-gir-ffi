const std = @import("std");
const meta = std.meta;
const assert = std.debug.assert;
const Gtk = @import("Gtk.zig");
const core = Gtk.core;
const WidgetClass = Gtk.WidgetClass;

/// Convenience wrapper for gtk_widget_class_bind_template_child
/// Template child should be named `"tc_" ++ name` or `"ti_" ++ name`(internal child)
pub fn bindChild(class: *WidgetClass, comptime Object: type) void {
    inline for (comptime meta.fieldNames(Object)) |name| {
        if (comptime name.len <= 3 or name[0] != 't' or (name[1] != 'c' and name[1] != 'i') or name[2] != '_') continue;
        comptime var name_c: [name.len - 3:0]u8 = undefined;
        comptime std.mem.copy(u8, name_c[0..], name[3..]);
        class.bindTemplateChildFull(&name_c, if (name[1] == 'i') .True else .False, @offsetOf(Object, name));
    }
    if (@hasDecl(Object, "Private")) {
        inline for (comptime meta.fieldNames(Object.Private)) |name| {
            if (comptime name.len <= 3 or name[0] != 't' or (name[1] != 'c' and name[1] != 'i') or name[2] != '_') continue;
            comptime var name_c: [name.len - 3:0]u8 = undefined;
            comptime std.mem.copy(u8, name_c[0..], name[3..]);
            class.bindTemplateChildFull(&name_c, if (name[1] == 'i') .True else .False, @offsetOf(Object.Private, name) + core.typeTag(Object).private_offset);
        }
    }
}

/// Convenience wrapper for gtk_widget_class_bind_template_callback
/// Template callback should be named `"TC" ++ name`
pub fn bindCallback(class: *WidgetClass, comptime Class: type) void {
    inline for (comptime meta.declarations(Class)) |decl| {
        const name = decl.name;
        if (comptime name.len <= 2 or name[0] != 'T' or name[1] != 'C') continue;
        comptime var name_c: [name.len - 2:0]u8 = undefined;
        comptime std.mem.copy(u8, name_c[0..], name[2..]);
        class.bindTemplateCallbackFull(&name_c, @ptrCast(core.Callback, &@field(Class, name)));
    }
}
