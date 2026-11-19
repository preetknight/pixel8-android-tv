#!/system/bin/sh
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done
sleep 5

echo 3 > /sys/module/exynos_drm/parameters/dp_rate 2>/dev/null
echo 10 > /sys/module/exynos_drm/parameters/dp_bpc 2>/dev/null

if [ "$(cat /sys/devices/platform/110f0000.drmdp/drm-displayport/hpd 2>/dev/null)" = "1" ]; then
    echo 0 > /sys/devices/platform/110f0000.drmdp/drm-displayport/hpd
    sleep 1
    echo 1 > /sys/devices/platform/110f0000.drmdp/drm-displayport/hpd
    sleep 3
fi

export BOOTCLASSPATH="$BOOTCLASSPATH:/system/framework/services.jar:/data/local/tmp/set_4k_hdr.dex"
export LD_LIBRARY_PATH="/system/lib64:/apex/com.android.adbd/lib64"
app_process /system/bin Set4KHDR >/data/local/tmp/set4k.log 2>&1

sleep 2
wm size 2160x3840 -d 0
wm density 640 -d 0

export BOOTCLASSPATH="$(echo "$BOOTCLASSPATH" | sed 's/set_4k_hdr\.dex/keep_4k_hdr.dex/')"
nohup app_process /system/bin Keep4KHDR >/data/local/tmp/keep4k.log 2>&1 &
nohup /data/local/tmp/auto_hdr.sh >/dev/null 2>&1 &
