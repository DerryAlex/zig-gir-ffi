#!/usr/bin/bash
for gir in cairo-1.0 freetype2-2.0 Gdk-4.0 GdkPixbuf-2.0 Gio-2.0 GLib-2.0 GModule-2.0 GObject-2.0 Graphene-1.0 Gsk-4.0 Gtk-4.0 HarfBuzz-0.0 Pango-1.0 PangoCairo-1.0
do
    ./g-ir-compiler /usr/share/gir-1.0/${gir}.gir -o ../girepository-1.0/${gir}.typelib
done
