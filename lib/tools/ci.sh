gir_version="0.19.2"

apt src gobject-introspection
cd $(ls -F | grep 'gobject-introspection' | grep '/$')
meson setup build && cd build
patch girepository/girnode.c ../../girnode.patch
meson compile
export PATH=$(pwd)/tools:${PATH}
cd ../../..

git clone https://github.com/gtk-rs/gir.git && cd gir
git checkout ${gir_version}
for gir in $(ls *.gir)
do
    typelib=$(echo ${gir} | sed 's/.gir/.typelib/')
    g-ir-compiler ${gir} -o ${typelib} --includedir .
done