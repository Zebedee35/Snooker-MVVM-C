#!/usr/bin/env python3
"""Translation tooling for the Snooker String Catalog.

    check                       validate the catalog and the drafts
    export  [--out DIR]         write the reviewer CSV + HTML page
    import  LANG [--from FILE]  merge translations into the catalog

`Localization/Localizable.xcstrings` is the source of truth. Drafts live in
`Tools/l10n/drafts.json` and are *not* shipped until imported — so a language
only reaches users once a native speaker has signed it off.
"""

import argparse
import csv
import html
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "Localization" / "Localizable.xcstrings"
DRAFTS = ROOT / "Tools" / "l10n" / "drafts.json"
PBXPROJ = ROOT / "Snooker.xcodeproj" / "project.pbxproj"

# %@, %d, %1$d … — the placeholders the app substitutes values into. A
# translation that loses one, or invents one, crashes or prints garbage at
# runtime, so these are compared rather than trusted.
SPECIFIER = re.compile(r"%(?:(\d+)\$)?[-+ #0]*[\d.*]*(?:hh|h|ll|l|q|L|z|t|j)?([@dDuUxXoOfeEgGcCsSpaAn%])")


# ---------------------------------------------------------------- catalog io

def load_catalog():
    return json.loads(CATALOG.read_text(encoding="utf-8"))


