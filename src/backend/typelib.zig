const std = @import("std");
const options = @import("options");
const Allocator = std.mem.Allocator;
const Writer = std.Io.Writer;
const gi = @import("../gi.zig");
const Repository = gi.Repository;
const fmt = @import("../fmt.zig");
const TypeFormatter = fmt.TypeFormatter;
const libgi = @import("typelib/girepository-2.0.zig");

var _repo: ?*libgi.Repository = null;
var _cur_ns: ?[]const u8 = null;

/// Load `namespace` if it isn't ready.
pub fn load(self: *Repository, namespace: []const u8, version: ?[]const u8) Repository.Error!void {
    if (!options.has_typelib) return error.FileNotFound;

    if (_repo == null) _repo = libgi.Repository.new();
    var repo = _repo.?;

    const allocator = self.allocator;
    for (self._search_paths.items) |path| {
        const c_path = try allocator.dupeZ(u8, path);
        defer allocator.free(c_path);
        repo.prependSearchPath(c_path);
    }
    self._search_paths.clearRetainingCapacity();

    const c_namespace = try allocator.dupeZ(u8, namespace);
    defer allocator.free(c_namespace);
    const c_version = if (version) |v| try allocator.dupeZ(u8, v) else null;
    defer if (c_version) |v| allocator.free(v);
    var err: ?*libgi.core.Error = null;
    _ = repo.require(c_namespace, c_version orelse null, .{}, &err) catch {
        std.log.err("{?s}", .{err.?.message});
        return error.FileNotFound;
    };

    const nss = blk: {
        const tmp = repo.getLoadedNamespaces();
        break :blk tmp.ret[0..tmp.n_namespaces_out];
    };
    for (nss) |c_ns_name| {
        const ns_name: []const u8 = std.mem.span(c_ns_name);
        _cur_ns = ns_name;
        defer _cur_ns = null;
        if (!self.namespaces.contains(ns_name)) {
            var ns: gi.Namespace = try .init(allocator, ns_name);
            errdefer ns.deinit(allocator);
            const deps = blk: {
                const tmp = repo.getDependencies(c_ns_name);
                break :blk tmp.ret[0..tmp.n_dependencies_out];
            };
            for (deps) |c_dep_name| {
                var dep_name: []const u8 = std.mem.span(c_dep_name);
                if (std.mem.indexOfScalar(u8, dep_name, '-')) |pos| dep_name = dep_name[0..pos];
                try ns.dependencies.append(allocator, try allocator.dupe(u8, dep_name));
            }
            const n_info = repo.getNInfos(c_ns_name);
            var idx: u32 = 0;
            while (idx < n_info) : (idx += 1) {
                const info = repo.getInfo(c_ns_name, idx);
                var parsed_info = try parseInfo(allocator, info);
                errdefer parsed_info.deinit(allocator);
                try ns.infos.append(allocator, parsed_info);
            }
            try self.namespaces.put(allocator, ns_name, ns);
        }
    }
}

/// Convert top-level `libgi.BaseInfo` to `gi.Info`
fn parseInfo(allocator: Allocator, info: *libgi.BaseInfo) Allocator.Error!gi.Info {
    if (info.tryInto(libgi.CallbackInfo)) |callback| {
        return .{ .callback = try parseCallback(allocator, callback) };
    } else if (info.tryInto(libgi.FunctionInfo)) |function| {
        return .{ .function = try parseFunction(allocator, function) };
    } else if (info.tryInto(libgi.ConstantInfo)) |constant| {
        return .{ .constant = try parseConstant(allocator, constant) };
    } else if (info.tryInto(libgi.FlagsInfo)) |flags| {
        return .{ .flags = try parseFlags(allocator, flags) };
    } else if (info.tryInto(libgi.EnumInfo)) |@"enum"| {
        return .{ .@"enum" = try parseEnum(allocator, @"enum") };
    } else if (info.tryInto(libgi.InterfaceInfo)) |interface| {
        return .{ .interface = try parseInterface(allocator, interface) };
    } else if (info.tryInto(libgi.ObjectInfo)) |object| {
        return .{ .object = try parseObject(allocator, object) };
    } else if (info.tryInto(libgi.StructInfo)) |@"struct"| {
        return .{ .@"struct" = try parseStruct(allocator, @"struct") };
    } else if (info.tryInto(libgi.UnionInfo)) |@"union"| {
        return .{ .@"union" = try parseUnion(allocator, @"union") };
    } else if (info.tryInto(libgi.UnresolvedInfo)) |unresolved| {
        return .{ .unresolved = try parseUnresolved(allocator, unresolved) };
    } else {
        unreachable;
    }
}

