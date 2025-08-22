const std = @import("std");
const gi = @import("gi");
const core = gi.core;
const GLib = gi.GLib;
const GObject = gi.GObject;
const Gio = gi.Gio;
const Gtk = gi.Gtk;
const ExampleApp = @import("example_app.zig").ExampleApp;
const Action = Gio.Action;
const ActionMap = Gio.ActionMap;
const Application = Gtk.Application;
const ApplicationWindow = Gtk.ApplicationWindow;
const Builder = Gtk.Builder;
const Button = Gtk.Button;
const Editable = Gtk.Editable;
const Entry = Gtk.Entry;
const Error = GLib.Error;
const File = Gio.File;
const Label = Gtk.Label;
const ListBox = Gtk.ListBox;
const MenuButton = Gtk.MenuButton;
const MenuModel = Gio.MenuModel;
const Object = GObject.Object;
const ParamSpec = GObject.ParamSpec;
const PropertyAction = Gio.PropertyAction;
const Revealer = Gtk.Revealer;
const ScrolledWindow = Gtk.ScrolledWindow;
const SearchBar = Gtk.SearchBar;
const SearchEntry = Gtk.SearchEntry;
const Settings = Gio.Settings;
const Stack = Gtk.Stack;
const TextIter = Gtk.TextIter;
const TextTag = Gtk.TextTag;
const TextView = Gtk.TextView;
const ToggleButton = Gtk.ToggleButton;
const Widget = Gtk.Widget;
const Window = Gtk.Window;

pub const CstrContext = struct {
    pub fn hash(_: CstrContext, key: [*:0]u8) u64 {
        return std.hash.Wyhash.hash(0, std.mem.span(key));
    }

    pub fn eql(_: CstrContext, a: [*:0]u8, b: [*:0]u8) bool {
        return std.mem.orderZ(u8, a, b) == .eq;
    }
};

pub const ExampleAppWindowClass = extern struct {
    parent_class: ApplicationWindow.Class,

    pub fn init(class: *ExampleAppWindowClass) void {
        const widget_class: *Widget.Class = @ptrCast(class);
        widget_class.setTemplateFromResource("/org/gtk/exampleapp/window.ui");
        const children: []const [:0]const u8 = &.{
            "stack",
            "gears",
            "search",
            "searchbar",
            "searchentry",
            "sidebar",
            "words",
            "lines",
            "lines_label",
        };
        inline for (children) |child| {
            widget_class.bindTemplateChildFull(child, false, @offsetOf(ExampleAppWindow, child));
        }
        widget_class.bindTemplateCallbackFull("search_text_changed", @ptrCast(&searchTextChanged));
        widget_class.bindTemplateCallbackFull("visible_child_changed", @ptrCast(&visibleChildChanged));
    }

    fn searchTextChanged(entry: *Entry, self: *ExampleAppWindow) callconv(.c) void {
        const text = entry.into(Editable).getText();
        if (text[0] == 0) return;
        var tab = self.stack.getVisibleChild().?.tryInto(ScrolledWindow).?;
        var view = tab.getChild().?.tryInto(TextView).?;
        var buffer = view.getBuffer();
        var start: TextIter = undefined;
        buffer.getStartIter(&start);
        var match_start: TextIter = undefined;
        var match_end: TextIter = undefined;
        if (start.forwardSearch(text, .{ .case_insensitive = true }, &match_start, &match_end, null)) {
            buffer.selectRange(&match_start, &match_end);
            _ = view.scrollToIter(&match_start, 0, false, 0, 0);
        }
    }

    fn visibleChildChanged(stack: *Stack, _: *ParamSpec, self: *ExampleAppWindow) callconv(.c) void {
        if (stack.into(Widget).inDestruction()) return;
        self.searchbar.setSearchMode(false);
        self.updateWords();
        self.updateLines();
    }
};

