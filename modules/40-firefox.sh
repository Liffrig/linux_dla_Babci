#!/usr/bin/env bash
# OPIS: Firefox – strona startowa, uBlock, blokada powiadomień i dodatków
# shellcheck disable=SC2154  # zmienne z config.env

main() {
  have_cmd firefox || apt_install firefox

  # /etc/firefox/policies/ – działa dla Firefoksa z .deb (Mint) i przetrwa aktualizacje
  export START_PAGE FIREFOX_SCALE FIREFOX_SAVE_PASSWORDS FIREFOX_BLOCK_ADDONS FIREFOX_BOOKMARKS_TOOLBAR
  printf '%s\n' "${TILES[@]}" \
    | python3 -I "$REPO_DIR/lib/gen_firefox_policies.py" \
    | write_root_file /etc/firefox/policies/policies.json
  ok "polityki: /etc/firefox/policies/policies.json (sprawdzisz w about:policies)"
}
