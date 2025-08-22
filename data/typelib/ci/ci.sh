#!/usr/bin/bash

apt-get source glib2.0
pushd $(ls -F | grep 'glib2.0' | grep '/$')
patch girepository/girnode.c ../girnode.patch || exit 1
meson setup build && cd build
meson compile
export PATH=$(pwd)/girepository/compiler:$(pwd)/girepository/decompiler:$(pwd)/girepository/inspector:${PATH}
popd

pushd ../../gir

# utf8
sed -i 's/type name="utf8" c:type="gchar"/type name="gchar" c:type="gchar"/g' GLib-2.0.gir
# Win32
sed -i 's/type name="GLib.Win32/type name="GLibWin32./g' GLibWin32-2.0.gir
sed -i 's/type name="Gio.Win32/type name="GioWin32./g' GioWin32-2.0.gir
# misc
sed -i 's/gconstpointer/gpointer/g' Pango-1.0.gir

for gir in $(ls *.gir)
do
    typelib=$(echo ${gir} | sed 's/.gir/.typelib/')
    gi-compile-repository ${gir} -o ../typelib/${typelib} --includedir .
done

# LLP64
sed -i 's/glong/gint/g' GLib-2.0.gir
sed -i 's/gulong/guint/g' GLib-2.0.gir
gi-compile-repository GLib-2.0.gir -o ../typelib/x86_64-windows/GLib-2.0.typelib --includedir .

popd
