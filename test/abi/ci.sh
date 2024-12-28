#!/usr/bin/bash

zig translate-c -cflags $(pkg-config --keep-system-cflags --cflags-only-I gtk4) -- c.h >c.zig
patch c.zig c.patch || exit 1