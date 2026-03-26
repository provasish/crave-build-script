#!/bin/bash

# ================= CONFIG =================

TG_BOT_TOKEN="8614247175:AAHQzSIbrgB1pNXQ-J2vyUsQUbpOWvQ_6Qc"
TG_CHAT_ID="-1003529010804"

DEVICE="spartan"
ROM="Evolution-X"
ANDROID="16"

export TZ="Asia/Kolkata"
export BUILD_USERNAME=hunt3r
export BUILD_HOSTNAME=pro

OUT_DIR="out/target/product/${DEVICE}"
ZIP_PATTERN="Evolution*${DEVICE}*.zip"
JSON_FILE="out/target/product/${DEVICE}/${DEVICE}.json"

# ==========================================

send_tg() {
curl -s "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" 
-d chat_id="${TG_CHAT_ID}" 
-d parse_mode="HTML" 
-d disable_web_page_preview=true 
-d text="$1" > /dev/null
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

send_tg "<b>🚀 Build Started</b> <b>ROM:</b> $ROM <b>Android:</b> $ANDROID <b>Device:</b> $DEVICE <b>Time:</b> $(date)"

echo "========== INIT & SYNC =========="

repo init -u https://github.com/Evolution-X/manifest -b bq2 --git-lfs --depth=1

/opt/crave/resync.sh
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

echo "========== CLEAN OLD TREES =========="
rm -rf device/realme vendor/realme kernel/realme hardware/oplus hardware/dolby vendor/oplus vendor/evolution-priv

echo "========== CLONE TREES =========="

git clone https://github.com/EvoX-Spartan/android_device_realme_spartan device/realme/spartan
git clone https://github.com/EvoX-Spartan/android_device_realme_sm8250-common device/realme/sm8250-common

git clone https://github.com/EvoX-Spartan/proprietary_vendor_realme_spartan vendor/realme/spartan
git clone https://github.com/EvoX-Spartan/proprietary_vendor_realme_sm8250-common vendor/realme/sm8250-common --depth=1

git clone https://github.com/EvoX-Spartan/android_kernel_realme_sm8250 -b bka kernel/realme/sm8250 --depth=1

git clone https://github.com/EvoX-Spartan/hardware_dolby hardware/dolby --depth=1
git clone https://github.com/EvoX-Spartan/android_hardware_oplus hardware/oplus

git clone https://gitlab.com/provasishh/proprietary_vendor_oplus_camera.git vendor/oplus/camera --depth=1

echo "========== SIGNING KEYS =========="

git clone https://github.com/Evolution-X/vendor_evolution-priv_keys-template vendor/evolution-priv/keys --depth 1
chmod +x vendor/evolution-priv/keys/keys.sh
pushd vendor/evolution-priv/keys
./keys.sh
popd

echo "========== BUILD SETUP =========="
source build/envsetup.sh

echo "========== CLEAN INSTALL =========="
m installclean

echo "========== LUNCH =========="
lunch lineage_${DEVICE}-bp4a-user

echo "========== BUILD START =========="
m evolution -j$(nproc --all)
STATUS=$?

END=$(date +%s)
DURATION=$(format_time $((END - START)))

# ================= RESULT ==================

if [[ $STATUS -eq 0 ]]; then
send_tg "<b>✅ Build Successful</b> <b>Duration:</b> $DURATION"

```
ZIP=$(ls ${OUT_DIR}/${ZIP_PATTERN} 2>/dev/null | tail -n 1)

# Upload ROM
if [[ -f "$ZIP" ]]; then
    send_tg "📤 Uploading ROM..."
    ROM_LINK=$(upload_gofile "$ZIP")
else
    ROM_LINK=""
fi

# Upload JSON
if [[ -f "$JSON_FILE" ]]; then
    send_tg "📤 Uploading JSON..."
    JSON_LINK=$(upload_gofile "$JSON_FILE")
else
    JSON_LINK=""
fi

# Final message
MESSAGE="<b>📦 Upload Completed</b>"

if [[ -n "$ROM_LINK" ]]; then
    MESSAGE+="
```

<b>ROM:</b> <a href="$ROM_LINK">Download</a>"
else
MESSAGE+="
❌ ROM upload failed"
fi

```
if [[ -n "$JSON_LINK" ]]; then
    MESSAGE+="
```

<b>JSON:</b> <a href="$JSON_LINK">Download</a>"
else
MESSAGE+="
❌ JSON upload failed"
fi

```
send_tg "$MESSAGE"
```

else
send_tg "<b>❌ Build Failed</b> <b>Duration:</b> $DURATION"
fi

if [[ -f out/error.log ]]; then
    send_tg "<pre>$(tail -n 20 out/error.log)</pre>"
fi
```


