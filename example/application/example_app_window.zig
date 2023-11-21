const std = @import("std");
const gtk = @import("gtk");
const core = gtk.core;
const template = gtk.template;
const meta = std.meta;
const assert = std.debug.assert;
const ExampleApp = @import("example_app.zig").ExampleApp;
const Action = core.Action;
const Application = gtk.Application;
const ApplicationWindow = gtk.ApplicationWindow;
const ApplicationWindowClass = gtk.ApplicationWindowClass;
const Builder = gtk.Builder;
const Button = gtk.Button;
const Entry = gtk.Entry;
const File = core.File;
const Label = gtk.Label;
const ListBox = gtk.ListBox;
const MenuButton = gtk.MenuButton;
const MenuModel = core.MenuModel;
const Object = core.Object;
const ObjectClass = core.ObjectClass;
const ParamSpec = core.ParamSpec;
const PropertyAction = core.PropertyAction;
const Revealer = gtk.Revealer;
const ScrolledWindow = gtk.ScrolledWindow;
const SearchBar = gtk.SearchBar;
const SearchEntry = gtk.SearchEntry;
const Settings = core.Settings;
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
    parent: ApplicationWindowClass,

    pub fn init(class: *ExampleAppWindowClass) void {
        var widget_class: *WidgetClass = @ptrCast(class);
        widget_class.setTemplateFromResource("/org/gtk/exampleapp/window.ui");
        template.bindChild(widget_class, ExampleAppWindow);
        template.bindCallback(widget_class, ExampleAppWindowClass);
    }

    // @override
    pub fn dispose(arg_object: *Object) callconv(.C) void {
        var self = arg_object.tryInto(ExampleAppWindow).?;
        self.settings.__call("unref", .{});
        self.__call("disposeTemplate", .{ExampleAppWindow.type()});
        self.__call("disposeV", .{ExampleAppWindow.Parent.type()});
    }

    // template callback
    pub fn TCsearch_text_changed(entry: *Entry, self: *ExampleAppWindow) callconv(.C) void {
        const text = entry.__call("getText", .{});
        if (text[0] == 0) return;
        var tab = self.tc_stack.getVisibleChild().?.tryInto(ScrolledWindow).?;
        var view = tab.getChild().?.tryInto(TextView).?;
        var buffer = view.getBuffer();
        var start: TextIter = undefined;
        buffer.getStartIter(&start);
        var match_start: TextIter = undefined;
        var match_end: TextIter = undefined;
        if (start.forwardSearch(text, .CaseInsensitive, &match_start, &match_end, null)) {
            buffer.selectRange(&match_start, &match_end);
            _ = view.scrollToIter(&match_start, 0, false, 0, 0);
        }
    }

    // template callback
    pub fn TCvisible_child_changed(stack: *Stack, _: *ParamSpec, self: *ExampleAppWindow) callconv(.C) void {
        if (stack.__call("inDestruction", .{})) return;
        self.tc_searchbar.setSearchMode(false);
        self.updateWords();
        self.updateLines();
    }
};

