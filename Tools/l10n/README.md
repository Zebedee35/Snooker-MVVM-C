# Translations

`Localization/Localizable.xcstrings` is the source of truth. It ships English
only; a language appears in the app just once it has been reviewed by someone
who speaks it and imported here.

Both targets share `Localization/` — the app and the Live Activity widget read
the same catalog, so a status pill or round name reads identically in each.

## Adding a string

1. Add the accessor to `Localization/L10n.swift`.
2. Add the key to the catalog with an English value and a **comment**. The
   comment is the only context a reviewer gets: say where the string appears,
   what any placeholder holds, and any length limit.
3. `python3 Tools/l10n/l10n.py check` — fails if a key is missing its English
   value, warns if it has no comment.

Call sites use `L10n.Settings.signOut`, never a raw key, so deleting a key
breaks the build instead of silently rendering the key name at runtime.

## Getting a language translated

```bash
python3 Tools/l10n/l10n.py export
```

Writes `Tools/l10n/review/` — a CSV and a self-contained HTML page. Send people
the page: it shows each English string with its context and the draft
translation, validates placeholders as they type, keeps their work in the
browser, and gives them a corrected CSV to send back.

Drafts live in `drafts.json`. They are machine-written starting points, not
finished translations — `review_flags` in that file lists the specific calls
that need a native speaker.

## Shipping a reviewed language

```bash
python3 Tools/l10n/l10n.py import tr --from ~/Downloads/snooker-translations-tr.csv
```

This refuses to import if a translation drops or invents a placeholder
(`%@`, `%1$d`) or changes the line-break count — mistakes that crash or garble
the UI rather than merely reading badly. On success it writes the catalog and
adds the language to `knownRegions` in the project file, which is what actually
makes the build emit a `.lproj` for it.

Then open Xcode and build. Nothing else to wire up: the Settings → Language
picker is built from `Bundle.main.localizations`, so the new language appears
on its own, and the row stays hidden while English is the only option.

Keys left untranslated fall back to English rather than showing the key.

## How language selection works

`LanguageManager` holds either `.system` (follow the device, re-negotiated
through Foundation so `de-AT` matches `de`) or an explicit code. Changing it
swaps the `.lproj` bundle and posts `.appLanguageChanged`; `AppCoordinator`
rebuilds the tab bar in place, keeping the user on the tab they were on. The
choice syncs to `user_settings.language` alongside the other preferences —
see `Supabase/07_multi_language_setup.sql`.

A few things stay outside our control:

- **System-drawn UI** — keyboard, share sheet, the search bar's Cancel button —
  follows `AppleLanguages`, which only takes effect on the next launch. The
  Language screen says so.
- **The widget** follows the device language, not the in-app picker. Widgets
  run in their own process with their own `UserDefaults`; sharing the choice
  would need an App Group, which this project doesn't have yet.

## Text that isn't in the catalog

Round names and match statuses arrive from the backend as English data, and
are used for logic as well as display. They are mapped to catalog keys at the
point of display by `RoundName` and `MatchStatusName`; anything unrecognised
passes through in English rather than breaking the screen. If the feed starts
sending a new round name, add a case there and a key to the catalog.
