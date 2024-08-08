const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const glib = gtk.glib;
const gobject = gtk.gobject;
const gio = gtk.gio;
const template = gtk.template;
const meta = std.meta;
const assert = std.debug.assert;
const ExampleApp = @import("example_app.zig").ExampleApp;
const Action = gio.Action;
const Application = gtk.Application;
const ApplicationWindow = gtk.ApplicationWindow;
const ApplicationWindowClass = gtk.ApplicationWindowClass;
const Builder = gtk.Builder;
const Button = gtk.Button;
const Entry = gtk.Entry;
const File = gio.File;
const Label = gtk.Label;
const ListBox = gtk.ListBox;
const MenuButton = gtk.MenuButton;
const MenuModel = gio.MenuModel;
const Object = gobject.Object;
const ObjectClass = gobject.ObjectClass;
const ParamSpec = gobject.ParamSpec;
const PropertyAction = gio.PropertyAction;
const Revealer = gtk.Revealer;
const ScrolledWindow = gtk.ScrolledWindow;
const SearchBar = gtk.SearchBar;
const SearchEntry = gtk.SearchEntry;
const Settings = gio.Settings;
const Stack = gtk.Stack;
const TextIter = gtk.TextIter;
const TextTag = gtk.TextTag;
const TextView = gtk.TextView;
const ToggleButton = gtk.ToggleButton;
const Widget = gtk.Widget;
const WidgetClass = gtk.WidgetClass;

pub const CstrContext = struct {
    pub fn hash(_: CstrContext, key: [*:0]u8) u64 {
        return std.hash.Wyhash.hash(0, std.mem.span(key));
    }

    pub fn eql(_: CstrContext, a: [*:0]u8, b: [*:0]u8) bool {
        return std.mem.orderZ(u8, a, b) == .eq;
    }
};

