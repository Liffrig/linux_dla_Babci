#!/usr/bin/env bash
# OPIS: przyspieszenie starszego sprzętu (zram, zbędne usługi)
# shellcheck disable=SC2154  # zmienne z config.env

setup_zram() {
  is_yes "$ZRAM" || { skip "ZRAM=no"; return 0; }
  if swapon --show=NAME --noheadings 2>/dev/null | grep -q zram && ! pkg_installed zram-tools; then
    ok "zram już działa (skonfigurowany przez system)"
    return 0
  fi
  apt_install zram-tools
  write_root_file /etc/default/zramswap <<EOF
# Linux dla Babci – skompresowany swap w RAM
ALGO=zstd
PERCENT=${ZRAM_PERCENT}
PRIORITY=100
EOF
  # przy zram opłaca się częściej "swapować" do RAM niż czytać z dysku
  write_root_file /etc/sysctl.d/90-babcia-zram.conf <<'EOF'
vm.swappiness=150
vm.page-cluster=0
EOF
  sysctl -q --system || true
  systemctl enable zramswap >/dev/null 2>&1
  systemctl restart zramswap
  ok "zram: ${ZRAM_PERCENT}% RAM, zstd"
}

disable_unit() {
  local unit="$1"
  if systemctl list-unit-files "$unit" --no-legend 2>/dev/null | grep -q .; then
    systemctl disable --now "$unit" >/dev/null 2>&1 || true
    ok "wyłączono $unit"
  fi
}

main() {
  needs_systemd || return 0
  setup_zram
  is_yes "$DISABLE_BLUETOOTH" && disable_unit bluetooth.service
  if is_yes "$DISABLE_PRINTING"; then
    disable_unit cups.service
    disable_unit cups-browsed.service
  fi
  return 0
}
