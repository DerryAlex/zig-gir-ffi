const core = @This();
const std = @import("std");
const assert = std.debug.assert;
const GLib = @import("GLib.zig");
const GObject = @import("GObject.zig");

const _type = @import("core/type.zig");
// glib type
pub const Type = _type.Type;
// glib builtin types
pub const List = _type.List;
pub const SList = _type.SList;
pub const Array = _type.Array;
pub const PtrArray = _type.PtrArray;
pub const HashTable = _type.HashTable;

const _cast = @import("core/cast.zig");
pub const isA = _cast.isA;
pub const upCast = _cast.upCast;
pub const downCast = _cast.downCast;
pub const dynamicCast = _cast.dynamicCast;
pub const unsafeCast = _cast.unsafeCast;

const _value = @import("core/value.zig");
pub const Value = _value.Value;

const _closure = @import("core/closure.zig");
pub const Closure = _closure.Closure;

const _property = @import("core/property.zig");
pub const Property = _property.Property;

const _signal = @import("core/signal.zig");
pub const Signal = _signal.Signal;
pub const SimpleSignal = _signal.SimpleSignal;
pub const HandlerId = _signal.HandlerId;

/// Inherits from Self.Parent
pub fn Extend(comptime Self: type) type {
    return struct {
        /// Converts to base type T
        pub fn into(self: *Self, comptime T: type) *T {
            return upCast(T, self);
        }

        /// Converts to derived type T
        pub fn tryInto(self: *Self, comptime T: type) ?*T {
            return downCast(T, self);
        }

        /// Converted from derived type
        ///
        /// Safety: It is the caller's responsibility to ensure that the cast is legal.
        pub fn from(object: anytype) *Self {
            const O = std.meta.Child(@TypeOf(object));
            if (comptime isA(Self)(O)) {
                return upCast(Self, object);
            } else if (comptime isA(O)(Self)) {
                return downCast(Self, object).?;
            } else {
                @compileError(std.fmt.comptimePrint("{s} cannot be cast to {s}", .{ @typeName(O), @typeName(Self) }));
            }
        }

        /// Converted from base type
        pub fn tryFrom(object: anytype) ?*Self {
            return object.tryInto(Self);
        }

        /// Returns the class of a given object
        pub fn getClass(self: *Self, comptime Object: type) *Object.Class {
            const instance = unsafeCast(GObject.TypeInstance, upCast(Object, self));
            const class = instance.g_class.?;
            return unsafeCast(Object.Class, class);
        }

        /// Returns the parent class of a given object
        pub fn getParentClass(self: *Self, comptime Object: type) *Object.Class {
            const instance = unsafeCast(GObject.TypeInstance, upCast(Object, self));
            const class = instance.g_class.?;
            const p_class = class.peekParent();
            return unsafeCast(Object.Class, p_class);
        }

        /// Returns the interface of a given instance
        pub fn getIface(self: *Self, comptime Interface: type) *Interface.Class {
            const instance = unsafeCast(GObject.TypeInstance, upCast(Interface, self));
            const class = instance.g_class.?;
            const interface = GObject.TypeInterface.peek(class, .from(Interface)).?;
            return unsafeCast(Interface.Class, interface);
        }
    };
}

// --------------
// subclass begin

/// Creates a new instance of an `Object` subtype.
pub fn newObject(comptime T: type) *T {
    const cFn = @extern(*const fn (Type, ?[*:0]const u8, ...) callconv(.c) *GObject.Object, .{ .name = "g_object_new" });
    return unsafeCast(T, cFn(.from(T), null));
}

/// Type-specific data
const TypeTag = struct {
    type_id: Type = .invalid,
    private_offset: c_int = 0,
};

/// Storage for the type-specific data
pub fn typeTag(comptime Object: type) *TypeTag {
    const Static = struct {
        comptime {
            _ = Object;
        }

        var tag = TypeTag{};
    };
    return &Static.tag;
}

/// Initializes all fields of the struct with their default value.
fn initStruct(comptime T: type, value: *T) void {
    const info = @typeInfo(T).@"struct";
    inline for (info.fields) |field| {
        if (field.default_value_ptr) |default_value_ptr| {
            const default_value = @as(*align(1) const field.type, @ptrCast(default_value_ptr)).*;
            @field(value, field.name) = default_value;
        }
    }
}

