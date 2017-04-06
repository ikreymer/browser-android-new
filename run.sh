android_arch=$ANDROID_ARCH
if [ -z "$android_arch" ]
then
    android_arch="x86_64"
fi

xsetroot -cursor_name left_ptr
run_browser jwm -display $DISPLAY &

PATH=$PATH:${ANDROID_HOME}/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator

echo "hw.keyboard = yes" >> ~/.android/avd/${android_arch}.avd/config.ini

# Force centering
echo "window.x=-10" >> ~/.android/avd/${android_arch}.avd/emulator-user.ini
echo "window.y=-10" >> ~/.android/avd/${android_arch}.avd/emulator-user.ini

export LD_LIBRARY_PATH="/opt/android-sdk-linux/tools/lib64/:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/opt/android-sdk-linux/emulator/lib64/qt/lib/:$LD_LIBRARY_PATH"

# Set up and run emulator
#run_browser emulator64-${android_arch} -avd ${android_arch} -noaudio -gpu off -verbose -qemu &
run_browser emulator64-x86 -avd ${android_arch} -writable-system -noaudio -accel on -gpu off \
			   -prop "status.battery.level_raw=100" -verbose -show-kernel -memory 2048 \
			   -selinux disabled -qemu &
			   #-snapstorage /app/snapstore.img -snapshot emu \

PID=$!

sleep 20

if [[ -n "$PROXY_GET_CA" ]]; then
    curl -x "$PROXY_HOST:$PROXY_PORT"  "$PROXY_GET_CA" > /tmp/proxy-ca.pem

    /app/addcert.sh /tmp/proxy-ca.pem
fi

# Wait until boot is done
while [ "`adb shell getprop sys.boot_completed | tr -d '\r' `" != "1" ] ; do sleep 1; done

# set battery to full!
#echo -e "auth $(cat ~/.emulator_console_auth_token)\npower capacity 100" | socat - TCP4:localhost:5554

# Launch browser!
adb shell 'echo "chrome --no-default-browser-check --no-first-run --disable-fre" > /data/local/chrome-command-line'

adb shell am start -n com.android.chrome/com.google.android.apps.chrome.Main -d "$URL"

wait $PID


