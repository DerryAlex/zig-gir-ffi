const std = @import("std");
const root = @import("root");
const Gtk = root.Gtk;
const core = Gtk.core;
const template = Gtk.template;
const meta = std.meta;
const assert = std.debug.assert;
const ExampleApp = @import("example_app.zig").ExampleApp;

pub const CstrContext = struct {
    pub fn hash(self: CstrContext, key: [*:0]const u8) u64 {
        _ = self;
        return std.hash.Wyhash.hash(0, key[0..std.mem.indexOfSentinel(u8, 0, key)]);
    }

    pub fn eql(self: CstrContext, a: [*:0]const u8, b: [*:0]const u8) bool {
        _ = self;
        return std.cstr.cmp(a, b) == 0;
    }
};

pub const ExampleAppWindowClass = extern struct {
    parent: Gtk.ApplicationWindowClass,

    pub fn init(self: *ExampleAppWindowClass) callconv(.C) void {
        var object_class = @ptrCast(*core.ObjectClass, self);
        object_class.dispose = &dispose;
        var widget_class = @ptrCast(*Gtk.WidgetClass, self);
        widget_class.setTemplateFromResource("/org/gtk/exampleapp/window.ui");
        template.bindChild(widget_class, ExampleAppWindowImpl);
        template.bindCallback(widget_class, ExampleAppWindowClass);
    }

    pub fn dispose(object: core.Object) callconv(.C) void {
        var win = object.tryInto(ExampleAppWindow).?;
        win.disposeOverride();
    }

    pub fn TCsearch_text_changed(entry: Gtk.Entry, win: ExampleAppWindow) callconv(.C) void {
        var text = entry.callMethod("getText", .{});
        if (text[0] == 0) return;
        var tab = win.instance.TCstack.getVisibleChild().expect("visible child").tryInto(Gtk.ScrolledWindow).?;
        var view = tab.getChild().expect("child").tryInto(Gtk.TextView).?;
        var buffer = view.getBuffer();
        var start = buffer.getStartIter();
        var success = start.forwardSearch(text, .CaseInsensitive, null);
        switch (success) {
            .Ok => |ret| {
                var match_start = ret.match_start;
                var match_end = ret.match_end;
                buffer.selectRange(&match_start, &match_end);
                _ = view.scrollToIter(&match_start, 0, core.Boolean.False, 0, 0);
            },
            .Err => {},
        }
    }

    pub fn TCvisible_child_changed(stack: Gtk.Stack, _: core.ParamSpec, win: ExampleAppWindow) callconv(.C) void {
        if (stack.callMethod("inDestruction", .{}).toBool()) return;
        win.instance.TCsearchbar.setSearchMode(core.Boolean.False);
        win.updateWords();
        win.updateLines();
    }
};

const ExampleAppWindowImpl = extern struct {
    parent: Gtk.ApplicationWindow.cType(),
    settings: core.Settings,
    TCstack: Gtk.Stack,
    TCgears: Gtk.MenuButton,
    TCsearch: Gtk.ToggleButton,
    TCsearchbar: Gtk.SearchBar,
    TCsearchentry: Gtk.SearchEntry,
    TCsidebar: Gtk.Revealer,
    TCwords: Gtk.ListBox,
    TClines: Gtk.Label,
    TClines_label: Gtk.Label,
};

pub const ExampleAppWindowNullable = packed struct {
    ptr: ?*ExampleAppWindowImpl,

    pub fn expect(self: ExampleAppWindowNullable, message: []const u8) ExampleAppWindow {
        if (self.ptr) |some| {
            return ExampleAppWindow{ .instance = some };
        } else @panic(message);
    }

    pub fn wrap(self: ExampleAppWindowNullable) ?ExampleAppWindow {
        return if (self.ptr) |some| ExampleAppWindow{ .instance = some } else null;
    }
};

