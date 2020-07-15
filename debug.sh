#!/bin/sh
# Connect to remote gdbserver
ROOTDIR=/tmp
GDB=/opt/android-sdk/ndk-bundle/prebuilt/linux-x86_64/bin/gdb
APP=com.android.chrome

if [ ! -e "$ROOTDIR/system/bin/app_process" ]; then
	mkdir -p $ROOTDIR/system
	mkdir $ROOTDIR/system/bin
	mkdir $ROOTDIR/system/lib
	adb pull /system/bin/app_process $ROOTDIR/system/bin/
	adb pull /system/bin/linker $ROOTDIR/system/bin/
	adb pull /system/lib/libc.so $ROOTDIR/system/lib/
	adb pull /system/lib/libm.so $ROOTDIR/system/lib/
	adb pull /system/lib/libdl.so $ROOTDIR/system/lib/
fi

adb forward tcp:5039 tcp:5039
#adb forward tcp:8700 jdwp:$(adb shell pgrep "^$APP$")
adb shell su -c /data/local/tmp/gdbserver :5039 --attach \`pgrep "^${APP}$"\` 2>&1 > /dev/null &
#jdb -attach localhost:8700 2>&1 > /dev/null &
sleep .3

$GDB \
	-ex 'set osabi GNU/Linux' \
	-ex "file $ROOTDIR/system/bin/app_process" \
	-ex "set solib-search-path $ROOTDIR/system/bin:$ROOTDIR/system/lib:./obj/local/armeabi-v7a" \
	-ex 'set sysroot target:' \
	-ex 'set follow-fork-mode child' \
	-ex 'set detach-on-fork off' \
	-ex 'display/i $pc' \
	-ex 'display/i $pc-2' \
	-ex 'target remote :5039'

