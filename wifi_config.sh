#!/bin/bash
#

# Device Serial Number
SN=$1

if [[ $# -eq 0 ]] ; then
	echo "Required device Serial Number as parameter"
    exit 0
fi

# Get this information by connecting manually once, and do
#   adb pull /data/misc/wifi/wpa_supplicant.conf
ADB_PULL="adb -s $SN pull /data/misc/wifi/wpa_supplicant.conf"
WIRELESS_CTRL_INTERFACE=/data/misc/wifi/sockets
WIRELESS_SSID="[m4u_corp]"
WIRELESS_KEY_MGMT="WPA-EAP IEEE8021X"
WIRELESS_EAP=PEAP
WIRELESS_USER=patricia.oliveira
WIRELESS_PASSWORD=hash:47b1bf19604e8951bc86a316b49e6660
# Generate another hash password if you need: echo -n {plain_text_password} | iconv -t utf16le | openssl md4

adb start-server
adb wait-for-device
echo "adb connection....[CONNECTED]"
adb root
adb wait-for-device
adb remount
adb wait-for-device

pushd /tmp
rm wpa_supplicant.conf 2>/dev/null # Remove any old one
adbpull_status=`$ADB_PULL 2>&1`
echo -e "\nAttempting: $ADB_PULL"
if [ `echo $adbpull_status | grep -wc "does not exist"` -gt 0 ]; then
    echo "  wpa_supplicant.conf does not exist yet on your device yet."
    echo "This means you have not used your wireless yet."
    echo ""
    echo "Taking our best shot at creating this file with default config.."

    echo "ctrl_interface=$WIRELESS_CTRL_INTERFACE" >> wpa_supplicant.conf
    echo "update_config=1" >> wpa_supplicant.conf
    echo "device_type=0-00000000-0" >> wpa_supplicant.conf
else
    echo $adbpull_status
    echo "  wpa_supplicant.conf exists!"
fi

echo ""
echo "Add network entry for wpa_supplicant.conf.."
echo "" >> wpa_supplicant.conf
echo "network={" >> wpa_supplicant.conf
echo "  ssid=\"$WIRELESS_SSID\"" >> wpa_supplicant.conf
echo "  key_mgmt=$WIRELESS_KEY_MGMT" >> wpa_supplicant.conf
echo "  eap=$WIRELESS_EAP" >> wpa_supplicant.conf
echo "  identity=\"$WIRELESS_USER\"" >> wpa_supplicant.conf
echo "  password=$WIRELESS_PASSWORD" >> wpa_supplicant.conf
#echo "  password=\"$WIRELESS_PASSWORD\"" >> wpa_supplicant.conf
echo "  priority=1" >> wpa_supplicant.conf
#echo "	sim_slot=\"-1\"" >> wpa_supplicant.conf
#echo "	imsi=\"none\"" >> wpa_supplicant.conf
#echo "	proactive_key_caching=1" >> wpa_supplicant.conf
echo "}" >> wpa_supplicant.conf
echo "Pushing wpa_supplicant.conf.."
adb -s $SN push wpa_supplicant.conf /data/misc/wifi/wpa_supplicant.conf
popd #/tmp

adb -s $SN shell chown system.wifi /data/misc/wifi/wpa_supplicant.conf
adb -s $SN shell chmod 660 /data/misc/wifi/wpa_supplicant.conf

echo ""
echo "Finished!"
adb -s $SN shell am start -a android.intent.action.MAIN -n com.android.settings/.Settings
echo "Please toggle wifi off/on now.. (ifconfig not sufficient, monkey this)"