pub const ExampleAppWindow = packed struct {
    instance: *ExampleAppWindowImpl,
    traitExampleAppWindow: void = {},

    pub const Parent = Gtk.ApplicationWindow;

    pub fn init(self: ExampleAppWindow) callconv(.C) void {
        self.callMethod("initTemplate", .{});
        var builder = Gtk.Builder.newFromResource("/org/gtk/exampleapp/gears-menu.ui");
        defer builder.callMethod("unref", .{});
        var menu = builder.getObject("menu").expect("menu").tryInto(core.MenuModel).?;
        var gears = self.instance.TCgears;
        gears.setMenuModel(menu.asSome());
        self.instance.settings = core.Settings.new("org.gtk.exampleapp");
        var settings = self.instance.settings;
        var stack = self.instance.TCstack;
        settings.bind("transition", stack.into(core.Object), stack.propertyTransitionType().name(), .Default);
        var sidebar = self.instance.TCsidebar;
        settings.bind("show-words", sidebar.into(core.Object), sidebar.callMethod("propertyRevealChild", .{}).name(), .Default);
        var search = self.instance.TCsearch;
        var searchbar = self.instance.TCsearchbar;
        _ = search.callMethod("bindProperty", .{ search.callMethod("propertyActive", .{}).name(), searchbar.into(core.Object), searchbar.propertySearchModeEnabled().name(), .Bidirectional });
        _ = sidebar.callMethod("propertyRevealChild", .{}).connectNotify(updateWords, .{self}, .{ .swapped = true });
        var action1 = settings.createAction("show-words");
        defer core.unsafeCast(core.Object, action1.instance).unref();
        self.callMethod("addAction", .{action1});
        var lines = self.instance.TClines;
        var action2 = core.PropertyAction.new("show-lines", lines.into(core.Object), lines.callMethod("propertyVisible", .{}).name());
        defer action2.callMethod("unref", .{});
        self.callMethod("addAction", .{action2.into(core.Action)});
        var lines_label = self.instance.TClines_label;
        _ = lines.callMethod("bindProperty", .{ lines.callMethod("propertyVisible", .{}).name(), lines_label.into(core.Object), lines_label.callMethod("propertyVisible", .{}).name(), .Default });
    }

    pub fn new(app: ExampleApp) ExampleAppWindow {
        var property_names = [_][*:0]const u8{"application"};
        var property_values = std.mem.zeroes([1]core.Value);
        var application = property_values[0].init(core.GType.Object);
        defer application.unset();
        application.setObject(app.into(core.Object).asSome());
        return core.newObject(gType(), property_names[0..], property_values[0..]).tryInto(ExampleAppWindow).?;
    }

    pub fn disposeOverride(self: ExampleAppWindow) void {
        const Once = struct {
            var done: bool = false;
        };
        if (!Once.done) {
            Once.done = true;
            self.instance.settings.callMethod("unref", .{}); // equivalent to g_clear_object
        }
        self.callMethod("disposeV", .{Parent.gType()});
    }

    pub fn open(self: ExampleAppWindow, file: core.File) void {
        var basename = file.getBasename().?;
        defer core.freeDiscardConst(basename);
        var scrolled = Gtk.ScrolledWindow.new();
        scrolled.callMethod("setHexpand", .{core.Boolean.True});
        scrolled.callMethod("setVexpand", .{core.Boolean.True});
        var view = Gtk.TextView.new();
        view.setEditable(core.Boolean.False);
        view.setCursorVisible(core.Boolean.False);
        scrolled.setChild(view.into(Gtk.Widget).asSome());
        _ = self.instance.TCstack.addTitled(scrolled.into(Gtk.Widget), basename, basename);
        var buffer = view.getBuffer();
        var result = file.loadContents(.{ .ptr = null });
        switch (result) {
            .Ok => |ok| {
                defer core.free(ok.contents.ptr);
                defer core.freeDiscardConst(ok.etag_out);
                buffer.setText(@ptrCast([*:0]const u8, ok.contents.ptr), @intCast(i32, ok.contents.len));
            },
            .Err => |err| {
                defer err.free();
                std.log.warn("{s}", .{err.message.?});
                return;
            },
        }
        var tag = Gtk.TextTag.new(null);
        _ = buffer.getTagTable().add(tag);
        self.instance.settings.bind("font", tag.into(core.Object), tag.callMethod("propertyFont", .{}).name(), .Default);
        var start_iter = buffer.getStartIter();
        var end_iter = buffer.getEndIter();
        buffer.applyTag(tag, &start_iter, &end_iter);
        self.instance.TCsearch.callMethod("setSensitive", .{core.Boolean.True});
        self.updateWords();
        self.updateLines();
    }

    fn findWord(button: Gtk.Button, win: ExampleAppWindow) void {
        var word = button.getLabel().?;
        win.instance.TCsearchentry.callMethod("setText", .{word});
    }

    pub fn updateWords(self: ExampleAppWindow) void {
        var tab = if (self.instance.TCstack.getVisibleChild().wrap()) |some| some.tryInto(Gtk.ScrolledWindow).? else return;
        var view = tab.getChild().expect("child").tryInto(Gtk.TextView).?;
        var buffer = view.getBuffer();
        var start = buffer.getStartIter();
        var end: Gtk.TextIter = undefined;
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer {
            if (gpa.deinit()) @panic("");
        }
        const allocator = gpa.allocator();
        var strings = std.HashMap([*:0]const u8, void, CstrContext, std.hash_map.default_max_load_percentage).init(allocator);
        defer {
            var iter = strings.keyIterator();
            while (iter.next()) |some| {
                core.freeDiscardConst(some.*);
            }
            strings.deinit();
        }
        outer: while (!start.isEnd().toBool()) {
            while (!start.startsWord().toBool()) {
                if (!start.forwardChar().toBool()) break :outer;
            }
            end = start;
            if (!end.forwardWordEnd().toBool()) break :outer;
            var word = buffer.getText(&start, &end, core.Boolean.False);
            defer core.freeDiscardConst(word);
            strings.put(core.utf8Strdown(word, -1), {}) catch @panic("");
            start = end;
        }
        while (true) {
            var child = self.instance.TCwords.callMethod("getFirstChild", .{});
            if (child.wrap()) |some| {
                self.instance.TCwords.remove(some);
            } else {
                break;
            }
        }
        var iter = strings.keyIterator();
        while (iter.next()) |some| {
            var row = Gtk.Button.newWithLabel(some.*);
            _ = row.signalClicked().connect(findWord, .{self}, .{});
            self.instance.TCwords.insert(row.into(Gtk.Widget), -1);
        }
    }

    pub fn updateLines(self: ExampleAppWindow) void {
        var tab = if (self.instance.TCstack.getVisibleChild().wrap()) |some| some.tryInto(Gtk.ScrolledWindow).? else return;
        var view = tab.getChild().expect("child").tryInto(Gtk.TextView).?;
        var buffer = view.getBuffer();
        var count = buffer.getLineCount();
        var buf: [22]u8 = undefined;
        _ = std.fmt.bufPrint(buf[0..], "{d}{c}", .{ count, 0 }) catch @panic("");
        self.instance.TClines.setText(@ptrCast([*:0]const u8, &buf));
    }

    pub fn CallMethod(comptime method: []const u8) ?type {
        if (std.mem.eql(u8, method, "open")) return void;
        if (Parent.CallMethod(method)) |some| return some;
        return null;
    }

    pub fn callMethod(self: ExampleAppWindow, comptime method: []const u8, args: anytype) gen_return_type: {
        if (CallMethod(method)) |some| {
            break :gen_return_type some;
        } else {
            @compileError(std.fmt.comptimePrintf("No such method {s}", .{method}));
        }
    } {
        if (comptime std.mem.eql(u8, method, "open")) {
            return @call(.auto, open, .{self} ++ args);
        } else if (Parent.CallMethod(method)) |_| {
            return self.into(Parent).callMethod(method, args);
        } else {
            @compileError("No such method");
        }
    }

    pub fn cType() type {
        return ExampleAppWindowImpl;
    }

    pub fn gType() core.GType {
        return core.registerType(ExampleAppWindowClass, ExampleAppWindow, "ExampleAppWindow", .{ .final = true });
    }

    pub fn isAImpl(comptime T: type) bool {
        return meta.trait.hasField("traitExampleAppWindow")(T);
    }

    pub fn into(self: ExampleAppWindow, comptime T: type) T {
        return core.upCast(T, self);
    }

    pub fn tryInto(self: ExampleAppWindow, comptime T: type) ?T {
        return core.downCast(T, self);
    }

    pub fn asSome(self: ExampleAppWindow) ExampleAppWindowNullable {
        return .{ .ptr = self.instance };
    }
};
