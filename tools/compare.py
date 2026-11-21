"""Compare the AI-generated corpus with the original MP-SD corpus.

Usage:  python3 tools/compare.py [--a PATH] [--b PATH]
"""
from __future__ import annotations

import argparse
import json
import os
import re
import statistics

SPLITS = ["malicious_pure", "powershell_benign_dataset", "mixed_malicious"]
MARKERS = {
    "help_block": r"<#",
    "param_block": r"(?im)^\s*param\s*\(",
    "try_catch": r"(?i)\btry\s*\{",
    "iex": r"(?i)\b(?:iex|invoke-expression)\b",
    "download": r"(?i)downloadstring|downloadfile|net\.webclient",
    "enc_b64": r"(?i)frombase64string|-enc\b|-encodedcommand",
    "addtype": r"(?i)add-type|dllimport|virtualalloc",
    "hidden": r"(?i)-w(?:indowstyle)?\s+hidden|bypass",
    "persist": r"(?i)currentversion\\run|schtasks|register-scheduledtask",
    "amsi": r"(?i)amsi",
    "ip_literal": r"\b(?:\d{1,3}\.){3}\d{1,3}\b",
}


def corpus_stats(root: str, split: str) -> dict:
    d = os.path.join(root, split)
    if not os.path.isdir(d):
        return {}
    files = [f for f in os.listdir(d) if f.endswith(".ps1")]
    sizes, lines, hits = [], [], {k: 0 for k in MARKERS}
    for f in files:
        try:
            t = open(os.path.join(d, f), encoding="utf-8", errors="ignore").read()
        except OSError:
            continue
        sizes.append(len(t))
        lines.append(t.count("\n") + 1)
        for k, rx in MARKERS.items():
            if re.search(rx, t):
                hits[k] += 1
    n = len(sizes) or 1
    return {
        "n": len(files),
        "chars_median": int(statistics.median(sizes)) if sizes else 0,
        "chars_mean": int(statistics.mean(sizes)) if sizes else 0,
        "chars_max": max(sizes) if sizes else 0,
        "lines_median": int(statistics.median(lines)) if lines else 0,
        "share": {k: round(100 * v / n, 1) for k, v in hits.items()},
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--a", default="/home/ubuntu/work/mpsd", help="original corpus")
    ap.add_argument("--b", default="/home/ubuntu/work/ai-mpsd", help="AI corpus")
    ap.add_argument("--json", default="")
    a = ap.parse_args()
    out = {"original": {}, "ai": {}}
    for split in SPLITS:
        out["original"][split] = corpus_stats(a.a, split)
        out["ai"][split] = corpus_stats(a.b, split)

    def row(split: str) -> str:
        o, g = out["original"][split], out["ai"][split]
        if not o or not g:
            return f"| {split} | missing | missing |"
        return (f"| {split} | {o['n']} / {g['n']} | {o['chars_median']} / {g['chars_median']} "
                f"| {o['lines_median']} / {g['lines_median']} | "
                f"{o['share']['help_block']}% / {g['share']['help_block']}% | "
                f"{o['share']['param_block']}% / {g['share']['param_block']}% | "
                f"{o['share']['try_catch']}% / {g['share']['try_catch']}% |")

    print("| split | files orig/AI | median chars | median lines | help<# | param | try |")
    print("|---|---|---|---|---|---|---|")
    for s in SPLITS:
        print(row(s))
    print()
    keys = ["iex", "download", "enc_b64", "addtype", "hidden", "persist", "amsi", "ip_literal"]
    print("| split | " + " | ".join(keys) + " |")
    print("|---|" + "---|" * len(keys))
    for s in SPLITS:
        o, g = out["original"][s], out["ai"][s]
        if not o or not g:
            continue
        print(f"| {s} | " + " | ".join(f"{o['share'][k]} / {g['share'][k]}" for k in keys) + " |")
    if a.json:
        with open(a.json, "w") as fh:
            json.dump(out, fh, indent=2)


if __name__ == "__main__":
    main()
