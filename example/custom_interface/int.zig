const std = @import("std");
const root = @import("root");
const Gtk = root.Gtk;
const core = Gtk.core;
const Object = core.Object;
const ObjectClass = core.ObjectClass;
const PartialEq = @import("eq.zig").PartialEq;
const PartialOrd = @import("ord.zig").PartialOrd;

pub const TypedIntClass = extern struct {
    parent: ObjectClass,
};

pub const TypeIntPrivate = struct {
    value: i32,
};

pub const TypedInt = extern struct {
    parent: Parent,
    private: *Private,

    pub const Parent = Object;
    pub const Private = TypeIntPrivate;
    pub const Interfaces = [_]type{ PartialEq, PartialOrd };
    pub usingnamespace core.Extend(TypedInt);

    pub fn new(value: i32) *TypedInt {
        var object = core.newObject(TypedInt, null, null);
        object.private.value = value;
        return object;
    }

    fn eq(self: *PartialEq, rhs: *PartialEq) bool {
        const lhs_value = self.tryInto(TypedInt).?.private.value;
        const rhs_value = rhs.tryInto(TypedInt).?.private.value;
        return lhs_value == rhs_value;
    }

    pub fn initPartialEq(interface: *PartialEq) void {
        interface._eq = &eq;
    }

    fn cmp(self: *PartialOrd, rhs: *PartialOrd) PartialOrd.Order {
        const lhs_value = self.tryInto(TypedInt).?.private.value;
        const rhs_value = rhs.tryInto(TypedInt).?.private.value;
        if (lhs_value == rhs_value) return .Eq;
        return if (lhs_value < rhs_value) .Lt else .Gt;
    }

    pub fn initPartialOrd(interface: *PartialOrd) void {
        interface._cmp = &cmp;
    }

    pub fn @"type"() core.Type {
        return core.registerType(TypedIntClass, TypedInt, "TypedInt", .{});
    }
};
