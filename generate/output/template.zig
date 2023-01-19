const std = @import("std");
const meta = std.meta;
const assert = std.debug.assert;
const Gtk = @import("Gtk.zig");
const core = Gtk.core;

/// Convenience wrapper for gtk_widget_class_bind_template_child
/// Template child should be named `"TC" ++ name`
pub fn bindChild(class: *Gtk.WidgetClass, comptime Impl: type) void {
    inline for (comptime meta.fieldNames(Impl)) |name| {
        if (comptime name.len <= 2 or name[0] != 'T' or name[1] != 'C') continue;
        comptime var name_c: [name.len - 2:0]u8 = undefined;
        comptime std.mem.copy(u8, name_c[0..], name[2..]);
        class.bindTemplateChildFull(&name_c, core.Boolean.False, @offsetOf(Impl, name));
    }
}

/// Convenience wrapper for gtk_widget_class_bind_template_callback
/// Template callback should be named `"TC" ++ name`
pub fn bindCallback(class: *Gtk.WidgetClass, comptime Class: type) void {
    inline for (comptime meta.declarations(Class)) |decl| {
        const name = decl.name;
        if (comptime name.len <= 2 or name[0] != 'T' or name[1] != 'C') continue;
        // if (comptime !decl.is_pub) {
        //     @compileLog(decl.name, "should be public");
        //     continue;
        // }
        comptime var name_c: [name.len - 2:0]u8 = undefined;
        comptime std.mem.copy(u8, name_c[0..], name[2..]);
        class.bindTemplateCallbackFull(&name_c, @ptrCast(core.Callback, &@field(Class, name)));
    }
}