"""Static sanity checks for generated PowerShell samples (no execution)."""
from __future__ import annotations

import base64
import re
import sys

ALLOWED_HOSTS = ("example.com", "example.net", "example.org", "contoso.com",
                 "adatum.com", "internal.corp", "localhost")
ALLOWED_IP_PREFIX = ("192.0.2.", "198.51.100.", "203.0.113.", "127.0.0.1")

FORBIDDEN = [
    r"vssadmin\s+delete", r"wbadmin\s+delete", r"cipher\s+/w", r"format-volume",
    r"remove-item\s+-recurse\s+(-force\s+)?c:\\", r"rm\s+-rf\s+/",
    r"Invoke-Expression\s*\(?\s*\(New-Object\s+Net\.WebClient\)\.DownloadString\('http://(?!192\.0\.2)" ,
]

_HELP = re.compile(r"<#.*?#>", re.S)
_LINE_COMMENT = re.compile(r"(?m)^[ \t]*#[^\n]*$")
_STRIP = None


def strip_strings_comments(src: str) -> str:
    s = _LINE_COMMENT.sub("", _HELP.sub("", src))
    s = re.sub(r"@\"[\s\S]*?\"@|@'[\s\S]*?'@", "''", s)
    s = re.sub(r"\"(?:[^\"`]|`.)*\"", "''", s)
    s = re.sub(r"'(?:[^']|'')*'", "''", s)
    return s


def balanced(src: str) -> tuple[bool, str]:
    s = strip_strings_comments(src)
    stack = []
    pairs = {")": "(", "}": "{", "]": "["}
    for ch in s:
        if ch in "({[":
            stack.append(ch)
        elif ch in ")}]":
            if not stack or stack.pop() != pairs[ch]:
                return False, f"unbalanced {ch}"
    if stack:
        return False, f"unclosed {stack[-1]}"
    return True, "ok"


def hosts(src: str) -> list[str]:
    out = []
    for m in re.finditer(r"(?:https?|ftp)://([^/\s'\")]+)", src, re.I):
        out.append(m.group(1).lower())
    for m in re.finditer(r"\b(?:\d{1,3}\.){3}\d{1,3}\b", src):
        out.append(m.group(0))
    return sorted(set(out))


def check(src: str) -> dict:
    ok, why = balanced(src)
    hs = hosts(src)
    bad_hosts = [h for h in hs if not (h.startswith(ALLOWED_IP_PREFIX)
                                       or any(a in h for a in ALLOWED_HOSTS))]
    bad = [p for p in FORBIDDEN if re.search(p, src, re.I)]
    problems = []
    if not ok:
        problems.append(why)
    if bad_hosts:
        problems.append(f"non-allowlisted host(s): {bad_hosts[:3]}")
    if bad:
        problems.append(f"forbidden pattern: {bad[0]}")
    if len(src) > 4_500_000:
        problems.append("too large")
    return {"ok": not problems, "problems": problems, "chars": len(src),
            "lines": src.count("\n") + 1, "hosts": hs}


if __name__ == "__main__":
    bad = 0
    for p in sys.argv[1:]:
        src = open(p, encoding="utf-8", errors="ignore").read()
        r = check(src)
        if not r["ok"]:
            bad += 1
            print(p, r["problems"])
    print(f"checked {len(sys.argv)-1} files, {bad} problems")
