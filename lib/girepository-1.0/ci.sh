#!/usr/bin/bash

gir_version="0.20.0"

apt-get source gobject-introspection
cd $(ls -F | grep 'gobject-introspection' | grep '/$')
patch girepository/girnode.c ../girnode.patch
meson setup build && cd build
meson compile
export PATH=$(pwd)/tools:${PATH}
cd ../..

git clone https://github.com/gtk-rs/gir-files.git && cd gir-files
git checkout ${gir_version}
sed -i 's/type name="utf8" c:type="gchar"/type name="gchar" c:type="gchar"/g' GLib-2.0.gir
sed -i 's/field name="priority" introspectable="0" readable="0" private="1"/field name="priority" readable="0" private="1"/g' GLib-2.0.gir
sed -i 's/enumeration name="ThreadPriority" introspectable="0" deprecated="1"/enumeration name="ThreadPriority" deprecated="1"/g' GLib-2.0.gir
sed -i 's/gconstpointer/gpointer/g' Pango-1.0.gir
for gir in $(ls *.gir)
do
    typelib=$(echo ${gir} | sed 's/.gir/.typelib/')
    g-ir-compiler ${gir} -o ../${typelib} --includedir .
done
cd ..
