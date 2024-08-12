msys2 -c 'zig translate-c -cflags $(pkg-config --cflags gtk4) -- c_win.h -I/ucrt64/include >c_win.zig'
patch c_win.zig c_win.patch