def save_catalog(catalog):
    CATALOG.write_text(
        json.dumps(catalog, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def load_drafts():
    if not DRAFTS.exists():
        return {"translations": {}, "review_flags": {}}
    return json.loads(DRAFTS.read_text(encoding="utf-8"))


def entry_values(entry, language):
    """The strings for one key in one language, as {plural form or "": text}.

    Non-plural entries come back under the empty-string key, so callers can
    treat both shapes the same way.
    """
    localization = entry.get("localizations", {}).get(language)
    if not localization:
        return {}
    if "stringUnit" in localization:
        return {"": localization["stringUnit"]["value"]}
    variations = localization.get("variations", {}).get("plural", {})
    return {form: unit["stringUnit"]["value"] for form, unit in variations.items()}


def make_localization(value):
    """Builds a catalog localization from a string or a {plural: text} dict."""
    if isinstance(value, dict):
        return {
            "variations": {
                "plural": {
                    form: {"stringUnit": {"state": "translated", "value": text}}
                    for form, text in value.items()
                }
            }
        }
    return {"stringUnit": {"state": "translated", "value": value}}


# --------------------------------------------------------------- validation

def specifiers(text):
    """Placeholders in a string, order-independent and position-aware.

    Positional forms (%1$d) are compared by position; plain ones by order of
    appearance, which is how Foundation resolves them.
    """
    found = []
    for index, (position, kind) in enumerate(SPECIFIER.findall(text), start=1):
        if kind == "%":          # literal %% — not a placeholder
            continue
        found.append(f"{position or index}${kind}")
    return sorted(found)


def check_translation(key, source, translated):
    """Returns a list of problems with one translated string."""
    problems = []
    expected, actual = specifiers(source), specifiers(translated)
    if expected != actual:
        problems.append(
            f"{key}: placeholders differ — source has {expected or 'none'}, "
            f"translation has {actual or 'none'}"
        )
    if source.count("\n") != translated.count("\n"):
        problems.append(
            f"{key}: line breaks differ — source has {source.count(chr(10))}, "
            f"translation has {translated.count(chr(10))}"
        )
    if not translated.strip():
        problems.append(f"{key}: translation is empty")
    return problems


def validate(catalog, language, incoming):
    """Checks incoming translations against the English source."""
    problems, unknown = [], []
    for key, value in incoming.items():
        entry = catalog["strings"].get(key)
        if entry is None:
            unknown.append(key)
            continue

        source = entry_values(entry, catalog["sourceLanguage"])
        target = value if isinstance(value, dict) else {"": value}

        # A plural source needs at least the "other" form in every language;
        # languages without a plural distinction supply only that.
        if len(source) > 1 and "other" not in target:
            problems.append(f"{key}: plural entry is missing the 'other' form")

        for form, text in target.items():
            reference = source.get(form) or source.get("other") or next(iter(source.values()), "")
            problems.extend(check_translation(f"{key}[{form}]" if form else key, reference, text))

    if unknown:
        problems.append(f"{len(unknown)} key(s) not in the catalog: {', '.join(sorted(unknown)[:5])}…")

    missing = sorted(set(catalog["strings"]) - set(incoming))
    return problems, missing


# ------------------------------------------------------------------ commands

L10N_SWIFT = ROOT / "Localization" / "L10n.swift"


def referenced_keys():
    """Keys L10n actually asks for."""
    return set(re.findall(r'tr\("([^"]+)"', L10N_SWIFT.read_text(encoding="utf-8")))


def cmd_check(_args):
    catalog = load_catalog()
    drafts = load_drafts()
    source = catalog["sourceLanguage"]

    print(f"catalog: {len(catalog['strings'])} keys, source language {source}")

    failed = False
    for key, entry in sorted(catalog["strings"].items()):
        if not entry_values(entry, source):
            print(f"  ERROR {key}: no {source} value")
            failed = True
        if not entry.get("comment"):
            print(f"  WARN  {key}: no comment — translators get no context")

    # The catalog is hand-authored, so anything in it that L10n never asks for
    # is noise — most likely Xcode's automatic extraction picking up a SwiftUI
    # literal (a preview string, or score interpolation like "%lld - %lld").
    # Those reach translators as phantom rows, so fail on them.
    # SWIFT_EMIT_LOC_STRINGS is set to NO to stop it at source; this catches
    # the setting being turned back on.
    referenced = referenced_keys()
    for key in sorted(set(catalog["strings"]) - referenced):
        print(f"  ERROR {key!r}: in the catalog but never used by L10n "
              f"— likely auto-extracted; delete it")
        failed = True
    for key in sorted(referenced - set(catalog["strings"])):
        print(f"  ERROR {key!r}: used by L10n but missing from the catalog")
        failed = True

    for language, incoming in sorted(drafts.get("translations", {}).items()):
        problems, missing = validate(catalog, language, incoming)
        status = "OK" if not problems else f"{len(problems)} PROBLEM(S)"
        print(f"\ndraft {language}: {len(incoming)}/{len(catalog['strings'])} keys — {status}")
        for problem in problems:
            print(f"  ERROR {problem}")
            failed = True
        if missing:
            print(f"  {len(missing)} untranslated: {', '.join(missing[:5])}"
                  + ("…" if len(missing) > 5 else ""))

    return 1 if failed else 0


def cmd_export(args):
    catalog = load_catalog()
    drafts = load_drafts()
    languages = sorted(drafts.get("translations", {}))
    out = Path(args.out) if args.out else ROOT / "Tools" / "l10n" / "review"
    out.mkdir(parents=True, exist_ok=True)

    rows = build_rows(catalog, drafts, languages)

    csv_path = out / "translations.csv"
    with csv_path.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.writer(handle)
        writer.writerow(["key", "context", "english"] + languages)
        for row in rows:
            writer.writerow([row["key"], row["comment"], row["english"]]
                            + [row["translations"].get(language, "") for language in languages])

    html_path = out / "index.html"
    html_path.write_text(render_page(rows, languages, drafts), encoding="utf-8")

    print(f"wrote {csv_path} ({len(rows)} rows)")
    print(f"wrote {html_path}")
    return 0


def build_rows(catalog, drafts, languages):
    """Flattens the catalog into reviewer rows, one per key or plural form."""
    rows = []
    source = catalog["sourceLanguage"]
    for key, entry in sorted(catalog["strings"].items()):
        english = entry_values(entry, source)
        for form in sorted(english, key=lambda f: (f != "one", f)):
            row_key = f"{key}::{form}" if form else key
            translations = {}
            for language in languages:
                value = drafts["translations"].get(language, {}).get(key)
                if isinstance(value, dict):
                    translations[language] = value.get(form, value.get("other", ""))
                elif value is not None and not form:
                    translations[language] = value
            rows.append({
                "key": row_key,
                "base_key": key,
                "form": form,
                "comment": entry.get("comment", ""),
                "english": english[form],
                "translations": translations,
                "group": key.split(".")[0],
            })
    return rows


def cmd_import(args):
    catalog = load_catalog()
    language = args.language

    if args.source:
        incoming = read_csv(Path(args.source), language)
    else:
        incoming = load_drafts()["translations"].get(language)
        if incoming is None:
            sys.exit(f"no drafts for '{language}' in {DRAFTS}")

    problems, missing = validate(catalog, language, incoming)
    if problems:
        print(f"refusing to import — {len(problems)} problem(s):")
        for problem in problems:
            print(f"  {problem}")
        return 1

    for key, value in incoming.items():
        entry = catalog["strings"][key]
        entry.setdefault("localizations", {})[language] = make_localization(value)

    save_catalog(catalog)
    added = add_known_region(language)

    print(f"imported {len(incoming)} keys for '{language}'")
    if missing:
        print(f"  {len(missing)} key(s) left untranslated — they fall back to English")
    print(f"  knownRegions: {'added ' + language if added else language + ' already present'}")
    print("\nOpen the project in Xcode and build; the picker lists the language automatically.")
    return 0


def read_csv(path, language):
    """Reads one language column out of a reviewed CSV."""
    with path.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        if language not in (reader.fieldnames or []):
            sys.exit(f"{path} has no '{language}' column (found: {reader.fieldnames})")

        incoming = {}
        for row in reader:
            text = (row.get(language) or "").strip()
            if not text:
                continue
            key = row["key"]
            if "::" in key:                       # plural form, e.g. tip_jar.per_month::one
                base, form = key.split("::", 1)
                incoming.setdefault(base, {})[form] = text
            else:
                incoming[key] = text
    return incoming


def add_known_region(language):
    """Adds the language to the project's knownRegions.

    Without this Xcode does not treat the language as one the project ships,
    and the build produces no .lproj for it — the translations would be in the
    catalog but invisible at runtime.
    """
    text = PBXPROJ.read_text(encoding="utf-8")
    marker = "\t\t\tknownRegions = (\n"
    if marker not in text:
        sys.exit("could not find knownRegions in project.pbxproj")

    start = text.index(marker) + len(marker)
    end = text.index("\t\t\t);", start)
    if f"\t\t\t\t{language},\n" in text[start:end]:
        return False

    return_text = text[:start] + f"\t\t\t\t{language},\n" + text[start:]
    PBXPROJ.write_text(return_text, encoding="utf-8")
    return True


# ----------------------------------------------------------------- html page

def render_page(rows, languages, drafts):
    flags = drafts.get("review_flags", {})
    payload = json.dumps({
        "languages": languages,
        "rows": rows,
        "flags": flags,
    }, ensure_ascii=False)

    template = (Path(__file__).parent / "review_template.html").read_text(encoding="utf-8")
    return template.replace("/*__DATA__*/null", payload).replace(
        "__KEY_COUNT__", str(len({row["base_key"] for row in rows}))
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("check", help="validate the catalog and drafts")

    export = sub.add_parser("export", help="write the reviewer CSV and HTML page")
    export.add_argument("--out", help="output directory")

    imp = sub.add_parser("import", help="merge a language into the catalog")
    imp.add_argument("language", help="language code, e.g. tr")
    imp.add_argument("--from", dest="source", help="reviewed CSV (defaults to drafts.json)")

    args = parser.parse_args()
    return {"check": cmd_check, "export": cmd_export, "import": cmd_import}[args.command](args)


if __name__ == "__main__":
    sys.exit(main())
