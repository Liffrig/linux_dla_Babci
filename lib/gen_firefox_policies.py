#!/usr/bin/env python3
"""Generuje policies.json dla Firefoksa.

Wejście: kafelki "Nazwa|URL|emoji" na stdin, opcje w zmiennych środowiskowych.
Wyjście: JSON na stdout.
Dokumentacja polityk: https://mozilla.github.io/policy-templates/
"""
import json
import os
import sys


def yes(name: str) -> bool:
    return os.environ.get(name, "").strip().lower() in {"y", "yes", "tak", "t", "1", "true"}


tiles = []
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    parts = line.split("|")
    if len(parts) >= 2:
        tiles.append({"name": parts[0], "url": parts[1]})

start_page = os.environ["START_PAGE"]

prefs = {
    # bez pytań "czy przetłumaczyć", "czy ustawić jako domyślną" itp.
    "browser.aboutConfig.showWarning": {"Value": False, "Status": "default"},
    "browser.tabs.warnOnClose": {"Value": False, "Status": "default"},
    "browser.translations.automaticallyPopup": {"Value": False, "Status": "default"},
    # karty zawsze na wierzchu, duże przyciski
    "browser.uidensity": {"Value": 2, "Status": "default"},  # 2 = "dotykowy" (większe)
    "browser.compactmode.show": {"Value": False, "Status": "default"},
    "layout.spellcheckDefault": {"Value": 1, "Status": "default"},
}
scale = os.environ.get("FIREFOX_SCALE", "").strip()
if scale:
    prefs["layout.css.devPixelsPerPx"] = {"Value": scale, "Status": "default"}

policies = {
    "DisableAppUpdate": True,          # aktualizacje przez system (apt), nie przez Firefoksa
    "DisableTelemetry": True,
    "DisableFirefoxStudies": True,
    "DisablePocket": True,
    "DisableProfileImport": True,
    "DisableSetDesktopBackground": True,
    "DontCheckDefaultBrowser": True,
    "NoDefaultBookmarks": True,
    "OverrideFirstRunPage": "",
    "OverridePostUpdatePage": "",
    "PromptForDownloadLocation": False,
    "Homepage": {"URL": start_page, "StartPage": "homepage", "Locked": False},
    "NewTabPage": True,
    "FirefoxHome": {
        "Search": True,
        "TopSites": True,
        "SponsoredTopSites": False,
        "Highlights": False,
        "Pocket": False,
        "SponsoredPocket": False,
        "Snippets": False,
        "Locked": False,
    },
    "UserMessaging": {
        "ExtensionRecommendations": False,
        "FeatureRecommendations": False,
        "UrlbarInterventions": False,
        "SkipOnboarding": True,
        "MoreFromMozilla": False,
        "FirefoxLabs": False,
        "Locked": True,
    },
    "FirefoxSuggest": {
        "WebSuggestions": False,
        "SponsoredSuggestions": False,
        "ImproveSuggest": False,
        "Locked": True,
    },
    # fałszywe "wirusy" najczęściej przychodzą przez powiadomienia ze stron
    "Permissions": {
        "Notifications": {"BlockNewRequests": True, "Locked": True},
        "Location": {"BlockNewRequests": True},
        "Autoplay": {"Default": "block-audio"},
    },
    "PopupBlocking": {"Default": True, "Locked": True},
    "EnableTrackingProtection": {"Value": True, "Cryptomining": True, "Fingerprinting": True},
    "PasswordManagerEnabled": yes("FIREFOX_SAVE_PASSWORDS"),
    "OfferToSaveLogins": yes("FIREFOX_SAVE_PASSWORDS"),
    "RequestedLocales": ["pl"],
    "Preferences": prefs,
    "ExtensionSettings": {
        # uBlock Origin – blokuje reklamy i dużo podejrzanych stron
        "uBlock0@raymondhill.net": {
            "installation_mode": "force_installed",
            "install_url": "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi",
            "private_browsing": True,
        },
    },
}

if yes("FIREFOX_BLOCK_ADDONS"):
    policies["ExtensionSettings"]["*"] = {
        "installation_mode": "blocked",
        "blocked_install_message": "Instalacja dodatków jest wyłączona. Zadzwoń do wnuczka 🙂",
    }

if yes("FIREFOX_BOOKMARKS_TOOLBAR") and tiles:
    policies["DisplayBookmarksToolbar"] = "always"
    # "Bookmarks" kładzie zakładki bezpośrednio na pasku (ManagedBookmarks
    # chowa je w folderze, co jest dla Babci o jedno kliknięcie za dużo)
    policies["Bookmarks"] = [
        {"Title": t["name"], "URL": t["url"], "Placement": "toolbar"} for t in tiles
    ]
else:
    policies["DisplayBookmarksToolbar"] = "never"

json.dump({"policies": policies}, sys.stdout, ensure_ascii=False, indent=2)
sys.stdout.write("\n")
