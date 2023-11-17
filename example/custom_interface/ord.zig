const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const TypeInterface = core.TypeInterface;
const PartialEq = @import("eq.zig").PartialEq;

pub const PartialOrd = extern struct {
    parent: TypeInterface,
    _cmp: ?*const fn (self: *PartialOrd, rhs: *PartialOrd) Order = null,
    _lt: ?*const fn (self: *PartialOrd, rhs: *PartialOrd) bool = &defaultLt,
    _le: ?*const fn (self: *PartialOrd, rhs: *PartialOrd) bool = &defaultLe,
    _gt: ?*const fn (self: *PartialOrd, rhs: *PartialOrd) bool = &defaultGt,
    _ge: ?*const fn (self: *PartialOrd, rhs: *PartialOrd) bool = &defaultGe,

    pub const Prerequisites = [_]type{PartialEq};
    pub usingnamespace core.Extend(PartialOrd);

    pub const Order = enum { Lt, Eq, Gt };

    pub fn cmp(self: *PartialOrd, rhs: *PartialOrd) Order {
        const interface = core.typeInstanceGetInterface(PartialOrd, self);
        const cmp_fn = interface._cmp.?;
        return cmp_fn(self, rhs);
    }

    pub fn lt(self: *PartialOrd, rhs: *PartialOrd) bool {
        const interface = core.typeInstanceGetInterface(PartialOrd, self);
        const lt_fn = interface._lt.?;
        return lt_fn(self, rhs);
    }

    pub fn le(self: *PartialOrd, rhs: *PartialOrd) bool {
        const interface = core.typeInstanceGetInterface(PartialOrd, self);
        const le_fn = interface._le.?;
        return le_fn(self, rhs);
    }

    pub fn gt(self: *PartialOrd, rhs: *PartialOrd) bool {
        const interface = core.typeInstanceGetInterface(PartialOrd, self);
        const gt_fn = interface._gt.?;
        return gt_fn(self, rhs);
    }

    pub fn ge(self: *PartialOrd, rhs: *PartialOrd) bool {
        const interface = core.typeInstanceGetInterface(PartialOrd, self);
        const ge_fn = interface._ge.?;
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

    pub fn @"type"() core.Type {
        return core.registerInterface(PartialOrd, "PartialOrd");
    }
};