pub const ExampleAppWindow = extern struct {
    parent: Parent,
    settings: *Settings,
    stack: *Stack, // template child
    gears: *MenuButton, // template child
    search: *ToggleButton, // template child
    searchbar: *SearchBar, // template child
    searchentry: *SearchEntry, // template child
    sidebar: *Revealer, // template child
    words: *ListBox, // template child
    lines: *Label, // template child
    lines_label: *Label, // template child

    pub const Parent = ApplicationWindow;
    pub const Class = ExampleAppWindowClass;

    const Ext = core.Extend(@This());
    pub const into = Ext.into;
    pub const tryInto = Ext.tryInto;
    pub const getParentClass = Ext.getParentClass;

    pub const Override = struct {
        pub fn dispose(object: *Object) callconv(.c) void {
            const self = object.tryInto(ExampleAppWindow).?;
            self.settings.into(Object).unref();
            self.into(Widget).disposeTemplate(gType());
            const p_class = self.getParentClass(Object);
            p_class.dispose.?(object);
        }
    };

    pub fn init(self: *ExampleAppWindow) void {
        self.into(Widget).initTemplate();
        const builder: *Builder = .newFromResource("/org/gtk/exampleapp/gears-menu.ui");
        defer builder.into(Object).unref();
        const menu = builder.getObject("menu").?.tryInto(MenuModel).?;
        self.gears.setMenuModel(menu);
        self.settings = Settings.new("org.gtk.exampleapp");
        self.settings.bind("transition", self.stack.into(Object), "transition-type", .{});
        self.settings.bind("show-words", self.sidebar.into(Object), "reveal-child", .{});
        _ = self.search.into(Object).bindProperty("active", self.searchbar.into(Object), "search-mode-enabled", .{ .bidirectional = true });
        _ = self.sidebar._props.@"reveal-child".connectNotify(.init(updateWords, .{self}), .{});
        const action_show_words = self.settings.createAction("show-words");
        defer core.unsafeCast(Object, action_show_words).unref();
        self.into(ActionMap).addAction(action_show_words);
        const action_show_lines: *PropertyAction = .new("show-lines", self.lines.into(Object), "visible");
        defer action_show_lines.into(Object).unref();
        self.into(ActionMap).addAction(action_show_lines.into(Action));
        _ = self.lines.into(Object).bindProperty("visible", self.lines_label.into(Object), "visible", .{});
    }

    pub fn new(app: *ExampleApp) *ExampleAppWindow {
        const self = core.newObject(ExampleAppWindow);
        self.into(Window)._props.application.set(app.into(Application));
        return self;
    }

    pub fn open(self: *ExampleAppWindow, file: *File) void {
        const basename = file.getBasename().?;
        defer GLib.free(basename);
        var scrolled = ScrolledWindow.new();
        scrolled.into(Widget).setHexpand(true);
        scrolled.into(Widget).setVexpand(true);
        const view: *TextView = .new();
        view.setEditable(false);
        view.setCursorVisible(false);
        scrolled.setChild(view.into(Widget));
        _ = self.stack.addTitled(scrolled.into(Widget), basename, basename);
        var buffer = view.getBuffer();
        var err: ?*Error = null;
        const result = file.loadContents(null, &err) catch {
            defer err.?.free();
            std.log.warn("{s}", .{err.?.message.?});
            return;
        };
        defer GLib.free(result.contents.ptr);
        defer GLib.free(result.etag_out);
        buffer.setText(@ptrCast(result.contents.ptr), @intCast(result.contents.len));
        var tag = TextTag.new(null);
        _ = buffer.getTagTable().add(tag);
        self.settings.bind("font", tag.into(Object), "font", .{});
        var start_iter: TextIter = undefined;
        var end_iter: TextIter = undefined;
        buffer.getStartIter(&start_iter);
        buffer.getEndIter(&end_iter);
        buffer.applyTag(tag, &start_iter, &end_iter);
        self.search.into(Widget).setSensitive(true);
        self.updateWords();
        self.updateLines();
    }

    fn findWord(button: *Button, self: *ExampleAppWindow) void {
        const word = button.getLabel().?;
        self.searchentry.into(Editable).setText(word);
    }

    pub fn updateWords(self: *ExampleAppWindow) void {
        var tab = if (self.stack.getVisibleChild()) |some| some.tryInto(ScrolledWindow).? else return;
        var view = tab.getChild().?.tryInto(Gtk.TextView).?;
        var buffer = view.getBuffer();
        var start: TextIter = undefined;
        var end: TextIter = undefined;
        buffer.getStartIter(&start);
        const allocator = std.heap.smp_allocator;
        var strings = std.HashMap([*:0]u8, void, CstrContext, std.hash_map.default_max_load_percentage).init(allocator);
        defer {
            var iter = strings.keyIterator();
            while (iter.next()) |some| {
                GLib.free(some.*);
            }
            strings.deinit();
        }
        outer: while (!start.isEnd()) {
            while (!start.startsWord()) {
                if (!start.forwardChar()) break :outer;
            }
            end = start;
            if (!end.forwardWordEnd()) break :outer;
            const word = buffer.getText(&start, &end, false);
            defer GLib.free(word);
            strings.put(GLib.utf8Strdown(word, -1), {}) catch @panic("");
            start = end;
        }
        while (true) {
            const child = self.words.into(Widget).getFirstChild();
            if (child) |some| {
                self.words.remove(some);
            } else {
                break;
            }
        }
        var iter = strings.keyIterator();
        while (iter.next()) |some| {
            var row: *Button = .newWithLabel(some.*);
            _ = row._signals.clicked.connect(.init(findWord, .{self}), .{});
            self.words.insert(row.into(Widget), -1);
        }
    }

    pub fn updateLines(self: *ExampleAppWindow) void {
        var tab = if (self.stack.getVisibleChild()) |some| some.tryInto(ScrolledWindow).? else return;
        var view = tab.getChild().?.tryInto(TextView).?;
        var buffer = view.getBuffer();
        const count = buffer.getLineCount();
        var buf: [22]u8 = undefined;
        _ = std.fmt.bufPrintZ(&buf, "{d}", .{count}) catch unreachable;
        self.lines.setText(@ptrCast(&buf));
    }

    pub fn gType() core.Type {
        return core.registerType(ExampleAppWindow, "ExampleAppWindow", .{ .final = true });
    }
};
