const std = @import("std");
const core = @import("core.zig");
const gobject = @import("gobject.zig");

fn isHandle(T: std.builtin.Type) bool {
    if (T != .pointer) return false;
    const child = @typeInfo(T.pointer.child);
    if (child != .@"struct") return false;
    const fields = child.@"struct".fields;
    if (fields.len != 1) return false;
    return fields[0].type == c_int;
}

pub const expect = std.testing.expect;

pub fn isAbiCompatitable(comptime U: type, comptime V: type) bool {
    var typeinfo_u = @typeInfo(U);
    var typeinfo_v = @typeInfo(V);

    if (typeinfo_u == .@"opaque" or typeinfo_v == .@"opaque") return true;
    if (typeinfo_u == .@"struct" and @sizeOf(U) == 0 and @hasField(U, "skip_zig_test")) return true;
    if (typeinfo_v == .@"struct" and @sizeOf(V) == 0 and @hasField(V, "skip_zig_test")) return true;

    if (typeinfo_u == .noreturn) {
        typeinfo_u = @typeInfo(void);
    }
    if (typeinfo_v == .noreturn) {
        typeinfo_v = @typeInfo(void);
    }

    if (typeinfo_u == .optional and @typeInfo(typeinfo_u.optional.child) == .pointer) {
        typeinfo_u = @typeInfo(typeinfo_u.optional.child);
    }
    if (typeinfo_v == .optional and @typeInfo(typeinfo_v.optional.child) == .pointer) {
        typeinfo_v = @typeInfo(typeinfo_v.optional.child);
    }

    if (typeinfo_u == .pointer and typeinfo_u.pointer.size == .One and @typeInfo(typeinfo_u.pointer.child) == .array) {
        typeinfo_u = @typeInfo([*]@typeInfo(typeinfo_u.pointer.child).array.child);
    }
    if (typeinfo_v == .pointer and typeinfo_v.pointer.size == .One and @typeInfo(typeinfo_v.pointer.child) == .array) {
        typeinfo_v = @typeInfo([*]@typeInfo(typeinfo_v.pointer.child).array.child);
    }

    if (typeinfo_u == .@"enum") {
        typeinfo_u = @typeInfo(typeinfo_u.@"enum".tag_type);
    }
    if (typeinfo_v == .@"enum") {
        typeinfo_v = @typeInfo(typeinfo_v.@"enum".tag_type);
    }
    if (typeinfo_u == .@"struct" and typeinfo_u.@"struct".layout == .@"packed") {
        typeinfo_u = @typeInfo(typeinfo_u.@"struct".backing_integer.?);
    }
    if (typeinfo_v == .@"struct" and typeinfo_v.@"struct".layout == .@"packed") {
        typeinfo_v = @typeInfo(typeinfo_v.@"struct".backing_integer.?);
    }

    if (typeinfo_u == .bool) {
        typeinfo_u = @typeInfo(c_int);
    }
    if (typeinfo_v == .bool) {
        typeinfo_v = @typeInfo(c_int);
    }

    if (isHandle(typeinfo_u) and typeinfo_v == .int) return true;
    if (isHandle(typeinfo_v) and typeinfo_u == .int) return true;

    if (@as(std.builtin.TypeId, typeinfo_u) != @as(std.builtin.TypeId, typeinfo_v)) return false;

    switch (typeinfo_u) {
        .type, .void, .bool, .comptime_float, .comptime_int => return true,
        .int => {
            const intinfo_u = typeinfo_u.int;
            const intinfo_v = typeinfo_v.int;
            if (intinfo_u.bits != intinfo_v.bits) return false;
            if (intinfo_u.signedness != intinfo_v.signedness) {
                // char and flags may be translated as unsigned
                if (intinfo_u.bits != 8 and intinfo_u.bits != 32) return false;
            }
            return true;
        },
        .float => return typeinfo_u.float.bits == typeinfo_v.float.bits,
        .pointer => {
            const pointerinfo_u = typeinfo_u.pointer;
            const pointerinfo_v = typeinfo_v.pointer;
            if (pointerinfo_u.size != .C and pointerinfo_v.size != .C) {
                var has_anyopaque = false;
                if (pointerinfo_u.size == .One and @typeInfo(pointerinfo_u.child) == .@"opaque") has_anyopaque = true;
                if (pointerinfo_v.size == .One and @typeInfo(pointerinfo_v.child) == .@"opaque") has_anyopaque = true;
                if (!has_anyopaque) {
                    if (pointerinfo_u.size != pointerinfo_v.size) return false;
                    if ((pointerinfo_u.sentinel == null) != (pointerinfo_v.sentinel == null)) return false;
                }
            } else {
                if (pointerinfo_u.size == .Slice or pointerinfo_v.size == .Slice) return false;
            }
            return isAbiCompatitable(pointerinfo_u.child, pointerinfo_v.child);
        },
        .array => {
            const arrayinfo_u = typeinfo_u.array;
            const arrayinfo_v = typeinfo_v.array;
            return arrayinfo_u.len == arrayinfo_v.len and isAbiCompatitable(arrayinfo_u.child, arrayinfo_v.child);
        },
        .@"struct" => return typeinfo_u.@"struct".layout == typeinfo_v.@"struct".layout and @sizeOf(U) == @sizeOf(V),
        .optional => return isAbiCompatitable(typeinfo_u.optional.child, typeinfo_v.optional.child),
        .@"enum" => return U == V,
        .@"union" => return typeinfo_u.@"union".layout == typeinfo_v.@"union".layout and @sizeOf(U) == @sizeOf(V),
        .@"fn" => {
            const fninfo_u = typeinfo_u.@"fn";
            const fninfo_v = typeinfo_v.@"fn";
            // if (fninfo_u.calling_convention != fninfo_v.calling_convention) return false;
            if (!fninfo_u.is_var_args and !fninfo_v.is_var_args) {
                if (fninfo_u.params.len != fninfo_v.params.len) return false;
            }
            const params_len = if (fninfo_u.params.len <= fninfo_v.params.len) fninfo_u.params.len else fninfo_v.params.len;
            if (params_len == 0) return true; // cairo_image_surface_create
            inline for (0..params_len) |idx| {
                if (!isAbiCompatitable(fninfo_u.params[idx].type.?, fninfo_v.params[idx].type.?)) return false;
            }
            const return_type_u = fninfo_u.return_type.?;
            const return_type_v = fninfo_v.return_type.?;
            if (isAbiCompatitable(return_type_u, return_type_v)) {
                return true;
            } else {
                var return_info_u = @typeInfo(return_type_u);
                var return_info_v = @typeInfo(return_type_v);
                if (return_info_u == .optional and @typeInfo(return_info_u.optional.child) == .pointer) return_info_u = @typeInfo(return_info_u.optional.child);
                if (return_info_v == .optional and @typeInfo(return_info_v.optional.child) == .pointer) return_info_v = @typeInfo(return_info_v.optional.child);
                if (return_info_u == .pointer and return_info_v == .pointer) {
                    const UObj = return_info_u.pointer.child;
                    const VObj = return_info_v.pointer.child;
                    if (@typeInfo(UObj) == .@"struct" and @typeInfo(VObj) == .@"struct") {
                        if (core.isA(gobject.Object)(UObj)) {
                            var flag = false;
                            comptime {
                                var T = UObj;
                                while (@hasDecl(T, "Parent")) {
                                    T = T.Parent;
                                    if (isAbiCompatitable(T, VObj)) {
                                        flag = true;
                                        break;
                                    }
                                }
                            }
                            if (flag) return true;
                        }
                        if (core.isA(gobject.Object)(VObj)) {
                            var flag = false;
                            comptime {
                                var T = VObj;
                                while (@hasDecl(T, "Parent")) {
                                    T = T.Parent;
                                    if (isAbiCompatitable(UObj, T)) {
                                        flag = true;
                                        break;
                                    }
                                }
                            }
                            if (flag) return true;
                        }
                    }
                }
            }
            return false;
        },
        else => unreachable,
    }
    return false;
}
