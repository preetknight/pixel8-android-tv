#!/system/bin/sh
# Unbind goodix_ts touchscreen driver early at boot (prevents ghost touches on damaged panel)
for i in $(seq 1 30); do
    if [ -e /sys/bus/platform/drivers/goodix_ts/goodix_ts.0 ]; then
        echo -n goodix_ts.0 > /sys/bus/platform/drivers/goodix_ts/unbind
        break
    fi
    sleep 0.5
done
