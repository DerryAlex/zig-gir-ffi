const std = @import("std");
const gi = @import("gi");
const core = gi.core;
const TypeInterface = gi.GObject.TypeInterface;
const PartialEq = @import("eq.zig").PartialEq;

pub const Iface = extern struct {
    parent: TypeInterface,
    cmp_fn: ?*const fn (self: *PartialOrd, rhs: *PartialOrd) PartialOrd.Order = null,
    lt_fn: ?*const fn (self: *PartialOrd, rhs: *PartialOrd) bool = &defaultlt,
    le_fn: ?*const fn (self: *PartialOrd, rhs: *PartialOrd) bool = &defaultLe,
    gt_fn: ?*const fn (self: *PartialOrd, rhs: *PartialOrd) bool = &defaultgt,
    ge_fn: ?*const fn (self: *PartialOrd, rhs: *PartialOrd) bool = &defaultGe,

    pub const Order = enum { lt, eq, gt };

    fn defaultlt(self: *PartialOrd, rhs: *PartialOrd) bool {
        return switch (self.cmp(rhs)) {
            .lt => true,
            .eq, .gt => false,
        };
    }

    fn defaultLe(self: *PartialOrd, rhs: *PartialOrd) bool {
        return switch (self.cmp(rhs)) {
            .lt, .eq => true,
            .gt => false,
        };
    }

    fn defaultgt(self: *PartialOrd, rhs: *PartialOrd) bool {
        return switch (self.cmp(rhs)) {
            .lt, .eq => false,
            .gt => true,
        };
    }

    fn defaultGe(self: *PartialOrd, rhs: *PartialOrd) bool {
        return switch (self.cmp(rhs)) {
            .lt => false,
            .eq, .gt => false,
        };
    }
};

pub const PartialOrd = struct {
    pub const Prerequisites = [_]type{PartialEq};
    pub const Class = Iface;

    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    const getIface = Ext.getIface;

    pub const Order = Iface.Order;

    pub fn cmp(self: *PartialOrd, rhs: *PartialOrd) Order {
        const interface = self.getIface(PartialOrd);
        const cmp_fn = interface.cmp_fn.?;
        return cmp_fn(self, rhs);
    }

    pub fn lt(self: *PartialOrd, rhs: *PartialOrd) bool {
        const interface = self.getIface(PartialOrd);
        const lt_fn = interface.lt_fn.?;
        return lt_fn(self, rhs);
    }

    pub fn le(self: *PartialOrd, rhs: *PartialOrd) bool {
        const interface = self.getIface(PartialOrd);
        const le_fn = interface.le_fn.?;
        return le_fn(self, rhs);
    }

    pub fn gt(self: *PartialOrd, rhs: *PartialOrd) bool {
        const interface = self.getIface(PartialOrd);
        const gt_fn = interface.gt_fn.?;
        return gt_fn(self, rhs);
    }

    pub fn ge(self: *PartialOrd, rhs: *PartialOrd) bool {
        const interface = self.getIface(PartialOrd);
        const ge_fn = interface.ge_fn.?;
        return ge_fn(self, rhs);
    }

    pub fn gType() core.Type {
        return core.registerInterface(PartialOrd, "PartialOrd");
    }
};
