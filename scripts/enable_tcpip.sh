#!/system/bin/sh
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done
sleep 2
setprop service.adb.tcp.port 5555
stop adbd
start adbd