/// Registers a new static type
pub fn registerType(comptime Object: type, name: [*:0]const u8, flags: GObject.TypeFlags) Type {
    if (@hasDecl(Object, "Override")) {
        checkOverride(Object, Object.Override);
    }
    const Class: type = Object.Class;
    const class_init = struct {
        fn trampoline(class: *Class) callconv(.c) void {
            if (typeTag(Object).private_offset != 0) {
                _ = GObject.TypeClass.adjustPrivateOffset(class, &typeTag(Object).private_offset);
            }
            initStruct(Class, class);
            if (comptime @hasDecl(Object, "Override")) {
                overrideClass(Object, Object.Override, class);
            }
            if (comptime @hasDecl(Class, "init")) {
                class.init();
            }
        }
    }.trampoline;
    const instance_init = struct {
        fn trampoline(self: *Object) callconv(.c) void {
            if (comptime @hasDecl(Object, "Private")) {
                self.private = @ptrFromInt(@as(usize, @bitCast(@as(isize, @bitCast(@intFromPtr(self))) + typeTag(Object).private_offset)));
                initStruct(Object.Private, self.private);
            }
            initStruct(Object, self);
            if (comptime @hasDecl(Object, "init")) {
                self.init();
            }
        }
    }.trampoline;
    if (GLib.Once.initEnter(&typeTag(Object).type_id)) {
        var info: GObject.TypeInfo = .{
            .class_size = @sizeOf(Class),
            .base_init = null,
            .base_finalize = null,
            .class_init = @ptrCast(&class_init),
            .class_finalize = null,
            .class_data = null,
            .instance_size = @sizeOf(Object),
            .n_preallocs = 0,
            .instance_init = @ptrCast(&instance_init),
            .value_table = null,
        };
        const type_id = GObject.typeRegisterStatic(.from(Object.Parent), name, &info, flags);
        if (@hasDecl(Object, "Private")) {
            typeTag(Object).private_offset = GObject.typeAddInstancePrivate(type_id, @sizeOf(Object.Private));
        }
        if (@hasDecl(Object, "Override") and @hasDecl(Object, "Interfaces")) {
            inline for (Object.Interfaces) |Interface| {
                overrideInterface(Interface, Object.Override, type_id);
            }
        }
        GLib.Once.initLeave(&typeTag(Object).type_id, @intFromEnum(type_id));
    }
    return typeTag(Object).type_id;
}

fn overrideClass(comptime Object: type, comptime Override: type, class: *Object.Class) void {
    const Class = Object.Class;
    inline for (comptime std.meta.declarations(Override)) |decl| {
        if (@hasField(Class, decl.name)) {
            @field(class, decl.name) = @field(Override, decl.name);
        }
    }
    if (@hasDecl(Object, "Parent")) {
        overrideClass(Object.Parent, Override, @ptrCast(class));
    }
}

fn overrideInterface(comptime Interface: type, comptime Override: type, type_id: Type) void {
    const Class = Interface.Class;
    const interface_init = struct {
        pub fn trampoline(interface: *Class) callconv(.c) void {
            inline for (comptime std.meta.declarations(Override)) |decl| {
                if (@hasField(Class, decl.name)) {
                    @field(interface, decl.name) = @field(Override, decl.name);
                }
            }
        }
    }.trampoline;
    var info: GObject.InterfaceInfo = .{
        .interface_init = @ptrCast(&interface_init),
        .interface_finalize = null,
        .interface_data = null,
    };
    GObject.typeAddInterfaceStatic(type_id, .from(Interface), &info);
}

fn checkOverride(comptime Object: type, comptime Override: type) void {
    comptime {
        const decls = std.meta.declarations(Override);
        var overriden_count = [_]usize{0} ** decls.len;
        if (@hasDecl(Object, "Interfaces")) {
            for (Object.Interfaces) |Interface| {
                const Class = Interface.Class;
                for (decls, 0..) |decl, idx| {
                    if (@hasField(Class, decl.name)) {
                        overriden_count[idx] += 1;
                    }
                }
            }
        }
        var T: type = Object;
        while (true) {
            if (@hasDecl(T, "Class")) {
                const Class: type = T.Class;
                for (decls, 0..) |decl, idx| {
                    if (@hasField(Class, decl.name)) {
                        overriden_count[idx] += 1;
                    }
                }
                if (T != GObject.InitiallyUnowned and @hasDecl(T, "Parent")) {
                    T = T.Parent;
                } else {
                    break;
                }
            }
        }
        for (overriden_count, 0..) |count, idx| {
            if (count == 0) {
                @compileError("'" ++ decls[idx].name ++ "' does not override any method");
            }
            if (count > 1) {
                @compileError("'" ++ decls[idx].name ++ "' overrides multiple methods");
            }
        }
    }
}

/// Registers a new static type
pub fn registerInterface(comptime Interface: type, name: [*:0]const u8) Type {
    const Class: type = Interface.Class;
    const class_init = struct {
        pub fn trampoline(class: *Class) callconv(.c) void {
            initStruct(Class, class);
            if (comptime @hasDecl(Interface, "init")) {
                class.init();
            }
        }
    }.trampoline;
    if (GLib.Once.initEnter(&typeTag(Interface).type_id)) {
        var info: GObject.TypeInfo = .{
            .class_size = @sizeOf(Class),
            .base_init = null,
            .base_finalize = null,
            .class_init = @ptrCast(&class_init),
            .class_finalize = null,
            .class_data = null,
            .instance_size = 0,
            .n_preallocs = 0,
            .instance_init = null,
            .value_table = null,
        };
        const type_id = GObject.typeRegisterStatic(.interface, name, &info, .{});
        if (comptime @hasDecl(Interface, "Prerequisites")) {
            inline for (Interface.Prerequisites) |Prerequisite| {
                GObject.TypeInterface.addPrerequisite(type_id, .from(Prerequisite));
            }
        }
        GLib.Once.initLeave(&typeTag(Interface).type_id, @intFromEnum(type_id));
    }
    return typeTag(Interface).type_id;
}

// subclass end
// ------------
