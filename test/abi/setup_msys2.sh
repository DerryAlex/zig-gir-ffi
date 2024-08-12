#!/usr/bin/bash
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