pub const ExampleAppWindowClass = extern struct {
    parent_class: ApplicationWindowClass,

    pub var parent_class: ?*ApplicationWindowClass = null;

    pub fn init(class: *ExampleAppWindowClass) void {
        parent_class = @ptrCast(gobject.TypeClass.peekParent(@ptrCast(class)));
        var widget_class: *WidgetClass = @ptrCast(class);
        widget_class.setTemplateFromResource("/org/gtk/exampleapp/window.ui");
        template.bindChild(widget_class, ExampleAppWindow, &[_]template.BindingZ{
            .{ .name = "stack" },
            .{ .name = "gears" },
            .{ .name = "search" },
            .{ .name = "searchbar" },
            .{ .name = "searchentry" },
            .{ .name = "sidebar" },
            .{ .name = "words" },
            .{ .name = "lines" },
            .{ .name = "lines_label" },
        }, null);
        template.bindCallback(widget_class, ExampleAppWindowClass, &[_]template.BindingZ{
            .{
                .name = "search_text_changed",
                .symbol = "searchTextChanged",
            },
            .{
                .name = "visible_child_changed",
                .symbol = "visibleChildChanged",
            },
        });
    }

    pub fn searchTextChanged(entry: *Entry, self: *ExampleAppWindow) callconv(.C) void {
        const text = entry.__call("getText", .{});
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

    pub fn visibleChildChanged(stack: *Stack, _: *ParamSpec, self: *ExampleAppWindow) callconv(.C) void {
        if (stack.__call("inDestruction", .{})) return;
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
    pub usingnamespace core.Extend(ExampleAppWindow);

    pub const Override = struct {
        pub fn dispose(arg_object: *Object) callconv(.C) void {
            var self = arg_object.tryInto(ExampleAppWindow).?;
            self.settings.__call("unref", .{});
            self.__call("disposeTemplate", .{ExampleAppWindow.gType()});
            const p_class: *ObjectClass = @ptrCast(Class.parent_class.?);
            p_class.dispose.?(arg_object);
        }
    };

    pub fn init(self: *ExampleAppWindow) void {
        self.__call("initTemplate", .{});
        var builder = Builder.newFromResource("/org/gtk/exampleapp/gears-menu.ui");
        defer builder.__call("unref", .{});
        const menu = builder.getObject("menu").?.tryInto(MenuModel).?;
        self.gears.setMenuModel(menu);
        self.settings = Settings.new("org.gtk.exampleapp");
        self.settings.bind("transition", self.stack.into(Object), "transition-type", .{});
        self.settings.bind("show-words", self.sidebar.into(Object), "reveal-child", .{});
        _ = self.search.__call("bindProperty", .{ "active", self.searchbar.into(Object), "search-mode-enabled", .{ .bidirectional = true } });
        _ = self.sidebar.signalConnect("notify::reveal-child", updateWords, .{self}, .{ .swapped = true }, &.{ void, *gobject.Object, *gobject.ParamSpec });
        const action_show_words = self.settings.createAction("show-words");
        defer core.unsafeCast(Object, action_show_words).unref();
        self.__call("addAction", .{action_show_words});
        var action_show_lines = PropertyAction.new("show-lines", self.lines.into(Object), "visible");
        defer action_show_lines.__call("unref", .{});
        self.__call("addAction", .{action_show_lines.into(Action)});
        _ = self.lines.__call("bindProperty", .{ "visible", self.lines_label.into(Object), "visible", .{} });
    }

    pub fn new(app: *ExampleApp) *ExampleAppWindow {
        return core.newObject(ExampleAppWindow, .{
            .application = app.into(Application),
        });
    }

    pub fn open(self: *ExampleAppWindow, file: *File) void {
        const basename = file.getBasename().?;
        defer glib.free(basename);
        var scrolled = ScrolledWindow.new();
        scrolled.__call("setHexpand", .{true});
        scrolled.__call("setVexpand", .{true});
        var view = TextView.new();
        view.setEditable(false);
        view.setCursorVisible(false);
        scrolled.setChild(view.into(Widget));
        _ = self.stack.addTitled(scrolled.into(Widget), basename, basename);
        var buffer = view.getBuffer();
        var err: ?*core.Error = null;
        const result = file.loadContents(null, &err) catch {
            defer err.?.free();
            std.log.warn("{s}", .{err.?.message.?});
            return;
        };
        defer glib.free(result.contents.ptr);
        defer glib.free(result.etag_out);
        buffer.setText(@ptrCast(result.contents.ptr), @intCast(result.contents.len));
        var tag = TextTag.new(null);
        _ = buffer.getTagTable().add(tag);
        self.settings.bind("font", tag.into(Object), "font", .{});
        var start_iter: TextIter = undefined;
        var end_iter: TextIter = undefined;
        buffer.getStartIter(&start_iter);
        buffer.getEndIter(&end_iter);
        buffer.applyTag(tag, &start_iter, &end_iter);
        self.search.__call("setSensitive", .{true});
        self.updateWords();
        self.updateLines();
    }

    fn findWord(button: *Button, self: *ExampleAppWindow) void {
        const word = button.getLabel().?;
        self.searchentry.__call("setText", .{word});
    }

    pub fn updateWords(self: *ExampleAppWindow) void {
        var tab = if (self.stack.getVisibleChild()) |some| some.tryInto(ScrolledWindow).? else return;
        var view = tab.getChild().?.tryInto(gtk.TextView).?;
        var buffer = view.getBuffer();
        var start: TextIter = undefined;
        var end: TextIter = undefined;
        buffer.getStartIter(&start);
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer {
            _ = gpa.deinit();
        }
        const allocator = gpa.allocator();
        var strings = std.HashMap([*:0]u8, void, CstrContext, std.hash_map.default_max_load_percentage).init(allocator);
        defer {
            var iter = strings.keyIterator();
            while (iter.next()) |some| {
                glib.free(some.*);
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
            defer glib.free(word);
            strings.put(glib.utf8Strdown(word, -1), {}) catch @panic("");
            start = end;
        }
        while (true) {
            const child = self.words.__call("getFirstChild", .{});
            if (child) |some| {
                self.words.remove(some);
            } else {
                break;
            }
        }
        var iter = strings.keyIterator();
        while (iter.next()) |some| {
            var row = Button.newWithLabel(some.*);
            _ = row.connectClicked(findWord, .{self}, .{});
            self.words.insert(row.into(Widget), -1);
        }
    }

    pub fn updateLines(self: *ExampleAppWindow) void {
        var tab = if (self.stack.getVisibleChild()) |some| some.tryInto(ScrolledWindow).? else return;
        var view = tab.getChild().?.tryInto(TextView).?;
        var buffer = view.getBuffer();
        const count = buffer.getLineCount();
        var buf: [22]u8 = undefined;
        _ = std.fmt.bufPrintZ(buf[0..], "{d}", .{count}) catch @panic("");
        self.lines.setText(@ptrCast(&buf));
    }

    pub fn gType() core.Type {
        return core.registerType(ExampleAppWindow, "ExampleAppWindow", .{ .final = true });
    }
};
