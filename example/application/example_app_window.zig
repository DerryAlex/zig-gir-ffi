const std = @import("std");
const root = @import("root");
const Gtk = root.Gtk;
const core = Gtk.core;
const template = Gtk.template;
const meta = std.meta;
const assert = std.debug.assert;
const ExampleApp = @import("example_app.zig").ExampleApp;
const Action = core.Action;
const Application = Gtk.Application;
const ApplicationWindow = Gtk.ApplicationWindow;
const ApplicationWindowClass = Gtk.ApplicationWindowClass;
const Builder = Gtk.Builder;
const Button = Gtk.Button;
const Entry = Gtk.Entry;
const File = core.File;
const Label = Gtk.Label;
const ListBox = Gtk.ListBox;
const MenuButton = Gtk.MenuButton;
const MenuModel = Gtk.MenuModel;
const Object = core.Object;
const ObjectClass = core.ObjectClass;
const ParamSpec = core.ParamSpec;
const PropertyAction = core.PropertyAction;
const Revealer = Gtk.Revealer;
const ScrolledWindow = Gtk.ScrolledWindow;
const SearchBar = Gtk.SearchBar;
const SearchEntry = Gtk.SearchEntry;
const Settings = core.Settings;
const Stack = Gtk.Stack;
const TextIter = Gtk.TextIter;
const TextTag = Gtk.TextTag;
const TextView = Gtk.TextView;
const ToggleButton = Gtk.ToggleButton;
const Widget = Gtk.Widget;
const WidgetClass = Gtk.WidgetClass;

pub const CstrContext = struct {
    pub fn hash(_: CstrContext, key: [*:0]u8) u64 {
        return std.hash.Wyhash.hash(0, std.mem.span(key));
    }

    pub fn eql(_: CstrContext, a: [*:0]u8, b: [*:0]u8) bool {
        return std.cstr.cmp(a, b) == 0;
    }
};

pub const ExampleAppWindowClass = extern struct {
    parent: ApplicationWindowClass,

    pub fn init(class: *ExampleAppWindowClass) void {
        var object_class = @ptrCast(*ObjectClass, class);
        object_class.dispose = &dispose;
        var widget_class = @ptrCast(*WidgetClass, class);
        widget_class.setTemplateFromResource("/org/gtk/exampleapp/window.ui");
        template.bindChild(widget_class, ExampleAppWindow);
        template.bindCallback(widget_class, ExampleAppWindowClass);
    }

    // @override
    pub fn dispose(arg_object: *Object) callconv(.C) void {
        var self = arg_object.tryInto(ExampleAppWindow).?;
        if (!self.cleared) {
            self.settings.__call("unref", .{});
            self.cleared = true;
        }
        self.__call("disposeTemplate", .{ExampleAppWindow.type()});
        self.__call("disposeV", .{ExampleAppWindow.Parent.type()});
    }

    // template callback
    pub fn TCsearch_text_changed(entry: *Entry, self: *ExampleAppWindow) callconv(.C) void {
        var text = entry.__call("getText", .{});
        if (text[0] == 0) return;
        var tab = self.TCstack.getVisibleChild().?.tryInto(ScrolledWindow).?;
        var view = tab.getChild().?.tryInto(TextView).?;
        var buffer = view.getBuffer();
        var start: TextIter = undefined;
        buffer.getStartIter(&start);
        var search_result = start.forwardSearch(text, .CaseInsensitive, null);
        switch (search_result) {
            .Ok => |ok| {
                var match_start = ok.match_start;
                var match_end = ok.match_end;
                buffer.selectRange(&match_start, &match_end);
                _ = view.scrollToIter(&match_start, 0, .False, 0, 0);
            },
            .Err => {},
        }
    }

    // template callback
    pub fn TCvisible_child_changed(stack: *Stack, _: *ParamSpec, self: *ExampleAppWindow) callconv(.C) void {
        if (stack.__call("inDestruction", .{}).toBool()) return;
        self.TCsearchbar.setSearchMode(.False);
        self.updateWords();
        self.updateLines();
    }
};

