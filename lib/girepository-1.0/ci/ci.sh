#!/usr/bin/bash

gir_version="0.20.5"

apt-get source glib2.0
cd $(ls -F | grep 'glib2.0' | grep '/$')
patch girepository/girnode.c ../girnode.patch || exit 1
meson setup build && cd build
meson compile
export PATH=$(pwd)/girepository/compiler:$(pwd)/girepository/decompiler:$(pwd)/girepository/inspector:${PATH}
cd ../..

git clone https://github.com/gtk-rs/gir-files.git && cd gir-files
git checkout ${gir_version}

# utf8
sed -i 's/type name="utf8" c:type="gchar"/type name="gchar" c:type="gchar"/g' GLib-2.0.gir
# introspectable
sed -i 's/field name="priority" introspectable="0"/field name="priority"/g' GLib-2.0.gir
sed -i 's/enumeration name="ThreadPriority" introspectable="0" deprecated="1"/enumeration name="ThreadPriority"/g' GLib-2.0.gir
sed -i 's/c:identifier="g_cclosure_new\(.*\)"\(.*\) introspectable="0"/c:identifier="g_cclosure_new\1"\2/g' GObject-2.0.gir
sed -i 's/c:identifier="g_closure_\(.*\)"\(.*\) introspectable="0"/c:identifier="g_closure_\1"\2/g' GObject-2.0.gir
sed -i 's/c:identifier="g_object_new_with_properties"\(.*\) introspectable="0"/c:identifier="g_object_new_with_properties"\1/g' GObject-2.0.gir
sed -i 's/c:identifier="g_signal_newv"\(.*\) introspectable="0"/c:identifier="g_signal_newv"\1/g' GObject-2.0.gir
# Win32
sed -i 's/type name="GLib.Win32/type name="GLibWin32./g' GLibWin32-2.0.gir
sed -i 's/type name="Gio.Win32/type name="GioWin32./g' GioWin32-2.0.gir
# misc
sed -i 's/gconstpointer/gpointer/g' Pango-1.0.gir

for gir in $(ls *.gir)
do
    typelib=$(echo ${gir} | sed 's/.gir/.typelib/')
    gi-compile-repository ${gir} -o ../../${typelib} --includedir .
done

# LLP64
sed -i 's/glong/gint/g' GLib-2.0.gir
sed -i 's/gulong/guint/g' GLib-2.0.gir
gi-compile-repository GLib-2.0.gir -o ../../x86_64-windows/GLib-2.0.typelib --includedir .

cd ..
