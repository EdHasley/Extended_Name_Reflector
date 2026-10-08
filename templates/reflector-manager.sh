#!/bin/bash
# Extended Name Reflector Manager
# Project-specific management layer for EdHasley/Extended_Name_Reflector.
# PP5PK's original user/database manager remains available as option 1.
set -u

MAIN_H="/usr/src/xlxd/src/main.h"
SRC_DIR="/usr/src/xlxd/src"
CONF="/etc/extended-name-reflector/reflector.conf"
DASH_CFG="/var/www/html/xlxd/pgs/config.inc.php"
CALLHOME="/xlxd/callinghome.php"
USER_MANAGER="/xlxd/users_db/reflector_user_manager.sh"

need_root() { if [[ ${EUID:-$(id -u)} -ne 0 ]]; then exec sudo "$0" "$@"; fi; }
pause(){ read -r -p "Press Enter to continue..." _; }
yn(){ local a; read -r -p "$1 [y/N]: " a; [[ "${a^^}" == Y || "${a^^}" == YES ]]; }
port(){ [[ "$1" =~ ^[0-9]+$ ]] && ((1<=10#$1 && 10#$1<=65535)); }
get_define(){ grep -E "^[[:space:]]*#define[[:space:]]+$1[[:space:]]+" "$MAIN_H" 2>/dev/null | tail -1 | awk '{print $3}'; }
set_define(){
  local key="$1" val="$2"
  grep -Eq "^[[:space:]]*#define[[:space:]]+${key}[[:space:]]+" "$MAIN_H" || { echo "Cannot find ${key} in ${MAIN_H}"; return 1; }
  sed -Ei "s|^([[:space:]]*#define[[:space:]]+${key}[[:space:]]+).*|\\1${val}|" "$MAIN_H"
}
toggle_define(){ local key="$1" cur ans; cur=$(get_define "$key"); read -r -p "$key (0=off, 1=on) [${cur:-?}]: " ans; ans=${ans:-$cur}; [[ "$ans" == 0 || "$ans" == 1 ]] || return 1; set_define "$key" "$ans"; }
port_define(){ local key="$1" cur ans; cur=$(get_define "$key"); read -r -p "$key port [${cur:-?}]: " ans; ans=${ans:-$cur}; port "$ans" || { echo "Invalid port."; return 1; }; set_define "$key" "$ans"; }

rebuild(){
  echo
  echo "This recompiles XLXD and restarts the reflector service."
  yn "Continue" || return
  (cd "$SRC_DIR" && make && make install) || { echo "Build/install failed. Existing service was not deliberately removed."; pause; return; }
  if [[ -x /ambed/ambed ]]; then
    (cd /usr/src/xlxd/ambed && make && make install) || { echo "AMBED build failed; check the build output."; pause; return; }
    systemctl is-active --quiet ambed.service && systemctl restart ambed.service
  fi
  systemctl restart xlxd.service || { echo "XLXD restart failed."; pause; return; }
  echo "XLXD rebuilt and restarted."
  pause
}

protocols(){
  while true; do
    clear
    echo "=== Protocol Enable / Disable ==="
    echo "1 DExtra       $(get_define ENABLE_DEXTRA)"
    echo "2 DPlus        $(get_define ENABLE_DPLUS)"
    echo "3 DCS          $(get_define ENABLE_DCS)"
    echo "4 XLX interlink $(get_define ENABLE_XLX)"
    echo "5 DMRPlus      $(get_define ENABLE_DMRPLUS)"
    echo "6 DMR MMDVM    $(get_define ENABLE_DMRMMDVM)"
    echo "7 Yaesu / System Fusion"
    echo "8 G3 Terminal  $(get_define ENABLE_G3)"
    echo "X Back"
    read -r -p "> " c
    case "$c" in
      1) toggle_define ENABLE_DEXTRA ;;
      2) toggle_define ENABLE_DPLUS ;;
      3) toggle_define ENABLE_DCS ;;
      4) toggle_define ENABLE_XLX ;;
      5) toggle_define ENABLE_DMRPLUS ;;
      6) toggle_define ENABLE_DMRMMDVM ;;
      7)
        echo "YSF:  $(get_define ENABLE_YSF)"
        echo "IMRS: $(get_define ENABLE_IMRS)"
        toggle_define ENABLE_YSF
        toggle_define ENABLE_IMRS
        ;;
      8) toggle_define ENABLE_G3 ;;
      [Xx]) return ;;
    esac
  done
}

