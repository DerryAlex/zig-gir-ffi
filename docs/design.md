## Design

### Object

Object marks its `Parent`, `Class` and optionally `Interfaces`. The comptime magic happens in `core.Extend` which provides functionalities including access to property and type-safe signal.

To define custom object, provide `gType` (through `core.registerType`) and `new` (through `core.newObject`). For more details, see examples/custom or dive into core.zig.

#### Property

Properties of an object will be listed in the comment. User can use `object.property(T, property_name)` to access.

To define custom property, provide `properties` in class, which returns a slice of properties. Override `Object.get_property` and `Object.set_property` if you expect them to work properly. Getter and setter method will usally be provided.

#### Signal

A `connectSIGNAL` method will be generated for each signal.

To define custom signal, provide `signals` in class, which returns a slice of signal ids. Provide a connect method for each signal.

#### Vfunc

A method with V suffix will be generated.

> *Warning*: The override syntax has not been finalized.

### Interface

See example/interface.

> *Warning*: The override syntax has not been finalized.
