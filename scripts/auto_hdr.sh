#!/system/bin/sh
STATE="sdr"
set_hdr() {
    if [ "$STATE" != "hdr" ]; then
        insmod /data/local/tmp/dp_hdr_hlg.ko 2>/dev/null
        STATE="hdr"
    fi
}
set_sdr() {
    if [ "$STATE" != "sdr" ]; then
        insmod /data/local/tmp/dp_hdr_sdr.ko 2>/dev/null
        STATE="sdr"
    fi
}

logcat -v brief -T 1 CCodecBuffers:D CCodec:D starboard_media:I MediaCodec:D *:S | while IFS= read -r line; do
    case "$line" in
        *"color-transfer = 6"*|*"color-transfer = 7"*)
            set_hdr
            ;;
        *"color-transfer = 3"*|*"hold CodecLooper"*|*"MediaCodec.release"*)
            set_sdr
            ;;
    esac
done
