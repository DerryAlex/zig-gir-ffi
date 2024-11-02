#!/usr/bin/bash

gir_version="0.20.1"

# apt-get source glib2.0
# cd $(ls -F | grep 'glib2.0' | grep '/$')
apt-get source gobject-introspection
cd $(ls -F | grep 'gobject-introspection' | grep '/$')
patch girepository/girnode.c ../girnode.patch || exit 1
meson setup build && cd build
meson compile
# export PATH=$(pwd)/girepository/compiler:$(pwd)/girepository/decompiler:$(pwd)/girepository/inspector:${PATH}
cd ../..
export PATH=$(pwd)/tools:${PATH}

git clone https://github.com/gtk-rs/gir-files.git && cd gir-files
git checkout ${gir_version}

# fetch GIRepository-3.0.gir
cp /usr/share/gir-1.0/GIRepository-3.0.gir .

# utf8
sed -i 's/type name="utf8" c:type="gchar"/type name="gchar" c:type="gchar"/g' GLib-2.0.gir
sed -i 's/type name="utf8" c:type="char"/type name="gchar" c:type="char"/g' HarfBuzz-0.0.gir
# introspectable
sed -i 's/field name="priority" introspectable="0"/field name="priority"/g' GLib-2.0.gir
sed -i 's/enumeration name="ThreadPriority" introspectable="0" deprecated="1"/enumeration name="ThreadPriority"/g' GLib-2.0.gir
sed -i 's/function name="image_surface_create"/function name="image_surface_create" introspectable="0"/g' cairo-1.0.gir
# Win32
sed -i 's/type name="GLib.Win32/type name="GLibWin32./g' GLibWin32-2.0.gir
sed -i 's/type name="Gio.Win32/type name="GioWin32./g' GioWin32-2.0.gir
# misc
sed -i 's/gconstpointer/gpointer/g' Pango-1.0.gir

for gir in $(ls *.gir)
do
    typelib=$(echo ${gir} | sed 's/.gir/.typelib/')
    # gi-compile-repository ${gir} -o ../${typelib} --includedir .
    g-ir-compiler ${gir} -o ../${typelib} --includedir .
done

cd ..