fn parseCallback(allocator: Allocator, info: *libgi.CallbackInfo) Allocator.Error!gi.Callback {
    return .{ .callable = try parseCallable(allocator, info.into(libgi.CallableInfo)) };
}

fn parseFunction(allocator: Allocator, info: *libgi.FunctionInfo) Allocator.Error!gi.Function {
    var function: gi.Function = .{ .callable = try parseCallable(allocator, info.into(libgi.CallableInfo)) };
    errdefer function.deinit(allocator);
    function.symbol = try allocator.dupe(u8, std.mem.span(info.getSymbol()));
    function.flags = info.getFlags();
    return function;
}

fn parseConstant(allocator: Allocator, info: *libgi.ConstantInfo) Allocator.Error!gi.Constant {
    var constant: gi.Constant = try .init(allocator, getFullName(info.into(libgi.BaseInfo)));
    errdefer constant.deinit(allocator);
    constant.type_tag = info.getTypeInfo().getTag();
    _ = info.getValue(&constant.value);
    return constant;
}

fn parseEnum(allocator: Allocator, info: *libgi.EnumInfo) Allocator.Error!gi.Enum {
    var _enum: gi.Enum = try .init(allocator, getFullName(info.into(libgi.BaseInfo)));
    errdefer _enum.deinit(allocator);
    _enum.storage_type = info.getStorageType();
    const n_method = info.getNMethods();
    var idx: u32 = 0;
    while (idx < n_method) : (idx += 1) try _enum.methods.append(allocator, try parseFunction(allocator, info.getMethod(idx)));
    const n_value = info.getNValues();
    idx = 0;
    while (idx < n_value) : (idx += 1) try _enum.values.append(allocator, try parseValue(allocator, info.getValue(idx)));
    return _enum;
}

fn parseFlags(allocator: Allocator, info: *libgi.FlagsInfo) Allocator.Error!gi.Flags {
    return .{ .base = try parseEnum(allocator, info.into(libgi.EnumInfo)) };
}

fn parseInterface(allocator: Allocator, info: *libgi.InterfaceInfo) Allocator.Error!gi.Interface {
    var interface: gi.Interface = try .init(allocator, getFullName(info.into(libgi.BaseInfo)));
    const n_constant = info.getNConstants();
    var idx: u32 = 0;
    while (idx < n_constant) : (idx += 1) try interface.constants.append(allocator, try parseConstant(allocator, info.getConstant(idx)));
    const n_method = info.getNMethods();
    idx = 0;
    while (idx < n_method) : (idx += 1) try interface.methods.append(allocator, try parseFunction(allocator, info.getMethod(idx)));
    const n_preq = info.getNPrerequisites();
    idx = 0;
    while (idx < n_preq) : (idx += 1) try interface.prerequisites.append(allocator, try parseInfo(allocator, info.getPrerequisite(idx)));
    const n_prop = info.getNProperties();
    idx = 0;
    while (idx < n_prop) : (idx += 1) try interface.properties.append(allocator, try parseProperty(allocator, info.getProperty(idx)));
    const n_signal = info.getNSignals();
    idx = 0;
    while (idx < n_signal) : (idx += 1) try interface.signals.append(allocator, try parseSignal(allocator, info.getSignal(idx)));
    const n_vfunc = info.getNVfuncs();
    idx = 0;
    while (idx < n_vfunc) : (idx += 1) try interface.vfuncs.append(allocator, try parseVFunc(allocator, info.getVfunc(idx)));
    return interface;
}

fn parseObject(allocator: Allocator, info: *libgi.ObjectInfo) Allocator.Error!gi.Object {
    var object: gi.Object = try .init(allocator, getFullName(info.into(libgi.BaseInfo)));
    errdefer object.deinit(allocator);
    if (info.getClassStruct()) |class_struct| {
        object.class_struct = try allocator.create(gi.Base);
        object.class_struct.?.* = try parseBase(allocator, class_struct.into(libgi.BaseInfo));
    }
    if (info.getParent()) |parent| {
        object.parent = try allocator.create(gi.Base);
        object.parent.?.* = try parseBase(allocator, parent.into(libgi.BaseInfo));
    }
    const n_constant = info.getNConstants();
    var idx: u32 = 0;
    while (idx < n_constant) : (idx += 1) try object.constants.append(allocator, try parseConstant(allocator, info.getConstant(idx)));
    const n_field = info.getNFields();
    idx = 0;
    while (idx < n_field) : (idx += 1) try object.fields.append(allocator, try parseField(allocator, info.getField(idx)));
    const n_interface = info.getNInterfaces();
    idx = 0;
    while (idx < n_interface) : (idx += 1) try object.interfaces.append(allocator, try parseInterface(allocator, info.getInterface(idx)));
    const n_method = info.getNMethods();
    idx = 0;
    while (idx < n_method) : (idx += 1) try object.methods.append(allocator, try parseFunction(allocator, info.getMethod(idx)));
    const n_prop = info.getNProperties();
    idx = 0;
    while (idx < n_prop) : (idx += 1) try object.properties.append(allocator, try parseProperty(allocator, info.getProperty(idx)));
    const n_signal = info.getNSignals();
    idx = 0;
    while (idx < n_signal) : (idx += 1) try object.signals.append(allocator, try parseSignal(allocator, info.getSignal(idx)));
    const n_vfunc = info.getNVfuncs();
    idx = 0;
    while (idx < n_vfunc) : (idx += 1) try object.vfuncs.append(allocator, try parseVFunc(allocator, info.getVfunc(idx)));
    return object;
}

