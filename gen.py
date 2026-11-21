"""Build the AI-generated counterpart of the MP-SD PowerShell dataset.

Layout mirrors github.com/das-lab/mpsd:

    malicious_pure/            N malicious scripts
    powershell_benign_dataset/ N benign scripts
    mixed_malicious/           N malicious+benign concatenations

Family builders live in packs/ and receive a seeded ``random.Random``.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import random
import re
import statistics
import sys
import time
from collections import Counter

sys.path.insert(0, os.path.dirname(__file__))
from packs import benign_pack, malicious_pack  # noqa: E402

try:  # optional extra families (long-tail loader)
    from packs import malicious_extra  # noqa: E402
except Exception:  # pragma: no cover
    malicious_extra = None

MAL_FAMILIES = list(malicious_pack.FAMILIES)
if malicious_extra is not None:
    MAL_FAMILIES += list(malicious_extra.FAMILIES)


def apply_weights(families):
    """Override family weights from packs/weights.json when present."""
    path = os.path.join(os.path.dirname(__file__), "packs", "weights.json")
    if not os.path.exists(path):
        return families
    with open(path) as fh:
        w = json.load(fh)
    return [(name, float(w.get(name, weight)), fn) for name, weight, fn in families]


HIDDEN_RE = re.compile(r"\s+-WindowStyle\s+Hidden", re.I)
URL_HOSTS = ("example.com", "example.org", "example.net")


def _test_net(rng):
    return rng.choice(("192.0.2.%d" % rng.randint(2, 250),
                       "198.51.100.%d" % rng.randint(2, 250),
                       "203.0.113.%d" % rng.randint(2, 250)))


def calibrate(src: str, rng) -> str:
    """Light calibration documented in README.

    Template libraries over-produce ``-WindowStyle Hidden`` and mostly use
    example.* domains; the original corpus is IP-heavy and rarely passes that
    flag. Both edits preserve syntax and semantics of the sample.
    """
    if rng.random() < 0.72:
        src = HIDDEN_RE.sub("", src)
    if rng.random() < 0.65:
        for host in URL_HOSTS:
            if host in src:
                src = src.replace(host, _test_net(rng))
    return src


def pick_family(families, rng):
    total = sum(w for _, w, _ in families)
    x = rng.uniform(0, total)
    acc = 0.0
    for name, w, fn in families:
        acc += w
        if x <= acc:
            return name, fn
    return families[-1][0], families[-1][2]


def build_corpus(pack, n, rng, label):
    seen: set[str] = set()
    items: list[tuple[str, str, str]] = []  # (family, filename_stub, source)
    attempts = 0
    fam_counts: Counter = Counter()
    while len(items) < n:
        attempts += 1
        if attempts > n * 40:
            raise RuntimeError(f"{label}: cannot reach {n} unique samples")
        family, fn = pick_family(pack.FAMILIES, rng)
        try:
            src = fn(rng)
        except Exception as exc:  # a broken builder must not kill the run
            print(f"  ! builder {family} failed: {exc}", flush=True)
            continue
        if not isinstance(src, str) or len(src.strip()) < 20:
            continue
        src = calibrate(src, rng)
        h = hashlib.sha1(src.encode("utf-8", "ignore")).hexdigest()
        if h in seen:
            continue
        seen.add(h)
        fam_counts[family] += 1
        items.append((family, h, src))
    return items, fam_counts, attempts


def write_split(items, outdir, rng, prefix=""):
    os.makedirs(outdir, exist_ok=True)
    written = []
    for i, (family, h, src) in enumerate(items, 1):
        name = f"{prefix}{i}.ps1" if not prefix else f"{prefix}{i}.ps1"
        body = ("\n" if rng.random() < 0.5 else "") + src.rstrip() + "\n"
        path = os.path.join(outdir, name)
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(body)
        written.append((path, family, len(body)))
    return written


def describe(written, label):
    sizes = [w[2] for w in written]
    return {
        "label": label,
        "n": len(written),
        "chars_min": min(sizes),
        "chars_median": int(statistics.median(sizes)),
        "chars_mean": int(statistics.mean(sizes)),
        "chars_max": max(sizes),
        "families": dict(Counter(w[1] for w in written)),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="/home/ubuntu/work/ai-mpsd")
    ap.add_argument("--malicious", type=int, default=4202)
    ap.add_argument("--benign", type=int, default=4316)
    ap.add_argument("--mixed", type=int, default=4202)
    ap.add_argument("--seed", type=int, default=20261121)
    a = ap.parse_args()

    rng = random.Random(a.seed)
    t0 = time.time()

    print("building malicious corpus ...", flush=True)
    mal_pack = type("P", (), {"FAMILIES": apply_weights(MAL_FAMILIES)})
    mal, mal_fam, mal_att = build_corpus(mal_pack, a.malicious, rng, "malicious")
    print(f"  {len(mal)} unique in {mal_att} attempts", flush=True)

    print("building benign corpus ...", flush=True)
    ben_pack = type("P", (), {"FAMILIES": apply_weights(list(benign_pack.FAMILIES))})
    ben, ben_fam, ben_att = build_corpus(ben_pack, a.benign, rng, "benign")
    print(f"  {len(ben)} unique in {ben_att} attempts", flush=True)

    wm = write_split(mal, os.path.join(a.out, "malicious_pure"), rng)
    wb = write_split(ben, os.path.join(a.out, "powershell_benign_dataset"), rng)

    # mixed: one malicious + one benign, concatenated (benign first ~half the time)
    rng.shuffle(mal)
    rng.shuffle(ben)
    mixed_items = []
    for i in range(a.mixed):
        m_fam, _, m_src = mal[i % len(mal)]
        b_fam, _, b_src = ben[(i * 7 + 3) % len(ben)]
        parts = [b_src.rstrip(), m_src.rstrip()]
        if i % 2:
            parts.reverse()
        src = "\n".join(parts)
        mixed_items.append((f"{b_fam}+{m_fam}", hashlib.sha1(src.encode()).hexdigest(), src))
    wmix = write_split(mixed_items, os.path.join(a.out, "mixed_malicious"), rng,
                       prefix="")  # names fixed below
    # dataset uses "<benign>_<malicious>.ps1" names; rename to that shape
    for i, (path, _, _) in enumerate(wmix, 0):
        m_id = (i % len(mal)) + 1
        b_id = (i * 7 + 3) % len(ben) + 1
        new = os.path.join(os.path.dirname(path), f"{1000 + i}_{b_id}.ps1")
        os.replace(path, new)
    mixed_sizes = [os.path.getsize(os.path.join(a.out, "mixed_malicious", f))
                   for f in os.listdir(os.path.join(a.out, "mixed_malicious"))]

    stats = {
        "seed": a.seed,
        "generated_in_s": round(time.time() - t0, 1),
        "malicious_pure": describe(wm, "malicious_pure"),
        "powershell_benign_dataset": describe(wb, "powershell_benign_dataset"),
        "mixed_malicious": {
            "label": "mixed_malicious",
            "n": len(mixed_sizes),
            "chars_min": min(mixed_sizes),
            "chars_median": int(statistics.median(mixed_sizes)),
            "chars_mean": int(statistics.mean(mixed_sizes)),
            "chars_max": max(mixed_sizes),
        },
    }
    with open(os.path.join(a.out, "dataset_stats.json"), "w") as fh:
        json.dump(stats, fh, indent=2)
    print(json.dumps(stats, indent=2)[:2500], flush=True)
    print(f"done in {time.time()-t0:.1f}s -> {a.out}", flush=True)


if __name__ == "__main__":
    main()
