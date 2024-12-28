#include <gtk/gtk.h>

#if defined (unix)
# include <glib-unix.h>
#endif

#if defined (linux)
# include <gdk/wayland/gdkwayland.h>
# include <gdk/x11/gdkx.h>
#elif defined (_WIN32)
# include <gdk/win32/gdkwin32.h>
#elif defined (__APPLE__)
# include <gdk/macos/gdkmacos.h>
#endif