ports_menu(){
  while true; do
    clear
    echo "=== Protocol Ports ==="
    echo "1 DExtra       $(get_define DEXTRA_PORT)"
    echo "2 DPlus        $(get_define DPLUS_PORT)"
    echo "3 DCS          $(get_define DCS_PORT)"
    echo "4 XLX interlink $(get_define XLX_PORT)"
    echo "5 DMRPlus      $(get_define DMRPLUS_PORT)"
    echo "6 DMR MMDVM    $(get_define DMRMMDVM_PORT)"
    echo "7 YSF           $(get_define YSF_PORT)"
    echo "8 IMRS          $(get_define IMRS_PORT)"
    echo "9 G3 presence   $(get_define G3_PRESENCE_PORT)"
    echo "10 G3 config    $(get_define G3_CONFIG_PORT)"
    echo "11 G3 DV        $(get_define G3_DV_PORT)"
    echo "12 AMBE/transcoder $(get_define TRANSCODER_PORT)"
    echo "X Back"
    read -r -p "> " c
    case "$c" in
      1) port_define DEXTRA_PORT;; 2) port_define DPLUS_PORT;; 3) port_define DCS_PORT;;
      4) port_define XLX_PORT;; 5) port_define DMRPLUS_PORT;; 6) port_define DMRMMDVM_PORT;;
      7) port_define YSF_PORT;; 8) port_define IMRS_PORT;; 9) port_define G3_PRESENCE_PORT;;
      10) port_define G3_CONFIG_PORT;; 11) port_define G3_DV_PORT;; 12) transcoder_port;;
      [Xx]) return;;
    esac
  done
}

ysf_menu(){
  clear
  echo "=== Yaesu / System Fusion Settings ==="
  toggle_define ENABLE_YSF
  toggle_define ENABLE_IMRS
  port_define YSF_PORT
  port_define IMRS_PORT
  local cur ans
  cur=$(get_define YSF_DEFAULT_NODE_TX_FREQ); read -r -p "YSF frequency Hz [${cur:-433125000}]: " ans; ans=${ans:-${cur:-433125000}}
  [[ "$ans" =~ ^[0-9]+$ ]] && { set_define YSF_DEFAULT_NODE_TX_FREQ "$ans"; set_define YSF_DEFAULT_NODE_RX_FREQ "$ans"; }
  toggle_define YSF_AUTOLINK_ENABLE || true
  pause
}

transcoder_port(){
  port_define TRANSCODER_PORT || return
  if [[ -f /usr/src/xlxd/ambed/main.h ]]; then
    local value=$(get_define TRANSCODER_PORT)
    sed -Ei "s|^(#define[[:space:]]+TRANSCODER_PORT[[:space:]]+).*|\\1$value|" /usr/src/xlxd/ambed/main.h
    echo "Both XLXD and AMBED ports updated. Choose Rebuild to apply."
  fi
}

ambe_menu(){
  clear
  echo "=== AMBE / Transcoder ==="
  transcoder_port
  if [[ -f /etc/systemd/system/ambed.service ]]; then
    if systemctl is-enabled --quiet ambed.service 2>/dev/null; then
      yn "Disable AMBE service" && systemctl disable --now ambed.service
    else
      yn "Enable AMBE service" && systemctl enable --now ambed.service
    fi
  else
    echo "AMBED service is not installed. The manager will not install hardware drivers automatically."
  fi
  pause
}

dashboard_settings(){
  local name callhome
  name=$(sed -n 's/^EXTENDED_NAME="\(.*\)"/\1/p' "$CONF" | tail -1)
  callhome=$(sed -n 's/^CALL_HOME="\([YN]\)"/\1/p' "$CONF" | tail -1)
  python3 /usr/local/bin/dashboard-settings.py /var/www/html/xlxd/config.inc.php "$name" "${callhome:-N}"
}

