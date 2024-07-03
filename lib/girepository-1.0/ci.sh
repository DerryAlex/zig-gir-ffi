#!/usr/bin/bash

gir_version="0.19.2"

apt-get source gobject-introspection
cd $(ls -F | grep 'gobject-introspection' | grep '/$')
patch girepository/girnode.c ../../girnode.patch
meson setup build && cd build
meson compile
export PATH=$(pwd)/tools:${PATH}
cd ../..

git clone https://github.com/gtk-rs/gir-files.git && cd gir-files
git checkout ${gir_version}
sed -i 's/gconstpointer/gpointer/' Pango-1.0.gir
for gir in $(ls *.gir)
do
    typelib=$(echo ${gir} | sed 's/.gir/.typelib/')
    g-ir-compiler ${gir} -o ../${typelib} --includedir .
done
cd ..
