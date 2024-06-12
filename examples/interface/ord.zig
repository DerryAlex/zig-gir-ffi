const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const gobject = gtk.gobject;
const TypeInterface = gobject.TypeInterface;
const PartialEq = @import("eq.zig").PartialEq;

pub const PartialOrd = extern struct {
    parent: TypeInterface,
    cmp_fn: ?*const fn (self: *PartialOrd, rhs: *PartialOrd) Order = null,
    lt_fn: ?*const fn (self: *PartialOrd, rhs: *PartialOrd) bool = &defaultLt,
    le_fn: ?*const fn (self: *PartialOrd, rhs: *PartialOrd) bool = &defaultLe,
    gt_fn: ?*const fn (self: *PartialOrd, rhs: *PartialOrd) bool = &defaultGt,
    ge_fn: ?*const fn (self: *PartialOrd, rhs: *PartialOrd) bool = &defaultGe,

    pub const Prerequisites = [_]type{PartialEq};
    pub usingnamespace core.Extend(PartialOrd);

    pub const Order = enum { Lt, Eq, Gt };

    pub fn cmp(self: *PartialOrd, rhs: *PartialOrd) Order {
        const interface = core.typeInstanceGetInterface(PartialOrd, self);
        const cmp_fn = interface.cmp_fn.?;
        return cmp_fn(self, rhs);
    }

    pub fn lt(self: *PartialOrd, rhs: *PartialOrd) bool {
        const interface = core.typeInstanceGetInterface(PartialOrd, self);
        const lt_fn = interface.lt_fn.?;
        return lt_fn(self, rhs);
    }

    pub fn le(self: *PartialOrd, rhs: *PartialOrd) bool {
        const interface = core.typeInstanceGetInterface(PartialOrd, self);
        const le_fn = interface.le_fn.?;
        return le_fn(self, rhs);
    }

    pub fn gt(self: *PartialOrd, rhs: *PartialOrd) bool {
        const interface = core.typeInstanceGetInterface(PartialOrd, self);
        const gt_fn = interface.gt_fn.?;
        return gt_fn(self, rhs);
    }

    pub fn ge(self: *PartialOrd, rhs: *PartialOrd) bool {
        const interface = core.typeInstanceGetInterface(PartialOrd, self);
        const ge_fn = interface.ge_fn.?;
        return ge_fn(self, rhs);
    }

    fn defaultLt(self: *PartialOrd, rhs: *PartialOrd) bool {
        return switch (self.cmp(rhs)) {
            .Lt => true,
            .Eq, .Gt => false,
        };
    }

    fn defaultLe(self: *PartialOrd, rhs: *PartialOrd) bool {
        return switch (self.cmp(rhs)) {
            .Lt, .Eq => true,
            .Gt => false,
        };
    }

    fn defaultGt(self: *PartialOrd, rhs: *PartialOrd) bool {
        return switch (self.cmp(rhs)) {
            .Lt, .Eq => false,
            .Gt => true,
        };
    }

    fn defaultGe(self: *PartialOrd, rhs: *PartialOrd) bool {
        return switch (self.cmp(rhs)) {
            .Lt => false,
            .Eq, .Gt => false,
        };
    }

    pub fn gType() core.Type {
        return core.registerInterface(PartialOrd, "PartialOrd");
    }
};
