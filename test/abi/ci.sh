#!/usr/bin/bash
pkg_rel=0 # used to trigger ci without actual changes
zig translate-c -cflags $(pkg-config --cflags gtk4) -- /usr/include/gtk-4.0/gtk/gtk.h -I/usr/include -I/usr/include/x86_64-linux-gnu/ >c_linux.zig