pub const ExampleAppWindow = extern struct {
    parent: Parent,
    settings: *Settings,
    tc_stack: *Stack, // template child
    tc_gears: *MenuButton, // template child
    tc_search: *ToggleButton, // template child
    tc_searchbar: *SearchBar, // template child
    tc_searchentry: *SearchEntry, // template child
    tc_sidebar: *Revealer, // template child
    tc_words: *ListBox, // template child
    tc_lines: *Label, // template child
    tc_lines_label: *Label, // template child

    pub const Parent = ApplicationWindow;
    pub usingnamespace core.Extend(ExampleAppWindow);

    pub fn init(self: *ExampleAppWindow) void {
        self.__call("initTemplate", .{});
        var builder = Builder.newFromResource("/org/gtk/exampleapp/gears-menu.ui");
        defer builder.__call("unref", .{});
        const menu = builder.getObject("menu").?.tryInto(MenuModel).?;
        self.tc_gears.setMenuModel(menu);
        self.settings = Settings.new("org.gtk.exampleapp");
        self.settings.bind("transition", self.tc_stack.into(Object), "transition-type", .Default);
        self.settings.bind("show-words", self.tc_sidebar.into(Object), "reveal-child", .Default);
        _ = self.tc_search.__call("bindProperty", .{ "active", self.tc_searchbar.into(Object), "search-mode-enabled", .Bidirectional });
        _ = self.tc_sidebar.__call("connectRevealChildNotifySwap", .{ updateWords, .{self}, .{} });
        const action_show_words = self.settings.createAction("show-words");
        defer core.unsafeCast(Object, action_show_words).unref();
        self.__call("addAction", .{action_show_words});
        var action_show_lines = PropertyAction.new("show-lines", self.tc_lines.into(Object), "visible");
        defer action_show_lines.__call("unref", .{});
        self.__call("addAction", .{action_show_lines.into(Action)});
        _ = self.tc_lines.__call("bindProperty", .{ "visible", self.tc_lines_label.into(Object), "visible", .Default });
    }

    pub fn new(app: *ExampleApp) *ExampleAppWindow {
        var application = core.ValueZ(Application).init();
        defer application.deinit();
        application.set(app.into(Application));
        var property_names = [_][*:0]const u8{"application"};
        var property_values = [_]core.Value{application.value};
        return core.newObject(ExampleAppWindow, property_names[0..], property_values[0..]);
    }

    pub fn open(self: *ExampleAppWindow, file: *File) void {
        const basename = file.getBasename().?;
        defer core.free(basename);
        var scrolled = ScrolledWindow.new();
        scrolled.__call("setHexpand", .{true});
        scrolled.__call("setVexpand", .{true});
        var view = TextView.new();
        view.setEditable(false);
        view.setCursorVisible(false);
        scrolled.setChild(view.into(Widget));
        _ = self.tc_stack.addTitled(scrolled.into(Widget), basename, basename);
        var buffer = view.getBuffer();
        const contents = file.loadContents(null) catch {
            var err = core.getError();
            defer err.free();
            std.log.warn("{s}", .{err.message.?});
            return;
        };
        defer core.free(contents.contents.ptr);
        defer core.free(contents.etag_out);
        buffer.setText(@ptrCast(contents.contents.ptr), @intCast(contents.contents.len));
        var tag = TextTag.new(null);
        _ = buffer.getTagTable().add(tag);
        self.settings.bind("font", tag.into(Object), "font", .Default);
        var start_iter: TextIter = undefined;
        var end_iter: TextIter = undefined;
        buffer.getStartIter(&start_iter);
        buffer.getEndIter(&end_iter);
        buffer.applyTag(tag, &start_iter, &end_iter);
        self.tc_search.__call("setSensitive", .{true});
        self.updateWords();
        self.updateLines();
    }

    fn findWord(button: *Button, self: *ExampleAppWindow) void {
        const word = button.getLabel().?;
        self.tc_searchentry.__call("setText", .{word});
    }

    pub fn updateWords(self: *ExampleAppWindow) void {
        var tab = if (self.tc_stack.getVisibleChild()) |some| some.tryInto(ScrolledWindow).? else return;
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
                core.free(some.*);
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
            defer core.free(word);
            strings.put(core.utf8Strdown(word, -1), {}) catch @panic("");
            start = end;
        }
        while (true) {
            const child = self.tc_words.__call("getFirstChild", .{});
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
        const count = buffer.getLineCount();
        var buf: [22]u8 = undefined;
        _ = std.fmt.bufPrintZ(buf[0..], "{d}", .{count}) catch @panic("");
        self.tc_lines.setText(@ptrCast(&buf));
    }

    pub fn @"type"() core.Type {
        return core.registerType(ExampleAppWindowClass, ExampleAppWindow, "ExampleAppWindow", .{ .final = true });
    }
};
