#!/bin/bash

# --- CONFIGURATION ---
TOKEN="8614247175:AAHQzSIbrgB1pNXQ-J2vyUsQUbpOWvQ_6Qc"
CHAT_ID="-1003529010804"
DEVICE="spartan"

# Start the timer
START=$(date +%s)

# 1. Initialize and Sync
echo "--- Initializing EvolutionX ---"
repo init -u https://github.com/Evolution-X/manifest -b bq2 --git-lfs --depth=1
/opt/crave/resync.sh

# 2. Clean up old specific repos
echo "--- Cleaning old repos ---"
rm -rf device/realme kernel/realme vendor/realme hardware/oplus hardware/dolby vendor/evolution-priv/keys vendor/oplus out/target/product/spartan

# 3. Clone Trees
echo "--- Cloning Device Trees ---"
git clone https://github.com/Evolution-X-Devices/device_realme_spartan device/realme/spartan
git clone https://github.com/EvoX-Spartan/android_device_realme_sm8250-common device/realme/sm8250-common
git clone https://github.com/Evolution-X-Devices/vendor_realme_spartan vendor/realme/spartan
git clone --depth=1 https://github.com/EvoX-Spartan/proprietary_vendor_realme_sm8250-common vendor/realme/sm8250-common
git clone --depth=1 https://github.com/EvoX-Spartan/android_kernel_realme_sm8250 kernel/realme/sm8250
git clone https://github.com/EvoX-Spartan/hardware_dolby hardware/dolby
git clone https://github.com/EvoX-Spartan/android_hardware_oplus hardware/oplus
git clone --depth=1 https://gitlab.com/provasishh/proprietary_vendor_oplus_camera.git vendor/oplus/camera

git clone https://github.com/Evolution-X/vendor_evolution-priv_keys-template vendor/evolution-priv/keys --depth 1
chmod +x vendor/evolution-priv/keys/keys.sh
pushd vendor/evolution-priv/keys
./keys.sh
popd

# 5. Notify Telegram Start
curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage \
    -d chat_id=$CHAT_ID \
    -d text="🚀 EvolutionX build for realme GT NEO 3T (spartan) started on Crave.io"

# 6. Build
. build/envsetup.sh
make installclean
lunch lineage_spartan-bp4a-user
m evolution

# 7. Check Status and Upload
status=$?
if [ $status -eq 0 ]; then
    # Calculate duration
    END=$(date +%s)
    DIFF=$((END - START))
    DURATION="$((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds"

    echo "--- BUILD SUCCESS ---"
    OUT_DIR="out/target/product/$DEVICE"
    ZIP_PATH=$(ls $OUT_DIR/Evolution*.zip 2>/dev/null | head -n 1)
    JSON_PATH="$OUT_DIR/spartan.json"
    
    if [ -f "$ZIP_PATH" ]; then
        echo "Uploading files to GoFile..."
        
        # Upload ROM Zip
        RESULT_ZIP=$(curl -sSL https://raw.githubusercontent.com/elohim-etz/GoFile-Upload/main/upload.sh | bash -s -- "$ZIP_PATH")
        URL_ZIP=$(echo "$RESULT_ZIP" | grep -o "https://gofile.io/d/[a-zA-Z0-9]*")

        # Upload spartan.json
        if [ -f "$JSON_PATH" ]; then
            RESULT_JSON=$(curl -sSL https://raw.githubusercontent.com/elohim-etz/GoFile-Upload/main/upload.sh | bash -s -- "$JSON_PATH")
            URL_JSON=$(echo "$RESULT_JSON" | grep -o "https://gofile.io/d/[a-zA-Z0-9]*")
        fi

        # Prepare Telegram Message (HTML Mode for perfect links)
        MESSAGE="✅ <b>EvolutionX for realme GT NEO 3T Build Complete!</b>%0A%0A📦 <b>ROM:</b> <a href='$URL_ZIP'>Download</a>"
        if [ -n "$URL_JSON" ]; then
            MESSAGE+="%0A📄 <b>Metadata:</b> <a href='$URL_JSON'>spartan.json</a>"
        fi
        MESSAGE+="%0A%0A⏱ <b>Build Time:</b> $DURATION"

        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
             -d "chat_id=$CHAT_ID" \
             -d "parse_mode=HTML" \
             -d "text=$MESSAGE"
    else
        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
             -d "chat_id=$CHAT_ID" \
             -d "text=❌ Build succeeded but the .zip file was not found."
    fi
else
    echo "--- BUILD FAILED ---"
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
         -d "chat_id=$CHAT_ID" \
         -d "text=❌ Build failed with exit code $status"
    exit 1
fi
