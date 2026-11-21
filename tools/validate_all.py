"""Run the static checker over every sample of a corpus (parallel)."""
from __future__ import annotations

import argparse
import json
import os
import sys
from collections import Counter
from concurrent.futures import ProcessPoolExecutor

sys.path.insert(0, os.path.dirname(__file__))
from check import check  # noqa: E402

SPLITS = ["malicious_pure", "powershell_benign_dataset", "mixed_malicious"]


def _one(path: str) -> tuple[str, str, list[str], int]:
    src = open(path, encoding="utf-8", errors="ignore").read()
    r = check(src)
    return path, ("ok" if r["ok"] else "bad"), r["problems"], r["chars"]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("root", nargs="?", default="/home/ubuntu/work/ai-mpsd")
    ap.add_argument("--json", default="")
    a = ap.parse_args()
    paths = []
    for s in SPLITS:
        d = os.path.join(a.root, s)
        if os.path.isdir(d):
            paths += [os.path.join(d, f) for f in sorted(os.listdir(d)) if f.endswith(".ps1")]
    print(f"checking {len(paths)} files", flush=True)
    status = Counter()
    problems = Counter()
    examples = {}
    sizes = []
    with ProcessPoolExecutor(max_workers=4) as ex:
        for path, st, probs, n in ex.map(_one, paths, chunksize=200):
            status[st] += 1
            sizes.append(n)
            for p in probs:
                key = p.split(":")[0][:60]
                problems[key] += 1
                examples.setdefault(key, path)
    print("status:", dict(status))
    print("problems:", dict(problems.most_common(10)))
    if examples:
        for k, v in list(examples.items())[:5]:
            print("  example:", k, "->", v)
    sizes.sort()
    if sizes:
        print(f"chars: min={sizes[0]} median={sizes[len(sizes)//2]} max={sizes[-1]}")
    if a.json:
        with open(a.json, "w") as fh:
            json.dump({"total": len(paths), "status": dict(status),
                       "problems": dict(problems), "examples": examples}, fh, indent=2)


if __name__ == "__main__":
    main()
