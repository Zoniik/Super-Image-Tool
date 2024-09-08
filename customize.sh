#!/sbin/sh
#Super_Image Tool
#By Zonik

SKIPUNZIP=0

#Variables para Ksu
KSU_VARIABLES="

KSU
KSU_VER
KSU_VER_CODE
KSU_KERNEL_VER_CODE
LATESTARTSERVICE
MODPATH
SKIPUNZIP
PROPFILE
POSTFSDATA
SKIPMOUNT

"

export KSU_VARIABLES $KSU_VARIABLES

#DI binary
di_binary="META-INF/com/google/android/update-binary"
route_di_binary="$TMPDIR/$di_binary"
unzip -qo "$ZIPFILE" "$di_binary" -d "$TMPDIR"
if [ -f "$route_di_binary" ]; then
   . "$route_di_binary"
else
    abort "ERROR Incompatible update-binary"
fi
#Fin