#!/bin/sh
gcc `pkg-config --cflags gobject-introspection-1.0` -Wall -g -ggdb gir-zig.c emit.c fmt.c -o gir-zig `pkg-config --libs gobject-introspection-1.0`