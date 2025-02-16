const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const gobject = gtk.gobject;
const TypeInterface = gobject.TypeInterface;

pub const PartialEq = extern struct {
    parent: TypeInterface,
    eq_fn: ?*const fn (self: *PartialEq, rhs: *PartialEq) bool = null,
    ne_fn: ?*const fn (self: *PartialEq, rhs: *PartialEq) bool = &defaultNe,

    const Ext = core.Extend(@This());
    pub const __call = Ext.__call;
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub const getInterface = Ext.getInterface;

    pub fn eq(self: *PartialEq, rhs: *PartialEq) bool {
        const interface = self.getInterface(PartialEq);
        const eq_fn = interface.eq_fn.?;
        return eq_fn(self, rhs);
    }

    pub fn ne(self: *PartialEq, rhs: *PartialEq) bool {
        const interface = self.getInterface(PartialEq);
        const ne_fn = interface.ne_fn.?;
        return ne_fn(self, rhs);
    }

    fn defaultNe(self: *PartialEq, rhs: *PartialEq) bool {
        return !self.eq(rhs);
    }

    pub fn gType() core.Type {
        return core.registerInterface(PartialEq, "PartialEq");
    }
};