dashboard_menu(){
  local new
  read -r -p "New extended name (Enter keeps current): " new
  [[ -n "$new" ]] || return
  # Metadata remains a simple quoted value; do not execute it as shell code.
  [[ ${#new} -le 60 && "$new" != *\"* && "$new" != *\\* && "$new" != *$'\n'* ]] || { echo "Use 1–60 characters without double quotes or backslashes."; pause; return; }
  local escaped=${new//&/\\&}; escaped=${escaped//|/\\|}
  sed -i "s|^EXTENDED_NAME=.*|EXTENDED_NAME=\"$escaped\"|" "$CONF"
  dashboard_settings && echo "Extended name updated."
  pause
}

callhome_menu(){
  local ans
  read -r -p "Public call-home advertising Y/N: " ans; ans=${ans^^}
  [[ "$ans" == Y || "$ans" == N ]] || { echo "Invalid."; pause; return; }
  sed -i "s/^CALL_HOME=.*/CALL_HOME=\"$ans\"/" "$CONF"
  dashboard_settings && echo "Call-home set to $ans."
  pause
}

header_menu(){
  clear
  echo "=== Optional Dashboard Header ==="
  echo "The original header is preserved before replacement."
  echo "Custom PNG height must match the currently installed header."
  local current="" custom=""
  current=$(find /var/www/html/xlxd -type f -name 'header.png' 2>/dev/null | head -1)
  [[ -n "$current" ]] || { echo "Installed header.png not found."; pause; return; }
  echo "Installed header: $current"
  read -r -p "Full path to custom header.png (Enter cancels): " custom
  [[ -n "$custom" ]] || return
  [[ -f "$custom" ]] || { echo "File not found."; pause; return; }
  file "$custom" | grep -qi 'PNG image' || { echo "The selected file is not a PNG."; pause; return; }
  [[ -f "${current}.original" ]] || cp -p "$current" "${current}.original"
  # PNG IHDR stores width/height at bytes 16..23. Compare height only; width may vary.
  oldh=$(od -An -tu4 -N4 -j20 --endian=big "$current" | tr -d ' ')
  newh=$(od -An -tu4 -N4 -j20 --endian=big "$custom" | tr -d ' ')
  if [[ -z "$oldh" || -z "$newh" || "$oldh" != "$newh" ]]; then
    echo "Header height mismatch. Installed=${oldh:-unknown}px custom=${newh:-unknown}px. No change made."
    pause; return
  fi
  cp "$custom" "$current"
  chmod 644 "$current"
  echo "Custom header installed. Width was allowed to vary; height remained ${oldh}px."
  pause
}

status_menu(){
  echo "XLXD service: $(systemctl is-active xlxd.service 2>/dev/null || true)"
  echo "Apache:       $(systemctl is-active apache2 2>/dev/null || true)"
  echo "AMBE:         $(systemctl is-active ambed.service 2>/dev/null || echo not-installed)"
  echo "Protocol ID:  $(sed -n 's/^PROTOCOL_ID="\(.*\)"/\1/p' "$CONF" 2>/dev/null | tail -1)"
  echo "Extended name: $(sed -n 's/^EXTENDED_NAME="\(.*\)"/\1/p' "$CONF" 2>/dev/null | tail -1)"
  pause
}

need_root "$@"
while true; do
  clear
  echo "=============================================="
  echo "        EXTENDED NAME REFLECTOR MANAGER"
  echo "=============================================="
  echo "1. User / RadioID / whitelist management"
  echo "2. Enable or disable protocols"
  echo "3. Change protocol ports"
  echo "4. Yaesu / System Fusion / IMRS settings"
  echo "5. AMBE / transcoder settings"
  echo "6. Extended name / dashboard text"
  echo "7. Public call-home advertising"
  echo "8. Optional custom dashboard header.png"
  echo "9. Rebuild XLXD and restart reflector"
  echo "10. Show service / reflector status"
  echo "X. Exit"
  read -r -p "> " choice
  case "$choice" in
    1) [[ -x "$USER_MANAGER" ]] && "$USER_MANAGER" || { echo "PP5PK user manager is missing."; pause; };;
    2) protocols;; 3) ports_menu;; 4) ysf_menu;; 5) ambe_menu;; 6) dashboard_menu;;
    7) callhome_menu;; 8) header_menu;; 9) rebuild;; 10) status_menu;; [Xx]) exit 0;;
  esac
done
