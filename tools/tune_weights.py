"""Fit family weights so the AI corpus matches the original behaviour mix.

The idea: for every family, measure P(marker present) on a sample. Then solve
a non-negative least-squares problem for weights that reproduce the marker
shares of the original MP-SD malicious corpus. Style markers (help block,
param block, try/catch) are deliberately NOT matched: they are the variable
under study.
"""
from __future__ import annotations

import json
import os
import random
import re
import sys

import numpy as np
from scipy.optimize import nnls

sys.path.insert(0, os.path.dirname(__file__))
ROOT = "/home/ubuntu/work/ai-mpsd"
ORIG = "/home/ubuntu/work/mpsd/malicious_pure"

MARKERS = {
    "iex": r"(?i)\b(?:iex|invoke-expression)\b",
    "download": r"(?i)downloadstring|downloadfile|net\.webclient",
    "enc_b64": r"(?i)frombase64string|-enc\b|-encodedcommand",
    "addtype": r"(?i)add-type|dllimport|virtualalloc",
    "hidden": r"(?i)-w(?:indowstyle)?\s+hidden|bypass",
    "persist": r"(?i)currentversion\\run|schtasks|register-scheduledtask",
    "amsi": r"(?i)amsi",
    "ip_literal": r"\b(?:\d{1,3}\.){3}\d{1,3}\b",
}
SIZE_EDGES = [(0, 600), (600, 6000), (6000, 50000), (50000, 10**9)]


def markers_of(src: str) -> list[float]:
    v = [1.0 if re.search(rx, src) else 0.0 for rx in MARKERS.values()]
    n = len(src)
    v += [1.0 if lo <= n < hi else 0.0 for lo, hi in SIZE_EDGES]
    return v


def original_target() -> np.ndarray:
    rows = []
    for f in os.listdir(ORIG):
        if f.endswith(".ps1"):
            rows.append(markers_of(open(os.path.join(ORIG, f), encoding="utf-8",
                                        errors="ignore").read()))
    return np.array(rows).mean(axis=0)


def family_probs(families, k: int = 700, seed: int = 11) -> tuple[list[str], np.ndarray]:
    names, cols = [], []
    for name, _w, fn in families:
        rng = random.Random(seed + len(names) * 101)
        rows = [markers_of(fn(rng)) for _ in range(k)]
        names.append(name)
        cols.append(np.array(rows).mean(axis=0))
    return names, np.array(cols)


def main() -> None:
    sys.path.insert(0, ROOT)
    from packs import benign_pack, malicious_pack, malicious_extra  # noqa: F401

    families = list(malicious_pack.FAMILIES) + list(malicious_extra.FAMILIES)
    t = original_target()
    names, P = family_probs(families)

    # solve  P.T w ~= t,  sum(w) = 1,  w >= 0
    lam = 3.0
    A = np.vstack([P.T, lam * np.ones((1, len(names)))])
    b = np.concatenate([t, [lam]])
    w, _res = nnls(A, b)
    w = w / w.sum()
    # keep every family reachable
    w = np.maximum(w, 0.004)
    w = w / w.sum()

    scale = 1000.0
    weights = {n: int(round(x * scale)) for n, x in zip(names, w)}
    fitted = (P.T @ w)

    labels = list(MARKERS) + [f"size_{lo}-{hi if hi < 10**9 else 'inf'}" for lo, hi in SIZE_EDGES]
    print(f"{'marker':22s} {'orig':>7s} {'fit':>7s}")
    for lab, o, f in zip(labels, t, fitted):
        print(f"{lab:22s} {o*100:6.1f}% {f*100:6.1f}%")
    print(f"\n{'family':26s} weight")
    for n, x in sorted(weights.items(), key=lambda kv: -kv[1]):
        print(f"{n:26s} {x:5d}")

    out = os.path.join(ROOT, "packs", "weights.json")
    with open(out, "w") as fh:
        json.dump(weights, fh, indent=2)
    print("\nwrote", out)


if __name__ == "__main__":
    main()
