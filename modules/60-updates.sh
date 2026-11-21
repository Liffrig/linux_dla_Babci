#!/usr/bin/env bash
# OPIS: automatyczne aktualizacje w tle, bez powiadomień dla Babci
# shellcheck disable=SC2154  # zmienne z config.env

hide_update_tray() {
  is_yes "$HIDE_UPDATE_NOTIFICATIONS" || return 0
  local name
  for name in mintupdate mintreport; do
    write_user_file "$(user_home)/.config/autostart/$name.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Hidden=true
X-GNOME-Autostart-enabled=false
EOF
  done
  ok "ukryte powiadomienia o aktualizacjach"
}

main() {
  hide_update_tray
  needs_systemd || return 0
  is_yes "$AUTO_UPDATES" || { skip "AUTO_UPDATES=no"; return 0; }

  if have_cmd mintupdate-automation; then
    # natywny mechanizm Minta: aktualizacje + sprzątanie starych jąder (timery systemd)
    mintupdate-automation upgrade enable
    mintupdate-automation autoremove enable
    ok "mintupdate-automation: włączone (log: /var/log/mintupdate.log)"
  else
    warn "brak mintupdate-automation – używam unattended-upgrades"
    apt_install unattended-upgrades
    write_root_file /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
    ok "unattended-upgrades: włączone"
  fi
}
