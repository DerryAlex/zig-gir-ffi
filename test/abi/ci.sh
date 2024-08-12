#!/usr/bin/bash
pkg_rel=1 # used to trigger ci without actual changes
zig translate-c -cflags $(pkg-config --cflags gtk4) -- c_linux.h -I/usr/include -I/usr/include/x86_64-linux-gnu/ >c_linux.zig
patch c_linux.zig c_linux.patch