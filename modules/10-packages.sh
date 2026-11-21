#!/usr/bin/env bash
# OPIS: instalacja potrzebnych i usunięcie zbędnych programów
# shellcheck disable=SC2154  # zmienne z config.env

main() {
  # potrzebne samym skryptom
  apt_install gettext-base python3 libglib2.0-bin xdg-user-dirs

  apt_install "${PKGS_ADD[@]}"

  local p to_remove=()
  for p in "${PKGS_REMOVE[@]}"; do
    pkg_installed "$p" && to_remove+=("$p")
  done
  if [[ ${#to_remove[@]} -gt 0 ]]; then
    log "Usuwam: ${to_remove[*]}"
    DEBIAN_FRONTEND=noninteractive apt-get purge -y -qq "${to_remove[@]}"
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y -qq
  fi
  ok "pakiety"
}