pub const ExampleAppWindow = packed struct {
    parent: Parent,
    settings: Settings,
    tc_stack: Stack, // template child
    tc_gears: MenuButton, // template child
    tc_search: ToggleButton, // template child
    tc_search_bar: SearchBar, // template child
    tc_search_entry: SearchEntry, // template child
    tc_sidebar: Revealer, // template child
    tc_words: ListBox, // template child
    tc_lines: Label, // template child
    tc_lines_label: Label, // template child

    pub const Parent = ApplicationWindow;

    pub fn init(self: *ExampleAppWindow) void {
        self.__call("initTemplate", .{});
        var builder = Builder.newFromResource("/org/gtk/exampleapp/gears-menu.ui");
        defer builder.__call("unref", .{});
        var menu = builder.getObject("menu").?.tryInto(MenuModel).?;
        self.tc_gears.setMenuModel(menu);
        self.settings = Settings.new("org.gtk.exampleapp");
        self.settings.bind("transition", self.tc_stack.into(Object), "transition-type", .Default);
        self.settings.bind("show-words", self.tc_sidebar.into(Object), "reveal-child", .Default);
        _ = self.tc_search.__call("bindProperty", .{ "active", self.tc_searchbar.into(Object), "search-mode-enabled", .Bidirectional });
        _ = self.tc_sidebar.__call("connectRevealChildNotifySwap", .{ updateWords, .{self}, .{} });
        var action_show_words = self.settings.createAction("show-words");
        defer core.unsafeCast(Object, action_show_words).unref();
        self.__call("addAction", .{action_show_words});
        var action_show_lines = core.PropertyAction.new("show-lines", self.tc_lines.into(Object), "visible");
        defer action_show_lines.__call("unref", .{});
        self.__call("addAction", .{action_show_words.into(Action)});
        _ = self.tc_lines.callMethod("bindProperty", .{ "visible", self.tc_lines_label.into(Object), "visible", .Default });
    }

    pub fn new(app: *ExampleApp) *ExampleAppWindow {
        var application = core.ValueZ(Application).init();
        defer application.deinit();
        application.set(app.into(Application));
        var property_names = [_][*:0]const u8{"application"};
        var property_values = [_]core.Value{application.value};
        return core.objectNewWithProperties(@"type"(), property_names[0..], property_values[0..]).tryInto(ExampleAppWindow).?;
    }

    pub fn open(self: *ExampleAppWindow, file: *File) void {
        var basename = file.getBasename().?;
        defer core.free(basename);
        var scrolled = ScrolledWindow.new();
        scrolled.__call("setHexpand", .{.True});
        scrolled.__call("setVexpand", .{.True});
        var view = TextView.new();
        view.setEditable(.False);
        view.setCursorVisible(.False);
        scrolled.setChild(view.into(Widget));
        _ = self.tc_stack.addTitled(scrolled.into(Widget), basename, basename);
        var buffer = view.getBuffer();
        var contents = file.loadContents(null);
        switch (contents) {
            .Ok => |ok| {
                defer core.free(ok.contents.ptr);
                defer core.free(ok.etag_out);
                buffer.setText(@ptrCast([*:0]const u8, ok.contents.ptr), @intCast(i32, ok.contents.len));
            },
            .Err => |err| {
                defer err.free();
                std.log.warn("{s}", .{err.message.?});
                return;
            },
        }
        var tag = TextTag.new(null);
        _ = buffer.getTagTable().add(tag);
        self.settings.bind("font", tag.into(Object), "font", .Default);
        var start_iter: TextIter = undefined;
        var end_iter: TextIter = undefined;
        buffer.getStartIter(&start_iter);
        buffer.getEndIter(&end_iter);
        buffer.applyTag(tag, &start_iter, &end_iter);
        self.tc_search.__call("setSensitive", .{.True});
        self.updateWords();
        self.updateLines();
    }

    fn findWord(button: *Button, self: *ExampleAppWindow) void {
        var word = button.getLabel().?;
        self.tc_search_entry.__call("setText", .{word});
    }

    pub fn updateWords(self: *ExampleAppWindow) void {
        var tab = if (self.instance.tc_stack.getVisibleChild()) |some| some.tryInto(ScrolledWindow).? else return;
        var view = tab.getChild().?.tryInto(Gtk.TextView).?;
        var buffer = view.getBuffer();
        var start: TextIter = undefined;
        var end: TextIter = undefined;
        buffer.getStartIter(&start);
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer {
            if (gpa.deinit()) @panic("");
        }
        const allocator = gpa.allocator();
        var strings = std.HashMap([*:0]u8, void, CstrContext, std.hash_map.default_max_load_percentage).init(allocator);
        defer {
            var iter = strings.keyIterator();
            while (iter.next()) |some| {
                core.free(some.*);
            }
            strings.deinit();
        }
        outer: while (!start.isEnd().toBool()) {
            while (!start.startsWord().toBool()) {
                if (!start.forwardChar().toBool()) break :outer;
            }
            end = start;
            if (!end.forwardWordEnd().toBool()) break :outer;
            var word = buffer.getText(&start, &end, .False);
            defer core.free(word);
            strings.put(core.utf8Strdown(word, -1), {}) catch @panic("");
            start = end;
        }
        while (true) {
            var child = self.tc_words.__call("getFirstChild", .{});
            if (child) |some| {
                self.tc_words.remove(some);
            } else {
                break;
            }
        }
        var iter = strings.keyIterator();
        while (iter.next()) |some| {
            var row = Button.newWithLabel(some.*);
            _ = row.connectClicked(findWord, .{self}, .{});
            self.tc_words.insert(row.into(Widget), -1);
        }
    }

    pub fn updateLines(self: *ExampleAppWindow) void {
        var tab = if (self.tc_stack.getVisibleChild()) |some| some.tryInto(ScrolledWindow).? else return;
        var view = tab.getChild().?.tryInto(TextView).?;
        var buffer = view.getBuffer();
        var count = buffer.getLineCount();
        var buf: [22]u8 = undefined;
        _ = std.fmt.bufPrintZ(buf[0..], "{d}", .{count}) catch @panic("");
        self.tc_lines.setText(@ptrCast([*:0]const u8, &buf));
    }

    pub fn __Call(comptime method: []const u8) ?type {
        if (std.mem.eql(u8, method, "open")) return void;
        return core.CallInherited(@This(), method);
    }

    pub fn __call(self: *ExampleAppWindow, comptime method: []const u8, args: anytype) if (__Call(method)) |some| some else @compileError(std.fmt.comptimePrint("No such method {s}", .{method})) {
        if (comptime std.mem.eql(u8, method, "open")) return @call(.auto, open, .{self} ++ args);
        return core.callInherited(self, method, args);
    }

    pub fn into(self: *ExampleAppWindow, comptime T: type) *T {
        return core.upCast(T, self);
    }

    pub fn tryInto(self: *ExampleAppWindow, comptime T: type) ?*T {
        return core.downCast(T, self);
    }

    pub fn @"type"() core.Type {
        return core.registerType(ExampleAppWindowClass, ExampleAppWindow, "ExampleAppWindow", .{ .final = true });
    }
};
