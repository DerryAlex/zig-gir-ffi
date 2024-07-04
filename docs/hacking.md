## Hacking

### Dependency

Ensure you have the required dependency:

- GIRepository 2.0, which is part of GLib since version 2.80

You can install it from a package manager (e.g., `apt-get install libgirepository-2.0-0`) or build it from [source](https://gitlab.gnome.org/GNOME/glib/).

### Update typelibs

Update `gir_version` in `lib/girepository-1.0/ci.sh`. 

### Architecture

`main.zig` handles command line options and does some simple dispatch. `girepository-2.0.zig` is generated from `GIRepository-3.0.typelib` using the generator and `core_min.zig` is a minimum file to support it. The logic of generating is in `gi-ext.zig`, which abuses zig's formatting.

You are suggested to read in the following order:

- `EnumInfoExt`, `FlagsInfoExt`, `InterfaceInfoExt`, `ObjectInfoExt`, `StructInfoExt` and `UnionInfoExt`. Simply emit their fields and methods.

- `ValueInfoExt` then `ConstantInfoExt`. Almost independent.

- `TypeInfoExt`.

- `ArgInfoExt` and `FieldInfoExt`.

- `FunctionInfoExt` and its helper `CallableInfoExt`. This is relatively complex.

- `CallbackInfoExt`, `PropertyInfoExt`, `RegisteredTypeInfoExt`, `SignalInfoExt` and `VFuncInfoExt`. Simple but may be confusing if you are not familiar with other `Ext`s.
