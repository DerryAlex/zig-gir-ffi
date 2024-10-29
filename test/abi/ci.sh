#!/usr/bin/bash
pkg_rel=2 # used to trigger ci without actual changes

zig translate-c -cflags $(pkg-config --keep-system-cflags --cflags-only-I gtk4) -- c_linux.h >c_linux.zig
patch c_linux.zig c_linux.patch || exit 1