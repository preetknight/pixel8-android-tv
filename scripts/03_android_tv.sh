#!/system/bin/sh

# 1. Wait for system boot completed
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done
sleep 3

# 2. Disable lock screen & dismiss keyguard
locksettings set-disabled true
cmd window dismiss-keyguard
input keyevent 82
input keyevent 3

# 3. Disable Pixel Launcher permanently (removes Taskbar and bottom navigation bar completely)
pm disable-user --user 0 com.google.android.apps.nexuslauncher

# 4. 16:9 Aspect Ratio & 4K Render Buffer (960x540dp TV layout)
wm size 2160x3840 -d 0
wm density 640 -d 0

# 5. Permanent Landscape Lock
settings put system accelerometer_rotation 0
settings put system user_rotation 1
cmd window set-ignore-orientation-request -d 0 true
cmd window fixed-to-user-rotation -d 0 enabled
cmd window user-rotation -d 0 lock 1

# 6. Disable navigation bar & gesture hints, enable cutout removal
cmd overlay disable com.android.internal.systemui.navbar.threebutton
cmd overlay enable com.android.internal.systemui.navbar.gestural
settings put secure navigation_bar_gesture_hint 0
cmd overlay enable com.android.internal.display.cutout.emulation.noCutout
settings put global policy_control immersive.status=*

# 7. Android TV Keyboard (LeanKeyboard)
ime enable org.liskovsoft.androidtv.rukeyboard/com.liskovsoft.leankeyboard.ime.LeanbackImeService
ime set org.liskovsoft.androidtv.rukeyboard/com.liskovsoft.leankeyboard.ime.LeanbackImeService

# 8. Launch HideStatusBar daemon ONLY if not already running
if ! ps -A | grep -v grep | grep -qi "hide_statusbar"; then
    nohup app_process -Djava.class.path=/data/adb/kiosk/hide_statusbar.dex /system/bin HideStatusBar >/data/local/tmp/hide_sb.log 2>&1 &
fi

# 9. Mirror settings and keep awake
settings put secure mirror_built_in_display 1
svc power stayon true
settings put system screen_off_timeout 2147483647

# 10. TV Box Power & Battery Optimizations
# - Limit charge to 80% to protect battery 24/7
settings put secure charge_optimization_mode 1
# - Zero internal screen brightness to reduce heat & power draw
settings put system screen_brightness_mode 0
settings put system screen_brightness 0

# 11. Set GlassTV as home launcher
cmd package set-home-activity com.techgenius.tvoslauncher/.MainActivity

# 12. Ensure Touchscreen Kernel Module is completely unloaded
rmmod goodix_brl_touch 2>/dev/null
if [ -e /sys/bus/platform/drivers/goodix_ts/goodix_ts.0 ]; then
    echo -n goodix_ts.0 > /sys/bus/platform/drivers/goodix_ts/unbind 2>/dev/null
fi

# 13. Background watcher daemon:
# - Auto-enables connected external display
# - Permanently ensures touchscreen remains dead and unloaded
while true; do
    rmmod goodix_brl_touch 2>/dev/null
    if [ -e /sys/bus/platform/drivers/goodix_ts/goodix_ts.0 ]; then
        echo -n goodix_ts.0 > /sys/bus/platform/drivers/goodix_ts/unbind 2>/dev/null
    fi

    ext_ids=$(cmd display get-displays --type external -i 2>/dev/null)
    for id in $ext_ids 2; do
        cmd display enable-display "$id" >/dev/null 2>&1
    done

    sleep 5
done &
