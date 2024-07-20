const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const gobject = gtk.gobject;
const TypeInterface = gobject.TypeInterface;

pub const PartialEq = extern struct {
    parent: TypeInterface,
    eq_fn: ?*const fn (self: *PartialEq, rhs: *PartialEq) bool = null,
    ne_fn: ?*const fn (self: *PartialEq, rhs: *PartialEq) bool = &defaultNe,

    pub fn eq(self: *PartialEq, rhs: *PartialEq) bool {
        const interface = core.typeInstanceGetInterface(PartialEq, self);
        const eq_fn = interface.eq_fn.?;
        return eq_fn(self, rhs);
    }

    pub fn ne(self: *PartialEq, rhs: *PartialEq) bool {
        const interface = core.typeInstanceGetInterface(PartialEq, self);
        const ne_fn = interface.ne_fn.?;
        return ne_fn(self, rhs);
    }

    fn defaultNe(self: *PartialEq, rhs: *PartialEq) bool {
        return !self.eq(rhs);
    }

    pub fn into(self: *PartialEq, comptime T: type) *T {
        return core.upCast(T, self);
    }

    pub fn tryInto(self: *PartialEq, comptime T: type) ?*T {
        return core.downCast(T, self);
    }

    pub fn __method__(self: *PartialEq) core.MethodMixin(PartialEq) {
        return .{ .self = self };
    }

    pub fn gType() core.Type {
        return core.registerInterface(PartialEq, "PartialEq");
    }
};
