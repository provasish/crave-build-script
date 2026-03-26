#!/bin/bash

# ================= CONFIG =================

TG_BOT_TOKEN="8614247175:AAHQzSIbrgB1pNXQ-J2vyUsQUbpOWvQ_6Qc"
TG_CHAT_ID="-1003529010804"

DEVICE="spartan"
ROM="The Clover Project"
ANDROID="16"

export TZ="Asia/Kolkata"
export BUILD_USERNAME=hunt3r
export BUILD_HOSTNAME=pro

OUT_DIR="out/target/product/${DEVICE}"
ZIP_PATTERN="Evolution*${DEVICE}*.zip"
JSON_FILE="out/target/product/${DEVICE}/${DEVICE}.json"

# ==========================================

send_tg() {
local TEXT="$1"

```
curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TG_CHAT_ID}" \
    --data-urlencode "text=${TEXT}" \
    --data-urlencode "parse_mode=HTML" \
    --data-urlencode "disable_web_page_preview=true" \
    > /dev/null
```

}

upload_gofile() {
FILE="$1"

```
SERVER=$(curl -s https://api.gofile.io/getServer | jq -r '.data.server')
RESPONSE=$(curl -s -F "file=@${FILE}" "https://${SERVER}.gofile.io/uploadFile")

STATUS=$(echo "$RESPONSE" | jq -r '.status')
if [[ "$STATUS" == "ok" ]]; then
    echo "$RESPONSE" | jq -r '.data.downloadPage'
else
    echo ""
fi
```

}

format_time() {
T=$1
printf "%02dh:%02dm:%02ds" $((T/3600)) $((T%3600/60)) $((T%60))
}

# ================= START ==================

START=$(date +%s)

send_tg "<b>🚀 Build Started</b>
ROM: $ROM
Device: $DEVICE"

echo "========== INIT & SYNC =========="

repo init -u https://github.com/The-Clover-Project/manifest.git -b 16-qpr2 --git-lfs --depth=1

/opt/crave/resync.sh
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

echo "========== CLEAN =========="
rm -rf device/realme vendor/realme kernel/realme hardware/oplus hardware/dolby vendor/oplus vendor/clover-priv

echo "========== CLONE =========="

git clone https://github.com/clover-spartan/android_device_realme_spartan device/realme/spartan
git clone https://github.com/clover-spartan/android_device_realme_sm8250-common device/realme/sm8250-common

git clone https://github.com/clover-spartan/proprietary_vendor_realme_spartan vendor/realme/spartan
git clone https://github.com/clover-spartan/proprietary_vendor_realme_sm8250-common vendor/realme/sm8250-common --depth=1

git clone https://github.com/clover-spartan/android_kernel_realme_sm8250 kernel/realme/sm8250 --depth=1

git clone https://github.com/clover-spartan/android_hardware_dolby hardware/dolby
git clone https://github.com/clover-spartan/android_hardware_oplus hardware/oplus

git clone https://gitlab.com/provasishh/proprietary_vendor_oplus_camera.git vendor/oplus/camera --depth=1

echo "========== SIGNING KEYS =========="

git clone https://github.com/Olzhas-Kdyr/keys -b cl vendor/clover-priv/keys

echo "========== BUILD =========="
source build/envsetup.sh
lunch clover_${DEVICE}-bp4a-user
m installclean

mka clover -j$(nproc --all)
STATUS=$?

END=$(date +%s)
DURATION=$(format_time $((END - START)))

# ================= RESULT ==================

if [[ $STATUS -eq 0 ]]; then
send_tg "<b>✅ Build Success</b>
Duration: $DURATION"

```
ZIP=$(ls ${OUT_DIR}/${ZIP_PATTERN} 2>/dev/null | tail -n 1)

ROM_LINK=""
JSON_LINK=""

if [[ -f "$ZIP" ]]; then
    ROM_LINK=$(upload_gofile "$ZIP")
fi

if [[ -f "$JSON_FILE" ]]; then
    JSON_LINK=$(upload_gofile "$JSON_FILE")
fi

send_tg "<b>📦 Upload Done</b>
```

ROM: $ROM_LINK
JSON: $JSON_LINK"

else
send_tg "<b>❌ Build Failed</b>
Duration: $DURATION"
fi
