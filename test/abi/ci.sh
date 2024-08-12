#!/usr/bin/bash
pkg_rel=1 # used to trigger ci without actual changes

zig translate-c -cflags $(pkg-config --keep-system-cflags --cflags-only-I gtk4) -- c_linux.h >c_linux.zig
patch c_linux.zig c_linux.patch

# pkg-config cross-compliation support
sed -i 's:prefix=/ucrt64:prefix=ucrt64:g' ucrt64/lib/pkgconfig/*.pc
export PKG_CONFIG_PATH=$(pwd)/ucrt64/lib/pkgconfig/

zig translate-c -target x86_64-windows-gnu -cflags $(pkg-config --cflags-only-I gtk4) -Iucrt64/include -- c_win.h > c_win.zig
patch c_win.zig c_win.patch