const std = @import("std");
const gi = @import("gi");
const core = gi.core;
const TypeInterface = gi.GObject.TypeInterface;

pub const Iface = extern struct {
    parent: TypeInterface,
    eq_fn: ?*const fn (self: *PartialEq, rhs: *PartialEq) bool = null,
    ne_fn: ?*const fn (self: *PartialEq, rhs: *PartialEq) bool = &defaultNe,

    fn defaultNe(self: *PartialEq, rhs: *PartialEq) bool {
        return !self.eq(rhs);
    }
};

pub const PartialEq = extern struct {
    pub const Class = Iface;

    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    const getIface = Ext.getIface;

    pub fn eq(self: *PartialEq, rhs: *PartialEq) bool {
        const interface = self.getIface(PartialEq);
        const eq_fn = interface.eq_fn.?;
        return eq_fn(self, rhs);
    }

    pub fn ne(self: *PartialEq, rhs: *PartialEq) bool {
        const interface = self.getIface(PartialEq);
        const ne_fn = interface.ne_fn.?;
        return ne_fn(self, rhs);
    }

    pub fn gType() core.Type {
        return core.registerInterface(PartialEq, "PartialEq");
    }
};
