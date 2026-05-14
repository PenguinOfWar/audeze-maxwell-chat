#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WP_CONF_DIR="${HOME}/.config/wireplumber/wireplumber.conf.d"
WP_SCRIPT_DIR="${HOME}/.local/share/wireplumber/scripts"

VENDOR_ID="0x3329"
PRODUCT_ID="0x4b19"

echo "--- Audeze Maxwell Chat sink installer ---"
echo

# check if the Maxwell dongle is present and find its card number
CARD_NUM=""
if pactl list cards 2>/dev/null | grep -q "device.vendor.id = \"${VENDOR_ID}\""; then
  CARD_NUM=$(pactl list cards 2>/dev/null \
    | grep -A 50 "device.vendor.id = \"${VENDOR_ID}\"" \
    | grep "alsa.card = " | head -1 \
    | grep -o '"[0-9]*"' | tr -d '"')
  echo "--- Audeze Maxwell Dongle detected (ALSA card ${CARD_NUM}) ---"
else
  echo "WARNING: Audeze Maxwell Dongle not detected (vendor ${VENDOR_ID})."
  echo "         Config will still be installed and will activate when the device is plugged in."
  echo "         Run this script again with the dongle connected to persist mixer settings."
  echo
fi

# create config directories if needed
for dir in "${WP_CONF_DIR}" "${WP_SCRIPT_DIR}"; do
  if [[ ! -d "${dir}" ]]; then
    echo "--- Creating ${dir} ---"
    mkdir -p "${dir}"
  fi
done

# install conf
conf_src="${SCRIPT_DIR}/wireplumber/51-audeze-maxwell-chat.conf"
conf_dst="${WP_CONF_DIR}/51-audeze-maxwell-chat.conf"
if [[ ! -f "${conf_src}" ]]; then
  echo "ERROR: Missing source file ${conf_src}"
  exit 1
fi
echo "--- Installing 51-audeze-maxwell-chat.conf ---"
cp "${conf_src}" "${conf_dst}"

# install Lua script
lua_src="${SCRIPT_DIR}/wireplumber/scripts/audeze-maxwell-chat.lua"
lua_dst="${WP_SCRIPT_DIR}/audeze-maxwell-chat.lua"
if [[ ! -f "${lua_src}" ]]; then
  echo "ERROR: Missing source file ${lua_src}"
  exit 1
fi
echo "--- Installing audeze-maxwell-chat.lua ---"
cp "${lua_src}" "${lua_dst}"

echo
echo "--- Restarting WirePlumber ---"
systemctl --user restart wireplumber
sleep 2

# set PCM 1 to max and persist ALSA mixer state if device is present
if [[ -n "${CARD_NUM}" ]]; then
  echo "--- Setting Chat sink (PCM 1) to maximum volume on card ${CARD_NUM}..."
  amixer -c "${CARD_NUM}" sset 'PCM',1 100% 2>/dev/null \
    || echo "    WARNING: Could not set PCM 1 volume - set it manually with: alsamixer -c ${CARD_NUM}"
  echo "--- Saving ALSA mixer state for card ${CARD_NUM}..."
  sudo alsactl store "${CARD_NUM}"
  echo "    Mixer state persisted."
fi

echo
echo "--- Checking for Maxwell sinks ---"
wpctl status | grep -i "audeze\|maxwell" || echo "    (none found - device may not be connected)"

echo
echo "You should see two Audeze sinks:"
echo "  - Audeze Maxwell Chat"
echo "  - Audeze Maxwell Game"
echo
echo "Point applications at the appropriate channel."
echo "The chat mix knob on the headset controls the... mix."
echo
