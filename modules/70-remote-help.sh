#!/usr/bin/env bash
# OPIS: zdalna pomoc (RustDesk lub Tailscale)
# shellcheck disable=SC2154  # zmienne z config.env

install_rustdesk() {
  if ! pkg_installed rustdesk; then
    local ver="$RUSTDESK_VERSION" tmp
    if [[ "$ver" == latest ]]; then
      ver="$(curl -fsSL https://api.github.com/repos/rustdesk/rustdesk/releases/latest \
             | python3 -Ic 'import json,sys; print(json.load(sys.stdin)["tag_name"])')"
    fi
    tmp="$(mktemp -d)"
    log "Pobieram RustDesk $ver"
    curl -fL --retry 3 -o "$tmp/rustdesk.deb" \
      "https://github.com/rustdesk/rustdesk/releases/download/${ver}/rustdesk-${ver}-x86_64.deb"
    apt_update_once
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$tmp/rustdesk.deb"
    rm -rf "$tmp"
  fi
  systemctl enable --now rustdesk >/dev/null 2>&1 || true

  if [[ -n "${RUSTDESK_PASSWORD:-}" ]]; then
    sleep 2
    rustdesk --password "$RUSTDESK_PASSWORD" >/dev/null 2>&1 || warn "nie udało się ustawić hasła RustDesk"
  fi
  local id
  id="$(rustdesk --get-id 2>/dev/null || true)"
  ok "RustDesk zainstalowany${id:+ – ID komputera: $id} (zapisz je!)"
}

install_tailscale() {
  if ! have_cmd tailscale; then
    log "Instaluję Tailscale (oficjalny skrypt tailscale.com/install.sh)"
    curl -fsSL https://tailscale.com/install.sh | sh
  fi
  apt_install openssh-server
  systemctl enable --now tailscaled ssh >/dev/null 2>&1 || true
  if tailscale status >/dev/null 2>&1; then
    ok "Tailscale już połączony: $(tailscale ip -4 2>/dev/null | head -1)"
  else
    warn "Dokończ ręcznie: sudo tailscale up   (zaloguj się na swoje konto Tailscale)"
  fi
}

main() {
  needs_systemd || return 0
  case "${REMOTE_HELP:-none}" in
    rustdesk)  install_rustdesk ;;
    tailscale) install_tailscale ;;
    none)      skip "REMOTE_HELP=none" ;;
    *)         die "REMOTE_HELP: nieznana wartość '$REMOTE_HELP' (rustdesk|tailscale|none)" ;;
  esac
}