fn parseStruct(allocator: Allocator, info: *libgi.StructInfo) Allocator.Error!gi.Struct {
    var _struct: gi.Struct = try .init(allocator, getFullName(info.into(libgi.BaseInfo)));
    errdefer _struct.deinit(allocator);
    const n_field = info.getNFields();
    var idx: u32 = 0;
    while (idx < n_field) : (idx += 1) try _struct.fields.append(allocator, try parseField(allocator, info.getField(idx)));
    const n_method = info.getNMethods();
    idx = 0;
    while (idx < n_method) : (idx += 1) try _struct.methods.append(allocator, try parseFunction(allocator, info.getMethod(idx)));
    _struct.size = info.getSize();
    return _struct;
}

fn parseUnion(allocator: Allocator, info: *libgi.UnionInfo) Allocator.Error!gi.Union {
    var _union: gi.Union = try .init(allocator, getFullName(info.into(libgi.BaseInfo)));
    errdefer _union.deinit(allocator);
    const n_field = info.getNFields();
    var idx: u32 = 0;
    while (idx < n_field) : (idx += 1) try _union.fields.append(allocator, try parseField(allocator, info.getField(idx)));
    const n_method = info.getNMethods();
    idx = 0;
    while (idx < n_method) : (idx += 1) try _union.methods.append(allocator, try parseFunction(allocator, info.getMethod(idx)));
    return _union;
}

fn parseUnresolved(allocator: Allocator, info: *libgi.UnresolvedInfo) Allocator.Error!gi.Unresolved {
    return .{ .base = try parseBase(allocator, info.into(libgi.BaseInfo)) };
}

fn getName(info: *libgi.BaseInfo) []const u8 {
    return std.mem.span(info.getName().?);
}

fn getFullName(info: *libgi.BaseInfo) []const u8 {
    const Static = struct {
        var buffer: [64]u8 = undefined;
    };
    const name = std.mem.span(info.getName().?);
    if (info.getNamespace()) |ns| {
        const namespace = std.mem.span(ns);
        if (_cur_ns != null and !std.mem.eql(u8, _cur_ns.?, namespace)) {
            return std.fmt.bufPrint(&Static.buffer, "{s}.{s}", .{ namespace, name }) catch @panic("No Space Left");
        }
    }
    return name;
}

fn parseBase(allocator: Allocator, info: *libgi.BaseInfo) Allocator.Error!gi.Base {
    if (info.tryInto(libgi.CallbackInfo)) |cb| {
        const name = getName(info);
        if (!std.ascii.isUpper(name[0])) {
            const callable = cb.into(libgi.CallableInfo);
            var aw: Writer.Allocating = .init(allocator);
            errdefer aw.deinit();
            aw.writer.writeAll("*const fn(") catch return error.OutOfMemory;
            const n_arg = callable.getNArgs();
            var idx: u32 = 0;
            while (idx < n_arg) : (idx += 1) {
                const arg_info = callable.getArg(idx);
                const type_info = arg_info.getTypeInfo();
                if (type_info.getTag() == .interface) {
                    const interface = type_info.getInterface().?;
                    if (interface.tryInto(libgi.CallbackInfo)) |_cb| {
                        const _cb_name = getName(_cb.into(libgi.BaseInfo));
                        std.debug.assert(std.ascii.isUpper(_cb_name[0]));
                    }
                }
                var _type = try parseType(allocator, type_info);
                if (idx != 0) aw.writer.writeAll(", ") catch return error.OutOfMemory;
                aw.writer.print("{f}", .{TypeFormatter{ .type = &_type }}) catch return error.OutOfMemory;
            }
            aw.writer.writeAll(") callconv(.c) ") catch return error.OutOfMemory;
            var return_type = try parseType(allocator, callable.getReturnType());
            aw.writer.print("{f}", .{TypeFormatter{ .type = &return_type }}) catch return error.OutOfMemory;
            return .{
                .name = try aw.toOwnedSlice(),
                .namespace = &.{},
            };
        }
    }
    return try .init(allocator, getFullName(info));
}

