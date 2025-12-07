const std = @import("std");
const gi = @import("../../gi.zig");
pub const core = @import("core.min.zig");
const GLib = @import("core.min.zig");
const GModule = @import("core.min.zig");
const GObject = @import("core.min.zig");
const Gio = @import("core.min.zig");
const GIRepository = @This();
/// `GIArgInfo` represents an argument of a callable.
///
/// An argument is always part of a [class@GIRepository.CallableInfo].
/// @since 2.80
pub const ArgInfo = extern struct {
    pub const Parent = BaseInfo;
    parent: BaseInfoStack,
    padding: [6]?*anyopaque,
    /// Obtain the index of the user data argument. This is only valid
    /// for arguments which are callbacks.
    /// @since 2.80
    /// @param out_closure_index return location for the closure index
    pub fn getClosureIndex(self: *ArgInfo) ?u32 {
        var argO_out_closure_index: u32 = undefined;
        const arg_out_closure_index: ?*u32 = &argO_out_closure_index;
        const cFn = @extern(*const fn (*ArgInfo, ?*u32) callconv(.c) bool, .{ .name = "gi_arg_info_get_closure_index" });
        const ret = cFn(self, arg_out_closure_index);
        if (!ret) return null;
        return argO_out_closure_index;
    }
    /// Obtains the index of the [type@GLib.DestroyNotify] argument. This is only
    /// valid for arguments which are callbacks.
    /// @since 2.80
    /// @param out_destroy_index return location for the destroy index
    pub fn getDestroyIndex(self: *ArgInfo) ?u32 {
        var argO_out_destroy_index: u32 = undefined;
        const arg_out_destroy_index: ?*u32 = &argO_out_destroy_index;
        const cFn = @extern(*const fn (*ArgInfo, ?*u32) callconv(.c) bool, .{ .name = "gi_arg_info_get_destroy_index" });
        const ret = cFn(self, arg_out_destroy_index);
        if (!ret) return null;
        return argO_out_destroy_index;
    }
    /// Obtain the direction of the argument. Check [type@GIRepository.Direction]
    /// for possible direction values.
    /// @since 2.80
    pub fn getDirection(self: *ArgInfo) Direction {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) Direction, .{ .name = "gi_arg_info_get_direction" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the ownership transfer for this argument.
    /// [type@GIRepository.Transfer] contains a list of possible values.
    /// @since 2.80
    pub fn getOwnershipTransfer(self: *ArgInfo) Transfer {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) Transfer, .{ .name = "gi_arg_info_get_ownership_transfer" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the scope type for this argument.
    ///
    /// The scope type explains how a callback is going to be invoked, most
    /// importantly when the resources required to invoke it can be freed.
    ///
    /// [type@GIRepository.ScopeType] contains a list of possible values.
    /// @since 2.80
    pub fn getScope(self: *ArgInfo) ScopeType {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) ScopeType, .{ .name = "gi_arg_info_get_scope" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the type information for @info.
    /// @since 2.80
    pub fn getTypeInfo(self: *ArgInfo) *TypeInfo {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) *TypeInfo, .{ .name = "gi_arg_info_get_type_info" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain if the argument is a pointer to a struct or object that will
    /// receive an output of a function.
    ///
    /// The default assumption for `GI_DIRECTION_OUT` arguments which have allocation
    /// is that the callee allocates; if this is `TRUE`, then the caller must
    /// allocate.
    /// @since 2.80
    pub fn isCallerAllocates(self: *ArgInfo) bool {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) bool, .{ .name = "gi_arg_info_is_caller_allocates" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain if the argument is optional.
    ///
    /// For ‘out’ arguments this means that you can pass `NULL` in order to ignore
    /// the result.
    /// @since 2.80
    pub fn isOptional(self: *ArgInfo) bool {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) bool, .{ .name = "gi_arg_info_is_optional" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain if the argument is a return value. It can either be a
    /// parameter or a return value.
    /// @since 2.80
    pub fn isReturnValue(self: *ArgInfo) bool {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) bool, .{ .name = "gi_arg_info_is_return_value" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain if an argument is only useful in C.
    /// @since 2.80
    pub fn isSkip(self: *ArgInfo) bool {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) bool, .{ .name = "gi_arg_info_is_skip" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain information about a the type of given argument @info; this
    /// function is a variant of [method@GIRepository.ArgInfo.get_type_info] designed
    /// for stack allocation.
    ///
    /// The initialized @type must not be referenced after @info is deallocated.
    ///
    /// Once you are done with @type, it must be cleared using
    /// [method@GIRepository.BaseInfo.clear].
    /// @since 2.80
    /// @param type Initialized with information about type of @info
    pub fn loadTypeInfo(self: *ArgInfo, arg_type: *TypeInfo) void {
        const cFn = @extern(*const fn (*ArgInfo, *TypeInfo) callconv(.c) void, .{ .name = "gi_arg_info_load_type_info" });
        const ret = cFn(self, arg_type);
        return ret;
    }
    /// Obtain if the type of the argument includes the possibility of `NULL`.
    ///
    /// For ‘in’ values this means that `NULL` is a valid value.  For ‘out’
    /// values, this means that `NULL` may be returned.
    ///
    /// See also [method@GIRepository.ArgInfo.is_optional].
    /// @since 2.80
    pub fn mayBeNull(self: *ArgInfo) bool {
        const cFn = @extern(*const fn (*ArgInfo) callconv(.c) bool, .{ .name = "gi_arg_info_may_be_null" });
        const ret = cFn(self);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_arg_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// Stores an argument of varying type.
/// @since 2.80
pub const Argument = gi.Argument; // extern union {
//     /// boolean value
//     v_boolean: bool,
//     /// 8-bit signed integer value
//     v_int8: i8,
//     /// 8-bit unsigned integer value
//     v_uint8: u8,
//     /// 16-bit signed integer value
//     v_int16: i16,
//     /// 16-bit unsigned integer value
//     v_uint16: u16,
//     /// 32-bit signed integer value
//     v_int32: i32,
//     /// 32-bit unsigned integer value
//     v_uint32: u32,
//     /// 64-bit signed integer value
//     v_int64: i64,
//     /// 64-bit unsigned integer value
//     v_uint64: u64,
//     /// single float value
//     v_float: f32,
//     /// double float value
//     v_double: f64,
//     /// signed short integer value
//     v_short: i16,
//     /// unsigned short integer value
//     v_ushort: u16,
//     /// signed integer value
//     v_int: i32,
//     /// unsigned integer value
//     v_uint: u32,
//     /// signed long integer value
//     v_long: i64,
//     /// unsigned long integer value
//     v_ulong: u64,
//     /// sized `size_t` value
//     v_ssize: i64,
//     /// unsigned `size_t` value
//     v_size: u64,
//     /// nul-terminated string value
//     v_string: ?[*:0]const u8,
//     /// arbitrary pointer value
//     v_pointer: ?*anyopaque,
// };
/// The type of array in a [class@GIRepository.TypeInfo].
/// @since 2.80
pub const ArrayType = gi.ArrayType; // enum(i32) {
//     c = 0,
//     array = 1,
//     ptr_array = 2,
//     byte_array = 3,
// };
/// An opaque structure used to iterate over attributes
/// in a [class@GIRepository.BaseInfo] struct.
/// @since 2.80
pub const AttributeIter = extern struct {
    data: ?*anyopaque,
    _dummy: [4]?*anyopaque,
};
/// `GIBaseInfo` is the common base struct of all other Info structs
/// accessible through the [class@GIRepository.Repository] API.
///
/// All info structures can be cast to a `GIBaseInfo`, for instance:
///
/// ```c
///    GIFunctionInfo *function_info = …;
///    GIBaseInfo *info = (GIBaseInfo *) function_info;
/// ```
///
/// Most [class@GIRepository.Repository] APIs returning a `GIBaseInfo` are
/// actually creating a new struct; in other words,
/// [method@GIRepository.BaseInfo.unref] has to be called when done accessing the
/// data.
///
/// `GIBaseInfo` structuress are normally accessed by calling either
/// [method@GIRepository.Repository.find_by_name],
/// [method@GIRepository.Repository.find_by_gtype] or
/// [method@GIRepository.get_info].
///
/// ```c
/// GIBaseInfo *button_info =
///   gi_repository_find_by_name (NULL, "Gtk", "Button");
///
/// // use button_info…
///
/// gi_base_info_unref (button_info);
/// ```
/// @since 2.80
pub const BaseInfo = struct {
    pub const Class = BaseInfoClass;
    /// Clears memory allocated internally by a stack-allocated
    /// [type@GIRepository.BaseInfo].
    ///
    /// This does not deallocate the [type@GIRepository.BaseInfo] struct itself. It
    /// does clear the struct to zero so that calling this function subsequent times
    /// on the same struct is a no-op.
    ///
    /// This must only be called on stack-allocated [type@GIRepository.BaseInfo]s.
    /// Use [method@GIRepository.BaseInfo.unref] for heap-allocated ones.
    /// @since 2.80
    pub fn clear(self: *BaseInfo) void {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.c) void, .{ .name = "gi_base_info_clear" });
        const ret = cFn(self);
        return ret;
    }
    /// Compare two `GIBaseInfo`s.
    ///
    /// Using pointer comparison is not practical since many functions return
    /// different instances of `GIBaseInfo` that refers to the same part of the
    /// TypeLib; use this function instead to do `GIBaseInfo` comparisons.
    /// @since 2.80
    /// @param info2 a #GIBaseInfo
    pub fn equal(self: *BaseInfo, arg_info2: *BaseInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo, *BaseInfo) callconv(.c) bool, .{ .name = "gi_base_info_equal" });
        const ret = cFn(self, arg_info2);
        return ret;
    }
    /// Retrieve an arbitrary attribute associated with this node.
    /// @since 2.80
    /// @param name a freeform string naming an attribute
    pub fn getAttribute(self: *BaseInfo, arg_name: [*:0]const u8) ?[*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo, [*:0]const u8) callconv(.c) ?[*:0]u8, .{ .name = "gi_base_info_get_attribute" });
        const ret = cFn(self, arg_name);
        return ret;
    }
    /// Obtain the container of the @info.
    ///
    /// The container is the parent `GIBaseInfo`. For instance, the parent of a
    /// [class@GIRepository.FunctionInfo] is an [class@GIRepository.ObjectInfo] or
    /// [class@GIRepository.InterfaceInfo].
    /// @since 2.80
    pub fn getContainer(self: *BaseInfo) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.c) *BaseInfo, .{ .name = "gi_base_info_get_container" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the name of the @info.
    ///
    /// What the name represents depends on the type of the
    /// @info. For instance for [class@GIRepository.FunctionInfo] it is the name of
    /// the function.
    /// @since 2.80
    pub fn getName(self: *BaseInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_base_info_get_name" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the namespace of @info.
    /// @since 2.80
    pub fn getNamespace(self: *BaseInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_base_info_get_namespace" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the typelib this @info belongs to
    /// @since 2.80
    pub fn getTypelib(self: *BaseInfo) *Typelib {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.c) *Typelib, .{ .name = "gi_base_info_get_typelib" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain whether the @info is represents a metadata which is
    /// deprecated.
    /// @since 2.80
    pub fn isDeprecated(self: *BaseInfo) bool {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.c) bool, .{ .name = "gi_base_info_is_deprecated" });
        const ret = cFn(self);
        return ret;
    }
    /// Iterate over all attributes associated with this node.
    ///
    /// The iterator structure is typically stack allocated, and must have its first
    /// member initialized to `NULL`.  Attributes are arbitrary namespaced key–value
    /// pairs which can be attached to almost any item.  They are intended for use
    /// by software higher in the toolchain than bindings, and are distinct from
    /// normal GIR annotations.
    ///
    /// Both the @name and @value should be treated as constants
    /// and must not be freed.
    ///
    /// ```c
    /// void
    /// print_attributes (GIBaseInfo *info)
    /// {
    ///   GIAttributeIter iter = GI_ATTRIBUTE_ITER_INIT;
    ///   const char *name;
    ///   const char *value;
    ///   while (gi_base_info_iterate_attributes (info, &iter, &name, &value))
    ///     {
    ///       g_print ("attribute name: %s value: %s", name, value);
    ///     }
    /// }
    /// ```
    /// @since 2.80
    /// @param iterator a [type@GIRepository.AttributeIter] structure, must be
    ///   initialized; see below
    /// @param name Returned name, must not be freed
    /// @param value Returned name, must not be freed
    pub fn iterateAttributes(self: *BaseInfo, arg_iterator: **AttributeIter) struct {
        ret: bool,
        name: [*:0]u8,
        value: [*:0]u8,
    } {
        var argO_name: [*:0]u8 = undefined;
        const arg_name: *[*:0]u8 = &argO_name;
        var argO_value: [*:0]u8 = undefined;
        const arg_value: *[*:0]u8 = &argO_value;
        const cFn = @extern(*const fn (*BaseInfo, **AttributeIter, *[*:0]u8, *[*:0]u8) callconv(.c) bool, .{ .name = "gi_base_info_iterate_attributes" });
        const ret = cFn(self, arg_iterator, arg_name, arg_value);
        return .{ .ret = ret, .name = argO_name, .value = argO_value };
    }
    /// Increases the reference count of @info.
    /// @since 2.80
    pub fn ref(self: *BaseInfo) *BaseInfo {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.c) *BaseInfo, .{ .name = "gi_base_info_ref" });
        const ret = cFn(self);
        return ret;
    }
    /// Decreases the reference count of @info. When its reference count
    /// drops to 0, the info is freed.
    ///
    /// This must not be called on stack-allocated [type@GIRepository.BaseInfo]s —
    /// use [method@GIRepository.BaseInfo.clear] for that.
    /// @since 2.80
    pub fn unref(self: *BaseInfo) void {
        const cFn = @extern(*const fn (*BaseInfo) callconv(.c) void, .{ .name = "gi_base_info_unref" });
        const ret = cFn(self);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_base_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
pub const BaseInfoClass = opaque {};
pub const BaseInfoStack = extern struct {
    parent_instance: GObject.TypeInstance,
    dummy0: i32,
    dummy1: [3]?*anyopaque,
    dummy2: [2]u32,
    dummy3: [6]?*anyopaque,
};
/// `GICallableInfo` represents an entity which is callable.
///
/// Examples of callable are:
///
///  - functions ([class@GIRepository.FunctionInfo])
///  - virtual functions ([class@GIRepository.VFuncInfo])
///  - callbacks ([class@GIRepository.CallbackInfo]).
///
/// A callable has a list of arguments ([class@GIRepository.ArgInfo]), a return
/// type, direction and a flag which decides if it returns `NULL`.
/// @since 2.80
pub const CallableInfo = struct {
    pub const Parent = BaseInfo;
    /// Whether the callable can throw a [type@GLib.Error]
    /// @since 2.80
    pub fn canThrowGerror(self: *CallableInfo) bool {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) bool, .{ .name = "gi_callable_info_can_throw_gerror" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain information about a particular argument of this callable.
    /// @since 2.80
    /// @param n the argument index to fetch
    pub fn getArg(self: *CallableInfo, arg_n: u32) *ArgInfo {
        const cFn = @extern(*const fn (*CallableInfo, u32) callconv(.c) *ArgInfo, .{ .name = "gi_callable_info_get_arg" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Gets the callable info for the callable's asynchronous version
    /// @since 2.84
    pub fn getAsyncFunction(self: *CallableInfo) ?*CallableInfo {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) ?*CallableInfo, .{ .name = "gi_callable_info_get_async_function" });
        const ret = cFn(self);
        return ret;
    }
    /// See whether the caller owns the return value of this callable.
    ///
    /// [type@GIRepository.Transfer] contains a list of possible transfer values.
    /// @since 2.80
    pub fn getCallerOwns(self: *CallableInfo) Transfer {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) Transfer, .{ .name = "gi_callable_info_get_caller_owns" });
        const ret = cFn(self);
        return ret;
    }
    /// Gets the info for an async function's corresponding finish function
    /// @since 2.84
    pub fn getFinishFunction(self: *CallableInfo) ?*CallableInfo {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) ?*CallableInfo, .{ .name = "gi_callable_info_get_finish_function" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtains the ownership transfer for the instance argument.
    ///
    /// [type@GIRepository.Transfer] contains a list of possible transfer values.
    /// @since 2.80
    pub fn getInstanceOwnershipTransfer(self: *CallableInfo) Transfer {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) Transfer, .{ .name = "gi_callable_info_get_instance_ownership_transfer" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the number of arguments (both ‘in’ and ‘out’) for this callable.
    /// @since 2.80
    pub fn getNArgs(self: *CallableInfo) u32 {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) u32, .{ .name = "gi_callable_info_get_n_args" });
        const ret = cFn(self);
        return ret;
    }
    /// Retrieve an arbitrary attribute associated with the return value.
    /// @since 2.80
    /// @param name a freeform string naming an attribute
    pub fn getReturnAttribute(self: *CallableInfo, arg_name: [*:0]const u8) ?[*:0]u8 {
        const cFn = @extern(*const fn (*CallableInfo, [*:0]const u8) callconv(.c) ?[*:0]u8, .{ .name = "gi_callable_info_get_return_attribute" });
        const ret = cFn(self, arg_name);
        return ret;
    }
    /// Obtain the return type of a callable item as a [class@GIRepository.TypeInfo].
    ///
    /// If the callable doesn’t return anything, a [class@GIRepository.TypeInfo] of
    /// type [enum@GIRepository.TypeTag.VOID] will be returned.
    /// @since 2.80
    pub fn getReturnType(self: *CallableInfo) *TypeInfo {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) *TypeInfo, .{ .name = "gi_callable_info_get_return_type" });
        const ret = cFn(self);
        return ret;
    }
    /// Gets the callable info for the callable's synchronous version
    /// @since 2.84
    pub fn getSyncFunction(self: *CallableInfo) ?*CallableInfo {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) ?*CallableInfo, .{ .name = "gi_callable_info_get_sync_function" });
        const ret = cFn(self);
        return ret;
    }
    /// Invoke the given `GICallableInfo` by calling the given @function pointer.
    ///
    /// The set of arguments passed to @function will be constructed according to the
    /// introspected type of the `GICallableInfo`, using @in_args, @out_args
    /// and @error.
    /// @since 2.80
    /// @param function function pointer to call
    /// @param in_args array of ‘in’ arguments
    /// @param n_in_args number of arguments in @in_args
    /// @param out_args array of ‘out’ arguments allocated by
    ///   the caller, to be populated with outputted values
    /// @param n_out_args number of arguments in @out_args
    /// @param return_value return
    ///   location for the return value from the callable; `NULL` may be returned if
    ///   the callable returns that
    pub fn invoke(self: *CallableInfo, arg_function: ?*anyopaque, argS_in_args: []Argument, argS_out_args: []Argument, arg_return_value: *Argument, arg_error: *?*GLib.Error) error{GError}!bool {
        const arg_in_args: [*]Argument = @ptrCast(argS_in_args);
        const arg_n_in_args: u64 = @intCast((argS_in_args).len);
        const arg_out_args: [*]Argument = @ptrCast(argS_out_args);
        const arg_n_out_args: u64 = @intCast((argS_out_args).len);
        const cFn = @extern(*const fn (*CallableInfo, ?*anyopaque, [*]Argument, u64, [*]Argument, u64, *Argument, *?*GLib.Error) callconv(.c) bool, .{ .name = "gi_callable_info_invoke" });
        const ret = cFn(self, @ptrCast(arg_function), arg_in_args, arg_n_in_args, arg_out_args, arg_n_out_args, arg_return_value, arg_error);
        if (arg_error.* != null) return error.GError;
        return ret;
    }
    /// Gets whether a callable is ‘async’. Async callables have a
    /// [type@Gio.AsyncReadyCallback] parameter and user data.
    /// @since 2.84
    pub fn isAsync(self: *CallableInfo) bool {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) bool, .{ .name = "gi_callable_info_is_async" });
        const ret = cFn(self);
        return ret;
    }
    /// Determines if the callable info is a method.
    ///
    /// For [class@GIRepository.SignalInfo]s, this is always true, and for
    /// [class@GIRepository.CallbackInfo]s always false.
    /// For [class@GIRepository.FunctionInfo]s this looks at the
    /// `GI_FUNCTION_IS_METHOD` flag on the [class@GIRepository.FunctionInfo].
    /// For [class@GIRepository.VFuncInfo]s this is true when the virtual function
    /// has an instance parameter.
    ///
    /// Concretely, this function returns whether
    /// [method@GIRepository.CallableInfo.get_n_args] matches the number of arguments
    /// in the raw C method. For methods, there is one more C argument than is
    /// exposed by introspection: the `self` or `this` object.
    /// @since 2.80
    pub fn isMethod(self: *CallableInfo) bool {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) bool, .{ .name = "gi_callable_info_is_method" });
        const ret = cFn(self);
        return ret;
    }
    /// Iterate over all attributes associated with the return value.
    ///
    /// The iterator structure is typically stack allocated, and must have its
    /// first member initialized to `NULL`.
    ///
    /// Both the @name and @value should be treated as constants
    /// and must not be freed.
    ///
    /// See [method@GIRepository.BaseInfo.iterate_attributes] for an example of how
    /// to use a similar API.
    /// @since 2.80
    /// @param iterator a [type@GIRepository.AttributeIter] structure, must be
    ///   initialized; see below
    /// @param name Returned name, must not be freed
    /// @param value Returned name, must not be freed
    pub fn iterateReturnAttributes(self: *CallableInfo, arg_iterator: **AttributeIter) struct {
        ret: bool,
        name: [*:0]u8,
        value: [*:0]u8,
    } {
        var argO_name: [*:0]u8 = undefined;
        const arg_name: *[*:0]u8 = &argO_name;
        var argO_value: [*:0]u8 = undefined;
        const arg_value: *[*:0]u8 = &argO_value;
        const cFn = @extern(*const fn (*CallableInfo, **AttributeIter, *[*:0]u8, *[*:0]u8) callconv(.c) bool, .{ .name = "gi_callable_info_iterate_return_attributes" });
        const ret = cFn(self, arg_iterator, arg_name, arg_value);
        return .{ .ret = ret, .name = argO_name, .value = argO_value };
    }
    /// Obtain information about a particular argument of this callable; this
    /// function is a variant of [method@GIRepository.CallableInfo.get_arg] designed
    /// for stack allocation.
    ///
    /// The initialized @arg must not be referenced after @info is deallocated.
    ///
    /// Once you are done with @arg, it must be cleared using
    /// [method@GIRepository.BaseInfo.clear].
    /// @since 2.80
    /// @param n the argument index to fetch
    /// @param arg Initialize with argument number @n
    pub fn loadArg(self: *CallableInfo, arg_n: u32, arg_arg: *ArgInfo) void {
        const cFn = @extern(*const fn (*CallableInfo, u32, *ArgInfo) callconv(.c) void, .{ .name = "gi_callable_info_load_arg" });
        const ret = cFn(self, arg_n, arg_arg);
        return ret;
    }
    /// Obtain information about a return value of callable; this
    /// function is a variant of [method@GIRepository.CallableInfo.get_return_type]
    /// designed for stack allocation.
    ///
    /// The initialized @type must not be referenced after @info is deallocated.
    ///
    /// Once you are done with @type, it must be cleared using
    /// [method@GIRepository.BaseInfo.clear].
    /// @since 2.80
    /// @param type Initialized with return type of @info
    pub fn loadReturnType(self: *CallableInfo, arg_type: *TypeInfo) void {
        const cFn = @extern(*const fn (*CallableInfo, *TypeInfo) callconv(.c) void, .{ .name = "gi_callable_info_load_return_type" });
        const ret = cFn(self, arg_type);
        return ret;
    }
    /// See if a callable could return `NULL`.
    /// @since 2.80
    pub fn mayReturnNull(self: *CallableInfo) bool {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) bool, .{ .name = "gi_callable_info_may_return_null" });
        const ret = cFn(self);
        return ret;
    }
    /// See if a callable’s return value is only useful in C.
    /// @since 2.80
    pub fn skipReturn(self: *CallableInfo) bool {
        const cFn = @extern(*const fn (*CallableInfo) callconv(.c) bool, .{ .name = "gi_callable_info_skip_return" });
        const ret = cFn(self);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_callable_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// `GICallbackInfo` represents a callback.
/// @since 2.80
pub const CallbackInfo = struct {
    pub const Parent = CallableInfo;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_callback_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// `GIConstantInfo` represents a constant.
///
/// A constant has a type associated – which can be obtained by calling
/// [method@GIRepository.ConstantInfo.get_type_info] – and a value – which can be
/// obtained by calling [method@GIRepository.ConstantInfo.get_value].
/// @since 2.80
pub const ConstantInfo = struct {
    pub const Parent = BaseInfo;
    /// Free the value returned from [method@GIRepository.ConstantInfo.get_value].
    /// @since 2.80
    /// @param value the argument
    pub fn freeValue(self: *ConstantInfo, arg_value: *Argument) void {
        const cFn = @extern(*const fn (*ConstantInfo, *Argument) callconv(.c) void, .{ .name = "gi_constant_info_free_value" });
        const ret = cFn(self, arg_value);
        return ret;
    }
    /// Obtain the type of the constant as a [class@GIRepository.TypeInfo].
    /// @since 2.80
    pub fn getTypeInfo(self: *ConstantInfo) *TypeInfo {
        const cFn = @extern(*const fn (*ConstantInfo) callconv(.c) *TypeInfo, .{ .name = "gi_constant_info_get_type_info" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the value associated with the `GIConstantInfo` and store it in the
    /// @value parameter.
    ///
    /// @argument needs to be allocated before passing it in.
    ///
    /// The size of the constant value (in bytes) stored in @argument will be
    /// returned.
    ///
    /// Free the value with [method@GIRepository.ConstantInfo.free_value].
    /// @since 2.80
    /// @param value an argument
    pub fn getValue(self: *ConstantInfo, arg_value: *Argument) u64 {
        const cFn = @extern(*const fn (*ConstantInfo, *Argument) callconv(.c) u64, .{ .name = "gi_constant_info_get_value" });
        const ret = cFn(self, arg_value);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_constant_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// The direction of a [class@GIRepository.ArgInfo].
/// @since 2.80
pub const Direction = gi.Direction; // enum(i32) {
//     in = 0,
//     out = 1,
//     inout = 2,
// };
/// A `GIEnumInfo` represents an enumeration.
///
/// The `GIEnumInfo` contains a set of values (each a
/// [class@GIRepository.ValueInfo]) and a type.
///
/// The [class@GIRepository.ValueInfo] for a value is fetched by calling
/// [method@GIRepository.EnumInfo.get_value] on a `GIEnumInfo`.
/// @since 2.80
pub const EnumInfo = struct {
    pub const Parent = RegisteredTypeInfo;
    /// Obtain the string form of the quark for the error domain associated with
    /// this enum, if any.
    /// @since 2.80
    pub fn getErrorDomain(self: *EnumInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*EnumInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_enum_info_get_error_domain" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain an enum type method at index @n.
    /// @since 2.80
    /// @param n index of method to get
    pub fn getMethod(self: *EnumInfo, arg_n: u32) *FunctionInfo {
        const cFn = @extern(*const fn (*EnumInfo, u32) callconv(.c) *FunctionInfo, .{ .name = "gi_enum_info_get_method" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Obtain the number of methods that this enum type has.
    /// @since 2.80
    pub fn getNMethods(self: *EnumInfo) u32 {
        const cFn = @extern(*const fn (*EnumInfo) callconv(.c) u32, .{ .name = "gi_enum_info_get_n_methods" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the number of values this enumeration contains.
    /// @since 2.80
    pub fn getNValues(self: *EnumInfo) u32 {
        const cFn = @extern(*const fn (*EnumInfo) callconv(.c) u32, .{ .name = "gi_enum_info_get_n_values" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the tag of the type used for the enum in the C ABI. This will
    /// will be a signed or unsigned integral type.
    ///
    /// Note that in the current implementation the width of the type is
    /// computed correctly, but the signed or unsigned nature of the type
    /// may not match the sign of the type used by the C compiler.
    /// @since 2.80
    pub fn getStorageType(self: *EnumInfo) TypeTag {
        const cFn = @extern(*const fn (*EnumInfo) callconv(.c) TypeTag, .{ .name = "gi_enum_info_get_storage_type" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain a value for this enumeration.
    /// @since 2.80
    /// @param n index of value to fetch
    pub fn getValue(self: *EnumInfo, arg_n: u32) *ValueInfo {
        const cFn = @extern(*const fn (*EnumInfo, u32) callconv(.c) *ValueInfo, .{ .name = "gi_enum_info_get_value" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_enum_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// A `GIFieldInfo` struct represents a field of a struct, union, or object.
///
/// The `GIFieldInfo` is fetched by calling
/// [method@GIRepository.StructInfo.get_field],
/// [method@GIRepository.UnionInfo.get_field] or
/// [method@GIRepository.ObjectInfo.get_field].
///
/// A field has a size, type and a struct offset associated and a set of flags,
/// which are currently `GI_FIELD_IS_READABLE` or `GI_FIELD_IS_WRITABLE`.
///
/// See also: [type@GIRepository.StructInfo], [type@GIRepository.UnionInfo],
/// [type@GIRepository.ObjectInfo]
/// @since 2.80
pub const FieldInfo = struct {
    pub const Parent = BaseInfo;
    /// Reads a field identified by a `GIFieldInfo` from a C structure or
    /// union.
    ///
    /// This only handles fields of simple C types. It will fail for a field of a
    /// composite type like a nested structure or union even if that is actually
    /// readable.
    /// @since 2.80
    /// @param mem pointer to a block of memory representing a C structure or union
    /// @param value a [type@GIRepository.Argument] into which to store the value retrieved
    pub fn getField(self: *FieldInfo, arg_mem: ?*anyopaque, arg_value: *Argument) bool {
        const cFn = @extern(*const fn (*FieldInfo, ?*anyopaque, *Argument) callconv(.c) bool, .{ .name = "gi_field_info_get_field" });
        const ret = cFn(self, @ptrCast(arg_mem), arg_value);
        return ret;
    }
    /// Obtain the flags for this `GIFieldInfo`. See
    /// [flags@GIRepository.FieldInfoFlags] for possible flag values.
    /// @since 2.80
    pub fn getFlags(self: *FieldInfo) FieldInfoFlags {
        const cFn = @extern(*const fn (*FieldInfo) callconv(.c) FieldInfoFlags, .{ .name = "gi_field_info_get_flags" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the offset of the field member, in bytes. This is relative
    /// to the beginning of the struct or union.
    /// @since 2.80
    pub fn getOffset(self: *FieldInfo) u64 {
        const cFn = @extern(*const fn (*FieldInfo) callconv(.c) u64, .{ .name = "gi_field_info_get_offset" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the size of the field member, in bits. This is how
    /// much space you need to allocate to store the field.
    /// @since 2.80
    pub fn getSize(self: *FieldInfo) u64 {
        const cFn = @extern(*const fn (*FieldInfo) callconv(.c) u64, .{ .name = "gi_field_info_get_size" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the type of a field as a [type@GIRepository.TypeInfo].
    /// @since 2.80
    pub fn getTypeInfo(self: *FieldInfo) *TypeInfo {
        const cFn = @extern(*const fn (*FieldInfo) callconv(.c) *TypeInfo, .{ .name = "gi_field_info_get_type_info" });
        const ret = cFn(self);
        return ret;
    }
    /// Writes a field identified by a `GIFieldInfo` to a C structure or
    /// union.
    ///
    /// This only handles fields of simple C types. It will fail for a field of a
    /// composite type like a nested structure or union even if that is actually
    /// writable. Note also that that it will refuse to write fields where memory
    /// management would by required. A field with a type such as `char *` must be
    /// set with a setter function.
    /// @since 2.80
    /// @param mem pointer to a block of memory representing a C structure or union
    /// @param value a [type@GIRepository.Argument] holding the value to store
    pub fn setField(self: *FieldInfo, arg_mem: ?*anyopaque, arg_value: *Argument) bool {
        const cFn = @extern(*const fn (*FieldInfo, ?*anyopaque, *Argument) callconv(.c) bool, .{ .name = "gi_field_info_set_field" });
        const ret = cFn(self, @ptrCast(arg_mem), arg_value);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_field_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// Flags for a [class@GIRepository.FieldInfo].
/// @since 2.80
pub const FieldInfoFlags = packed struct(i32) {
    readable: bool = false,
    writable: bool = false,
    _: u30 = 0,
};
/// A `GIFlagsInfo` represents an enumeration which defines flag values
/// (independently set bits).
///
/// The `GIFlagsInfo` contains a set of values (each a
/// [class@GIRepository.ValueInfo]) and a type.
///
/// The [class@GIRepository.ValueInfo] for a value is fetched by calling
/// [method@GIRepository.EnumInfo.get_value] on a `GIFlagsInfo`.
/// @since 2.80
pub const FlagsInfo = struct {
    pub const Parent = EnumInfo;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_flags_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// `GIFunctionInfo` represents a function, method or constructor.
///
/// To find out what kind of entity a `GIFunctionInfo` represents, call
/// [method@GIRepository.FunctionInfo.get_flags].
///
/// See also [class@GIRepository.CallableInfo] for information on how to retrieve
/// arguments and other metadata.
/// @since 2.80
pub const FunctionInfo = struct {
    pub const Parent = CallableInfo;
    /// Obtain the [type@GIRepository.FunctionInfoFlags] for the @info.
    /// @since 2.80
    pub fn getFlags(self: *FunctionInfo) FunctionInfoFlags {
        const cFn = @extern(*const fn (*FunctionInfo) callconv(.c) FunctionInfoFlags, .{ .name = "gi_function_info_get_flags" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the property associated with this `GIFunctionInfo`.
    ///
    /// Only `GIFunctionInfo`s with the flag `GI_FUNCTION_IS_GETTER` or
    /// `GI_FUNCTION_IS_SETTER` have a property set. For other cases,
    /// `NULL` will be returned.
    /// @since 2.80
    pub fn getProperty(self: *FunctionInfo) ?*PropertyInfo {
        const cFn = @extern(*const fn (*FunctionInfo) callconv(.c) ?*PropertyInfo, .{ .name = "gi_function_info_get_property" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the symbol of the function.
    ///
    /// The symbol is the name of the exported function, suitable to be used as an
    /// argument to [method@GModule.Module.symbol].
    /// @since 2.80
    pub fn getSymbol(self: *FunctionInfo) [*:0]u8 {
        const cFn = @extern(*const fn (*FunctionInfo) callconv(.c) [*:0]u8, .{ .name = "gi_function_info_get_symbol" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the virtual function associated with this `GIFunctionInfo`.
    ///
    /// Only `GIFunctionInfo`s with the flag `GI_FUNCTION_WRAPS_VFUNC` have
    /// a virtual function set. For other cases, `NULL` will be returned.
    /// @since 2.80
    pub fn getVfunc(self: *FunctionInfo) ?*VFuncInfo {
        const cFn = @extern(*const fn (*FunctionInfo) callconv(.c) ?*VFuncInfo, .{ .name = "gi_function_info_get_vfunc" });
        const ret = cFn(self);
        return ret;
    }
    /// Invokes the function described in @info with the given
    /// arguments.
    ///
    /// Note that ‘inout’ parameters must appear in both argument lists. This
    /// function uses [`dlsym()`](man:dlsym(3)) to obtain a pointer to the function,
    /// so the library or shared object containing the described function must either
    /// be linked to the caller, or must have been loaded with
    /// [method@GModule.Module.symbol] before calling this function.
    /// @since 2.80
    /// @param in_args An array of
    ///   [type@GIRepository.Argument]s, one for each ‘in’ parameter of @info. If
    ///   there are no ‘in’ parameters, @in_args can be `NULL`.
    /// @param n_in_args the length of the @in_args array
    /// @param out_args An array of
    ///   [type@GIRepository.Argument]s, one for each ‘out’ parameter of @info. If
    ///   there are no ‘out’ parameters, @out_args may be `NULL`.
    /// @param n_out_args the length of the @out_args array
    /// @param return_value return location for the
    ///   return value of the function.
    pub fn invoke(self: *FunctionInfo, argS_in_args: ?[]Argument, argS_out_args: ?[]Argument, arg_return_value: *Argument, arg_error: *?*GLib.Error) error{GError}!bool {
        const arg_in_args: ?[*]Argument = @ptrCast(argS_in_args);
        const arg_n_in_args: u64 = @intCast((argS_in_args orelse &.{}).len);
        const arg_out_args: ?[*]Argument = @ptrCast(argS_out_args);
        const arg_n_out_args: u64 = @intCast((argS_out_args orelse &.{}).len);
        const cFn = @extern(*const fn (*FunctionInfo, ?[*]Argument, u64, ?[*]Argument, u64, *Argument, *?*GLib.Error) callconv(.c) bool, .{ .name = "gi_function_info_invoke" });
        const ret = cFn(self, arg_in_args, arg_n_in_args, arg_out_args, arg_n_out_args, arg_return_value, arg_error);
        if (arg_error.* != null) return error.GError;
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_function_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// Flags for a [class@GIRepository.FunctionInfo] struct.
/// @since 2.80
pub const FunctionInfoFlags = gi.FunctionFlags; // packed struct(i32) {
//     is_method: bool = false,
//     is_constructor: bool = false,
//     is_getter: bool = false,
//     is_setter: bool = false,
//     wraps_vfunc: bool = false,
//     is_async: bool = false,
//     _: u26 = 0,
// };
/// `GIInterfaceInfo` represents a `GInterface` type.
///
/// A `GInterface` has methods, fields, properties, signals,
/// interfaces, constants, virtual functions and prerequisites.
/// @since 2.80
pub const InterfaceInfo = struct {
    pub const Parent = RegisteredTypeInfo;
    /// Obtain a method of the interface type given a @name.
    ///
    /// `NULL` will be returned if there’s no method available with that name.
    /// @since 2.80
    /// @param name name of method to obtain
    pub fn findMethod(self: *InterfaceInfo, arg_name: [*:0]const u8) ?*FunctionInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, [*:0]const u8) callconv(.c) ?*FunctionInfo, .{ .name = "gi_interface_info_find_method" });
        const ret = cFn(self, arg_name);
        return ret;
    }
    /// Obtain a signal of the interface type given a @name.
    ///
    /// `NULL` will be returned if there’s no signal available with that name.
    /// @since 2.80
    /// @param name name of signal to find
    pub fn findSignal(self: *InterfaceInfo, arg_name: [*:0]const u8) ?*SignalInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, [*:0]const u8) callconv(.c) ?*SignalInfo, .{ .name = "gi_interface_info_find_signal" });
        const ret = cFn(self, arg_name);
        return ret;
    }
    /// Locate a virtual function slot with name @name.
    ///
    /// See the documentation for [method@GIRepository.ObjectInfo.find_vfunc] for
    /// more information on virtuals.
    /// @since 2.80
    /// @param name The name of a virtual function to find.
    pub fn findVfunc(self: *InterfaceInfo, arg_name: [*:0]const u8) ?*VFuncInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, [*:0]const u8) callconv(.c) ?*VFuncInfo, .{ .name = "gi_interface_info_find_vfunc" });
        const ret = cFn(self, arg_name);
        return ret;
    }
    /// Obtain an interface type constant at index @n.
    /// @since 2.80
    /// @param n index of constant to get
    pub fn getConstant(self: *InterfaceInfo, arg_n: u32) *ConstantInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, u32) callconv(.c) *ConstantInfo, .{ .name = "gi_interface_info_get_constant" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Returns the layout C structure associated with this `GInterface`.
    /// @since 2.80
    pub fn getIfaceStruct(self: *InterfaceInfo) ?*StructInfo {
        const cFn = @extern(*const fn (*InterfaceInfo) callconv(.c) ?*StructInfo, .{ .name = "gi_interface_info_get_iface_struct" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain an interface type method at index @n.
    /// @since 2.80
    /// @param n index of method to get
    pub fn getMethod(self: *InterfaceInfo, arg_n: u32) *FunctionInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, u32) callconv(.c) *FunctionInfo, .{ .name = "gi_interface_info_get_method" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Obtain the number of constants that this interface type has.
    /// @since 2.80
    pub fn getNConstants(self: *InterfaceInfo) u32 {
        const cFn = @extern(*const fn (*InterfaceInfo) callconv(.c) u32, .{ .name = "gi_interface_info_get_n_constants" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the number of methods that this interface type has.
    /// @since 2.80
    pub fn getNMethods(self: *InterfaceInfo) u32 {
        const cFn = @extern(*const fn (*InterfaceInfo) callconv(.c) u32, .{ .name = "gi_interface_info_get_n_methods" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the number of prerequisites for this interface type.
    ///
    /// A prerequisite is another interface that needs to be implemented for
    /// interface, similar to a base class for [class@GObject.Object]s.
    /// @since 2.80
    pub fn getNPrerequisites(self: *InterfaceInfo) u32 {
        const cFn = @extern(*const fn (*InterfaceInfo) callconv(.c) u32, .{ .name = "gi_interface_info_get_n_prerequisites" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the number of properties that this interface type has.
    /// @since 2.80
    pub fn getNProperties(self: *InterfaceInfo) u32 {
        const cFn = @extern(*const fn (*InterfaceInfo) callconv(.c) u32, .{ .name = "gi_interface_info_get_n_properties" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the number of signals that this interface type has.
    /// @since 2.80
    pub fn getNSignals(self: *InterfaceInfo) u32 {
        const cFn = @extern(*const fn (*InterfaceInfo) callconv(.c) u32, .{ .name = "gi_interface_info_get_n_signals" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the number of virtual functions that this interface type has.
    /// @since 2.80
    pub fn getNVfuncs(self: *InterfaceInfo) u32 {
        const cFn = @extern(*const fn (*InterfaceInfo) callconv(.c) u32, .{ .name = "gi_interface_info_get_n_vfuncs" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain an interface type’s prerequisite at index @n.
    /// @since 2.80
    /// @param n index of prerequisite to get
    pub fn getPrerequisite(self: *InterfaceInfo, arg_n: u32) *BaseInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, u32) callconv(.c) *BaseInfo, .{ .name = "gi_interface_info_get_prerequisite" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Obtain an interface type property at index @n.
    /// @since 2.80
    /// @param n index of property to get
    pub fn getProperty(self: *InterfaceInfo, arg_n: u32) *PropertyInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, u32) callconv(.c) *PropertyInfo, .{ .name = "gi_interface_info_get_property" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Obtain an interface type signal at index @n.
    /// @since 2.80
    /// @param n index of signal to get
    pub fn getSignal(self: *InterfaceInfo, arg_n: u32) *SignalInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, u32) callconv(.c) *SignalInfo, .{ .name = "gi_interface_info_get_signal" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Obtain an interface type virtual function at index @n.
    /// @since 2.80
    /// @param n index of virtual function to get
    pub fn getVfunc(self: *InterfaceInfo, arg_n: u32) *VFuncInfo {
        const cFn = @extern(*const fn (*InterfaceInfo, u32) callconv(.c) *VFuncInfo, .{ .name = "gi_interface_info_get_vfunc" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_interface_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// An error occurring while invoking a function via
/// [method@GIRepository.FunctionInfo.invoke].
/// @since 2.80
pub const InvokeError = enum(i32) {
    failed = 0,
    symbol_not_found = 1,
    argument_mismatch = 2,
};
/// `GIObjectInfo` represents a classed type.
///
/// Classed types in [type@GObject.Type] inherit from
/// [type@GObject.TypeInstance]; the most common type is [class@GObject.Object].
///
/// A `GIObjectInfo` doesn’t represent a specific instance of a classed type,
/// instead this represent the object type (i.e. the class).
///
/// A `GIObjectInfo` has methods, fields, properties, signals, interfaces,
/// constants and virtual functions.
/// @since 2.80
pub const ObjectInfo = struct {
    pub const Parent = RegisteredTypeInfo;
    /// Obtain a method of the object type given a @name.
    ///
    /// `NULL` will be returned if there’s no method available with that name.
    /// @since 2.80
    /// @param name name of method to obtain
    pub fn findMethod(self: *ObjectInfo, arg_name: [*:0]const u8) ?*FunctionInfo {
        const cFn = @extern(*const fn (*ObjectInfo, [*:0]const u8) callconv(.c) ?*FunctionInfo, .{ .name = "gi_object_info_find_method" });
        const ret = cFn(self, arg_name);
        return ret;
    }
    /// Obtain a method of the object given a @name, searching both the
    /// object @info and any interfaces it implements.
    ///
    /// `NULL` will be returned if there’s no method available with that name.
    ///
    /// Note that this function does *not* search parent classes; you will have
    /// to chain up if that’s desired.
    /// @since 2.80
    /// @param name name of method to obtain
    /// @param declarer The
    ///   [class@GIRepository.ObjectInfo] or [class@GIRepository.InterfaceInfo] which
    ///   declares the method, or `NULL` to ignore. If no method is found, this will
    ///   return `NULL`.
    pub fn findMethodUsingInterfaces(self: *ObjectInfo, arg_name: [*:0]const u8) struct {
        ret: ?*FunctionInfo,
        declarer: ?*BaseInfo,
    } {
        var argO_declarer: ?*BaseInfo = undefined;
        const arg_declarer: ?*?*BaseInfo = &argO_declarer;
        const cFn = @extern(*const fn (*ObjectInfo, [*:0]const u8, ?*?*BaseInfo) callconv(.c) ?*FunctionInfo, .{ .name = "gi_object_info_find_method_using_interfaces" });
        const ret = cFn(self, arg_name, arg_declarer);
        return .{ .ret = ret, .declarer = argO_declarer };
    }
    /// Obtain a signal of the object type given a @name.
    ///
    /// `NULL` will be returned if there’s no signal available with that name.
    /// @since 2.80
    /// @param name name of signal
    pub fn findSignal(self: *ObjectInfo, arg_name: [*:0]const u8) ?*SignalInfo {
        const cFn = @extern(*const fn (*ObjectInfo, [*:0]const u8) callconv(.c) ?*SignalInfo, .{ .name = "gi_object_info_find_signal" });
        const ret = cFn(self, arg_name);
        return ret;
    }
    /// Locate a virtual function slot with name @name.
    ///
    /// Note that the namespace for virtuals is distinct from that of methods; there
    /// may or may not be a concrete method associated for a virtual. If there is
    /// one, it may be retrieved using [method@GIRepository.VFuncInfo.get_invoker],
    /// otherwise that method will return `NULL`.
    ///
    /// See the documentation for [method@GIRepository.VFuncInfo.get_invoker] for
    /// more information on invoking virtuals.
    /// @since 2.80
    /// @param name the name of a virtual function to find.
    pub fn findVfunc(self: *ObjectInfo, arg_name: [*:0]const u8) ?*VFuncInfo {
        const cFn = @extern(*const fn (*ObjectInfo, [*:0]const u8) callconv(.c) ?*VFuncInfo, .{ .name = "gi_object_info_find_vfunc" });
        const ret = cFn(self, arg_name);
        return ret;
    }
    /// Locate a virtual function slot with name @name, searching both the object
    /// @info and any interfaces it implements.
    ///
    /// `NULL` will be returned if there’s no vfunc available with that name.
    ///
    /// Note that the namespace for virtuals is distinct from that of methods; there
    /// may or may not be a concrete method associated for a virtual. If there is
    /// one, it may be retrieved using [method@GIRepository.VFuncInfo.get_invoker],
    /// otherwise that method will return `NULL`.
    ///
    /// Note that this function does *not* search parent classes; you will have
    /// to chain up if that’s desired.
    /// @since 2.80
    /// @param name name of vfunc to obtain
    /// @param declarer The
    ///   [class@GIRepository.ObjectInfo] or [class@GIRepository.InterfaceInfo] which
    ///   declares the vfunc, or `NULL` to ignore. If no vfunc is found, this will
    ///   return `NULL`.
    pub fn findVfuncUsingInterfaces(self: *ObjectInfo, arg_name: [*:0]const u8) struct {
        ret: ?*VFuncInfo,
        declarer: ?*BaseInfo,
    } {
        var argO_declarer: ?*BaseInfo = undefined;
        const arg_declarer: ?*?*BaseInfo = &argO_declarer;
        const cFn = @extern(*const fn (*ObjectInfo, [*:0]const u8, ?*?*BaseInfo) callconv(.c) ?*VFuncInfo, .{ .name = "gi_object_info_find_vfunc_using_interfaces" });
        const ret = cFn(self, arg_name, arg_declarer);
        return .{ .ret = ret, .declarer = argO_declarer };
    }
    /// Obtain if the object type is an abstract type, i.e. if it cannot be
    /// instantiated.
    /// @since 2.80
    pub fn getAbstract(self: *ObjectInfo) bool {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) bool, .{ .name = "gi_object_info_get_abstract" });
        const ret = cFn(self);
        return ret;
    }
    /// Every [class@GObject.Object] has two structures; an instance structure and a
    /// class structure.  This function returns the metadata for the class structure.
    /// @since 2.80
    pub fn getClassStruct(self: *ObjectInfo) ?*StructInfo {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) ?*StructInfo, .{ .name = "gi_object_info_get_class_struct" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain an object type constant at index @n.
    /// @since 2.80
    /// @param n index of constant to get
    pub fn getConstant(self: *ObjectInfo, arg_n: u32) *ConstantInfo {
        const cFn = @extern(*const fn (*ObjectInfo, u32) callconv(.c) *ConstantInfo, .{ .name = "gi_object_info_get_constant" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Obtain an object type field at index @n.
    /// @since 2.80
    /// @param n index of field to get
    pub fn getField(self: *ObjectInfo, arg_n: u32) *FieldInfo {
        const cFn = @extern(*const fn (*ObjectInfo, u32) callconv(.c) *FieldInfo, .{ .name = "gi_object_info_get_field" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Checks whether the object type is a final type, i.e. if it cannot
    /// be derived.
    /// @since 2.80
    pub fn getFinal(self: *ObjectInfo) bool {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) bool, .{ .name = "gi_object_info_get_final" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain if the object type is of a fundamental type which is not
    /// `G_TYPE_OBJECT`.
    ///
    /// This is mostly for supporting `GstMiniObject`.
    /// @since 2.80
    pub fn getFundamental(self: *ObjectInfo) bool {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) bool, .{ .name = "gi_object_info_get_fundamental" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the symbol name of the function that should be called to convert
    /// an object instance pointer of this object type to a [type@GObject.Value].
    ///
    /// It’s mainly used for fundamental types. The type signature for the symbol
    /// is [type@GIRepository.ObjectInfoGetValueFunction]. To fetch the function
    /// pointer see [method@GIRepository.ObjectInfo.get_get_value_function_pointer].
    /// @since 2.80
    pub fn getGetValueFunctionName(self: *ObjectInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_object_info_get_get_value_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain a pointer to a function which can be used to extract an instance of
    /// this object type out of a [type@GObject.Value].
    ///
    /// This takes derivation into account and will reversely traverse
    /// the base classes of this type, starting at the top type.
    /// @since 2.80
    pub fn getGetValueFunctionPointer(self: *ObjectInfo) ObjectInfoGetValueFunction {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) ObjectInfoGetValueFunction, .{ .name = "gi_object_info_get_get_value_function_pointer" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain an object type interface at index @n.
    /// @since 2.80
    /// @param n index of interface to get
    pub fn getInterface(self: *ObjectInfo, arg_n: u32) *InterfaceInfo {
        const cFn = @extern(*const fn (*ObjectInfo, u32) callconv(.c) *InterfaceInfo, .{ .name = "gi_object_info_get_interface" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Obtain an object type method at index @n.
    /// @since 2.80
    /// @param n index of method to get
    pub fn getMethod(self: *ObjectInfo, arg_n: u32) *FunctionInfo {
        const cFn = @extern(*const fn (*ObjectInfo, u32) callconv(.c) *FunctionInfo, .{ .name = "gi_object_info_get_method" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Obtain the number of constants that this object type has.
    /// @since 2.80
    pub fn getNConstants(self: *ObjectInfo) u32 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) u32, .{ .name = "gi_object_info_get_n_constants" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the number of fields that this object type has.
    /// @since 2.80
    pub fn getNFields(self: *ObjectInfo) u32 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) u32, .{ .name = "gi_object_info_get_n_fields" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the number of interfaces that this object type has.
    /// @since 2.80
    pub fn getNInterfaces(self: *ObjectInfo) u32 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) u32, .{ .name = "gi_object_info_get_n_interfaces" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the number of methods that this object type has.
    /// @since 2.80
    pub fn getNMethods(self: *ObjectInfo) u32 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) u32, .{ .name = "gi_object_info_get_n_methods" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the number of properties that this object type has.
    /// @since 2.80
    pub fn getNProperties(self: *ObjectInfo) u32 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) u32, .{ .name = "gi_object_info_get_n_properties" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the number of signals that this object type has.
    /// @since 2.80
    pub fn getNSignals(self: *ObjectInfo) u32 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) u32, .{ .name = "gi_object_info_get_n_signals" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the number of virtual functions that this object type has.
    /// @since 2.80
    pub fn getNVfuncs(self: *ObjectInfo) u32 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) u32, .{ .name = "gi_object_info_get_n_vfuncs" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the parent of the object type.
    /// @since 2.80
    pub fn getParent(self: *ObjectInfo) ?*ObjectInfo {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) ?*ObjectInfo, .{ .name = "gi_object_info_get_parent" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain an object type property at index @n.
    /// @since 2.80
    /// @param n index of property to get
    pub fn getProperty(self: *ObjectInfo, arg_n: u32) *PropertyInfo {
        const cFn = @extern(*const fn (*ObjectInfo, u32) callconv(.c) *PropertyInfo, .{ .name = "gi_object_info_get_property" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Obtain the symbol name of the function that should be called to ref this
    /// object type.
    ///
    /// It’s mainly used for fundamental types. The type signature for
    /// the symbol is [type@GIRepository.ObjectInfoRefFunction]. To fetch the
    /// function pointer see
    /// [method@GIRepository.ObjectInfo.get_ref_function_pointer].
    /// @since 2.80
    pub fn getRefFunctionName(self: *ObjectInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_object_info_get_ref_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain a pointer to a function which can be used to
    /// increase the reference count an instance of this object type.
    ///
    /// This takes derivation into account and will reversely traverse
    /// the base classes of this type, starting at the top type.
    /// @since 2.80
    pub fn getRefFunctionPointer(self: *ObjectInfo) ObjectInfoRefFunction {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) ObjectInfoRefFunction, .{ .name = "gi_object_info_get_ref_function_pointer" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the symbol name of the function that should be called to set a
    /// [type@GObject.Value], given an object instance pointer of this object type.
    ///
    /// It’s mainly used for fundamental types. The type signature for the symbol
    /// is [type@GIRepository.ObjectInfoSetValueFunction]. To fetch the function
    /// pointer see [method@GIRepository.ObjectInfo.get_set_value_function_pointer].
    /// @since 2.80
    pub fn getSetValueFunctionName(self: *ObjectInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_object_info_get_set_value_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain a pointer to a function which can be used to set a
    /// [type@GObject.Value], given an instance of this object type.
    ///
    /// This takes derivation into account and will reversely traverse
    /// the base classes of this type, starting at the top type.
    /// @since 2.80
    pub fn getSetValueFunctionPointer(self: *ObjectInfo) ObjectInfoSetValueFunction {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) ObjectInfoSetValueFunction, .{ .name = "gi_object_info_get_set_value_function_pointer" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain an object type signal at index @n.
    /// @since 2.80
    /// @param n index of signal to get
    pub fn getSignal(self: *ObjectInfo, arg_n: u32) *SignalInfo {
        const cFn = @extern(*const fn (*ObjectInfo, u32) callconv(.c) *SignalInfo, .{ .name = "gi_object_info_get_signal" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Obtain the name of the function which, when called, will return the
    /// [type@GObject.Type] for this object type.
    /// @since 2.80
    pub fn getTypeInitFunctionName(self: *ObjectInfo) [*:0]u8 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) [*:0]u8, .{ .name = "gi_object_info_get_type_init_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the name of the object’s class/type.
    /// @since 2.80
    pub fn getTypeName(self: *ObjectInfo) [*:0]u8 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) [*:0]u8, .{ .name = "gi_object_info_get_type_name" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the symbol name of the function that should be called to unref this
    /// object type.
    ///
    /// It’s mainly used for fundamental types. The type signature for the symbol is
    /// [type@GIRepository.ObjectInfoUnrefFunction]. To fetch the function pointer
    /// see [method@GIRepository.ObjectInfo.get_unref_function_pointer].
    /// @since 2.80
    pub fn getUnrefFunctionName(self: *ObjectInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_object_info_get_unref_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain a pointer to a function which can be used to
    /// decrease the reference count an instance of this object type.
    ///
    /// This takes derivation into account and will reversely traverse
    /// the base classes of this type, starting at the top type.
    /// @since 2.80
    pub fn getUnrefFunctionPointer(self: *ObjectInfo) ObjectInfoUnrefFunction {
        const cFn = @extern(*const fn (*ObjectInfo) callconv(.c) ObjectInfoUnrefFunction, .{ .name = "gi_object_info_get_unref_function_pointer" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain an object type virtual function at index @n.
    /// @since 2.80
    /// @param n index of virtual function to get
    pub fn getVfunc(self: *ObjectInfo, arg_n: u32) *VFuncInfo {
        const cFn = @extern(*const fn (*ObjectInfo, u32) callconv(.c) *VFuncInfo, .{ .name = "gi_object_info_get_vfunc" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_object_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// Extract an object instance out of @value.
/// @since 2.80
/// @param value a [type@GObject.Value]
pub const ObjectInfoGetValueFunction = *const fn (arg_value: *GObject.Value) callconv(.c) ?*anyopaque;
/// Increases the reference count of an object instance.
/// @since 2.80
/// @param object object instance pointer
pub const ObjectInfoRefFunction = *const fn (arg_object: ?*anyopaque) callconv(.c) ?*anyopaque;
/// Update @value and attach the object instance pointer @object to it.
/// @since 2.80
/// @param value a [type@GObject.Value]
/// @param object object instance pointer
pub const ObjectInfoSetValueFunction = *const fn (arg_value: *GObject.Value, arg_object: ?*anyopaque) callconv(.c) void;
/// Decreases the reference count of an object instance.
/// @since 2.80
/// @param object object instance pointer
pub const ObjectInfoUnrefFunction = *const fn (arg_object: ?*anyopaque) callconv(.c) void;
/// `GIPropertyInfo` represents a property in a [class@GObject.Object].
///
/// A property belongs to either a [class@GIRepository.ObjectInfo] or a
/// [class@GIRepository.InterfaceInfo].
/// @since 2.80
pub const PropertyInfo = struct {
    pub const Parent = BaseInfo;
    /// Obtain the flags for this property info.
    ///
    /// See [type@GObject.ParamFlags] for more information about possible flag
    /// values.
    /// @since 2.80
    pub fn getFlags(self: *PropertyInfo) GObject.ParamFlags {
        const cFn = @extern(*const fn (*PropertyInfo) callconv(.c) GObject.ParamFlags, .{ .name = "gi_property_info_get_flags" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtains the getter function associated with this `GIPropertyInfo`.
    ///
    /// The setter is only available for `G_PARAM_READABLE` properties.
    /// @since 2.80
    pub fn getGetter(self: *PropertyInfo) ?*FunctionInfo {
        const cFn = @extern(*const fn (*PropertyInfo) callconv(.c) ?*FunctionInfo, .{ .name = "gi_property_info_get_getter" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the ownership transfer for this property.
    ///
    /// See [type@GIRepository.Transfer] for more information about transfer values.
    /// @since 2.80
    pub fn getOwnershipTransfer(self: *PropertyInfo) Transfer {
        const cFn = @extern(*const fn (*PropertyInfo) callconv(.c) Transfer, .{ .name = "gi_property_info_get_ownership_transfer" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtains the setter function associated with this `GIPropertyInfo`.
    ///
    /// The setter is only available for `G_PARAM_WRITABLE` properties that
    /// are also not `G_PARAM_CONSTRUCT_ONLY`.
    /// @since 2.80
    pub fn getSetter(self: *PropertyInfo) ?*FunctionInfo {
        const cFn = @extern(*const fn (*PropertyInfo) callconv(.c) ?*FunctionInfo, .{ .name = "gi_property_info_get_setter" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the type information for the property @info.
    /// @since 2.80
    pub fn getTypeInfo(self: *PropertyInfo) *TypeInfo {
        const cFn = @extern(*const fn (*PropertyInfo) callconv(.c) *TypeInfo, .{ .name = "gi_property_info_get_type_info" });
        const ret = cFn(self);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_property_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// `GIRegisteredTypeInfo` represents an entity with a [type@GObject.Type]
/// associated.
///
/// Could be either a [class@GIRepository.EnumInfo],
/// [class@GIRepository.InterfaceInfo], [class@GIRepository.ObjectInfo],
/// [class@GIRepository.StructInfo] or a [class@GIRepository.UnionInfo].
///
/// A registered type info struct has a name and a type function.
///
/// To get the name call [method@GIRepository.RegisteredTypeInfo.get_type_name].
/// Most users want to call [method@GIRepository.RegisteredTypeInfo.get_g_type]
/// and don’t worry about the rest of the details.
///
/// If the registered type is a subtype of `G_TYPE_BOXED`,
/// [method@GIRepository.RegisteredTypeInfo.is_boxed] will return true, and
/// [method@GIRepository.RegisteredTypeInfo.get_type_name] is guaranteed to
/// return a non-`NULL` value. This is relevant for the
/// [class@GIRepository.StructInfo] and [class@GIRepository.UnionInfo]
/// subclasses.
/// @since 2.80
pub const RegisteredTypeInfo = struct {
    pub const Parent = BaseInfo;
    /// Obtain the [type@GObject.Type] for this registered type.
    ///
    /// If there is no type information associated with @info, or the shared library
    /// which provides the `type_init` function for @info cannot be called, then
    /// `G_TYPE_NONE` is returned.
    /// @since 2.80
    pub fn getGType(self: *RegisteredTypeInfo) core.Type {
        const cFn = @extern(*const fn (*RegisteredTypeInfo) callconv(.c) core.Type, .{ .name = "gi_registered_type_info_get_g_type" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the type init function for @info.
    ///
    /// The type init function is the function which will register the
    /// [type@GObject.Type] within the GObject type system. Usually this is not
    /// called by language bindings or applications — use
    /// [method@GIRepository.RegisteredTypeInfo.get_g_type] directly instead.
    /// @since 2.80
    pub fn getTypeInitFunctionName(self: *RegisteredTypeInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*RegisteredTypeInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_registered_type_info_get_type_init_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the type name of the struct within the GObject type system.
    ///
    /// This type can be passed to [func@GObject.type_name] to get a
    /// [type@GObject.Type].
    /// @since 2.80
    pub fn getTypeName(self: *RegisteredTypeInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*RegisteredTypeInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_registered_type_info_get_type_name" });
        const ret = cFn(self);
        return ret;
    }
    /// Get whether the registered type is a boxed type.
    ///
    /// A boxed type is a subtype of the fundamental `G_TYPE_BOXED` type.
    /// It’s a type which has registered a [type@GObject.Type], and which has
    /// associated copy and free functions.
    ///
    /// Most boxed types are `struct`s; some are `union`s; and it’s possible for a
    /// boxed type to be neither, but that is currently unsupported by
    /// libgirepository. It’s also possible for a `struct` or `union` to have
    /// associated copy and/or free functions *without* being a boxed type, by virtue
    /// of not having registered a [type@GObject.Type].
    ///
    /// This function will return false for [type@GObject.Type]s which are not boxed,
    /// such as classes or interfaces. It will also return false for the `struct`s
    /// associated with a class or interface, which return true from
    /// [method@GIRepository.StructInfo.is_gtype_struct].
    /// @since 2.80
    pub fn isBoxed(self: *RegisteredTypeInfo) bool {
        const cFn = @extern(*const fn (*RegisteredTypeInfo) callconv(.c) bool, .{ .name = "gi_registered_type_info_is_boxed" });
        const ret = cFn(self);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_registered_type_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// `GIRepository` is used to manage repositories of namespaces. Namespaces
/// are represented on disk by type libraries (`.typelib` files).
///
/// The individual pieces of API within a type library are represented by
/// subclasses of [class@GIRepository.BaseInfo]. These can be found using
/// methods like [method@GIRepository.Repository.find_by_name] or
/// [method@GIRepository.Repository.get_info].
///
/// You are responsible for ensuring that the lifetime of the
/// [class@GIRepository.Repository] exceeds that of the lifetime of any of its
/// [class@GIRepository.BaseInfo]s. This cannot be guaranteed by using internal
/// references within libgirepository as that would affect performance.
///
/// ### Discovery of type libraries
///
/// `GIRepository` will typically look for a `girepository-1.0` directory
/// under the library directory used when compiling gobject-introspection. On a
/// standard Linux system this will end up being `/usr/lib/girepository-1.0`.
///
/// It is possible to control the search paths programmatically, using
/// [method@GIRepository.Repository.prepend_search_path]. It is also possible to
/// modify the search paths by using the `GI_TYPELIB_PATH` environment variable.
/// The environment variable takes precedence over the default search path
/// and the [method@GIRepository.Repository.prepend_search_path] calls.
///
/// ### Namespace ordering
///
/// In situations where namespaces may be searched in order, or returned in a
/// list, the namespaces will be returned in alphabetical order, with all fully
/// loaded namespaces being returned before any lazily loaded ones (those loaded
/// with `GI_REPOSITORY_LOAD_FLAG_LAZY`). This allows for deterministic and
/// reproducible results.
///
/// Similarly, if a symbol (such as a `GType` or error domain) is being searched
/// for in the set of loaded namespaces, the namespaces will be searched in that
/// order. In particular, this means that a symbol which exists in two namespaces
/// will always be returned from the alphabetically-higher namespace. This should
/// only happen in the case of `Gio` and `GioUnix`/`GioWin32`, which all refer to
/// the same `.so` file and expose overlapping sets of symbols. Symbols should
/// always end up being resolved to `GioUnix` or `GioWin32` if they are platform
/// dependent, rather than `Gio` itself.
/// @since 2.80
pub const Repository = struct {
    pub const Parent = GObject.Object;
    pub const Class = RepositoryClass;
    /// Create a new [class@GIRepository.Repository].
    /// @since 2.80
    pub fn new() *Repository {
        const cFn = @extern(*const fn () callconv(.c) *Repository, .{ .name = "gi_repository_new" });
        const ret = cFn();
        return ret;
    }
    /// Dump the introspection data from the types specified in @input_filename to
    /// @output_filename.
    ///
    /// The input file should be a
    /// UTF-8 Unix-line-ending text file, with each line containing either
    /// `get-type:` followed by the name of a [type@GObject.Type] `_get_type`
    /// function, or `error-quark:` followed by the name of an error quark function.
    /// No extra whitespace is allowed.
    ///
    /// This function will overwrite the contents of the output file.
    /// @since 2.80
    /// @param input_filename Input filename (for example `input.txt`)
    /// @param output_filename Output filename (for example `output.xml`)
    pub fn dump(arg_input_filename: [*:0]const u8, arg_output_filename: [*:0]const u8, arg_error: *?*GLib.Error) error{GError}!bool {
        const cFn = @extern(*const fn ([*:0]const u8, [*:0]const u8, *?*GLib.Error) callconv(.c) bool, .{ .name = "gi_repository_dump" });
        const ret = cFn(arg_input_filename, arg_output_filename, arg_error);
        if (arg_error.* != null) return error.GError;
        return ret;
    }
    pub fn errorQuark() GLib.Quark {
        const cFn = @extern(*const fn () callconv(.c) GLib.Quark, .{ .name = "gi_repository_error_quark" });
        const ret = cFn();
        return ret;
    }
    /// Obtain the option group for girepository.
    ///
    /// It’s used by the dumper and for programs that want to provide introspection
    /// information
    /// @since 2.80
    pub fn getOptionGroup() *GLib.OptionGroup {
        const cFn = @extern(*const fn () callconv(.c) *GLib.OptionGroup, .{ .name = "gi_repository_get_option_group" });
        const ret = cFn();
        return ret;
    }
    /// Obtain an unordered list of versions (either currently loaded or
    /// available) for @namespace_ in this @repository.
    ///
    /// The list is guaranteed to be `NULL` terminated. The `NULL` terminator is not
    /// counted in @n_versions_out.
    /// @since 2.80
    /// @param namespace_ GI namespace, e.g. `Gtk`
    /// @param n_versions_out The number of versions returned.
    pub fn enumerateVersions(self: *Repository, arg_namespace_: [*:0]const u8) [][*:0]const u8 {
        var argO_n_versions_out: u64 = undefined;
        const arg_n_versions_out: ?*u64 = &argO_n_versions_out;
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, ?*u64) callconv(.c) [*][*:0]const u8, .{ .name = "gi_repository_enumerate_versions" });
        const ret = cFn(self, arg_namespace_, arg_n_versions_out);
        return ret[0..@intCast(argO_n_versions_out)];
    }
    /// Searches for the enum type corresponding to the given [type@GLib.Error]
    /// domain.
    ///
    /// Before calling this function for a particular namespace, you must call
    /// [method@GIRepository.Repository.require] to load the namespace, or otherwise
    /// ensure the namespace has already been loaded.
    /// @since 2.80
    /// @param domain a [type@GLib.Error] domain
    pub fn findByErrorDomain(self: *Repository, arg_domain: GLib.Quark) ?*EnumInfo {
        const cFn = @extern(*const fn (*Repository, GLib.Quark) callconv(.c) ?*EnumInfo, .{ .name = "gi_repository_find_by_error_domain" });
        const ret = cFn(self, arg_domain);
        return ret;
    }
    /// Searches all loaded namespaces for a particular [type@GObject.Type].
    ///
    /// Note that in order to locate the metadata, the namespace corresponding to
    /// the type must first have been loaded.  There is currently no
    /// mechanism for determining the namespace which corresponds to an
    /// arbitrary [type@GObject.Type] — thus, this function will operate most
    /// reliably when you know the [type@GObject.Type] is from a loaded namespace.
    /// @since 2.80
    /// @param gtype [type@GObject.Type] to search for
    pub fn findByGtype(self: *Repository, arg_gtype: core.Type) ?*BaseInfo {
        const cFn = @extern(*const fn (*Repository, core.Type) callconv(.c) ?*BaseInfo, .{ .name = "gi_repository_find_by_gtype" });
        const ret = cFn(self, arg_gtype);
        return ret;
    }
    /// Searches for a particular entry in a namespace.
    ///
    /// Before calling this function for a particular namespace, you must call
    /// [method@GIRepository.Repository.require] to load the namespace, or otherwise
    /// ensure the namespace has already been loaded.
    /// @since 2.80
    /// @param namespace_ Namespace which will be searched
    /// @param name Entry name to find
    pub fn findByName(self: *Repository, arg_namespace_: [*:0]const u8, arg_name: [*:0]const u8) ?*BaseInfo {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, [*:0]const u8) callconv(.c) ?*BaseInfo, .{ .name = "gi_repository_find_by_name" });
        const ret = cFn(self, arg_namespace_, arg_name);
        return ret;
    }
    /// This function returns the ‘C prefix’, or the C level namespace
    /// associated with the given introspection namespace.
    ///
    /// Each C symbol starts with this prefix, as well each [type@GObject.Type] in
    /// the library.
    ///
    /// Note: The namespace must have already been loaded using a function
    /// such as [method@GIRepository.Repository.require] before calling this
    /// function.
    /// @since 2.80
    /// @param namespace_ Namespace to inspect
    pub fn getCPrefix(self: *Repository, arg_namespace_: [*:0]const u8) ?[*:0]u8 {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.c) ?[*:0]u8, .{ .name = "gi_repository_get_c_prefix" });
        const ret = cFn(self, arg_namespace_);
        return ret;
    }
    /// Retrieves all (transitive) versioned dependencies for
    /// @namespace_.
    ///
    /// The returned strings are of the form `namespace-version`.
    ///
    /// Note: @namespace_ must have already been loaded using a function
    /// such as [method@GIRepository.Repository.require] before calling this
    /// function.
    ///
    /// To get only the immediate dependencies for @namespace_, use
    /// [method@GIRepository.Repository.get_immediate_dependencies].
    ///
    /// The list is guaranteed to be `NULL` terminated. The `NULL` terminator is not
    /// counted in @n_dependencies_out.
    /// @since 2.80
    /// @param namespace_ Namespace of interest
    /// @param n_dependencies_out Return location for the number of
    ///   dependencies
    pub fn getDependencies(self: *Repository, arg_namespace_: [*:0]const u8) [][*:0]const u8 {
        var argO_n_dependencies_out: u64 = undefined;
        const arg_n_dependencies_out: ?*u64 = &argO_n_dependencies_out;
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, ?*u64) callconv(.c) [*][*:0]const u8, .{ .name = "gi_repository_get_dependencies" });
        const ret = cFn(self, arg_namespace_, arg_n_dependencies_out);
        return ret[0..@intCast(argO_n_dependencies_out)];
    }
    /// Return an array of the immediate versioned dependencies for @namespace_.
    /// Returned strings are of the form `namespace-version`.
    ///
    /// Note: @namespace_ must have already been loaded using a function
    /// such as [method@GIRepository.Repository.require] before calling this
    /// function.
    ///
    /// To get the transitive closure of dependencies for @namespace_, use
    /// [method@GIRepository.Repository.get_dependencies].
    ///
    /// The list is guaranteed to be `NULL` terminated. The `NULL` terminator is not
    /// counted in @n_dependencies_out.
    /// @since 2.80
    /// @param namespace_ Namespace of interest
    /// @param n_dependencies_out Return location for the number of
    ///   dependencies
    pub fn getImmediateDependencies(self: *Repository, arg_namespace_: [*:0]const u8) [][*:0]const u8 {
        var argO_n_dependencies_out: u64 = undefined;
        const arg_n_dependencies_out: ?*u64 = &argO_n_dependencies_out;
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, ?*u64) callconv(.c) [*][*:0]const u8, .{ .name = "gi_repository_get_immediate_dependencies" });
        const ret = cFn(self, arg_namespace_, arg_n_dependencies_out);
        return ret[0..@intCast(argO_n_dependencies_out)];
    }
    /// This function returns a particular metadata entry in the
    /// given namespace @namespace_.
    ///
    /// The namespace must have already been loaded before calling this function.
    /// See [method@GIRepository.Repository.get_n_infos] to find the maximum number
    /// of entries. It is an error to pass an invalid @idx to this function.
    /// @since 2.80
    /// @param namespace_ Namespace to inspect
    /// @param idx 0-based offset into namespace metadata for entry
    pub fn getInfo(self: *Repository, arg_namespace_: [*:0]const u8, arg_idx: u32) *BaseInfo {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, u32) callconv(.c) *BaseInfo, .{ .name = "gi_repository_get_info" });
        const ret = cFn(self, arg_namespace_, arg_idx);
        return ret;
    }
    /// Returns the current search path [class@GIRepository.Repository] will use when
    /// loading shared libraries referenced by imported namespaces.
    ///
    /// The list is internal to [class@GIRepository.Repository] and should not be
    /// freed, nor should its string elements.
    ///
    /// The list is guaranteed to be `NULL` terminated. The `NULL` terminator is not
    /// counted in @n_paths_out.
    /// @since 2.80
    /// @param n_paths_out The number of library paths returned.
    pub fn getLibraryPath(self: *Repository) [][*:0]const u8 {
        var argO_n_paths_out: u64 = undefined;
        const arg_n_paths_out: ?*u64 = &argO_n_paths_out;
        const cFn = @extern(*const fn (*Repository, ?*u64) callconv(.c) [*][*:0]const u8, .{ .name = "gi_repository_get_library_path" });
        const ret = cFn(self, arg_n_paths_out);
        return ret[0..@intCast(argO_n_paths_out)];
    }
    /// Return the list of currently loaded namespaces.
    ///
    /// The list is guaranteed to be `NULL` terminated. The `NULL` terminator is not
    /// counted in @n_namespaces_out.
    /// @since 2.80
    /// @param n_namespaces_out Return location for the number of
    ///   namespaces
    pub fn getLoadedNamespaces(self: *Repository) [][*:0]const u8 {
        var argO_n_namespaces_out: u64 = undefined;
        const arg_n_namespaces_out: ?*u64 = &argO_n_namespaces_out;
        const cFn = @extern(*const fn (*Repository, ?*u64) callconv(.c) [*][*:0]const u8, .{ .name = "gi_repository_get_loaded_namespaces" });
        const ret = cFn(self, arg_n_namespaces_out);
        return ret[0..@intCast(argO_n_namespaces_out)];
    }
    /// This function returns the number of metadata entries in
    /// given namespace @namespace_.
    ///
    /// The namespace must have already been loaded before calling this function.
    /// @since 2.80
    /// @param namespace_ Namespace to inspect
    pub fn getNInfos(self: *Repository, arg_namespace_: [*:0]const u8) u32 {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.c) u32, .{ .name = "gi_repository_get_n_infos" });
        const ret = cFn(self, arg_namespace_);
        return ret;
    }
    /// Look up the implemented interfaces for @gtype.
    ///
    /// This function cannot fail per se; but for a totally ‘unknown’
    /// [type@GObject.Type], it may return 0 implemented interfaces.
    ///
    /// The semantics of this function are designed for a dynamic binding,
    /// where in certain cases (such as a function which returns an
    /// interface which may have ‘hidden’ implementation classes), not all
    /// data may be statically known, and will have to be determined from
    /// the [type@GObject.Type] of the object.  An example is
    /// [func@Gio.File.new_for_path] returning a concrete class of
    /// `GLocalFile`, which is a [type@GObject.Type] we see at runtime, but
    /// not statically.
    /// @since 2.80
    /// @param gtype a [type@GObject.Type] whose fundamental type is `G_TYPE_OBJECT`
    /// @param n_interfaces_out Number of interfaces
    /// @param interfaces_out Interfaces for @gtype
    pub fn getObjectGtypeInterfaces(self: *Repository, arg_gtype: core.Type) []*[*]InterfaceInfo {
        var argO_n_interfaces_out: u64 = undefined;
        const arg_n_interfaces_out: *u64 = &argO_n_interfaces_out;
        var argO_interfaces_out: [*]*[*]InterfaceInfo = undefined;
        const arg_interfaces_out: *[*]*[*]InterfaceInfo = &argO_interfaces_out;
        const cFn = @extern(*const fn (*Repository, core.Type, *u64, *[*]*[*]InterfaceInfo) callconv(.c) void, .{ .name = "gi_repository_get_object_gtype_interfaces" });
        const ret = cFn(self, arg_gtype, arg_n_interfaces_out, arg_interfaces_out);
        _ = ret;
        return argO_interfaces_out[0..@intCast(argO_n_interfaces_out)];
    }
    /// Returns the current search path [class@GIRepository.Repository] will use when
    /// loading typelib files.
    ///
    /// The list is internal to [class@GIRepository.Repository] and should not be
    /// freed, nor should its string elements.
    ///
    /// The list is guaranteed to be `NULL` terminated. The `NULL` terminator is not
    /// counted in @n_paths_out.
    /// @since 2.80
    /// @param n_paths_out The number of search paths returned.
    pub fn getSearchPath(self: *Repository) [][*:0]const u8 {
        var argO_n_paths_out: u64 = undefined;
        const arg_n_paths_out: ?*u64 = &argO_n_paths_out;
        const cFn = @extern(*const fn (*Repository, ?*u64) callconv(.c) [*][*:0]const u8, .{ .name = "gi_repository_get_search_path" });
        const ret = cFn(self, arg_n_paths_out);
        return ret[0..@intCast(argO_n_paths_out)];
    }
    /// This function returns an array of paths to the
    /// shared C libraries associated with the given namespace @namespace_.
    ///
    /// There may be no shared library path associated, in which case this
    /// function will return `NULL`.
    ///
    /// Note: The namespace must have already been loaded using a function
    /// such as [method@GIRepository.Repository.require] before calling this
    /// function.
    ///
    /// The list is internal to [class@GIRepository.Repository] and should not be
    /// freed, nor should its string elements.
    ///
    /// The list is guaranteed to be `NULL` terminated. The `NULL` terminator is not
    /// counted in @out_n_elements.
    /// @since 2.80
    /// @param namespace_ Namespace to inspect
    /// @param out_n_elements Return location for the number of elements
    ///   in the returned array
    pub fn getSharedLibraries(self: *Repository, arg_namespace_: [*:0]const u8) [][*:0]const u8 {
        var argO_out_n_elements: u64 = undefined;
        const arg_out_n_elements: ?*u64 = &argO_out_n_elements;
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, ?*u64) callconv(.c) ?[*][*:0]const u8, .{ .name = "gi_repository_get_shared_libraries" });
        const ret = cFn(self, arg_namespace_, arg_out_n_elements);
        return ret[0..@intCast(argO_out_n_elements)];
    }
    /// If namespace @namespace_ is loaded, return the full path to the
    /// .typelib file it was loaded from.
    ///
    /// If the typelib for namespace @namespace_ was included in a shared library,
    /// return the special string `<builtin>`.
    /// @since 2.80
    /// @param namespace_ GI namespace to use, e.g. `Gtk`
    pub fn getTypelibPath(self: *Repository, arg_namespace_: [*:0]const u8) ?[*:0]u8 {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.c) ?[*:0]u8, .{ .name = "gi_repository_get_typelib_path" });
        const ret = cFn(self, arg_namespace_);
        return ret;
    }
    /// This function returns the loaded version associated with the given
    /// namespace @namespace_.
    ///
    /// Note: The namespace must have already been loaded using a function
    /// such as [method@GIRepository.Repository.require] before calling this
    /// function.
    /// @since 2.80
    /// @param namespace_ Namespace to inspect
    pub fn getVersion(self: *Repository, arg_namespace_: [*:0]const u8) [*:0]u8 {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.c) [*:0]u8, .{ .name = "gi_repository_get_version" });
        const ret = cFn(self, arg_namespace_);
        return ret;
    }
    /// Check whether a particular namespace (and optionally, a specific
    /// version thereof) is currently loaded.
    ///
    /// This function is likely to only be useful in unusual circumstances; in order
    /// to act upon metadata in the namespace, you should call
    /// [method@GIRepository.Repository.require] instead which will ensure the
    /// namespace is loaded, and return as quickly as this function will if it has
    /// already been loaded.
    /// @since 2.80
    /// @param namespace_ Namespace of interest
    /// @param version Required version, may be `NULL` for latest
    pub fn isRegistered(self: *Repository, arg_namespace_: [*:0]const u8, arg_version: ?[*:0]const u8) bool {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, ?[*:0]const u8) callconv(.c) bool, .{ .name = "gi_repository_is_registered" });
        const ret = cFn(self, arg_namespace_, arg_version);
        return ret;
    }
    /// Load the given @typelib into the repository.
    /// @since 2.80
    /// @param typelib the typelib to load
    /// @param flags flags affecting the loading operation
    pub fn loadTypelib(self: *Repository, arg_typelib: *Typelib, arg_flags: RepositoryLoadFlags, arg_error: *?*GLib.Error) error{GError}![*:0]u8 {
        const cFn = @extern(*const fn (*Repository, *Typelib, RepositoryLoadFlags, *?*GLib.Error) callconv(.c) [*:0]u8, .{ .name = "gi_repository_load_typelib" });
        const ret = cFn(self, arg_typelib, arg_flags, arg_error);
        if (arg_error.* != null) return error.GError;
        return ret;
    }
    /// Prepends @directory to the search path that is used to
    /// search shared libraries referenced by imported namespaces.
    ///
    /// Multiple calls to this function all contribute to the final
    /// list of paths.
    ///
    /// The list of paths is unique to @repository. When a typelib is loaded by the
    /// repository, the list of paths from the @repository at that instant is used
    /// by the typelib for loading its modules.
    ///
    /// If the library is not found in the directories configured
    /// in this way, loading will fall back to the system library
    /// path (i.e. `LD_LIBRARY_PATH` and `DT_RPATH` in ELF systems).
    /// See the documentation of your dynamic linker for full details.
    /// @since 2.80
    /// @param directory a single directory to scan for shared libraries
    pub fn prependLibraryPath(self: *Repository, arg_directory: [*:0]const u8) void {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.c) void, .{ .name = "gi_repository_prepend_library_path" });
        const ret = cFn(self, arg_directory);
        return ret;
    }
    /// Prepends @directory to the typelib search path.
    ///
    /// See also: gi_repository_get_search_path().
    /// @since 2.80
    /// @param directory directory name to prepend to the typelib
    ///   search path
    pub fn prependSearchPath(self: *Repository, arg_directory: [*:0]const u8) void {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8) callconv(.c) void, .{ .name = "gi_repository_prepend_search_path" });
        const ret = cFn(self, arg_directory);
        return ret;
    }
    /// Force the namespace @namespace_ to be loaded if it isn’t already.
    ///
    /// If @namespace_ is not loaded, this function will search for a
    /// `.typelib` file using the repository search path.  In addition, a
    /// version @version of namespace may be specified.  If @version is
    /// not specified, the latest will be used.
    /// @since 2.80
    /// @param namespace_ GI namespace to use, e.g. `Gtk`
    /// @param version Version of namespace, may be `NULL` for latest
    /// @param flags Set of [flags@GIRepository.RepositoryLoadFlags], may be 0
    pub fn require(self: *Repository, arg_namespace_: [*:0]const u8, arg_version: ?[*:0]const u8, arg_flags: RepositoryLoadFlags, arg_error: *?*GLib.Error) error{GError}!*Typelib {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, ?[*:0]const u8, RepositoryLoadFlags, *?*GLib.Error) callconv(.c) *Typelib, .{ .name = "gi_repository_require" });
        const ret = cFn(self, arg_namespace_, arg_version, arg_flags, arg_error);
        if (arg_error.* != null) return error.GError;
        return ret;
    }
    /// Force the namespace @namespace_ to be loaded if it isn’t already.
    ///
    /// If @namespace_ is not loaded, this function will search for a
    /// `.typelib` file within the private directory only. In addition, a
    /// version @version of namespace should be specified.  If @version is
    /// not specified, the latest will be used.
    /// @since 2.80
    /// @param typelib_dir Private directory where to find the requested
    ///   typelib
    /// @param namespace_ GI namespace to use, e.g. `Gtk`
    /// @param version Version of namespace, may be `NULL` for latest
    /// @param flags Set of [flags@GIRepository.RepositoryLoadFlags], may be 0
    pub fn requirePrivate(self: *Repository, arg_typelib_dir: [*:0]const u8, arg_namespace_: [*:0]const u8, arg_version: ?[*:0]const u8, arg_flags: RepositoryLoadFlags, arg_error: *?*GLib.Error) error{GError}!*Typelib {
        const cFn = @extern(*const fn (*Repository, [*:0]const u8, [*:0]const u8, ?[*:0]const u8, RepositoryLoadFlags, *?*GLib.Error) callconv(.c) *Typelib, .{ .name = "gi_repository_require_private" });
        const ret = cFn(self, arg_typelib_dir, arg_namespace_, arg_version, arg_flags, arg_error);
        if (arg_error.* != null) return error.GError;
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_repository_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
pub const RepositoryClass = extern struct {
    parent_class: GObject.ObjectClass,
};
/// An error code used with `GI_REPOSITORY_ERROR` in a [type@GLib.Error]
/// returned from a [class@GIRepository.Repository] routine.
/// @since 2.80
pub const RepositoryError = enum(i32) {
    typelib_not_found = 0,
    namespace_mismatch = 1,
    namespace_version_conflict = 2,
    library_not_found = 3,
};
/// Flags that control how a typelib is loaded.
/// @since 2.80
pub const RepositoryLoadFlags = packed struct(i32) {
    lazy: bool = false,
    _: u31 = 0,
};
/// Scope type of a [class@GIRepository.ArgInfo] representing callback,
/// determines how the callback is invoked and is used to decided when the invoke
/// structs can be freed.
/// @since 2.80
pub const ScopeType = gi.ScopeType; // enum(i32) {
//     invalid = 0,
//     call = 1,
//     async = 2,
//     notified = 3,
//     forever = 4,
// };
/// `GISignalInfo` represents a signal.
///
/// It’s a sub-struct of [class@GIRepository.CallableInfo] and contains a set of
/// flags and a class closure.
///
/// See [class@GIRepository.CallableInfo] for information on how to retrieve
/// arguments and other metadata from the signal.
/// @since 2.80
pub const SignalInfo = struct {
    pub const Parent = CallableInfo;
    /// Obtain the class closure for this signal if one is set.
    ///
    /// The class closure is a virtual function on the type that the signal belongs
    /// to. If the signal lacks a closure, `NULL` will be returned.
    /// @since 2.80
    pub fn getClassClosure(self: *SignalInfo) ?*VFuncInfo {
        const cFn = @extern(*const fn (*SignalInfo) callconv(.c) ?*VFuncInfo, .{ .name = "gi_signal_info_get_class_closure" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the flags for this signal info.
    ///
    /// See [flags@GObject.SignalFlags] for more information about possible flag
    /// values.
    /// @since 2.80
    pub fn getFlags(self: *SignalInfo) GObject.SignalFlags {
        const cFn = @extern(*const fn (*SignalInfo) callconv(.c) GObject.SignalFlags, .{ .name = "gi_signal_info_get_flags" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain if the returning `TRUE` in the signal handler will stop the emission
    /// of the signal.
    /// @since 2.80
    pub fn trueStopsEmit(self: *SignalInfo) bool {
        const cFn = @extern(*const fn (*SignalInfo) callconv(.c) bool, .{ .name = "gi_signal_info_true_stops_emit" });
        const ret = cFn(self);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_signal_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// `GIStructInfo` represents a generic C structure type.
///
/// A structure has methods and fields.
/// @since 2.80
pub const StructInfo = struct {
    pub const Parent = RegisteredTypeInfo;
    /// Obtain the type information for field named @name.
    /// @since 2.80
    /// @param name a field name
    pub fn findField(self: *StructInfo, arg_name: [*:0]const u8) ?*FieldInfo {
        const cFn = @extern(*const fn (*StructInfo, [*:0]const u8) callconv(.c) ?*FieldInfo, .{ .name = "gi_struct_info_find_field" });
        const ret = cFn(self, arg_name);
        return ret;
    }
    /// Obtain the type information for method named @name.
    /// @since 2.80
    /// @param name a method name
    pub fn findMethod(self: *StructInfo, arg_name: [*:0]const u8) ?*FunctionInfo {
        const cFn = @extern(*const fn (*StructInfo, [*:0]const u8) callconv(.c) ?*FunctionInfo, .{ .name = "gi_struct_info_find_method" });
        const ret = cFn(self, arg_name);
        return ret;
    }
    /// Obtain the required alignment of the structure.
    /// @since 2.80
    pub fn getAlignment(self: *StructInfo) u64 {
        const cFn = @extern(*const fn (*StructInfo) callconv(.c) u64, .{ .name = "gi_struct_info_get_alignment" });
        const ret = cFn(self);
        return ret;
    }
    /// Retrieves the name of the copy function for @info, if any is set.
    /// @since 2.80
    pub fn getCopyFunctionName(self: *StructInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*StructInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_struct_info_get_copy_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the type information for field with specified index.
    /// @since 2.80
    /// @param n a field index
    pub fn getField(self: *StructInfo, arg_n: u32) *FieldInfo {
        const cFn = @extern(*const fn (*StructInfo, u32) callconv(.c) *FieldInfo, .{ .name = "gi_struct_info_get_field" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Retrieves the name of the free function for @info, if any is set.
    /// @since 2.80
    pub fn getFreeFunctionName(self: *StructInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*StructInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_struct_info_get_free_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the type information for method with specified index.
    /// @since 2.80
    /// @param n a method index
    pub fn getMethod(self: *StructInfo, arg_n: u32) *FunctionInfo {
        const cFn = @extern(*const fn (*StructInfo, u32) callconv(.c) *FunctionInfo, .{ .name = "gi_struct_info_get_method" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Obtain the number of fields this structure has.
    /// @since 2.80
    pub fn getNFields(self: *StructInfo) u32 {
        const cFn = @extern(*const fn (*StructInfo) callconv(.c) u32, .{ .name = "gi_struct_info_get_n_fields" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the number of methods this structure has.
    /// @since 2.80
    pub fn getNMethods(self: *StructInfo) u32 {
        const cFn = @extern(*const fn (*StructInfo) callconv(.c) u32, .{ .name = "gi_struct_info_get_n_methods" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the total size of the structure.
    /// @since 2.80
    pub fn getSize(self: *StructInfo) u64 {
        const cFn = @extern(*const fn (*StructInfo) callconv(.c) u64, .{ .name = "gi_struct_info_get_size" });
        const ret = cFn(self);
        return ret;
    }
    /// Gets whether the structure is foreign, i.e. if it’s expected to be overridden
    /// by a native language binding instead of relying of introspected bindings.
    /// @since 2.80
    pub fn isForeign(self: *StructInfo) bool {
        const cFn = @extern(*const fn (*StructInfo) callconv(.c) bool, .{ .name = "gi_struct_info_is_foreign" });
        const ret = cFn(self);
        return ret;
    }
    /// Return true if this structure represents the ‘class structure’ for some
    /// [class@GObject.Object] or `GInterface`.
    ///
    /// This function is mainly useful to hide this kind of structure from generated
    /// public APIs.
    /// @since 2.80
    pub fn isGtypeStruct(self: *StructInfo) bool {
        const cFn = @extern(*const fn (*StructInfo) callconv(.c) bool, .{ .name = "gi_struct_info_is_gtype_struct" });
        const ret = cFn(self);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_struct_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// Number of entries in [enum@GIRepository.TypeTag].
/// @since 2.80
pub const TYPE_TAG_N_TYPES = 22;
/// `GITransfer` specifies who’s responsible for freeing the resources after an
/// ownership transfer is complete.
///
/// The transfer is the exchange of data between two parts, from the callee to
/// the caller.
///
/// The callee is either a function/method/signal or an object/interface where a
/// property is defined. The caller is the side accessing a property or calling a
/// function.
///
/// In the case of a containing type such as a list, an array or a hash table the
/// container itself is specified differently from the items within the
/// container. Each container is freed differently, check the documentation for
/// the types themselves for information on how to free them.
/// @since 2.80
pub const Transfer = gi.Transfer; // enum(i32) {
//     nothing = 0,
//     container = 1,
//     everything = 2,
// };
/// `GITypeInfo` represents a type, including information about direction and
/// transfer.
///
/// You can retrieve a type info from an argument (see
/// [class@GIRepository.ArgInfo]), a function’s return value (see
/// [class@GIRepository.FunctionInfo]), a field (see
/// [class@GIRepository.FieldInfo]), a property (see
/// [class@GIRepository.PropertyInfo]), a constant (see
/// [class@GIRepository.ConstantInfo]) or for a union discriminator (see
/// [class@GIRepository.UnionInfo]).
///
/// A type can either be a of a basic type which is a standard C primitive
/// type or an interface type. For interface types you need to call
/// [method@GIRepository.TypeInfo.get_interface] to get a reference to the base
/// info for that interface.
/// @since 2.80
pub const TypeInfo = extern struct {
    pub const Parent = BaseInfo;
    parent: BaseInfoStack,
    padding: [6]?*anyopaque,
    /// Convert a data pointer from a GLib data structure to a
    /// [type@GIRepository.Argument].
    ///
    /// GLib data structures, such as [type@GLib.List], [type@GLib.SList], and
    /// [type@GLib.HashTable], all store data pointers.
    ///
    /// In the case where the list or hash table is storing single types rather than
    /// structs, these data pointers may have values stuffed into them via macros
    /// such as `GPOINTER_TO_INT`.
    ///
    /// Use this function to ensure that all values are correctly extracted from
    /// stuffed pointers, regardless of the machine’s architecture or endianness.
    ///
    /// This function fills in the appropriate field of @arg with the value extracted
    /// from @hash_pointer, depending on the storage type of @info.
    /// @since 2.80
    /// @param hash_pointer a pointer, such as a [struct@GLib.HashTable] data pointer
    /// @param arg a [type@GIRepository.Argument] to fill in
    pub fn argumentFromHashPointer(self: *TypeInfo, arg_hash_pointer: ?*anyopaque, arg_arg: *Argument) void {
        const cFn = @extern(*const fn (*TypeInfo, ?*anyopaque, *Argument) callconv(.c) void, .{ .name = "gi_type_info_argument_from_hash_pointer" });
        const ret = cFn(self, @ptrCast(arg_hash_pointer), arg_arg);
        return ret;
    }
    /// Obtain the fixed array size of the type, in number of elements (not bytes).
    ///
    /// The type tag must be a `GI_TYPE_TAG_ARRAY` with a fixed size, or `FALSE` will
    /// be returned.
    /// @since 2.80
    /// @param out_size return location for the array size
    pub fn getArrayFixedSize(self: *TypeInfo) ?u64 {
        var argO_out_size: u64 = undefined;
        const arg_out_size: ?*u64 = &argO_out_size;
        const cFn = @extern(*const fn (*TypeInfo, ?*u64) callconv(.c) bool, .{ .name = "gi_type_info_get_array_fixed_size" });
        const ret = cFn(self, arg_out_size);
        if (!ret) return null;
        return argO_out_size;
    }
    /// Obtain the position of the argument which gives the array length of the type.
    ///
    /// The type tag must be a `GI_TYPE_TAG_ARRAY` with a length argument, or `FALSE`
    /// will be returned.
    /// @since 2.80
    /// @param out_length_index return location for the length argument
    pub fn getArrayLengthIndex(self: *TypeInfo) ?u32 {
        var argO_out_length_index: u32 = undefined;
        const arg_out_length_index: ?*u32 = &argO_out_length_index;
        const cFn = @extern(*const fn (*TypeInfo, ?*u32) callconv(.c) bool, .{ .name = "gi_type_info_get_array_length_index" });
        const ret = cFn(self, arg_out_length_index);
        if (!ret) return null;
        return argO_out_length_index;
    }
    /// Obtain the array type for this type.
    ///
    /// See [enum@GIRepository.ArrayType] for a list of possible values.
    ///
    /// It is an error to call this on an @info which is not an array type. Use
    /// [method@GIRepository.TypeInfo.get_tag] to check.
    /// @since 2.80
    pub fn getArrayType(self: *TypeInfo) ArrayType {
        const cFn = @extern(*const fn (*TypeInfo) callconv(.c) ArrayType, .{ .name = "gi_type_info_get_array_type" });
        const ret = cFn(self);
        return ret;
    }
    /// For types which have `GI_TYPE_TAG_INTERFACE` such as [class@GObject.Object]s
    /// and boxed values, this function returns full information about the referenced
    /// type.
    ///
    /// You can then inspect the type of the returned [class@GIRepository.BaseInfo]
    /// to further query whether it is a concrete [class@GObject.Object], an
    /// interface, a structure, etc., using the type checking macros like
    /// [func@GIRepository.IS_OBJECT_INFO], or raw [type@GObject.Type]s with
    /// [func@GObject.TYPE_FROM_INSTANCE].
    /// @since 2.80
    pub fn getInterface(self: *TypeInfo) ?*BaseInfo {
        const cFn = @extern(*const fn (*TypeInfo) callconv(.c) ?*BaseInfo, .{ .name = "gi_type_info_get_interface" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the parameter type @n, or `NULL` if the type is not an array.
    /// @since 2.80
    /// @param n index of the parameter
    pub fn getParamType(self: *TypeInfo, arg_n: u32) ?*TypeInfo {
        const cFn = @extern(*const fn (*TypeInfo, u32) callconv(.c) ?*TypeInfo, .{ .name = "gi_type_info_get_param_type" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Obtain the type tag corresponding to the underlying storage type in C for
    /// the type.
    ///
    /// See [type@GIRepository.TypeTag] for a list of type tags.
    /// @since 2.80
    pub fn getStorageType(self: *TypeInfo) TypeTag {
        const cFn = @extern(*const fn (*TypeInfo) callconv(.c) TypeTag, .{ .name = "gi_type_info_get_storage_type" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the type tag for the type.
    ///
    /// See [type@GIRepository.TypeTag] for a list of type tags.
    /// @since 2.80
    pub fn getTag(self: *TypeInfo) TypeTag {
        const cFn = @extern(*const fn (*TypeInfo) callconv(.c) TypeTag, .{ .name = "gi_type_info_get_tag" });
        const ret = cFn(self);
        return ret;
    }
    /// Convert a [type@GIRepository.Argument] to data pointer for use in a GLib
    /// data structure.
    ///
    /// GLib data structures, such as [type@GLib.List], [type@GLib.SList], and
    /// [type@GLib.HashTable], all store data pointers.
    ///
    /// In the case where the list or hash table is storing single types rather than
    /// structs, these data pointers may have values stuffed into them via macros
    /// such as `GPOINTER_TO_INT`.
    ///
    /// Use this function to ensure that all values are correctly stuffed into
    /// pointers, regardless of the machine’s architecture or endianness.
    ///
    /// This function returns a pointer stuffed with the appropriate field of @arg,
    /// depending on the storage type of @info.
    /// @since 2.80
    /// @param arg a [struct@GIRepository.Argument] with the value to stuff into a pointer
    pub fn hashPointerFromArgument(self: *TypeInfo, arg_arg: *Argument) ?*anyopaque {
        const cFn = @extern(*const fn (*TypeInfo, *Argument) callconv(.c) ?*anyopaque, .{ .name = "gi_type_info_hash_pointer_from_argument" });
        const ret = cFn(self, arg_arg);
        return ret;
    }
    /// Obtain if the type is passed as a reference.
    ///
    /// Note that the types of `GI_DIRECTION_OUT` and `GI_DIRECTION_INOUT` parameters
    /// will only be pointers if the underlying type being transferred is a pointer
    /// (i.e. only if the type of the C function’s formal parameter is a pointer to a
    /// pointer).
    /// @since 2.80
    pub fn isPointer(self: *TypeInfo) bool {
        const cFn = @extern(*const fn (*TypeInfo) callconv(.c) bool, .{ .name = "gi_type_info_is_pointer" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain if the last element of the array is `NULL`.
    ///
    /// The type tag must be a `GI_TYPE_TAG_ARRAY` or `FALSE` will be returned.
    /// @since 2.80
    pub fn isZeroTerminated(self: *TypeInfo) bool {
        const cFn = @extern(*const fn (*TypeInfo) callconv(.c) bool, .{ .name = "gi_type_info_is_zero_terminated" });
        const ret = cFn(self);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_type_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// The type tag of a [class@GIRepository.TypeInfo].
/// @since 2.80
pub const TypeTag = gi.TypeTag; // enum(i32) {
//     void = 0,
//     boolean = 1,
//     int8 = 2,
//     uint8 = 3,
//     int16 = 4,
//     uint16 = 5,
//     int32 = 6,
//     uint32 = 7,
//     int64 = 8,
//     uint64 = 9,
//     float = 10,
//     double = 11,
//     gtype = 12,
//     utf8 = 13,
//     filename = 14,
//     array = 15,
//     interface = 16,
//     glist = 17,
//     gslist = 18,
//     ghash = 19,
//     @"error" = 20,
//     unichar = 21,
// };
/// `GITypelib` represents a loaded `.typelib` file, which contains a description
/// of a single module’s API.
/// @since 2.80
pub const Typelib = opaque {
    /// Creates a new [type@GIRepository.Typelib] from a [type@GLib.Bytes].
    ///
    /// The [type@GLib.Bytes] can point to a memory location or a mapped file, and
    /// the typelib will hold a reference to it until the repository is destroyed.
    /// @since 2.80
    /// @param bytes memory chunk containing the typelib
    pub fn newFromBytes(arg_bytes: *GLib.Bytes, arg_error: *?*GLib.Error) error{GError}!*Typelib {
        const cFn = @extern(*const fn (*GLib.Bytes, *?*GLib.Error) callconv(.c) *Typelib, .{ .name = "gi_typelib_new_from_bytes" });
        const ret = cFn(arg_bytes, arg_error);
        if (arg_error.* != null) return error.GError;
        return ret;
    }
    /// Get the name of the namespace represented by @typelib.
    /// @since 2.80
    pub fn getNamespace(self: *Typelib) [*:0]u8 {
        const cFn = @extern(*const fn (*Typelib) callconv(.c) [*:0]u8, .{ .name = "gi_typelib_get_namespace" });
        const ret = cFn(self);
        return ret;
    }
    /// Increment the reference count of a [type@GIRepository.Typelib].
    /// @since 2.80
    pub fn ref(self: *Typelib) *Typelib {
        const cFn = @extern(*const fn (*Typelib) callconv(.c) *Typelib, .{ .name = "gi_typelib_ref" });
        const ret = cFn(self);
        return ret;
    }
    /// Loads a symbol from a `GITypelib`.
    /// @since 2.80
    /// @param symbol_name name of symbol to be loaded
    /// @param symbol returns a pointer to the symbol value, or `NULL`
    ///   on failure
    pub fn symbol(self: *Typelib, arg_symbol_name: [*:0]const u8) struct {
        ret: bool,
        symbol: ?*anyopaque,
    } {
        var argO_symbol: *anyopaque = undefined;
        const arg_symbol: *anyopaque = &argO_symbol;
        const cFn = @extern(*const fn (*Typelib, [*:0]const u8, *anyopaque) callconv(.c) bool, .{ .name = "gi_typelib_symbol" });
        const ret = cFn(self, arg_symbol_name, @ptrCast(arg_symbol));
        return .{ .ret = ret, .symbol = argO_symbol };
    }
    /// Decrement the reference count of a [type@GIRepository.Typelib].
    ///
    /// Once the reference count reaches zero, the typelib is freed.
    /// @since 2.80
    pub fn unref(self: *Typelib) void {
        const cFn = @extern(*const fn (*Typelib) callconv(.c) void, .{ .name = "gi_typelib_unref" });
        const ret = cFn(self);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_typelib_get_type" });
        return cFn();
    }
};
/// `GIUnionInfo` represents a union type.
///
/// A union has methods and fields.  Unions can optionally have a
/// discriminator, which is a field deciding what type of real union
/// fields is valid for specified instance.
/// @since 2.80
pub const UnionInfo = struct {
    pub const Parent = RegisteredTypeInfo;
    /// Obtain the type information for the method named @name.
    /// @since 2.80
    /// @param name a method name
    pub fn findMethod(self: *UnionInfo, arg_name: [*:0]const u8) ?*FunctionInfo {
        const cFn = @extern(*const fn (*UnionInfo, [*:0]const u8) callconv(.c) ?*FunctionInfo, .{ .name = "gi_union_info_find_method" });
        const ret = cFn(self, arg_name);
        return ret;
    }
    /// Obtain the required alignment of the union.
    /// @since 2.80
    pub fn getAlignment(self: *UnionInfo) u64 {
        const cFn = @extern(*const fn (*UnionInfo) callconv(.c) u64, .{ .name = "gi_union_info_get_alignment" });
        const ret = cFn(self);
        return ret;
    }
    /// Retrieves the name of the copy function for @info, if any is set.
    /// @since 2.80
    pub fn getCopyFunctionName(self: *UnionInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*UnionInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_union_info_get_copy_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the discriminator value assigned for n-th union field, i.e. the n-th
    /// union field is the active one if the discriminator contains this
    /// constant.
    ///
    /// If the union is not discriminated, `NULL` is returned.
    /// @since 2.80
    /// @param n a union field index
    pub fn getDiscriminator(self: *UnionInfo, arg_n: u64) ?*ConstantInfo {
        const cFn = @extern(*const fn (*UnionInfo, u64) callconv(.c) ?*ConstantInfo, .{ .name = "gi_union_info_get_discriminator" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Obtain the offset of the discriminator field within the structure.
    ///
    /// The union must be discriminated, or `FALSE` will be returned.
    /// @since 2.80
    /// @param out_offset return location for the offset, in bytes, of
    ///   the discriminator
    pub fn getDiscriminatorOffset(self: *UnionInfo) ?u64 {
        var argO_out_offset: u64 = undefined;
        const arg_out_offset: ?*u64 = &argO_out_offset;
        const cFn = @extern(*const fn (*UnionInfo, ?*u64) callconv(.c) bool, .{ .name = "gi_union_info_get_discriminator_offset" });
        const ret = cFn(self, arg_out_offset);
        if (!ret) return null;
        return argO_out_offset;
    }
    /// Obtain the type information of the union discriminator.
    /// @since 2.80
    pub fn getDiscriminatorType(self: *UnionInfo) ?*TypeInfo {
        const cFn = @extern(*const fn (*UnionInfo) callconv(.c) ?*TypeInfo, .{ .name = "gi_union_info_get_discriminator_type" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the type information for the field with the specified index.
    /// @since 2.80
    /// @param n a field index
    pub fn getField(self: *UnionInfo, arg_n: u32) *FieldInfo {
        const cFn = @extern(*const fn (*UnionInfo, u32) callconv(.c) *FieldInfo, .{ .name = "gi_union_info_get_field" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Retrieves the name of the free function for @info, if any is set.
    /// @since 2.80
    pub fn getFreeFunctionName(self: *UnionInfo) ?[*:0]u8 {
        const cFn = @extern(*const fn (*UnionInfo) callconv(.c) ?[*:0]u8, .{ .name = "gi_union_info_get_free_function_name" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the type information for the method with the specified index.
    /// @since 2.80
    /// @param n a method index
    pub fn getMethod(self: *UnionInfo, arg_n: u32) *FunctionInfo {
        const cFn = @extern(*const fn (*UnionInfo, u32) callconv(.c) *FunctionInfo, .{ .name = "gi_union_info_get_method" });
        const ret = cFn(self, arg_n);
        return ret;
    }
    /// Obtain the number of fields this union has.
    /// @since 2.80
    pub fn getNFields(self: *UnionInfo) u32 {
        const cFn = @extern(*const fn (*UnionInfo) callconv(.c) u32, .{ .name = "gi_union_info_get_n_fields" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the number of methods this union has.
    /// @since 2.80
    pub fn getNMethods(self: *UnionInfo) u32 {
        const cFn = @extern(*const fn (*UnionInfo) callconv(.c) u32, .{ .name = "gi_union_info_get_n_methods" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the total size of the union.
    /// @since 2.80
    pub fn getSize(self: *UnionInfo) u64 {
        const cFn = @extern(*const fn (*UnionInfo) callconv(.c) u64, .{ .name = "gi_union_info_get_size" });
        const ret = cFn(self);
        return ret;
    }
    /// Return `TRUE` if this union contains a discriminator field.
    /// @since 2.80
    pub fn isDiscriminated(self: *UnionInfo) bool {
        const cFn = @extern(*const fn (*UnionInfo) callconv(.c) bool, .{ .name = "gi_union_info_is_discriminated" });
        const ret = cFn(self);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_union_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// `GIUnresolvedInfo` represents an unresolved symbol.
/// @since 2.80
pub const UnresolvedInfo = struct {
    pub const Parent = BaseInfo;
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_unresolved_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// `GIVFuncInfo` represents a virtual function.
///
/// A virtual function is a callable object that belongs to either a
/// [type@GIRepository.ObjectInfo] or a [type@GIRepository.InterfaceInfo].
/// @since 2.80
pub const VFuncInfo = struct {
    pub const Parent = CallableInfo;
    /// Looks up where the implementation for @info is inside the type struct of
    /// @implementor_gtype.
    /// @since 2.80
    /// @param implementor_gtype [type@GObject.Type] implementing this virtual function
    pub fn getAddress(self: *VFuncInfo, arg_implementor_gtype: core.Type, arg_error: *?*GLib.Error) error{GError}!?*anyopaque {
        const cFn = @extern(*const fn (*VFuncInfo, core.Type, *?*GLib.Error) callconv(.c) ?*anyopaque, .{ .name = "gi_vfunc_info_get_address" });
        const ret = cFn(self, arg_implementor_gtype, arg_error);
        if (arg_error.* != null) return error.GError;
        return ret;
    }
    /// Obtain the flags for this virtual function info.
    ///
    /// See [flags@GIRepository.VFuncInfoFlags] for more information about possible
    /// flag values.
    /// @since 2.80
    pub fn getFlags(self: *VFuncInfo) VFuncInfoFlags {
        const cFn = @extern(*const fn (*VFuncInfo) callconv(.c) VFuncInfoFlags, .{ .name = "gi_vfunc_info_get_flags" });
        const ret = cFn(self);
        return ret;
    }
    /// If this virtual function has an associated invoker method, this
    /// method will return it.  An invoker method is a C entry point.
    ///
    /// Not all virtuals will have invokers.
    /// @since 2.80
    pub fn getInvoker(self: *VFuncInfo) ?*FunctionInfo {
        const cFn = @extern(*const fn (*VFuncInfo) callconv(.c) ?*FunctionInfo, .{ .name = "gi_vfunc_info_get_invoker" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the offset of the function pointer in the class struct.
    ///
    /// The value `0xFFFF` indicates that the struct offset is unknown.
    /// @since 2.80
    pub fn getOffset(self: *VFuncInfo) u64 {
        const cFn = @extern(*const fn (*VFuncInfo) callconv(.c) u64, .{ .name = "gi_vfunc_info_get_offset" });
        const ret = cFn(self);
        return ret;
    }
    /// Obtain the signal for the virtual function if one is set.
    ///
    /// The signal comes from the object or interface to which
    /// this virtual function belongs.
    /// @since 2.80
    pub fn getSignal(self: *VFuncInfo) ?*SignalInfo {
        const cFn = @extern(*const fn (*VFuncInfo) callconv(.c) ?*SignalInfo, .{ .name = "gi_vfunc_info_get_signal" });
        const ret = cFn(self);
        return ret;
    }
    /// Invokes the function described in @info with the given
    /// arguments.
    ///
    /// Note that ‘inout’ parameters must appear in both argument lists.
    /// @since 2.80
    /// @param implementor [type@GObject.Type] of the type that implements this virtual
    ///   function
    /// @param in_args an array of
    ///   [struct@GIRepository.Argument]s, one for each ‘in’ parameter of @info. If
    ///   there are no ‘in’ parameters, @in_args can be `NULL`
    /// @param n_in_args the length of the @in_args array
    /// @param out_args an array of
    ///   [struct@GIRepository.Argument]s allocated by the caller, one for each
    ///   ‘out’ parameter of @info. If there are no ‘out’ parameters, @out_args may
    ///   be `NULL`
    /// @param n_out_args the length of the @out_args array
    /// @param return_value return
    ///   location for the return value from the vfunc; `NULL` may be returned if
    ///   the vfunc returns that
    pub fn invoke(self: *VFuncInfo, arg_implementor: core.Type, argS_in_args: ?[]Argument, argS_out_args: ?[]Argument, arg_return_value: *Argument, arg_error: *?*GLib.Error) error{GError}!bool {
        const arg_in_args: ?[*]Argument = @ptrCast(argS_in_args);
        const arg_n_in_args: u64 = @intCast((argS_in_args orelse &.{}).len);
        const arg_out_args: ?[*]Argument = @ptrCast(argS_out_args);
        const arg_n_out_args: u64 = @intCast((argS_out_args orelse &.{}).len);
        const cFn = @extern(*const fn (*VFuncInfo, core.Type, ?[*]Argument, u64, ?[*]Argument, u64, *Argument, *?*GLib.Error) callconv(.c) bool, .{ .name = "gi_vfunc_info_invoke" });
        const ret = cFn(self, arg_implementor, arg_in_args, arg_n_in_args, arg_out_args, arg_n_out_args, arg_return_value, arg_error);
        if (arg_error.* != null) return error.GError;
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_vfunc_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// Flags of a [class@GIRepository.VFuncInfo] struct.
/// @since 2.80
pub const VFuncInfoFlags = packed struct(i32) {
    chain_up: bool = false,
    override: bool = false,
    not_override: bool = false,
    _: u29 = 0,
};
/// A `GIValueInfo` represents a value in an enumeration.
///
/// The `GIValueInfo` is fetched by calling
/// [method@GIRepository.EnumInfo.get_value] on a [class@GIRepository.EnumInfo].
/// @since 2.80
pub const ValueInfo = struct {
    pub const Parent = BaseInfo;
    /// Obtain the enumeration value of the `GIValueInfo`.
    /// @since 2.80
    pub fn getValue(self: *ValueInfo) i64 {
        const cFn = @extern(*const fn (*ValueInfo) callconv(.c) i64, .{ .name = "gi_value_info_get_value" });
        const ret = cFn(self);
        return ret;
    }
    pub fn gType() core.Type {
        const cFn = @extern(*const fn () callconv(.c) core.Type, .{ .name = "gi_value_info_get_type" });
        return cFn();
    }
    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
};
/// A generic C closure marshal function using ffi and
/// [type@GIRepository.Argument].
/// @since 2.80
/// @param closure a [type@GObject.Closure]
/// @param return_gvalue return location for the
///   return value from the closure, or `NULL` to ignore
/// @param n_param_values number of param values
/// @param param_values values to pass to the closure
///   parameters
/// @param invocation_hint invocation hint
/// @param marshal_data marshal data
pub fn cclosureMarshalGeneric(arg_closure: *GObject.Closure, arg_return_gvalue: ?*GObject.Value, argS_param_values: []GObject.Value, arg_invocation_hint: ?*anyopaque, arg_marshal_data: ?*anyopaque) void {
    const arg_n_param_values: u32 = @intCast((argS_param_values).len);
    const arg_param_values: [*]GObject.Value = @ptrCast(argS_param_values);
    const cFn = @extern(*const fn (*GObject.Closure, ?*GObject.Value, u32, [*]GObject.Value, ?*anyopaque, ?*anyopaque) callconv(.c) void, .{ .name = "gi_cclosure_marshal_generic" });
    const ret = cFn(arg_closure, arg_return_gvalue, arg_n_param_values, arg_param_values, @ptrCast(arg_invocation_hint), @ptrCast(arg_marshal_data));
    return ret;
}
/// Get the error quark which represents [type@GIRepository.InvokeError].
/// @since 2.80
pub fn invokeErrorQuark() GLib.Quark {
    const cFn = @extern(*const fn () callconv(.c) GLib.Quark, .{ .name = "gi_invoke_error_quark" });
    const ret = cFn();
    return ret;
}
/// Convert a data pointer from a GLib data structure to a
/// [type@GIRepository.Argument].
///
/// GLib data structures, such as [type@GLib.List], [type@GLib.SList], and
/// [type@GLib.HashTable], all store data pointers.
///
/// In the case where the list or hash table is storing single types rather than
/// structs, these data pointers may have values stuffed into them via macros
/// such as `GPOINTER_TO_INT`.
///
/// Use this function to ensure that all values are correctly extracted from
/// stuffed pointers, regardless of the machine’s architecture or endianness.
///
/// This function fills in the appropriate field of @arg with the value extracted
/// from @hash_pointer, depending on @storage_type.
/// @since 2.80
/// @param storage_type a [type@GIRepository.TypeTag] obtained from
///   [method@GIRepository.TypeInfo.get_storage_type]
/// @param hash_pointer a pointer, such as a [struct@GLib.HashTable] data pointer
/// @param arg a [type@GIRepository.Argument]
///   to fill in
pub fn typeTagArgumentFromHashPointer(arg_storage_type: TypeTag, arg_hash_pointer: ?*anyopaque, arg_arg: *Argument) void {
    const cFn = @extern(*const fn (TypeTag, ?*anyopaque, *Argument) callconv(.c) void, .{ .name = "gi_type_tag_argument_from_hash_pointer" });
    const ret = cFn(arg_storage_type, @ptrCast(arg_hash_pointer), arg_arg);
    return ret;
}
/// Convert a [type@GIRepository.Argument] to data pointer for use in a GLib
/// data structure.
///
/// GLib data structures, such as [type@GLib.List], [type@GLib.SList], and
/// [type@GLib.HashTable], all store data pointers.
///
/// In the case where the list or hash table is storing single types rather than
/// structs, these data pointers may have values stuffed into them via macros
/// such as `GPOINTER_TO_INT`.
///
/// Use this function to ensure that all values are correctly stuffed into
/// pointers, regardless of the machine’s architecture or endianness.
///
/// This function returns a pointer stuffed with the appropriate field of @arg,
/// depending on @storage_type.
/// @since 2.80
/// @param storage_type a [type@GIRepository.TypeTag] obtained from
///   [method@GIRepository.TypeInfo.get_storage_type]
/// @param arg a [type@GIRepository.Argument] with the value to stuff into a pointer
pub fn typeTagHashPointerFromArgument(arg_storage_type: TypeTag, arg_arg: *Argument) ?*anyopaque {
    const cFn = @extern(*const fn (TypeTag, *Argument) callconv(.c) ?*anyopaque, .{ .name = "gi_type_tag_hash_pointer_from_argument" });
    const ret = cFn(arg_storage_type, arg_arg);
    return ret;
}
/// Obtain a string representation of @type
/// @since 2.80
/// @param type the type_tag
pub fn typeTagToString(arg_type: TypeTag) [*:0]u8 {
    const cFn = @extern(*const fn (TypeTag) callconv(.c) [*:0]u8, .{ .name = "gi_type_tag_to_string" });
    const ret = cFn(arg_type);
    return ret;
}
