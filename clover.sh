#!/bin/bash

# --- CONFIGURATION ---
TOKEN="8614247175:AAHQzSIbrgB1pNXQ-J2vyUsQUbpOWvQ_6Qc"
CHAT_ID="-1003529010804"
DEVICE="spartan"

# 1. Initialize and Sync
echo "--- Initializing The Clover Project ---"
repo init -u https://github.com/The-Clover-Project/manifest.git -b 16-qpr2 --git-lfs --depth=1
/opt/crave/resync.sh

# 2. Clean up old specific repos
echo "--- Cleaning old repos ---"
rm -rf device/realme kernel/realme vendor/realme hardware/oplus hardware/dolby vendor/clover-priv/keys vendor/oplus out/target/product/spartan

# 3. Clone Trees
echo "--- Cloning Device Trees ---"
git clone https://github.com/clover-spartan/android_device_realme_spartan device/realme/spartan
git clone https://github.com/clover-spartan/android_device_realme_sm8250-common device/realme/sm8250-common
git clone https://github.com/clover-spartan/proprietary_vendor_realme_spartan vendor/realme/spartan
git clone --depth=1 https://github.com/clover-spartan/proprietary_vendor_realme_sm8250-common vendor/realme/sm8250-common
git clone --depth=1 https://github.com/clover-spartan/android_kernel_realme_sm8250 kernel/realme/sm8250
git clone https://github.com/clover-spartan/android_hardware_dolby hardware/dolby
git clone https://github.com/clover-spartan/android_hardware_oplus hardware/oplus
git clone --depth=1 https://gitlab.com/provasishh/proprietary_vendor_oplus_camera.git vendor/oplus/camera
git clone -b cl https://github.com/Olzhas-Kdyr/keys vendor/clover-priv/keys

# 5. Notify Telegram Start
curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage \
    -d chat_id=$CHAT_ID \
    -d text="🚀 Clover Project build for realme GT NEO 3T (spartan) started on Crave.io"

# 6. Build
. build/envsetup.sh
make installclean
lunch clover_spartan-bp4a-user
mka clover -j$(nproc --all)

# 7. Check Status and Upload
status=$?
if [ $status -eq 0 ]; then
    echo "--- BUILD SUCCESS ---"
    OUT_DIR="out/target/product/$DEVICE"
    ZIP_PATH=$(ls $OUT_DIR/Clover*.zip 2>/dev/null | head -n 1)
    JSON_PATH="$OUT_DIR/spartan.json"
    
    if [ -f "$ZIP_PATH" ]; then
        echo "Uploading files to GoFile..."
        
        # Upload ROM Zip
        RESULT_ZIP=$(curl -sSL https://raw.githubusercontent.com/elohim-etz/GoFile-Upload/main/upload.sh | bash -s -- "$ZIP_PATH")
        URL_ZIP=$(echo "$RESULT_ZIP" | grep -o "https://gofile.io/d/[a-zA-Z0-9]*")

        # Upload spartan.json (if it exists)
        if [ -f "$JSON_PATH" ]; then
            RESULT_JSON=$(curl -sSL https://raw.githubusercontent.com/elohim-etz/GoFile-Upload/main/upload.sh | bash -s -- "$JSON_PATH")
            URL_JSON=$(echo "$RESULT_JSON" | grep -o "https://gofile.io/d/[a-zA-Z0-9]*")
        fi

        # Prepare Telegram Message
        MESSAGE="✅ *Clover Project for realme GT NEO 3T Build Complete!*%0A%0A📦 *ROM:* [Download Link]($URL_ZIP)"
        if [ -n "$URL_JSON" ]; then
            MESSAGE+="%0A📄 *Metadata:* [spartan.json Link]($URL_JSON)"
        fi

        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
             -d "chat_id=$CHAT_ID" \
             -d "parse_mode=Markdown" \
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