fn parseArg(allocator: Allocator, info: *libgi.ArgInfo) Allocator.Error!gi.Arg {
    var arg: gi.Arg = try .init(allocator, getName(info.into(libgi.BaseInfo)));
    errdefer arg.deinit(allocator);
    arg.type_info = try allocator.create(gi.Type);
    arg.type_info.?.* = try parseType(allocator, info.getTypeInfo());
    arg.direction = info.getDirection();
    arg.ownership_transfer = info.getOwnershipTransfer();
    arg.caller_allocates = info.isCallerAllocates();
    arg.may_be_null = info.mayBeNull();
    arg.closure_index = info.getClosureIndex() orelse null;
    arg.destroy_index = info.getDestroyIndex() orelse null;
    arg.scope = info.getScope();
    return arg;
}

fn parseCallable(allocator: Allocator, info: *libgi.CallableInfo) Allocator.Error!gi.Callable {
    var callable: gi.Callable = try .init(allocator, getFullName(info.into(libgi.BaseInfo)));
    errdefer callable.deinit(allocator);
    const n_arg = info.getNArgs();
    var idx: u32 = 0;
    while (idx < n_arg) : (idx += 1) try callable.args.append(allocator, try parseArg(allocator, info.getArg(idx)));
    callable.return_type = try allocator.create(gi.Type);
    callable.return_type.?.* = try parseType(allocator, info.getReturnType());
    callable.can_throw_gerror = info.canThrowGerror();
    callable.is_method = info.isMethod();
    callable.may_return_null = info.mayReturnNull();
    callable.skip_return = info.skipReturn();
    return callable;
}

fn parseField(allocator: Allocator, info: *libgi.FieldInfo) Allocator.Error!gi.Field {
    var field: gi.Field = try .init(allocator, getName(info.into(libgi.BaseInfo)));
    errdefer field.deinit(allocator);
    field.offset = info.getOffset();
    field.size = info.getSize();
    field.type_info = try allocator.create(gi.Type);
    field.type_info.?.* = try parseType(allocator, info.getTypeInfo());
    return field;
}

fn parseProperty(allocator: Allocator, info: *libgi.PropertyInfo) Allocator.Error!gi.Property {
    var property: gi.Property = try .init(allocator, getName(info.into(libgi.BaseInfo)));
    errdefer property.deinit(allocator);
    property.type_info = try allocator.create(gi.Type);
    property.type_info.?.* = try parseType(allocator, info.getTypeInfo());
    return property;
}

fn parseSignal(allocator: Allocator, info: *libgi.SignalInfo) Allocator.Error!gi.Signal {
    return .{ .callable = try parseCallable(allocator, info.into(libgi.CallableInfo)) };
}

fn parseType(allocator: Allocator, info: *libgi.TypeInfo) Allocator.Error!gi.Type {
    var _type: gi.Type = try .init(allocator, "type");
    errdefer _type.deinit(allocator);
    _type.tag = info.getTag();
    _type.pointer = info.isPointer();
    if (_type.tag == .array) {
        _type.array_type = info.getArrayType();
        _type.array_fixed_size = info.getArrayFixedSize() orelse null;
        _type.array_length_index = info.getArrayLengthIndex() orelse null;
        _type.zero_terminated = info.isZeroTerminated();
        _type.param_type = try allocator.create(gi.Type);
        _type.param_type.?.* = try parseType(allocator, info.getParamType(0).?);
    }
    if (_type.tag == .interface) {
        _type.interface = try allocator.create(gi.Base);
        const interface = info.getInterface().?;
        _type.interface.?.* = try parseBase(allocator, interface);
    }
    return _type;
}

fn parseValue(allocator: Allocator, info: *libgi.ValueInfo) Allocator.Error!gi.Value {
    const base_info = info.into(libgi.BaseInfo);
    const name = std.mem.span(base_info.getName().?);
    var value: gi.Value = try .init(allocator, name);
    errdefer value.deinit(allocator);
    value.value = info.getValue();
    return value;
}

fn parseVFunc(allocator: Allocator, info: *libgi.VFuncInfo) Allocator.Error!gi.VFunc {
    return .{ .callable = try parseCallable(allocator, info.into(libgi.CallableInfo)) };
}
