const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const gobject = gtk.gobject;
const Object = gobject.Object;
const ObjectClass = gobject.ObjectClass;
const PartialEq = @import("eq.zig").PartialEq;
const PartialOrd = @import("ord.zig").PartialOrd;

pub const TypedIntClass = extern struct {
    parent_class: ObjectClass,
};

pub const TypeIntPrivate = struct {
    value: i32,
};

pub const TypedInt = extern struct {
    parent: Parent,
    private: *Private,

    pub const Parent = Object;
    pub const Private = TypeIntPrivate;
    pub const Class = TypedIntClass;
    pub const Interfaces = [_]type{ PartialEq, PartialOrd };
    pub usingnamespace core.Extend(TypedInt);

    pub const Override = struct {
        pub fn eq_fn(self: *PartialEq, rhs: *PartialEq) bool {
            const lhs_value = self.tryInto(TypedInt).?.private.value;
            const rhs_value = rhs.tryInto(TypedInt).?.private.value;
            return lhs_value == rhs_value;
        }

        pub fn cmp_fn(self: *PartialOrd, rhs: *PartialOrd) PartialOrd.Order {
            const lhs_value = self.tryInto(TypedInt).?.private.value;
            const rhs_value = rhs.tryInto(TypedInt).?.private.value;
            if (lhs_value == rhs_value) return .Eq;
            return if (lhs_value < rhs_value) .Lt else .Gt;
        }
    };

    pub fn new(value: i32) *TypedInt {
        var object = core.newObject(TypedInt, .{});
        object.private.value = value;
        return object;
    }

    pub fn gType() core.Type {
        return core.registerType(TypedInt, "TypedInt", .{});
    }
};
