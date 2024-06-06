#!/usr/bin/bash
compiler=$(pwd)/gobject-introspection/build/tools/g-ir-compiler
typelibdir=$(pwd)/../girepository-1.0

#girdir=/usr/share/gir-1.0
girdir=gir-files
cd ${girdir}

for gir in $(ls *.gir)
do
    typelib=$(echo ${gir} | sed 's/.gir/.typelib/')
    ${compiler} ${gir} -o ${typelibdir}/${typelib} --includedir .
done
