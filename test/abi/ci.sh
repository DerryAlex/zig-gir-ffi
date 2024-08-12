#!/usr/bin/bash
pkg_rel=1 # used to trigger ci without actual changes

zig translate-c -cflags $(pkg-config --keep-system-cflags --cflags-only-I gtk4) -- c_linux.h >c_linux.zig
patch c_linux.zig c_linux.patch

# setup msys2 env
HEADERS_VERSION=$(wget -qO- "https://packages.msys2.org/api/search?query=headers" | jq -r ".results.exact.version")
wget -qO- "https://mirror.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-headers-git-$HEADERS_VERSION-any.pkg.tar.zst" | \
    zstdcat - | tar -x ucrt64
WINPTHREADS_VERSION=$(wget -qO- "https://packages.msys2.org/api/search?query=winpthreads" | jq -r ".results.exact.version")
wget -qO- "https://mirror.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-winpthreads-git-$WINPTHREADS_VERSION-any.pkg.tar.zst" | \
    zstdcat - | tar -x ucrt64
GLIB_VERSION=$(wget -qO- "https://packages.msys2.org/api/search?query=glib2" | jq -r ".results.exact.version")
wget -qO- "https://mirror.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-glib2-$GLIB_VERSION-any.pkg.tar.zst" | \
    zstdcat - | tar -x ucrt64
PANGO_VERSION=$(wget -qO- "https://packages.msys2.org/api/search?query=pango" | jq -r ".results.exact.version")
wget -qO- "https://mirror.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-pango-$PANGO_VERSION-any.pkg.tar.zst" | \
    zstdcat - | tar -x ucrt64
GTK_VERSION=$(wget -qO- "https://packages.msys2.org/api/search?query=gtk4" | jq -r ".results.exact.version")
wget -qO- "https://mirror.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-gtk4-$GTK_VERSION-any.pkg.tar.zst" | \
    zstdcat - | tar -x ucrt64
# pkg-config cross-compliation support
sed -i 's:prefix=/ucrt64:prefix=ucrt64:g' ucrt64/lib/pkgconfig/*.pc
export PKG_CONFIG_PATH=$(pwd)/ucrt64/lib/pkgconfig/

zig translate-c -target x86_64-windows-gnu -cflags $(pkg-config --cflags-only-I gtk4) -Iucrt64/include -- c_win.h > c_win.zig
patch c_win.zig c_win.patch