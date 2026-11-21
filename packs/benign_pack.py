"""Benign PowerShell source templates for the MP-SD style corpus.

Every public builder takes a seeded ``random.Random`` and returns one complete
``.ps1`` script body as ``str``.  The module is side-effect free: it never uses
the global ``random`` module, the clock, the filesystem or the network.

Scripts are administrator / DevOps flavoured (AD audits, backups, log parsing,
reports, Pester specs, modules, installers, WinForms helpers, maintenance),
which makes them the negative class for a PowerShell malware detector.
"""

import random
import textwrap

# ---------------------------------------------------------------------------
# shared vocabulary
# ---------------------------------------------------------------------------

_DOMAINS = ["contoso.com", "adatum.com", "internal.corp"]
_SERVERS = ["srv01", "srv02", "web-prod-03", "app-prod-01", "dc01", "dc02",
            "filesrv01", "sql-prod-02", "web-stg-01", "mgmt01"]
_AUTHORS = ["Platform Engineering", "Infra Automation", "J. Weber",
            "M. Rahman", "Ops Team", "Server Operations", "IT Systems"]
_ENVS = ["Dev", "Test", "Staging", "Prod"]
_LEVELS = ["Information", "Warning", "Verbose"]

# ---------------------------------------------------------------------------
# small helpers
# ---------------------------------------------------------------------------


def _pick(rng, seq):
    return seq[rng.randrange(len(seq))]


def _chance(rng, p):
    return rng.random() < p


def _int(rng, lo, hi):
    return rng.randint(lo, hi)


def _date(rng):
    return "%04d-%02d-%02d" % (rng.choice([2024, 2025, 2026]),
                               rng.randint(1, 12), rng.randint(1, 28))


def _stamp(rng):
    return "%04d%02d%02d-%02d%02d%02d" % (rng.choice([2024, 2025, 2026]),
                                          rng.randint(1, 12), rng.randint(1, 28),
                                          rng.randint(0, 23), rng.randint(0, 59),
                                          rng.randint(0, 59))


def _clock(rng):
    return "%02d:%02d" % (rng.randint(0, 23), rng.choice([0, 15, 30, 45]))


def _q(rng, text):
    """PowerShell string literal; double quotes only for expansion-free text."""
    if '"' not in text and "$" not in text and "`" not in text and _chance(rng, 0.45):
        return '"' + text + '"'
    return "'" + text.replace("'", "''") + "'"


def _sec(rng, *blocks):
    """Join blocks with a blank line, dropping empty ones."""
    out = []
    for block in blocks:
        if not block:
            continue
        if out and _chance(rng, 0.85):
            out.append("")
        out.extend(block)
    return out


def _tier(rng):
    x = rng.random()
    if x < 0.10:
        return "short"
    if x < 0.70:
        return "medium"
    return "long"


def _render(lines):
    while lines and lines[-1] == "":
        lines.pop()
    while lines and lines[0] == "":
        lines.pop(0)
    return "\n".join(lines) + "\n"


def _mk(name, typ, default=None, attrs=None):
    return {"name": name, "type": typ, "default": default, "attrs": list(attrs or [])}


def _attrs(rng, kind="plain", vrange=None, validate=None, alias=None):
    out = []
    if kind == "mandatory":
        out.append("[Parameter(Mandatory = $true)]")
    elif kind == "pipeline":
        out.append("[Parameter(ValueFromPipeline = $true)]")
    elif kind == "help":
        out.append("[Parameter(HelpMessage = " + _q(
            rng, "Optional. The default value is used when the parameter is omitted.") + ")]")
    elif kind == "optional" or _chance(rng, 0.22):
        out.append("[Parameter(Mandatory = $false)]")
    if vrange:
        out.append("[ValidateRange(%d, %d)]" % vrange)
    if validate:
        out.append("[ValidateSet(" + ", ".join(_q(rng, v) for v in validate) + ")]")
    if alias:
        out.append("[Alias(" + _q(rng, alias) + ")]")
    return out


def _param_decls(rng, specs, indent=4, trailing_comma=True):
    pad = " " * indent
    out = []
    for i, spec in enumerate(specs):
        out.extend([pad + a for a in spec.get("attrs", [])])
        line = "%s[%s]$%s" % (pad, spec["type"], spec["name"])
        if spec.get("default") is not None:
            line += " = " + spec["default"]
        if trailing_comma and i < len(specs) - 1:
            line += ","
        out.append(line)
        if trailing_comma and i < len(specs) - 1 and _chance(rng, 0.4):
            out.append("")
    return out


def _param_block(rng, settings):
    out = []
    if _chance(rng, 0.85):
        out.append("[CmdletBinding()]")
    out.append("param(")
    out.extend(_param_decls(rng, settings))
    out.append(")")
    return out


def _config_block(rng, settings):
    if not settings:
        return []
    width = max(len(s["name"]) for s in settings)
    align = _chance(rng, 0.5)
    out = []
    for spec in settings:
        pad = " " * (width - len(spec["name"])) if align else ""
        rhs = spec["default"]
        if rhs is None:
            rhs = "$false" if spec["type"] == "switch" else "$null"
        out.append("$" + spec["name"] + pad + " = " + rhs)
    return out


def _help_block(rng, synopsis, description, examples, settings):
    out = ["<#"]
    out.append(".SYNOPSIS")
    out.append("    " + synopsis)
    if _chance(rng, 0.8):
        out.append(".DESCRIPTION")
        for para in description:
            for ln in textwrap.wrap(para, width=76):
                out.append("    " + ln)
    if settings and _chance(rng, 0.55):
        for spec in settings[:_int(rng, 1, min(2, len(settings)))]:
            out.append(".PARAMETER " + spec["name"])
            out.append("    " + _pick(rng, [
                "Overrides the default value defined in the parameter block.",
                "Used when the script runs unattended.",
                "Paths are resolved relative to the invoking session.",
                "Defaults to the value configured for this host.",
            ]))
    if examples and _chance(rng, 0.7):
        for ex in examples[:_int(rng, 1, min(2, len(examples)))]:
            out.append(".EXAMPLE")
            out.append("    " + ex)
    if _chance(rng, 0.5):
        out.append(".NOTES")
        out.append("    Author: " + _pick(rng, _AUTHORS))
        out.append("    Last updated: " + _date(rng))
    out.append("#>")
    return out


def _preamble(rng, synopsis, description, examples, settings,
              compact=False, help_p=0.50, param_p=0.72, requires_p=0.20):
    out = []
    if _chance(rng, requires_p):
        out.append("#Requires -Version 5.1")
    if not compact and _chance(rng, help_p):
        out.extend(_help_block(rng, synopsis, description, examples, settings))
        out.append("")
    has_param = bool(settings) and (not compact) and _chance(rng, param_p)
    if has_param:
        out.extend(_param_block(rng, settings))
        if _chance(rng, 0.8):
            out.append("")
    if _chance(rng, 0.30):
        out.append("$ErrorActionPreference = " + _q(rng, "Stop"))
        if _chance(rng, 0.5):
            out.append("")
    if not has_param:
        out.extend(_config_block(rng, settings))
        if _chance(rng, 0.7):
            out.append("")
    return out, has_param


_EXTRAS = [
    "$ProgressPreference = 'SilentlyContinue'",
    "$WarningPreference = 'Continue'",
    "$DebugPreference = 'SilentlyContinue'",
    "$InformationPreference = 'SilentlyContinue'",
    "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8",
    "$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'",
    "$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'",
    "$hostName = $env:COMPUTERNAME",
    "$culture = [System.Globalization.CultureInfo]::InvariantCulture",
    "$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path",
    "Set-StrictMode -Version 2.0",
]


def _extras(rng):
    k = _int(rng, 0, 3)
    if k == 0:
        return []
    return rng.sample(_EXTRAS, k)


# ---------------------------------------------------------------------------
# reusable PowerShell fragments
# ---------------------------------------------------------------------------


def _module_check(rng, module, message):
    if _chance(rng, 0.55):
        return ["if (-not (Get-Module -ListAvailable -Name %s)) {" % module,
                "    throw %s" % _q(rng, message),
                "}",
                "Import-Module %s -ErrorAction Stop" % module]
    return ["Import-Module %s -ErrorAction Stop" % module]


def _csv_export(rng, src, path_expr, indent=0, encoding=True):
    pad = "    " * indent
    args = ["-Path " + path_expr, "-NoTypeInformation"]
    if _chance(rng, 0.5):
        args = ["-NoTypeInformation", "-Path " + path_expr]
    if encoding and _chance(rng, 0.65):
        args.append("-Encoding UTF8")
    if _chance(rng, 0.35):
        out = [pad + src + " |"]
        for i, arg in enumerate(args):
            out.append(pad + "    " + arg + (" `" if i < len(args) - 1 else ""))
        return out
    return [pad + src + " | Export-Csv " + " ".join(args)]


def _html_style(rng):
    color = _pick(rng, ["#f4f4f4", "#eeeeee", "#e8eef7", "#f0f0f0"])
    font = _pick(rng, ["Segoe UI", "Arial", "Calibri", "Tahoma"])
    size = _pick(rng, ["11px", "12px", "13px"])
    return ["$style = @'",
            "<style>",
            "body { font-family: " + font + "; font-size: " + size + "; }",
            "table { border-collapse: collapse; width: 100%; }",
            "th { background: " + color + "; text-align: left; padding: 4px; }",
            "td { border-bottom: 1px solid #dddddd; padding: 4px; }",
            "</style>",
            "'@"]


def _mail_block(rng, to, frm, smtp, subject_expr, body_expr, port, indent=0):
    pad = "    " * indent
    if _chance(rng, 0.45):
        return [pad + "$mailParams = @{",
                pad + "    To         = " + to,
                pad + "    From       = " + frm,
                pad + "    Subject    = " + subject_expr,
                pad + "    Body       = " + body_expr,
                pad + "    SmtpServer = " + smtp,
                pad + "    Port       = " + str(port),
                pad + "    UseSsl     = $true",
                pad + "}",
                pad + "Send-MailMessage @mailParams"]
    args = ["-To " + to, "-From " + frm, "-Subject " + subject_expr,
            "-Body " + body_expr, "-SmtpServer " + smtp, "-Port " + str(port)]
    if _chance(rng, 0.6):
        args.append("-UseSsl")
    if _chance(rng, 0.4):
        out = [pad + "Send-MailMessage `"]
        for i, arg in enumerate(args):
            out.append(pad + "    " + arg + (" `" if i < len(args) - 1 else ""))
        return out
    if _chance(rng, 0.45):
        split = 3
        return [pad + "Send-MailMessage " + " ".join(args[:split]) + " `",
                pad + "    " + " ".join(args[split:])]
    return [pad + "Send-MailMessage " + " ".join(args)]


def _log_function(rng, name, log_var="$LogPath"):
    return ["function %s {" % name,
            "    param(",
            "        [Parameter(Mandatory = $true)]",
            "        [string]$Message,",
            "",
            "        [ValidateSet('INFO', 'WARN', 'ERROR')]",
            "        [string]$Level = 'INFO'",
            "    )",
            "",
            "    $line = \"{0} [{1}] {2}\" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message",
            "    Add-Content -Path " + log_var + " -Value $line -Encoding UTF8",
            "    if ($Level -eq 'ERROR') {",
            "        Write-Host $line -ForegroundColor Red",
            "    }",
            "}"]


def _generic_tail(rng):
    """Self-contained trailing blocks (no script variables) used for padding."""
    return [
        ["$psVersion = $PSVersionTable.PSVersion",
         "Write-Verbose (\"PowerShell {0}.{1} on {2}\" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)",
         "Write-Verbose (\"Completed at {0}\" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))"],
        ["$sessionLog = Join-Path $env:TEMP (\"session-\" + (Get-Date -Format 'yyyyMMdd') + \".log\")",
         "Add-Content -Path $sessionLog -Value (\"Run finished {0}\" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8"],
        ["$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)",
         "if (-not $isElevated) {",
         "    Write-Warning 'Some checks require an elevated session.'",
         "}"],
        ["$staleTemp = Get-ChildItem -Path $env:TEMP -Filter 'w3c-*' -Directory -ErrorAction SilentlyContinue |",
         "    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }",
         "foreach ($dir in $staleTemp) {",
         "    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue",
         "}"],
        ["$runningAsService = $env:SESSIONNAME -eq 'Services'",
         "Write-Verbose (\"Interactive session: {0}\" -f (-not $runningAsService))",
         "Write-Verbose (\"Temp folder: {0}\" -f [System.IO.Path]::GetTempPath())"],
        ["$culture = [System.Globalization.CultureInfo]::CurrentCulture",
         "Write-Verbose (\"Culture: {0}\" -f $culture.Name)",
         "Write-Verbose (\"Machine: {0}\" -f $env:COMPUTERNAME)"],
        ["$osVersion = [System.Environment]::OSVersion.VersionString",
         "Write-Verbose (\"Operating system: {0}\" -f $osVersion)",
         "Write-Verbose (\"User: {0}\" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"],
        ["$logFolder = Join-Path $env:TEMP 'ops-logs'",
         "if (-not (Test-Path -LiteralPath $logFolder)) {",
         "    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null",
         "}",
         "Write-Verbose (\"Log folder: {0}\" -f $logFolder)"],
        ["$elapsed = (Get-Date) - (Get-Date).Date",
         "Write-Verbose (\"Time since midnight: {0:N1} hours\" -f $elapsed.TotalHours)"],
        ["$powerShellHome = $PSHOME",
         "Write-Verbose (\"PowerShell home: {0}\" -f $powerShellHome)"],
    ]


def _pad(rng, lines, lo, blocks, hi=330):
    pool = list(blocks)
    rng.shuffle(pool)
    pool.extend(_generic_tail(rng))
    for block in pool:
        if len(lines) >= lo:
            break
        if len(lines) + len(block) + 2 > hi:
            continue
        lines.append("")
        lines.extend(block)
    return lines


def _json_export(rng, src, path_expr, indent=0):
    pad = "    " * indent
    depth = _int(rng, 3, 6)
    if _chance(rng, 0.5):
        return [pad + src + " | ConvertTo-Json -Depth %d | Set-Content -Path %s -Encoding UTF8"
                % (depth, path_expr)]
    return [pad + "$jsonBody = " + src + " | ConvertTo-Json -Depth %d" % depth,
            pad + "$jsonBody | Set-Content -Path " + path_expr + " -Encoding UTF8"]


# ---------------------------------------------------------------------------
# 1. Active Directory user / mailbox audit
# ---------------------------------------------------------------------------


def _ad_ctx(rng):
    domain = _pick(rng, _DOMAINS)
    dc = "DC=" + domain.replace(".", ",DC=")
    root = _pick(rng, ["C:\\Reports", "C:\\Logs\\reports", "D:\\Ops\\reports"])
    date = _date(rng)
    return {
        "Domain": domain,
        "SearchBase": "OU=%s,%s" % (_pick(rng, ["Staff", "Employees", "Users",
                                               "Contractors", "Managed Users"]), dc),
        "ReportPath": root + "\\ad-user-audit-" + date + ".csv",
        "HtmlPath": root + "\\ad-user-audit-" + date + ".html",
        "InactiveDays": _pick(rng, [30, 45, 60, 90, 120, 180]),
        "PasswordAge": _pick(rng, [60, 90, 120, 180, 365]),
        "SmtpServer": "smtp." + domain,
        "MailTo": "it-ops@" + domain,
        "MailFrom": "reporting@" + domain,
        "LogPath": "C:\\Logs\\ad-audit-" + date + ".log",
        "Script": _pick(rng, ["Get-ADUserAudit.ps1", "Invoke-ADUserAudit.ps1",
                              "Get-StaleADUser.ps1", "Export-ADUserReport.ps1"]),
        "Title": "AD user audit",
    }


def _ad_settings(rng, c):
    return [
        _mk("Domain", "string", _q(rng, c["Domain"]), _attrs(rng, "help", alias="DnsDomain")),
        _mk("SearchBase", "string", _q(rng, c["SearchBase"])),
        _mk("ReportPath", "string", _q(rng, c["ReportPath"])),
        _mk("HtmlPath", "string", _q(rng, c["HtmlPath"])),
        _mk("InactiveDays", "int", str(c["InactiveDays"]), _attrs(rng, "optional", vrange=(1, 365))),
        _mk("PasswordMaxAge", "int", str(c["PasswordAge"])),
        _mk("SmtpServer", "string", _q(rng, c["SmtpServer"])),
    ]


def _ad_query(rng):
    return ["$cutoff = (Get-Date).AddDays(-$InactiveDays)",
            "$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')",
            "$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties $properties"]


def _ad_stale(rng):
    return ["$stale = $users | Where-Object {",
            "    $_.Enabled -eq $true -and $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $cutoff",
            "}"]


def _ad_old_passwords(rng):
    return ["$pwdCutoff = (Get-Date).AddDays(-$PasswordMaxAge)",
            "$oldPasswords = $users | Where-Object {",
            "    $_.PasswordLastSet -ne $null -and $_.PasswordLastSet -lt $pwdCutoff",
            "}"]


def _ad_counts(rng):
    return ["$staleCount = @($stale).Count",
            "$disabledCount = @($users | Where-Object { $_.Enabled -eq $false }).Count",
            "$oldPwdCount = @($oldPasswords).Count"]


def _ad_mail_vars(rng):
    return ["$MailTo = \"it-ops@$Domain\"",
            "$MailFrom = \"reporting@$Domain\""]


def _ad_group_audit(rng):
    return ["$groupReport = foreach ($user in @($users | Select-Object -First 50)) {",
            "    $groups = Get-ADPrincipalGroupMembership -Identity $user.SamAccountName -ErrorAction SilentlyContinue |",
            "        Where-Object { $_.Name -ne 'Domain Users' }",
            "    [pscustomobject]@{",
            "        SamAccountName = $user.SamAccountName",
            "        GroupCount     = @($groups).Count",
            "        Groups         = (@($groups | Select-Object -ExpandProperty Name) -join '; ')",
            "    }",
            "}"]


def _ad_mail_report(rng, c, subject, body):
    out = list(_ad_mail_vars(rng))
    out.append("")
    out += _mail_block(rng, "$MailTo", "$MailFrom", "$SmtpServer", subject, body,
                       _pick(rng, [25, 587, 2525]))
    return out


def build_ad_user_audit(rng: random.Random) -> str:
    tier = _tier(rng)
    c = _ad_ctx(rng)
    settings = _ad_settings(rng, c)
    compact = tier == "short"
    pre, _ = _preamble(
        rng,
        synopsis="Audits Active Directory user accounts for stale sign-ins and password age.",
        description=[
            "Queries the configured search base, flags accounts whose last logon is "
            "older than the inactivity threshold and exports the result set to CSV.",
            "The script is read-only. It never modifies directory objects and can be "
            "scheduled on a management host with the RSAT tools installed.",
        ],
        examples=[".\\" + c["Script"] + " -InactiveDays %d" % c["InactiveDays"],
                  ".\\" + c["Script"] + " -SearchBase " + c["SearchBase"] + " -Verbose"],
        settings=([s for s in settings
                   if s["name"] in ("Domain", "SearchBase", "ReportPath", "InactiveDays")]
                  if compact else settings),
        compact=compact,
    )
    lines = list(pre)
    if tier != "short":
        lines.extend(_extras(rng))
    lines = _sec(rng, lines, ["Import-Module ActiveDirectory -ErrorAction Stop"])

    if tier == "short":
        lines = _sec(rng, lines, _ad_query(rng), _ad_stale(rng),
                     _csv_export(rng, "$stale | Select-Object Name, SamAccountName, LastLogonDate",
                                 "$ReportPath"),
                     ["Write-Host (\"Stale accounts: {0}\" -f @($stale).Count) -ForegroundColor Yellow"])
        return _render(lines)

    body = _sec(rng, lines,
                _module_check(rng, "ActiveDirectory",
                              "The ActiveDirectory module is not installed on this host."),
                _ad_query(rng),
                _ad_stale(rng),
                _ad_old_passwords(rng))

    if tier == "medium":
        body = _sec(rng, body, _ad_counts(rng),
                    _csv_export(rng, "$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet", "$ReportPath"),
                    _csv_export(rng, "$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet", "$ReportPath.Replace('.csv', '-passwords.csv')"),
                    ["Write-Host (\"Stale: {0} | Disabled: {1} | Old passwords: {2}\" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan",
                     "Write-Verbose (\"Report written to {0}\" -f $ReportPath)"])
        if _chance(rng, 0.45):
            body = _sec(rng, body, _ad_mail_report(
                rng, c, _q(rng, "AD user audit: stale accounts"),
                _q(rng, "Stale accounts were found. See the attached report.")))
        body = _pad(rng, body, 46, [])
        return _render(body)

    # long tier: helpers, per-OU sweep, group audit, html, mail, padding
    log_name = _pick(rng, ["Write-AuditLog", "Write-LogEntry", "Write-AuditTrail"])
    helper = _log_function(rng, log_name, "$LogPath")
    sweep = ["$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')",
             "$searchBases = @(",
             "    %s" % _q(rng, c["SearchBase"]),
             "    %s" % _q(rng, "OU=ServiceAccounts,DC=" + c["Domain"].replace(".", ",DC=")),
             ")",
             "",
             "$users = foreach ($base in $searchBases) {",
             "    Write-Verbose (\"Querying {0}\" -f $base)",
             "    Get-ADUser -Filter * -SearchBase $base -Properties $properties -ErrorAction Continue",
             "}"]
    body = _sec(rng, lines, ["$LogPath = %s" % _q(rng, c["LogPath"])], helper, _module_check(
        rng, "ActiveDirectory", "The ActiveDirectory module is not installed on this host."))
    body = _sec(rng, body, sweep,
                ["$cutoff = (Get-Date).AddDays(-$InactiveDays)"], _ad_stale(rng),
                _ad_old_passwords(rng), _ad_counts(rng))
    body = _sec(rng, body, _ad_group_audit(rng))
    body = _sec(rng, body,
                ["$groupReport | Export-Csv -Path %s -NoTypeInformation -Encoding UTF8"
                 % _q(rng, c["ReportPath"].replace(".csv", "-groups.csv"))],
                _csv_export(rng, "$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet, Enabled", "$ReportPath"),
                _csv_export(rng, "$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet", "$ReportPath.Replace('.csv', '-passwords.csv')"))
    body = _sec(rng, body,
                ["$disabled = $users | Where-Object { $_.Enabled -eq $false }",
                 "$disabled | Select-Object Name, SamAccountName, DistinguishedName |",
                 "    Export-Csv -Path $ReportPath.Replace('.csv', '-disabled.csv') -NoTypeInformation -Encoding UTF8"])
    body = _sec(rng, body, _html_style(rng),
                ["$stale |",
                 "    Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet |",
                 "    ConvertTo-Html -Title 'Stale AD accounts' -Head $style |",
                 "    Set-Content -Path $HtmlPath -Encoding UTF8"])
    body = _sec(rng, body,
                ["$summaryBody = @\"",
                 "Stale accounts : $staleCount",
                 "Disabled       : $disabledCount",
                 "Old passwords  : $oldPwdCount",
                 "Report         : $ReportPath",
                 "\"@"],
                _ad_mail_report(rng, c, _q(rng, "AD user audit: daily summary"),
                                "$summaryBody"))
    body = _sec(rng, body,
                ["Write-Host (\"AD audit finished: {0} stale, {1} disabled\" -f $staleCount, $disabledCount) -ForegroundColor Green",
                 log_name + " -Message (\"Audit completed for {0}\" -f $Domain) -Level INFO"])

    pad_blocks = [
        ["$transcript = Join-Path $env:TEMP (\"ad-audit-\" + (Get-Date -Format 'yyyyMMdd-HHmmss') + \".log\")",
         "Start-Transcript -Path $transcript -Append | Out-Null",
         "Write-Verbose (\"Transcript: {0}\" -f $transcript)"],
        ["$engine = Get-ADRootDSE -ErrorAction SilentlyContinue",
         "if ($engine) {",
         "    Write-Verbose (\"Domain controller: {0}\" -f $engine.dnsHostName)",
         "    Write-Verbose (\"Default naming context: {0}\" -f $engine.defaultNamingContext)",
         "}"],
        ["$neverLoggedOn = $users | Where-Object { $_.LastLogonDate -eq $null }",
         "if (@($neverLoggedOn).Count -gt 0) {",
         "    Write-Warning (\"{0} accounts have never signed in\" -f @($neverLoggedOn).Count)",
         "}"],
        ["$expiringSoon = $users | Where-Object {",
         "    $_.PasswordLastSet -ne $null -and $_.PasswordLastSet -lt (Get-Date).AddDays(-($PasswordMaxAge - 14))",
         "}",
         "Write-Verbose (\"Password changes due: {0}\" -f @($expiringSoon).Count)"],
        ["$byOu = $users | Group-Object -Property DistinguishedName |",
         "    Sort-Object -Property Count -Descending | Select-Object -First 5",
         "$byOu | Format-Table -AutoSize | Out-String | Write-Verbose"],
        ["$reportItem = Get-Item -LiteralPath $ReportPath -ErrorAction SilentlyContinue",
         "if ($reportItem) {",
         "    Write-Host (\"Report size: {0:N1} KB\" -f ($reportItem.Length / 1KB)) -ForegroundColor Gray",
         "}"],
        ["$ous = Get-ADOrganizationalUnit -Filter * -ErrorAction SilentlyContinue |",
         "    Select-Object -First 5 -Property Name, DistinguishedName",
         "$ous | Format-Table -AutoSize"],
        ["$sampleStale = $stale | Sort-Object -Property LastLogonDate | Select-Object -First 10",
         "$sampleStale | Format-Table Name, SamAccountName, LastLogonDate -AutoSize"],
        ["$pwdPolicy = Get-ADDefaultDomainPasswordPolicy -ErrorAction SilentlyContinue",
         "if ($pwdPolicy) {",
         "    Write-Verbose (\"Domain password age: {0} days\" -f $pwdPolicy.MaxPasswordAge.Days)",
         "}"],
    ]
    body = _pad(rng, body, 165, pad_blocks)
    return _render(body)


# ---------------------------------------------------------------------------
# 2. Backup with retention
# ---------------------------------------------------------------------------


def _backup_ctx(rng):
    app = _pick(rng, ["Contoso.Portal", "Adatum.Reporting", "Infra.Agent", "Contoso.Billing"])
    drive = _pick(rng, ["D", "E"])
    root = drive + ":\\Backups\\" + app.split(".")[-1]
    date = _date(rng)
    domain = _pick(rng, _DOMAINS)
    return {
        "App": app,
        "SourcePath": _pick(rng, ["D:\\Apps\\" + app, "C:\\Apps\\" + app,
                                  "E:\\Services\\" + app]),
        "BackupRoot": root,
        "RetentionDays": _pick(rng, [7, 14, 21, 30, 60]),
        "Compression": _pick(rng, ["Optimal", "Fastest", "NoCompression"]),
        "MinFreeGB": _pick(rng, [10, 20, 25, 50]),
        "LogPath": "C:\\Logs\\backup-" + app.split(".")[-1].lower() + "-" + date + ".log",
        "SmtpServer": "smtp." + domain,
        "MailTo": "backup-ops@" + domain,
        "MailFrom": "backup@" + domain,
        "Script": _pick(rng, ["Invoke-PortalBackup.ps1", "Start-AppBackup.ps1",
                              "Backup-Application.ps1"]),
    }


def _backup_settings(rng, c):
    return [
        _mk("SourcePath", "string", _q(rng, c["SourcePath"])),
        _mk("BackupRoot", "string", _q(rng, c["BackupRoot"]), _attrs(rng, "help")),
        _mk("RetentionDays", "int", str(c["RetentionDays"]), _attrs(rng, "optional", vrange=(1, 365))),
        _mk("CompressionLevel", "string", _q(rng, c["Compression"]),
            _attrs(rng, "plain", validate=["Optimal", "Fastest", "NoCompression"])),
        _mk("MinFreeGB", "int", str(c["MinFreeGB"])),
        _mk("DryRun", "switch", None),
    ]


def _backup_create(rng):
    return ["$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'",
            "$archive = Join-Path -Path $BackupRoot -ChildPath (\"%s-\" + $stamp + \".zip\")" % "backup",
            "New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null",
            "Compress-Archive -Path (Join-Path $SourcePath '*') -DestinationPath $archive -CompressionLevel $CompressionLevel -Force"]


def _backup_manifest(rng):
    return ["$item = Get-Item -LiteralPath $archive",
            "$hash = Get-FileHash -LiteralPath $archive -Algorithm SHA256",
            "$manifest = [pscustomobject]@{",
            "    Archive   = $archive",
            "    SizeMB    = [math]::Round($item.Length / 1MB, 2)",
            "    SHA256    = $hash.Hash",
            "    CreatedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')",
            "    Source    = $SourcePath",
            "}"]


def _backup_retention(rng):
    return ["$cutoff = (Get-Date).AddDays(-$RetentionDays)",
            "$expired = Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |",
            "    Where-Object { $_.LastWriteTime -lt $cutoff }",
            "foreach ($zip in $expired) {",
            "    Write-Host (\"Expired: {0}\" -f $zip.Name)",
            "    if ($DryRun) {",
            "        Write-Host (\"Would remove {0}\" -f $zip.FullName)",
            "        continue",
            "    }",
            "    Remove-Item -LiteralPath $zip.FullName -Force",
            "}"]


def _backup_disk(rng):
    return ["$driveLetter = $BackupRoot.Substring(0, 1)",
            "$drive = Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue",
            "if ($drive) {",
            "    $freeGB = [math]::Round($drive.Free / 1GB, 1)",
            "    if ($freeGB -lt $MinFreeGB) {",
            "        Write-Warning (\"Low free space on backup volume: {0} GB\" -f $freeGB)",
            "    }",
            "}"]


def _backup_verify(rng):
    return ["$probe = Join-Path $env:TEMP (\"restore-check-\" + $stamp)",
            "Expand-Archive -LiteralPath $archive -DestinationPath $probe -Force",
            "$restored = @(Get-ChildItem -Path $probe -Recurse -File).Count",
            "Write-Host (\"Restore check: {0} files recovered\" -f $restored)",
            "$staleProbes = Get-ChildItem -Path $env:TEMP -Filter 'restore-check-*' -Directory -ErrorAction SilentlyContinue |",
            "    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-2) }",
            "foreach ($dir in $staleProbes) {",
            "    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue",
            "}"]


def build_backup_retention(rng: random.Random) -> str:
    tier = _tier(rng)
    c = _backup_ctx(rng)
    settings = _backup_settings(rng, c)
    compact = tier == "short"
    pre, _ = _preamble(
        rng,
        synopsis="Creates a compressed backup of an application folder and prunes old archives.",
        description=[
            "Builds a timestamped zip archive, verifies its SHA256 hash and applies a "
            "retention window to the archive folder.",
            "Only files below the configured backup root are pruned, so a mistyped "
            "retention value cannot reach outside the archive directory.",
        ],
        examples=[".\\" + c["Script"] + " -RetentionDays %d" % c["RetentionDays"],
                  ".\\" + c["Script"] + " -BackupRoot " + c["BackupRoot"] + " -DryRun"],
        settings=settings,
        compact=compact,
    )
    lines = list(pre)
    if tier != "short":
        lines.extend(_extras(rng))
    slug = c["App"].split(".")[-1].lower()
    lines = _sec(rng, lines, ["New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null"])

    if tier == "short":
        lines = _sec(rng, lines,
                     ["$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'",
                      "$archive = Join-Path $BackupRoot (\"%s-\" + $stamp + \".zip\")" % slug,
                      "Compress-Archive -Path (Join-Path $SourcePath '*') -DestinationPath $archive -CompressionLevel $CompressionLevel",
                      "$cutoff = (Get-Date).AddDays(-$RetentionDays)",
                      "Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |",
                      "    Where-Object { $_.LastWriteTime -lt $cutoff } |",
                      "    Remove-Item -Force -WhatIf:$DryRun",
                      "Write-Host (\"Backup written to {0}\" -f $archive) -ForegroundColor Green"])
        return _render(lines)

    body = _sec(rng, lines, _backup_create(rng), _backup_manifest(rng),
                _json_export(rng, "$manifest", "(Join-Path $BackupRoot 'last-backup.json')"))

    if tier == "medium":
        body = _sec(rng, body, _backup_retention(rng), _backup_disk(rng),
                    ["Write-Host (\"Backup complete: {0:N2} MB\" -f $item.Length / 1MB) -ForegroundColor Green",
                     "$manifest | Format-List"])
        if _chance(rng, 0.4):
            body = _sec(rng, body,
                        ["$MailTo = %s" % _q(rng, c["MailTo"]),
                         "$MailFrom = %s" % _q(rng, c["MailFrom"]),
                         "$mailBody = (\"Archive: {0} ({1} MB)\" -f $archive, $manifest.SizeMB)"],
                        _mail_block(rng, "$MailTo", "$MailFrom", _q(rng, c["SmtpServer"]),
                                    _q(rng, "Backup completed"), "$mailBody", 25))
        body = _pad(rng, body, 48, [])
        return _render(body)

    body = _sec(rng, body, _backup_verify(rng), _backup_retention(rng), _backup_disk(rng))
    body = _sec(rng, body,
                ["$stage = Join-Path $env:TEMP (\"backup-stage-\" + $stamp)",
                 "robocopy $SourcePath $stage /E /R:1 /W:2 /NP /NFL /NDL | Out-Null",
                 "if ($LASTEXITCODE -ge 8) {",
                 "    throw (\"Staging copy failed with exit code {0}\" -f $LASTEXITCODE)",
                 "}",
                 "$stageCount = @(Get-ChildItem -Path $stage -Recurse -File).Count",
                 "Write-Verbose (\"Staged files: {0}\" -f $stageCount)"])
    body = _sec(rng, body,
                ["$count = @(Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File).Count",
                 "$totalGB = [math]::Round((@(Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |",
                 "    Measure-Object -Property Length -Sum).Sum) / 1GB, 2)",
                 "Write-Verbose (\"Archive count: {0}, total size: {1} GB\" -f $count, $totalGB)",
                 "$manifest | Export-Csv -Path (Join-Path $BackupRoot 'backup-history.csv') -NoTypeInformation -Append -Encoding UTF8"])
    body = _sec(rng, body, _html_style(rng),
                ["@($manifest) | ConvertTo-Html -Title 'Backup summary' -Head $style |",
                 "    Set-Content -Path (Join-Path $BackupRoot 'last-backup.html') -Encoding UTF8",
                 "Write-Host (\"Retention window: {0} days\" -f $RetentionDays) -ForegroundColor DarkGray"])
    body = _sec(rng, body,
                ["$MailTo = %s" % _q(rng, c["MailTo"]),
                 "$MailFrom = %s" % _q(rng, c["MailFrom"]),
                 "$mailBody = (\"Archive: {0}`nSize: {1} MB`nSHA256: {2}\" -f $archive, $manifest.SizeMB, $hash.Hash)"],
                _mail_block(rng, "$MailTo", "$MailFrom", _q(rng, c["SmtpServer"]),
                            _q(rng, "Backup completed"), "$mailBody", _pick(rng, [25, 587])))
    body = _sec(rng, body,
                ["$oldStages = Get-ChildItem -Path $env:TEMP -Filter 'backup-stage-*' -Directory -ErrorAction SilentlyContinue |",
                 "    Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-12) }",
                 "foreach ($dir in $oldStages) {",
                 "    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue",
                 "}"])
    body = _sec(rng, body,
                ["Write-Host (\"Backup finished: {0} files in archive\" -f $restored) -ForegroundColor Green"])

    pad_blocks = [
        ["$robolog = Join-Path $BackupRoot 'robocopy.log'",
         "robocopy $SourcePath $BackupRoot /E /R:2 /W:5 /NP /LOG:$robolog | Out-Null",
         "if ($LASTEXITCODE -ge 8) {",
         "    Write-Warning (\"robocopy reported exit code {0}\" -f $LASTEXITCODE)",
         "}"],
        ["$largeFiles = Get-ChildItem -Path $SourcePath -Recurse -File -ErrorAction SilentlyContinue |",
         "    Where-Object { $_.Length -gt 100MB } | Sort-Object Length -Descending | Select-Object -First 5",
         "$largeFiles | ForEach-Object {",
         "    Write-Verbose (\"Large file: {0} ({1:N1} MB)\" -f $_.Name, ($_.Length / 1MB))",
         "}"],
        ["$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -File C:\\Scripts\\Start-AppBackup.ps1'",
         "$trigger = New-ScheduledTaskTrigger -Daily -At %s" % _q(rng, _clock(rng)),
         "Register-ScheduledTask -TaskName 'Contoso-AppBackup' -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null"],
        ["$elapsed = Measure-Command -Expression {",
         "    Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File | Measure-Object -Property Length -Sum",
         "}",
         "Write-Verbose (\"Folder scan took {0:N0} ms\" -f $elapsed.TotalMilliseconds)"],
        ["$excluded = @('*.tmp', '*.log', '*.bak')",
         "Write-Verbose (\"Excluded patterns: {0}\" -f ($excluded -join ', '))"],
        ["$oldArchives = Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |",
         "    Sort-Object -Property LastWriteTime | Select-Object -First 3",
         "$oldArchives | Format-Table Name, LastWriteTime, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize"],
        ["$freeSpace = Get-PSDrive -Name ($BackupRoot.Substring(0, 1)) -ErrorAction SilentlyContinue",
         "if ($freeSpace) {",
         "    Write-Verbose (\"Free space: {0} GB\" -f [math]::Round($freeSpace.Free / 1GB, 1))",
         "}"],
    ]
    body = _pad(rng, body, 165, pad_blocks)
    return _render(body)


# ---------------------------------------------------------------------------
# 3. IIS / W3C log parser
# ---------------------------------------------------------------------------


def _iis_ctx(rng):
    site = _pick(rng, ["W3SVC1", "W3SVC2", "W3SVC7"])
    root = _pick(rng, ["C:\\inetpub\\logs\\LogFiles", "D:\\Logs\\iis"])
    date = _date(rng)
    return {
        "LogRoot": root + "\\" + site,
        "Days": _pick(rng, [1, 3, 7, 14, 30]),
        "TopN": _pick(rng, [5, 10, 15, 20]),
        "OutputPath": _pick(rng, ["C:\\Reports", "C:\\Logs\\reports", "D:\\Ops\\reports"]) +
                      "\\iis-top-" + date + ".csv",
        "HtmlPath": _pick(rng, ["C:\\Reports", "D:\\Ops\\reports"]) + "\\iis-" + date + ".html",
        "Script": _pick(rng, ["Get-IisTopUrls.ps1", "Invoke-IisLogReport.ps1",
                              "Parse-W3CLog.ps1"]),
        "MailTo": "webops@" + _pick(rng, _DOMAINS),
    }


def _iis_settings(rng, c):
    return [
        _mk("LogRoot", "string", _q(rng, c["LogRoot"]), _attrs(rng, "help")),
        _mk("Days", "int", str(c["Days"]), _attrs(rng, "optional", vrange=(1, 90))),
        _mk("TopN", "int", str(c["TopN"])),
        _mk("OutputPath", "string", _q(rng, c["OutputPath"])),
        _mk("HtmlPath", "string", _q(rng, c["HtmlPath"])),
    ]


def _iis_files(rng):
    return ["$cutoff = (Get-Date).AddDays(-$Days)",
            "$logFiles = Get-ChildItem -Path $LogRoot -Filter '*.log' -File |",
            "    Where-Object { $_.LastWriteTime -ge $cutoff }",
            "if (@($logFiles).Count -eq 0) {",
            "    throw (\"No IIS logs found in {0} for the last {1} days\" -f $LogRoot, $Days)",
            "}"]


def _iis_parse(rng):
    return ["$entries = foreach ($log in $logFiles) {",
            "    $fieldLine = Get-Content -LiteralPath $log.FullName -TotalCount 20 |",
            "        Where-Object { $_ -match '^#Fields:' } | Select-Object -First 1",
            "    if (-not $fieldLine) {",
            "        Write-Verbose (\"Skipping {0}: no field header\" -f $log.Name)",
            "        continue",
            "    }",
            "    $columns = ($fieldLine -replace '^#Fields:\\s*', '') -split ' '",
            "    $statusIndex = [array]::IndexOf($columns, 'sc-status')",
            "    $uriIndex = [array]::IndexOf($columns, 'cs-uri-stem')",
            "    $methodIndex = [array]::IndexOf($columns, 'cs-method')",
            "    $bytesIndex = [array]::IndexOf($columns, 'sc-bytes')",
            "    $timeIndex = [array]::IndexOf($columns, 'time-taken')",
            "    Get-Content -LiteralPath $log.FullName | Where-Object { $_ -notmatch '^#' } | ForEach-Object {",
            "        $parts = $_ -split ' '",
            "        if ($parts.Count -lt $columns.Count) {",
            "            return",
            "        }",
            "        [pscustomobject]@{",
            "            Date      = $parts[0]",
            "            Time      = $parts[1]",
            "            Method    = $parts[$methodIndex]",
            "            Uri       = $parts[$uriIndex]",
            "            Status    = [int]$parts[$statusIndex]",
            "            Bytes     = [int]$parts[$bytesIndex]",
            "            TimeTaken = [int]$parts[$timeIndex]",
            "        }",
            "    }",
            "}"]


def _iis_aggregate(rng):
    return ["$totalRequests = @($entries).Count",
            "$errorEntries = $entries | Where-Object { $_.Status -ge 400 }",
            "$totalMB = [math]::Round((($entries | Measure-Object -Property Bytes -Sum).Sum) / 1MB, 2)",
            "$topUrls = $entries |",
            "    Group-Object -Property Uri |",
            "    Sort-Object -Property Count -Descending |",
            "    Select-Object -First $TopN -Property @{Name = 'Uri'; Expression = { $_.Name }}, Count",
            "$byStatus = $entries |",
            "    Group-Object -Property Status |",
            "    Sort-Object -Property Count -Descending |",
            "    Select-Object -Property @{Name = 'Status'; Expression = { $_.Name }}, Count"]


def build_iis_log_parser(rng: random.Random) -> str:
    tier = _tier(rng)
    c = _iis_ctx(rng)
    settings = _iis_settings(rng, c)
    compact = tier == "short"
    pre, _ = _preamble(
        rng,
        synopsis="Parses IIS W3C logs and reports the busiest URLs and status codes.",
        description=[
            "Reads the newest log files below the configured site folder, discovers the "
            "field order from the #Fields header and aggregates requests, errors and "
            "transferred bytes.",
            "The output is a CSV file that can be opened in Excel or forwarded to the "
            "web operations mailbox.",
        ],
        examples=[".\\" + c["Script"] + " -Days %d -TopN %d" % (c["Days"], c["TopN"]),
                  ".\\" + c["Script"] + " -LogRoot " + c["LogRoot"]],
        settings=settings,
        compact=compact,
    )
    lines = list(pre)
    if tier != "short":
        lines.extend(_extras(rng))

    if tier == "short":
        lines = _sec(rng, lines,
                     ["$cutoff = (Get-Date).AddDays(-$Days)",
                      "$logs = Get-ChildItem -Path $LogRoot -Filter '*.log' -File |",
                      "    Where-Object { $_.LastWriteTime -ge $cutoff }",
                      "$entries = foreach ($log in $logs) {",
                      "    Get-Content -LiteralPath $log.FullName | Where-Object { $_ -notmatch '^#' } | ForEach-Object {",
                      "        $parts = $_ -split ' '",
                      "        [pscustomobject]@{ Status = [int]$parts[8]; Uri = $parts[3] }",
                      "    }",
                      "}"],
                     ["$entries | Group-Object Uri | Sort-Object Count -Descending |",
                      "    Select-Object -First $TopN Name, Count |",
                      "    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8",
                      "Write-Host (\"Parsed {0} lines from {1} files\" -f @($entries).Count, @($logs).Count) -ForegroundColor Cyan"])
        return _render(lines)

    body = _sec(rng, lines, _iis_files(rng), _iis_parse(rng), _iis_aggregate(rng))

    if tier == "medium":
        body = _sec(rng, body,
                    _csv_export(rng, "$topUrls", "$OutputPath"),
                    ["Write-Host (\"Requests: {0} | Errors: {1} | Traffic: {2} MB\" -f $totalRequests, @($errorEntries).Count, $totalMB) -ForegroundColor Cyan",
                     "$byStatus | Format-Table -AutoSize"])
        if _chance(rng, 0.4):
            body = _sec(rng, body, _html_style(rng),
                        ["$topUrls | ConvertTo-Html -Title 'Top URLs' -Head $style |",
                         "    Set-Content -Path $HtmlPath -Encoding UTF8"])
        body = _pad(rng, body, 46, [])
        return _render(body)

    body = _sec(rng, body,
                ["$slowest = $entries | Sort-Object -Property TimeTaken -Descending |",
                 "    Select-Object -First $TopN Uri, TimeTaken, Status"])
    body = _sec(rng, body, _csv_export(rng, "$topUrls", "$OutputPath"),
                ["$byStatus | Export-Csv -Path $OutputPath.Replace('.csv', '-status.csv') -NoTypeInformation -Encoding UTF8",
                 "$slowest | Export-Csv -Path $OutputPath.Replace('.csv', '-slow.csv') -NoTypeInformation"])
    body = _sec(rng, body,
                ["$byDay = $entries | Group-Object -Property Date | Sort-Object -Property Name |",
                 "    ForEach-Object {",
                 "        [pscustomobject]@{",
                 "            Date     = $_.Name",
                 "            Requests = $_.Count",
                 "            Errors   = @($_.Group | Where-Object { $_.Status -ge 400 }).Count",
                 "        }",
                 "    }",
                 "$byDay | Format-Table -AutoSize"])
    body = _sec(rng, body,
                ["$notFound = $entries | Where-Object { $_.Status -eq 404 } |",
                 "    Group-Object -Property Uri | Sort-Object -Property Count -Descending |",
                 "    Select-Object -First $TopN -Property @{Name = 'Uri'; Expression = { $_.Name }}, Count",
                 "$notFound | Export-Csv -Path $OutputPath.Replace('.csv', '-404.csv') -NoTypeInformation -Encoding UTF8"])
    body = _sec(rng, body,
                ["$byHour = $entries | Group-Object -Property { ($_.Time -split ':')[0] } |",
                 "    Sort-Object -Property Name",
                 "$byHour | ForEach-Object {",
                 "    Write-Verbose (\"Hour {0}: {1} requests\" -f $_.Name, $_.Count)",
                 "}"])
    body = _sec(rng, body, _html_style(rng),
                ["$byDay | ConvertTo-Html -Title 'IIS traffic by day' -Head $style |",
                 "    Set-Content -Path $HtmlPath -Encoding UTF8"])
    body = _sec(rng, body,
                ["$MailTo = %s" % _q(rng, c["MailTo"]),
                 "$MailFrom = %s" % _q(rng, "iis-report@" + c["MailTo"].split("@", 1)[1]),
                 "$summaryBody = $byStatus | ConvertTo-Html -Fragment | Out-String"],
                _mail_block(rng, "$MailTo", "$MailFrom", _q(rng, "smtp." + c["MailTo"].split("@", 1)[1]),
                            _q(rng, "IIS log summary"), "$summaryBody", _pick(rng, [25, 587])))
    body = _sec(rng, body,
                ["foreach ($log in $logFiles) {",
                 "    $sizeMB = [math]::Round($log.Length / 1MB, 2)",
                 "    Write-Verbose (\"{0}: {1} MB\" -f $log.Name, $sizeMB)",
                 "}",
                 "Write-Host (\"Top URL: {0} ({1} hits)\" -f $topUrls[0].Uri, $topUrls[0].Count) -ForegroundColor Green",
                 "Write-Verbose (\"Log files processed: {0}\" -f @($logFiles).Count)"])

    pad_blocks = [
        ["$errorRate = [math]::Round((@($errorEntries).Count / $totalRequests) * 100, 2)",
         "Write-Host (\"Error rate: {0} percent\" -f $errorRate) -ForegroundColor Yellow"],
        ["$bots = $entries | Where-Object { $_.Uri -match 'robots|sitemap' }",
         "Write-Verbose (\"Crawler requests: {0}\" -f @($bots).Count)"],
        ["$byMethod = $entries | Group-Object -Property Method | Sort-Object -Property Count -Descending",
         "$byMethod | Format-Table Name, Count -AutoSize"],
        ["$medianTime = ($entries | Measure-Object -Property TimeTaken -Average).Average",
         "Write-Verbose (\"Average time taken: {0:N1} ms\" -f $medianTime)"],
        ["$bigResponses = $entries | Sort-Object -Property Bytes -Descending | Select-Object -First 5",
         "$bigResponses | Format-Table Uri, Bytes, Status -AutoSize"],
        ["$compressed = @(Get-ChildItem -Path $LogRoot -Filter '*.log' -File |",
         "    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }).Count",
         "Write-Verbose (\"Logs older than 30 days: {0}\" -f $compressed)"],
    ]
    body = _pad(rng, body, 165, pad_blocks)
    return _render(body)


# ---------------------------------------------------------------------------
# 4. CSV report exporter
# ---------------------------------------------------------------------------


def _csv_ctx(rng):
    base = ["EmployeeId", "Name", "Department", "Site", "Amount"]
    extra = [c for c in ["CostCenter", "HireDate", "Manager"] if _chance(rng, 0.45)]
    cols = base + extra
    root = _pick(rng, ["C:\\Reports", "D:\\Ops\\reports", "C:\\Logs\\reports"])
    date = _date(rng)
    domain = _pick(rng, _DOMAINS)
    return {
        "Cols": cols,
        "GroupCol": _pick(rng, ["Department", "Site"]),
        "InputCsv": _pick(rng, ["C:\\Data\\exports\\headcount.csv",
                                "D:\\Incoming\\employees.csv",
                                "C:\\Scripts\\data\\headcount-export.csv"]),
        "OutputPath": root + "\\headcount-summary-" + date + ".csv",
        "Delimiter": ",",
        "MinAmount": _pick(rng, [1000, 2500, 5000, 10000]),
        "MailTo": "reporting@" + domain,
        "MailFrom": "bi@" + domain,
        "SmtpServer": "smtp." + domain,
        "Script": _pick(rng, ["Export-HeadcountReport.ps1", "Get-DepartmentTotals.ps1",
                              "Convert-CsvSummary.ps1"]),
    }


def _csv_settings(rng, c):
    settings = [
        _mk("InputCsv", "string", _q(rng, c["InputCsv"]), _attrs(rng, "help")),
        _mk("OutputPath", "string", _q(rng, c["OutputPath"])),
        _mk("GroupBy", "string", _q(rng, c["GroupCol"]),
            _attrs(rng, "optional", validate=["Department", "Site"])),
        _mk("MinAmount", "double", str(c["MinAmount"])),
    ]
    return settings


def _csv_load(rng, c):
    return ["if (-not (Test-Path -LiteralPath $InputCsv)) {",
            "    throw (\"Input file not found: {0}\" -f $InputCsv)",
            "}",
            "$rows = Import-Csv -LiteralPath $InputCsv -Delimiter %s" % _q(rng, c["Delimiter"]),
            "if (@($rows).Count -eq 0) {",
            "    throw 'The input CSV contains no data rows.'",
            "}",
            "$required = @('EmployeeId', 'Name', 'Department', 'Site', 'Amount')",
            "$available = $rows[0].PSObject.Properties.Name",
            "$missing = @($required | Where-Object { $available -notcontains $_ })",
            "if ($missing.Count -gt 0) {",
            "    throw (\"Missing column(s): {0}\" -f ($missing -join ', '))",
            "}",
            "$rows | ForEach-Object { $_.Amount = [double]$_.Amount }"]


def _csv_summary(rng, c):
    return ["$byGroup = $rows | Group-Object -Property $GroupBy | ForEach-Object {",
            "    $sum = ($_.Group | Measure-Object -Property Amount -Sum).Sum",
            "    [pscustomobject]@{",
            "        Group     = $_.Name",
            "        Metric    = $GroupBy",
            "        Employees = $_.Count",
            "        Total     = [math]::Round($sum, 2)",
            "        Average   = [math]::Round(($sum / $_.Count), 2)",
            "    }",
            "}"]


def build_csv_report_exporter(rng: random.Random) -> str:
    tier = _tier(rng)
    c = _csv_ctx(rng)
    settings = _csv_settings(rng, c)
    compact = tier == "short"
    pre, _ = _preamble(
        rng,
        synopsis="Reads an exported employee CSV and writes an aggregated summary report.",
        description=[
            "Validates the column layout of the source file, converts the Amount column "
            "to a number and aggregates headcount and spend per department or site.",
            "Missing columns are reported as a hard error so a changed export cannot "
            "silently produce an empty report.",
        ],
        examples=[".\\" + c["Script"] + " -InputCsv " + c["InputCsv"],
                  ".\\" + c["Script"] + " -GroupBy Site -MinAmount %d" % c["MinAmount"]],
        settings=settings,
        compact=compact,
    )
    lines = list(pre)
    if tier != "short":
        lines.extend(_extras(rng))

    if tier == "short":
        gc = c["GroupCol"]
        lines = _sec(rng, lines,
                     ["if (-not (Test-Path -LiteralPath $InputCsv)) {",
                      "    throw (\"Input file not found: {0}\" -f $InputCsv)",
                      "}",
                      "$rows = Import-Csv -LiteralPath $InputCsv -Delimiter ','"],
                     ["$byGroup = $rows | Group-Object -Property %s | ForEach-Object {" % gc,
                      "    [pscustomobject]@{",
                      "        %s       = $_.Name" % gc,
                      "        Employees = $_.Count",
                      "        Total     = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)",
                      "    }",
                      "}"],
                     ["$byGroup | Sort-Object -Property Total -Descending |",
                      "    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8",
                      "Write-Host (\"Rows: {0} | Groups: {1}\" -f @($rows).Count, @($byGroup).Count) -ForegroundColor Cyan"])
        return _render(lines)

    body = _sec(rng, lines, _csv_load(rng, c), _csv_summary(rng, c),
                ["$grandTotal = [math]::Round((($rows | Measure-Object -Property Amount -Sum).Sum), 2)",
                 "$rowCount = @($rows).Count"])

    if tier == "medium":
        body = _sec(rng, body,
                    _csv_export(rng, "$byGroup | Sort-Object -Property Total -Descending", "$OutputPath"),
                    ["$top = $byGroup | Sort-Object -Property Total -Descending | Select-Object -First 1",
                     "Write-Host (\"{0} rows processed, total {1:N2}\" -f $rowCount, $grandTotal) -ForegroundColor Green",
                     "Write-Host (\"Largest group: {0} ({1})\" -f $top.Group, $top.Metric) -ForegroundColor Cyan"])
        if _chance(rng, 0.5):
            body = _sec(rng, body,
                        _json_export(rng, "$byGroup", "$OutputPath.Replace('.csv', '.json')"))
        body = _pad(rng, body, 48, [])
        return _render(body)

    body = _sec(rng, body,
                _csv_export(rng, "$byGroup | Sort-Object -Property Total -Descending", "$OutputPath"),
                ["$aboveThreshold = $byGroup | Where-Object { $_.Total -ge $MinAmount }",
                 "$aboveThreshold | Export-Csv -Path $OutputPath.Replace('.csv', '-filtered.csv') -NoTypeInformation -Encoding UTF8"])
    body = _sec(rng, body,
                ["$bySite = $rows | Group-Object -Property Site | ForEach-Object {",
                 "    [pscustomobject]@{",
                 "        Site      = $_.Name",
                 "        Employees = $_.Count",
                 "        Total     = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)",
                 "    }",
                 "}",
                 "$bySite | Sort-Object -Property Total -Descending | Format-Table -AutoSize"])
    body = _sec(rng, body,
                ["$duplicates = $rows | Group-Object -Property EmployeeId |",
                 "    Where-Object { $_.Count -gt 1 } |",
                 "    Select-Object Name, Count",
                 "if (@($duplicates).Count -gt 0) {",
                 "    Write-Warning (\"Duplicate employee ids: {0}\" -f @($duplicates).Count)",
                 "}"])
    if "Manager" in c["Cols"]:
        body = _sec(rng, body,
                    ["$byManager = $rows | Group-Object -Property Manager |",
                     "    Sort-Object -Property Count -Descending | Select-Object -First 5",
                     "$byManager | Format-Table -AutoSize"])
    body = _sec(rng, body, _html_style(rng),
                ["$byGroup | Sort-Object -Property Total -Descending |",
                 "    ConvertTo-Html -Title 'Headcount summary' -Head $style |",
                 "    Set-Content -Path $OutputPath.Replace('.csv', '.html') -Encoding UTF8"])
    body = _sec(rng, body,
                _json_export(rng, "$byGroup", "$OutputPath.Replace('.csv', '.json')"),
                ["$bySite | Export-Csv -Path $OutputPath.Replace('.csv', '-by-site.csv') -NoTypeInformation -Encoding UTF8"])
    body = _sec(rng, body,
                ["$summaryBody = @\"",
                 "Rows processed : $rowCount",
                 "Grand total    : $grandTotal",
                 "Groups         : $($byGroup.Count)",
                 "Output         : $OutputPath",
                 "\"@"],
                ["$MailTo = %s" % _q(rng, c["MailTo"]),
                 "$MailFrom = %s" % _q(rng, c["MailFrom"])],
                _mail_block(rng, "$MailTo", "$MailFrom", _q(rng, c["SmtpServer"]),
                            _q(rng, "Headcount summary"), "$summaryBody", _pick(rng, [25, 587])))
    body = _sec(rng, body,
                ["Write-Host (\"Report written to {0}\" -f $OutputPath) -ForegroundColor Green",
                 "Write-Verbose (\"Filtered groups above threshold: {0}\" -f @($aboveThreshold).Count)"])

    pad_blocks = [
        ["$average = ($rows | Measure-Object -Property Amount -Average).Average",
         "Write-Verbose (\"Average amount: {0:N2}\" -f $average)"],
        ["$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')",
         "$formatted = $grandTotal.ToString('C2', $culture)",
         "Write-Verbose (\"Formatted total: {0}\" -f $formatted)"],
        ["$outputDir = Split-Path -Parent $OutputPath",
         "if (-not (Test-Path -LiteralPath $outputDir)) {",
         "    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null",
         "}"],
        ["$sample = $rows | Select-Object -First 3",
         "$sample | Format-Table -AutoSize | Out-String | Write-Verbose"],
        ["$byCostCenter = $rows | Where-Object { $_.PSObject.Properties.Name -contains 'CostCenter' } |",
         "    Group-Object -Property CostCenter | Sort-Object -Property Count -Descending | Select-Object -First 5",
         "$byCostCenter | Format-Table Name, Count -AutoSize"],
        ["$largest = $rows | Sort-Object -Property Amount -Descending | Select-Object -First 5",
         "$largest | Format-Table Name, Department, Amount -AutoSize"],
    ]
    body = _pad(rng, body, 165, pad_blocks)
    return _render(body)


# ---------------------------------------------------------------------------
# 5. Azure resource provisioning test
# ---------------------------------------------------------------------------


def _guid(rng):
    hexd = "0123456789abcdef"
    return "-".join("".join(hexd[rng.randrange(16)] for _ in range(n))
                    for n in (8, 4, 4, 4, 12))


def _az_ctx(rng):
    env = _pick(rng, ["test", "staging", "demo"])
    domain = _pick(rng, _DOMAINS)
    n = _int(rng, 1, 40)
    return {
        "Env": env,
        "ResourceGroup": "rg-portal-%s-%02d" % (env, n),
        "Location": _pick(rng, ["westeurope", "eastus", "northeurope", "uksouth"]),
        "VmName": "vm-portal-%s-%02d" % (env, n),
        "Storage": "st" + env + "%04d" % _int(rng, 1, 9999),
        "SubscriptionId": _guid(rng),
        "TemplateFile": "C:\\Scripts\\templates\\portal-%s.json" % env,
        "ParameterFile": "C:\\Scripts\\templates\\portal-%s.parameters.json" % env,
        "OutputPath": "C:\\Logs\\deploy-%s-%s.json" % (env, _date(rng)),
        "MailTo": "cloudops@" + domain,
        "SmtpServer": "smtp." + domain,
        "Script": _pick(rng, ["Test-AzPortalDeploy.ps1", "Invoke-AzSandbox.ps1",
                              "Deploy-PortalTest.ps1"]),
    }


def _az_settings(rng, c):
    return [
        _mk("ResourceGroup", "string", _q(rng, c["ResourceGroup"]), _attrs(rng, "help")),
        _mk("Location", "string", _q(rng, c["Location"]),
            _attrs(rng, "plain", validate=["westeurope", "eastus", "northeurope", "uksouth"])),
        _mk("TemplateFile", "string", _q(rng, c["TemplateFile"])),
        _mk("ParameterFile", "string", _q(rng, c["ParameterFile"])),
        _mk("SubscriptionId", "string", _q(rng, c["SubscriptionId"])),
        _mk("StorageAccount", "string", _q(rng, c["Storage"])),
        _mk("VmName", "string", _q(rng, c["VmName"])),
        _mk("OutputPath", "string", _q(rng, c["OutputPath"])),
        _mk("DryRun", "switch", None),
    ]


def _az_context(rng):
    return ["$context = Get-AzContext",
            "if (-not $context) {",
            "    Connect-AzAccount -Tenant %s -Subscription $SubscriptionId" % _q(rng, "contoso.com"),
            "}"]


def _az_validate(rng):
    return ["$validation = Test-AzResourceGroupDeployment `",
            "    -ResourceGroupName $ResourceGroup `",
            "    -TemplateFile $TemplateFile `",
            "    -TemplateParameterFile $ParameterFile",
            "if ($validation) {",
            "    $validation | Format-Table -AutoSize",
            "    throw 'Template validation failed.'",
            "}"]


def _az_deploy(rng, c):
    if _chance(rng, 0.4):
        return ["$deployParams = @{",
                "    ResourceGroupName     = $ResourceGroup",
                "    TemplateFile          = $TemplateFile",
                "    TemplateParameterFile = $ParameterFile",
                "    Name                  = $DeploymentName",
                "}",
                "$deployment = New-AzResourceGroupDeployment @deployParams -Verbose"]
    return ["$deployment = New-AzResourceGroupDeployment `",
            "    -ResourceGroupName $ResourceGroup `",
            "    -TemplateFile $TemplateFile `",
            "    -TemplateParameterFile $ParameterFile `",
            "    -Name $DeploymentName `",
            "    -Verbose"]


def _az_storage(rng):
    return ["$storage = New-AzStorageAccount -ResourceGroupName $ResourceGroup `",
            "    -Name $StorageAccount -Location $Location `",
            "    -SkuName Standard_LRS -Kind StorageV2 -ErrorAction Stop",
            "Write-Verbose (\"Storage account {0} provisioned\" -f $storage.StorageAccountName)"]


def _az_vm(rng):
    return ["$vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VmName -ErrorAction SilentlyContinue",
            "if ($vm) {",
            "    $status = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VmName -Status",
            "    $status.Statuses | Select-Object Code, DisplayStatus | Format-Table -AutoSize",
            "}",
            "else {",
            "    Write-Warning (\"Virtual machine {0} was not created\" -f $VmName)",
            "}"]


def build_azure_provision_test(rng: random.Random) -> str:
    tier = _tier(rng)
    c = _az_ctx(rng)
    settings = _az_settings(rng, c)
    compact = tier == "short"
    pre, _ = _preamble(
        rng,
        synopsis="Deploys a sandbox resource group from an ARM template and validates the result.",
        description=[
            "Runs a template validation first, then creates the resource group, the "
            "storage account and the test virtual machine before cleaning the sandbox up.",
            "The cleanup step honours the DryRun switch so the resources can be inspected "
            "after a failed deployment.",
        ],
        examples=[".\\" + c["Script"] + " -ResourceGroup " + c["ResourceGroup"],
                  ".\\" + c["Script"] + " -Location " + c["Location"] + " -DryRun"],
        settings=settings,
        compact=compact,
    )
    lines = list(pre)
    if tier != "short":
        lines.extend(_extras(rng))

    if tier == "short":
        lines = _sec(rng, lines, _az_context(rng),
                     ["if (-not (Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue)) {",
                      "    New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null",
                      "}",
                      "$DeploymentName = \"portal-\" + (Get-Date -Format 'yyyyMMdd-HHmm')",
                      "$deployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile $TemplateFile -Name $DeploymentName",
                      "Write-Host (\"Deployment {0}: {1}\" -f $deployment.DeploymentName, $deployment.ProvisioningState) -ForegroundColor Green"])
        return _render(lines)

    body = _sec(rng, lines,
                _module_check(rng, "Az.Resources", "The Az.Resources module is not installed."),
                _az_context(rng),
                ["$DeploymentName = \"portal-\" + (Get-Date -Format 'yyyyMMdd-HHmm')"],
                ["if (-not (Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue)) {",
                 "    New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null",
                 "    Write-Verbose (\"Created resource group {0}\" -f $ResourceGroup)",
                 "}"])

    if tier == "medium":
        body = _sec(rng, body, _az_deploy(rng, c), _az_profile(rng, c), _az_storage(rng), _az_vm(rng),
                    ["$deployment | Select-Object DeploymentName, ProvisioningState, Timestamp | Format-List",
                     "Write-Host (\"Provisioning state: {0}\" -f $deployment.ProvisioningState) -ForegroundColor Cyan"])
        if _chance(rng, 0.5):
            body = _sec(rng, body, _az_cleanup(rng))
        body = _pad(rng, body, 48, [])
        return _render(body)

    body = _sec(rng, body, _az_validate(rng), _az_deploy(rng, c), _az_profile(rng, c))
    body = _sec(rng, body, _az_storage(rng), _az_vm(rng),
                ["$deployment | Select-Object DeploymentName, ProvisioningState, Timestamp | Format-List",
                 "$deployment.Outputs | Format-Table -AutoSize"])
    body = _sec(rng, body,
                ["$summary = [pscustomobject]@{",
                 "    ResourceGroup     = $ResourceGroup",
                 "    Location          = $Location",
                 "    DeploymentName    = $DeploymentName",
                 "    ProvisioningState = $deployment.ProvisioningState",
                 "    StorageAccount    = $StorageAccount",
                 "    CompletedAt       = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')",
                 "}",
                 "$summary | ConvertTo-Json -Depth 3 | Set-Content -Path $OutputPath -Encoding UTF8"])
    body = _sec(rng, body, _html_style(rng),
                ["@($summary) | ConvertTo-Html -Title 'Deployment summary' -Head $style |",
                 "    Set-Content -Path $OutputPath.Replace('.json', '.html') -Encoding UTF8"])
    body = _sec(rng, body,
                ["$MailTo = %s" % _q(rng, c["MailTo"]),
                 "$subject = \"Sandbox deployment {0}\" -f $deployment.ProvisioningState"],
                _mail_block(rng, "$MailTo", _q(rng, "cloudops@" + c["MailTo"].split("@", 1)[1]),
                            _q(rng, c["SmtpServer"]), "$subject",
                            _q(rng, "See the deployment summary attached to the run log."),
                            _pick(rng, [25, 587])))
    body = _sec(rng, body, _az_cleanup(rng),
                ["Write-Host (\"Sandbox deployment finished: {0}\" -f $deployment.ProvisioningState) -ForegroundColor Green"])

    pad_blocks = [
        ["$tags = @{",
         "    Environment = %s" % _q(rng, c["Env"]),
         "    Owner       = 'platform-team'",
         "    CostCenter  = 'CC-1042'",
         "}",
         "Write-Verbose (\"Tags: {0}\" -f ($tags.Keys -join ', '))"],
        ["$quotas = Get-AzVMUsage -Location $Location -ErrorAction SilentlyContinue |",
         "    Where-Object { $_.CurrentValue -ge ($_.Limit * 0.8) }",
         "$quotas | Select-Object -First 5 Name, CurrentValue, Limit | Format-Table -AutoSize"],
        ["$providers = Get-AzResourceProvider -ProviderNamespace Microsoft.Compute -ErrorAction SilentlyContinue",
         "if ($providers) {",
         "    Write-Verbose (\"Provider registered: {0}\" -f $providers.RegistrationState)",
         "}"],
        ["$pricing = Get-AzConsumptionPriceSheet -ErrorAction SilentlyContinue",
         "Write-Verbose (\"Price sheet entries: {0}\" -f @($pricing).Count)"],
        ["$deployLog = Join-Path $env:TEMP (\"az-deploy-\" + (Get-Date -Format 'yyyyMMdd-HHmmss') + \".log\")",
         "Write-Verbose (\"Deployment log: {0}\" -f $deployLog)"],
    ]
    body = _pad(rng, body, 165, pad_blocks)
    return _render(body)


def _az_profile(rng, c):
    return ["$profile = Get-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue |",
            "    Sort-Object -Property Timestamp -Descending | Select-Object -First 3",
            "$profile | Select-Object DeploymentName, ProvisioningState, Timestamp | Format-Table -AutoSize"]


def _az_cleanup(rng):
    if _chance(rng, 0.5):
        return ["Remove-AzResourceGroup -Name $ResourceGroup -Force -WhatIf:$DryRun"]
    return ["if (-not $DryRun) {",
            "    Remove-AzResourceGroup -Name $ResourceGroup -Force | Out-Null",
            "    Write-Host (\"Removed sandbox resource group {0}\" -f $ResourceGroup)",
            "}"]


# ---------------------------------------------------------------------------
# 6. AWS / Azure cloud cost report
# ---------------------------------------------------------------------------


def _cost_ctx(rng):
    provider = _pick(rng, ["aws", "azure"])
    domain = _pick(rng, _DOMAINS)
    root = _pick(rng, ["C:\\Reports", "D:\\Ops\\finops", "C:\\Reports\\cloud"])
    month = "%04d-%02d" % (rng.choice([2025, 2026]), rng.randint(1, 12))
    return {
        "Provider": provider,
        "Profile": _pick(rng, ["contoso-prod", "adatum-billing", "default"]),
        "Region": _pick(rng, ["eu-west-1", "us-east-1", "ap-southeast-2", "westeurope"]),
        "Account": "%012d" % _int(rng, 100000000000, 999999999999),
        "Threshold": _pick(rng, [500, 750, 1000, 2500, 5000]),
        "Month": month,
        "ReportPath": root + "\\cost-" + provider + "-" + month + ".csv",
        "OutputPath": root + "\\cost-" + provider + "-" + month + ".json",
        "MailTo": "finops@" + domain,
        "SmtpServer": "smtp." + domain,
        "Script": _pick(rng, ["Get-CloudCostReport.ps1", "Export-MonthlySpend.ps1",
                              "Get-CostByService.ps1"]),
    }


def _cost_settings(rng, c):
    return [
        _mk("Threshold", "double", str(c["Threshold"]), _attrs(rng, "help")),
        _mk("Region", "string", _q(rng, c["Region"])),
        _mk("ProfileName", "string", _q(rng, c["Profile"])),
        _mk("Month", "string", _q(rng, c["Month"]), _attrs(rng, "optional")),
        _mk("Account", "string", _q(rng, c["Account"])),
        _mk("ReportPath", "string", _q(rng, c["ReportPath"])),
        _mk("OutputPath", "string", _q(rng, c["OutputPath"])),
    ]


def _cost_aws(rng, c):
    return ["$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')",
            "$end = (Get-Date).ToString('yyyy-MM-01')",
            "$raw = aws ce get-cost-and-usage --time-period Start=$start,End=$end --granularity MONTHLY --metrics UnblendedCost --profile $ProfileName --region $Region --output json",
            "if ($LASTEXITCODE -ne 0) {",
            "    throw 'AWS Cost Explorer query failed.'",
            "}",
            "$cost = $raw | ConvertFrom-Json",
            "$groups = foreach ($bucket in $cost.ResultsByTime) {",
            "    foreach ($group in $bucket.Groups) {",
            "        [pscustomobject]@{",
            "            Period  = $bucket.TimePeriod.Start",
            "            Service = $group.Keys[0]",
            "            Amount  = [math]::Round([double]$group.Metrics.UnblendedCost.Amount, 2)",
            "            Unit    = $group.Metrics.UnblendedCost.Unit",
            "        }",
            "    }",
            "}"]


def _cost_azure(rng, c):
    return ["$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')",
            "$end = (Get-Date).ToString('yyyy-MM-01')",
            "$usage = Get-AzConsumptionUsageDetail -StartDate $start -EndDate $end -ErrorAction Stop",
            "$groups = foreach ($line in $usage) {",
            "    [pscustomobject]@{",
            "        Period  = $line.UsageStart.ToString('yyyy-MM-dd')",
            "        Service = $line.ServiceName",
            "        Amount  = [math]::Round([double]$line.PretaxCost, 2)",
            "        Unit    = $line.Currency",
            "    }",
            "}"]


def _cost_aggregate(rng):
    return ["$byService = $groups | Group-Object -Property Service | ForEach-Object {",
            "    [pscustomobject]@{",
            "        Service = $_.Name",
            "        Amount  = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)",
            "    }",
            "} | Sort-Object -Property Amount -Descending",
            "$total = [math]::Round((($byService | Measure-Object -Property Amount -Sum).Sum), 2)",
            "Write-Host (\"Total spend for the period: {0:N2}\" -f $total) -ForegroundColor Cyan"]


def build_cloud_cost_report(rng: random.Random) -> str:
    tier = _tier(rng)
    c = _cost_ctx(rng)
    settings = _cost_settings(rng, c)
    compact = tier == "short"
    pre, _ = _preamble(
        rng,
        synopsis="Builds a monthly cloud cost report per service and flags overspend.",
        description=[
            "Queries the cost API of the selected provider, groups the spend per service "
            "and writes a CSV plus a JSON summary.",
            "When the monthly total passes the threshold the script emits a warning that "
            "can be picked up by the monitoring pipeline.",
        ],
        examples=[".\\" + c["Script"] + " -Threshold %d" % c["Threshold"],
                  ".\\" + c["Script"] + " -ProfileName " + c["Profile"]],
        settings=settings,
        compact=compact,
    )
    lines = list(pre)
    if tier != "short":
        lines.extend(_extras(rng))

    query = _cost_aws(rng, c) if c["Provider"] == "aws" else _cost_azure(rng, c)

    if tier == "short":
        if c["Provider"] == "aws":
            short_query = ["$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')",
                           "$end = (Get-Date).ToString('yyyy-MM-01')",
                           "$raw = aws ce get-cost-and-usage --time-period Start=$start,End=$end --granularity MONTHLY --metrics UnblendedCost --profile $ProfileName --region $Region --output json",
                           "$groups = ($raw | ConvertFrom-Json).ResultsByTime[0].Groups | ForEach-Object {",
                           "    [pscustomobject]@{ Service = $_.Keys[0]; Amount = [math]::Round([double]$_.Metrics.UnblendedCost.Amount, 2) }",
                           "}"]
        else:
            short_query = ["$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')",
                           "$end = (Get-Date).ToString('yyyy-MM-01')",
                           "$groups = Get-AzConsumptionUsageDetail -StartDate $start -EndDate $end | ForEach-Object {",
                           "    [pscustomobject]@{ Service = $_.ServiceName; Amount = [math]::Round([double]$_.PretaxCost, 2) }",
                           "}"]
        lines = _sec(rng, lines, short_query,
                     ["$total = [math]::Round((($groups | Measure-Object -Property Amount -Sum).Sum), 2)",
                      "$groups | Sort-Object -Property Amount -Descending | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8",
                      "if ($total -gt $Threshold) { Write-Warning (\"Spend {0:N2} above threshold\" -f $total) }"])
        return _render(lines)

    body = _sec(rng, lines, query, _cost_aggregate(rng))

    if tier == "medium":
        body = _sec(rng, body,
                    _csv_export(rng, "$byService", "$ReportPath"),
                    ["$topServices = $byService | Select-Object -First 5",
                     "$topServices | Format-Table -AutoSize",
                     "if ($total -gt $Threshold) {",
                     "    Write-Warning (\"Spend {0:N2} exceeded the threshold of {1:N2}\" -f $total, $Threshold)",
                     "}"])
        if _chance(rng, 0.5):
            body = _sec(rng, body,
                        _json_export(rng, "$byService", "$OutputPath"))
        body = _pad(rng, body, 48, [])
        return _render(body)

    body = _sec(rng, body,
                _csv_export(rng, "$byService", "$ReportPath"),
                _json_export(rng, "$byService", "$OutputPath"),
                ["$overThreshold = $byService | Where-Object { $_.Amount -ge ($Threshold / 10) }",
                 "$overThreshold | Export-Csv -Path $ReportPath.Replace('.csv', '-top.csv') -NoTypeInformation -Encoding UTF8"])
    body = _sec(rng, body,
                ["$daily = $groups | Group-Object -Property Period | ForEach-Object {",
                 "    [pscustomobject]@{",
                 "        Period = $_.Name",
                 "        Amount = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)",
                 "    }",
                 "} | Sort-Object -Property Period"])
    body = _sec(rng, body, _html_style(rng),
                ["$daily | ConvertTo-Html -Title 'Daily cloud spend' -Head $style |",
                 "    Set-Content -Path $ReportPath.Replace('.csv', '.html') -Encoding UTF8"])
    body = _sec(rng, body,
                ["$summaryBody = @\"",
                 "Provider  : %s" % c["Provider"],
                 "Account   : $Account",
                 "Period    : $Month",
                 "Total     : $total",
                 "Threshold : $Threshold",
                 "\"@"],
                ["$MailTo = %s" % _q(rng, c["MailTo"])],
                _mail_block(rng, "$MailTo", _q(rng, "finops@" + c["MailTo"].split("@", 1)[1]),
                            _q(rng, c["SmtpServer"]),
                            _q(rng, "Monthly cloud cost report"), "$summaryBody",
                            _pick(rng, [25, 587])))
    body = _sec(rng, body,
                ["if ($total -gt $Threshold) {",
                 "    Write-Warning (\"Spend {0:N2} exceeded the threshold of {1:N2}\" -f $total, $Threshold)",
                 "}",
                 "Write-Host (\"Report written to {0}\" -f $ReportPath) -ForegroundColor Green"])

    pad_blocks = [
        ["$cheapest = $byService | Sort-Object -Property Amount | Select-Object -First 5",
         "$cheapest | Format-Table -AutoSize"],
        ["$average = [math]::Round(($total / [math]::Max(@($byService).Count, 1)), 2)",
         "Write-Verbose (\"Average cost per service: {0:N2}\" -f $average)"],
        ["$budgetFile = Join-Path $PSScriptRoot 'budget.json'",
         "if (Test-Path -LiteralPath $budgetFile) {",
         "    $budget = Get-Content -LiteralPath $budgetFile -Raw | ConvertFrom-Json",
         "    Write-Verbose (\"Budget file loaded: {0}\" -f $budgetFile)",
         "}"],
        ["$serviceCount = @($byService).Count",
         "Write-Verbose (\"Services with spend: {0}\" -f $serviceCount)",
         "Write-Verbose (\"Provider profile: {0}\" -f $ProfileName)"],
        ["$history = Join-Path (Split-Path -Parent $ReportPath) 'cost-history.csv'",
         "Write-Verbose (\"History file: {0}\" -f $history)"],
    ]
    body = _pad(rng, body, 165, pad_blocks)
    return _render(body)


# ---------------------------------------------------------------------------
# 7. Pester unit tests
# ---------------------------------------------------------------------------


def _pester_ctx(rng):
    module = _pick(rng, ["Contoso.Agent", "Adatum.Reporting", "Infra.Tools", "Contoso.Helpers"])
    return {
        "Module": module,
        "Func": _pick(rng, ["Get-AgentStatus", "Get-ReportStatus", "Get-ServerState",
                            "Test-AgentHeartbeat"]),
        "Other": _pick(rng, ["Get-AgentConfig", "Set-AgentConfig", "Export-AgentLog"]),
        "Fixture": "$env:TEMP\\agent-fixture.json",
        "Script": module.replace(".", "-") + ".Tests.ps1",
        "Service": _pick(rng, ["ContosoAgent", "AdatumCollector", "InfraRelay"]),
        "Port": _pick(rng, [8443, 8080, 9443, 5000]),
    }


def _pester_before_all(rng, c, has_settings=False):
    root = "$ModulePath" if has_settings else "$PSScriptRoot"
    return ["BeforeAll {",
            "    Import-Module (Join-Path %s '%s.psd1') -Force" % (root, c["Module"]),
            "    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'",
            "}"]


def _pester_describe(rng, c):
    svc = c["Service"]
    return ["Describe '%s' {" % c["Func"],
            "    Context 'when the agent service is running' {",
            "        BeforeEach {",
            "            Mock Get-Service {",
            "                [pscustomobject]@{ Name = '%s'; Status = 'Running' }" % svc,
            "            } -ParameterFilter { $Name -eq '%s' }" % svc,
            "        }",
            "",
            "        It 'reports Running for a healthy agent' {",
            "            $result = %s -Name '%s'" % (c["Func"], svc),
            "            $result.Status | Should -Be 'Running'",
            "        }",
            "    }",
            "",
            "    It 'throws when the service does not exist' {",
            "        { %s -Name 'NoSuchAgent' } | Should -Throw" % c["Func"],
            "    }",
            "}"]


def _pester_cases(rng, c):
    return ["Describe '%s' {" % c["Other"],
            "    It 'returns the configured port for <Name>' -TestCases @(",
            "        @{ Name = '%s'; Expected = %d }" % (c["Service"], c["Port"]),
            "        @{ Name = 'SecondaryAgent'; Expected = %d }" % (c["Port"] + 100),
            "    ) {",
            "        param($Name, $Expected)",
            "        $config = %s -Name $Name" % c["Other"],
            "        $config.Port | Should -Be $Expected",
            "    }",
            "}"]


def build_pester_tests(rng: random.Random) -> str:
    tier = _tier(rng)
    c = _pester_ctx(rng)
    settings = []
    compact = tier == "short"
    if not compact and _chance(rng, 0.6):
        settings = [_mk("ModulePath", "string", "$PSScriptRoot",
                        _attrs(rng, "help"))]
    pre, has_param = _preamble(
        rng,
        synopsis="Pester specification for the %s module." % c["Module"],
        description=[
            "Covers the public surface of the module: status queries, configuration "
            "lookups and the error paths that must throw.",
            "Service lookups are mocked so the tests run on a build agent without the "
            "agent service installed.",
        ],
        examples=["Invoke-Pester -Path .\\%s -Output Detailed" % c["Script"]],
        settings=settings,
        compact=compact,
        help_p=0.4,
        param_p=(0.5 if not compact else 0.0),
        requires_p=0.4,
    )
    lines = list(pre)
    if tier != "short":
        lines.extend(_extras(rng))
    lines = _sec(rng, lines, _pester_before_all(rng, c, bool(settings)))

    if tier == "short":
        lines = _sec(rng, lines,
                     ["Describe '%s' {" % c["Func"],
                      "    It 'returns a status object' {",
                      "        %s -Name '%s' | Should -Not -BeNullOrEmpty" % (c["Func"], c["Service"]),
                      "    }",
                      "",
                      "    It 'throws for an unknown service' {",
                      "        { %s -Name 'NoSuchAgent' } | Should -Throw" % c["Func"],
                      "    }",
                      "}"],
                     ["AfterAll {",
                      "    Remove-Module %s -Force -ErrorAction SilentlyContinue" % c["Module"],
                      "}"])
        return _render(lines)

    body = _sec(rng, lines, _pester_describe(rng, c), _pester_cases(rng, c))

    if tier == "medium":
        body = _sec(rng, body,
                    ["Describe 'Get-AgentConfig' {",
                     "    It 'returns a port for the configured agent' {",
                     "        $config = Get-AgentConfig -Name '%s'" % c["Service"],
                     "        $config.Port | Should -BeGreaterThan 0",
                     "    }",
                     "}"])
        body = _sec(rng, body,
                    ["AfterAll {",
                     "    Remove-Module %s -Force -ErrorAction SilentlyContinue" % c["Module"],
                     "    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue",
                     "}"])
        body = _pad(rng, body, 48, [])
        return _render(body)

    body = _sec(rng, body,
                ["Describe '%s' {" % c["Func"],
                 "    Context 'with a stopped service' {",
                 "        BeforeEach {",
                 "            Mock Get-Service {",
                 "                [pscustomobject]@{ Name = '%s'; Status = 'Stopped' }" % c["Service"],
                 "            } -ParameterFilter { $Name -eq '%s' }" % c["Service"],
                 "        }",
                 "",
                 "        It 'reports Stopped' {",
                 "            (%s -Name '%s').Status | Should -Be 'Stopped'" % (c["Func"], c["Service"]),
                 "        }",
                 "    }",
                 "}"],
                ["Describe 'module metadata' {",
                 "    It 'exports only public functions' {",
                 "        $commands = Get-Command -Module '%s' | Select-Object -ExpandProperty Name" % c["Module"],
                 "        $commands | Should -Contain '%s'" % c["Func"],
                 "    }",
                 "}"])
    body = _sec(rng, body,
                ["Describe 'Get-AgentConfig validation' {",
                 "    It 'rejects an empty path' {",
                 "        { Get-AgentConfig -Path '' } | Should -Throw",
                 "    }",
                 "",
                 "    It 'accepts a path below the temp folder' {",
                 "        $path = Join-Path $env:TEMP 'agent.ini'",
                 "        { Get-AgentConfig -Path $path } | Should -Not -Throw",
                 "    }",
                 "}"])
    body = _sec(rng, body,
                ["AfterAll {",
                 "    Remove-Module %s -Force -ErrorAction SilentlyContinue" % c["Module"],
                 "    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue",
                 "}"])

    pad_blocks = [
        ["Describe 'Get-AgentStatus pipeline input' {",
         "    It 'accepts a server name from the pipeline' {",
         "        { '%s' | %s } | Should -Not -Throw" % (c["Service"], c["Func"]),
         "    }",
         "}"],
        ["Describe 'Get-AgentStatus output shape' {",
         "    It 'returns an object with a Status property' {",
         "        $result = %s -Name '%s'" % (c["Func"], c["Service"]),
         "        $result.PSObject.Properties.Name | Should -Contain 'Status'",
         "    }",
         "}"],
        ["Describe 'configuration fixture' {",
         "    It 'can be serialised to JSON' {",
         "        $config = [pscustomobject]@{ Name = '%s'; Port = %d }" % (c["Service"], c["Port"]),
         "        ($config | ConvertTo-Json) | Should -Not -BeNullOrEmpty",
         "    }",
         "}"],
        ["Describe 'error handling' {",
         "    It 'does not throw for a missing optional file' {",
         "        { Get-Item -LiteralPath (Join-Path $env:TEMP 'missing-agent.ini') -ErrorAction SilentlyContinue } | Should -Not -Throw",
         "    }",
         "}"],
        ["Describe 'tagging' {",
         "    It 'applies the requested tag' {",
         "        $tag = @{ Environment = 'Test' }",
         "        $tag.Environment | Should -Be 'Test'",
         "    }",
         "}"],
    ]
    body = _pad(rng, body, 165, pad_blocks)
    return _render(body)


# ---------------------------------------------------------------------------
# 8. Reusable module with exported functions
# ---------------------------------------------------------------------------


def _module_ctx(rng):
    family = _pick(rng, ["Contoso", "Adatum", "Infra"])
    noun = _pick(rng, ["Inventory", "Endpoint", "Node", "Service"])
    return {
        "Family": family,
        "Module": family + "." + noun,
        "Get": "Get-%s%s" % (family, noun),
        "Set": "Set-%s%s" % (family, noun + "Tag"),
        "Test": "Test-%s%s" % (family, noun + "Health"),
        "Private": "Resolve-%sPath" % family,
        "Env": _pick(rng, _ENVS),
        "Version": "%d.%d.%d" % (_int(rng, 1, 4), _int(rng, 0, 9), _int(rng, 0, 9)),
    }


def _module_help(rng, synopsis, params):
    out = ["    <#", "    .SYNOPSIS", "        " + synopsis]
    if _chance(rng, 0.6):
        out += ["    .DESCRIPTION", "        Returns data for the requested objects."]
    for p, desc in params:
        out += ["    .PARAMETER " + p, "        " + desc]
    out.append("    #>")
    return out


def _module_function_get(rng, c, full=True):
    out = ["function %s {" % c["Get"]]
    if full:
        out += _module_help(rng, "Returns %s inventory records." % c["Family"],
                            [("Name", "One or more object names."),
                             ("Environment", "Target environment.")])
    out += ["    [CmdletBinding()]",
            "    [OutputType([pscustomobject])]",
            "    param(",
            "        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]",
            "        [string[]]$Name,",
            "",
            "        [ValidateSet('Dev', 'Test', 'Prod')]",
            "        [string]$Environment = '%s'" % c["Env"],
            "    )",
            "",
            "    begin {",
            "        $results = [System.Collections.Generic.List[object]]::new()",
            "    }",
            "",
            "    process {",
            "        foreach ($item in $Name) {",
            "            $results.Add([pscustomobject]@{",
            "                Name        = $item",
            "                Environment = $Environment",
            "                QueriedAt   = Get-Date",
            "            })",
            "        }",
            "    }",
            "",
            "    end {",
            "        $results",
            "    }",
            "}"]
    return out


def _module_function_set(rng, c, full=True):
    out = ["function %s {" % c["Set"]]
    if full:
        out += _module_help(rng, "Applies a tag to an existing object.",
                            [("Name", "Object to tag."), ("Tag", "Tag value.")])
    out += ["    [CmdletBinding(SupportsShouldProcess = $true)]",
            "    param(",
            "        [Parameter(Mandatory = $true)]",
            "        [string]$Name,",
            "",
            "        [Parameter(Mandatory = $true)]",
            "        [string]$Tag",
            "    )",
            "",
            "    if ($PSCmdlet.ShouldProcess($Name, 'Apply tag')) {",
            "        Write-Verbose (\"Tagging {0} with {1}\" -f $Name, $Tag)",
            "        [pscustomobject]@{ Name = $Name; Tag = $Tag; UpdatedAt = Get-Date }",
            "    }",
            "}"]
    return out


def _module_function_test(rng, c, full=True):
    out = ["function %s {" % c["Test"]]
    if full:
        out += _module_help(rng, "Tests whether an object answers on its management port.",
                            [("Name", "Object to probe."), ("Port", "TCP port to probe.")])
    out += ["    [CmdletBinding()]",
            "    param(",
            "        [Parameter(Mandatory = $true)]",
            "        [string]$Name,",
            "",
            "        [int]$Port = 5985",
            "    )",
            "",
            "    $client = New-Object System.Net.Sockets.TcpClient",
            "    try {",
            "        $async = $client.BeginConnect($Name, $Port, $null, $null)",
            "        $connected = $async.AsyncWaitHandle.WaitOne(2000)",
            "        return ($connected -and $client.Connected)",
            "    }",
            "    catch {",
            "        return $false",
            "    }",
            "    finally {",
            "        $client.Close()",
            "    }",
            "}"]
    return out


def _module_private(rng, c):
    return ["function %s {" % c["Private"],
            "    [CmdletBinding()]",
            "    param(",
            "        [Parameter(Mandatory = $true)]",
            "        [string]$Path",
            "    )",
            "",
            "    if ([string]::IsNullOrWhiteSpace($Path)) {",
            "        throw 'Path must not be empty.'",
            "    }",
            "    return [System.IO.Path]::GetFullPath($Path)",
            "}"]


def build_module_export(rng: random.Random) -> str:
    tier = _tier(rng)
    c = _module_ctx(rng)
    pre, _ = _preamble(
        rng,
        synopsis="%s module with the exported inventory, tagging and health commands." % c["Module"],
        description=[
            "The module keeps a small in-memory cache and a default timeout so callers "
            "do not have to pass the same values on every call.",
        ],
        examples=["Import-Module .\\%s.psd1 -Force" % c["Module"],
                  "%s -Name 'srv01' -Environment Prod" % c["Get"]],
        settings=[],
        compact=(tier == "short"),
        help_p=0.35,
        param_p=0.0,
        requires_p=0.45,
    )
    head = list(pre)
    if tier != "short":
        head.extend(_extras(rng))
    head = _sec(rng, head,
                ["$script:DefaultTimeout = %d" % _pick(rng, [10, 30, 60]),
                 "$script:ModuleVersion = '%s'" % c["Version"]])

    if tier == "short":
        lines = _sec(rng, head,
                     ["function %s {" % c["Get"],
                      "    [CmdletBinding()]",
                      "    param(",
                      "        [Parameter(Mandatory = $true)]",
                      "        [string]$Name",
                      "    )",
                      "",
                      "    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }",
                      "}"],
                     ["Export-ModuleMember -Function %s" % c["Get"]])
        return _render(lines)

    body = _sec(rng, head, _module_function_get(rng, c, full=True),
                _module_function_set(rng, c, full=True))

    if tier == "medium":
        body = _sec(rng, body, _module_function_test(rng, c, full=False))
        body = _pad(rng, body, 52, [])
        body = _sec(rng, body,
                    ["Export-ModuleMember -Function %s, %s, %s" % (c["Get"], c["Set"], c["Test"])])
        return _render(body)

    body = _sec(rng, body, _module_function_test(rng, c, full=True))
    body = _sec(rng, body, _module_private(rng, c))
    body = _sec(rng, body,
                ["function %s-Cache {" % c["Family"],
                 "    [CmdletBinding()]",
                 "    param([string]$Key, [object]$Value)",
                 "",
                 "    if (-not $script:Cache) {",
                 "        $script:Cache = @{}",
                 "    }",
                 "    if ($PSBoundParameters.ContainsKey('Value')) {",
                 "        $script:Cache[$Key] = $Value",
                 "    }",
                 "    return $script:Cache[$Key]",
                 "}"])
    body = _sec(rng, body,
                ["function Get-%sModuleInfo {" % c["Family"],
                 "    [CmdletBinding()]",
                 "    param()",
                 "",
                 "    [pscustomobject]@{",
                 "        Module      = '%s'" % c["Module"],
                 "        Version     = $script:ModuleVersion",
                 "        Timeout     = $script:DefaultTimeout",
                 "        Exported    = @('%s', '%s', '%s')" % (c["Get"], c["Set"], c["Test"]),
                 "    }",
                 "}"])
    pad_blocks = [
        ["$script:Cache = @{}",
         "Write-Verbose ('Cache initialised for {0}' -f '%s')" % c["Module"]],
        ["$script:ExportedFunctions = @('%s', '%s', '%s')" % (c["Get"], c["Set"], c["Test"]),
         "Write-Verbose ('Exporting {0} functions' -f $script:ExportedFunctions.Count)"],
        ["if ($ExecutionContext.SessionState.Module) {",
         "    Write-Verbose 'Module session detected.'",
         "}",
         "else {",
         "    Write-Verbose 'Script session detected.'",
         "}"],
        ["$script:ModuleRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }",
         "Write-Verbose ('Module root: {0}' -f $script:ModuleRoot)"],
        ["Write-Verbose ('Loaded module {0} version {1}' -f '%s', $script:ModuleVersion)" % c["Module"]],
    ]
    body = _pad(rng, body, 162, pad_blocks)
    body = _sec(rng, body,
                ["Export-ModuleMember -Function %s, %s, %s, Get-%sModuleInfo"
                 % (c["Get"], c["Set"], c["Test"], c["Family"])])
    return _render(body)


# ---------------------------------------------------------------------------
# 9. Windows installer / deployment script
# ---------------------------------------------------------------------------


def _install_ctx(rng):
    product = _pick(rng, ["ContosoAgent", "AdatumCollector", "InfraRelay"])
    ver = "%d.%d.%d" % (_int(rng, 3, 6), _int(rng, 0, 9), _int(rng, 0, 9))
    return {
        "Product": product,
        "Version": ver,
        "InstallerPath": "C:\\Scripts\\packages\\%s-%s.msi" % (product, ver),
        "InstallDir": "C:\\Program Files\\%s\\%s" % ("Contoso" if "Contoso" in product else "Adatum", product),
        "ServiceName": product,
        "Port": _pick(rng, [8080, 8443, 9443, 9000]),
        "LogPath": "C:\\Logs\\install-%s-%s.log" % (product.lower(), _date(rng)),
        "RegPath": "HKLM:\\SOFTWARE\\%s\\%s" % ("Contoso" if "Contoso" in product else "Adatum", product),
        "RuleName": product + " Inbound",
        "TimeoutSec": _pick(rng, [60, 90, 120, 180]),
        "Script": _pick(rng, ["Install-Agent.ps1", "Deploy-Collector.ps1",
                              "Invoke-AgentSetup.ps1"]),
        "MailTo": "deploy@" + _pick(rng, _DOMAINS),
    }


def _install_settings(rng, c):
    return [
        _mk("InstallerPath", "string", _q(rng, c["InstallerPath"]), _attrs(rng, "help")),
        _mk("ServiceName", "string", _q(rng, c["ServiceName"])),
        _mk("Port", "int", str(c["Port"]), _attrs(rng, "optional", vrange=(1024, 65535))),
        _mk("TimeoutSec", "int", str(c["TimeoutSec"])),
        _mk("LogPath", "string", _q(rng, c["LogPath"])),
        _mk("RuleName", "string", _q(rng, c["RuleName"])),
    ]


def _install_admin_check(rng):
    return ["$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())",
            "if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {",
            "    throw 'This script must run from an elevated PowerShell session.'",
            "}"]


def _install_msi(rng, c):
    return ["if (-not (Test-Path -LiteralPath $InstallerPath)) {",
            "    throw (\"Installer package not found: {0}\" -f $InstallerPath)",
            "}",
            "$arguments = @('/i', $InstallerPath, '/qn', '/norestart', '/L*v', $LogPath)",
            "$process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $arguments -Wait -PassThru",
            "if ($process.ExitCode -ne 0) {",
            "    throw (\"Installation failed with exit code {0}\" -f $process.ExitCode)",
            "}",
            "Write-Verbose (\"msiexec completed with exit code {0}\" -f $process.ExitCode)"]


def _install_service(rng):
    return ["$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue",
            "if (-not $service) {",
            "    throw (\"Service {0} was not registered by the installer\" -f $ServiceName)",
            "}",
            "if ($service.Status -ne 'Running') {",
            "    Set-Service -Name $ServiceName -StartupType Automatic",
            "    Start-Service -Name $ServiceName",
            "    Write-Verbose (\"Started service {0}\" -f $ServiceName)",
            "}"]


def _install_health(rng):
    return ["$healthUri = \"http://localhost:$Port/health\"",
            "$deadline = (Get-Date).AddSeconds($TimeoutSec)",
            "do {",
            "    try {",
            "        $response = Invoke-WebRequest -Uri $healthUri -UseBasicParsing -TimeoutSec 5",
            "    }",
            "    catch {",
            "        $response = $null",
            "    }",
            "    if (-not $response) {",
            "        Start-Sleep -Seconds 2",
            "    }",
            "} while (-not $response -and (Get-Date) -lt $deadline)",
            "if (-not $response) {",
            "    throw (\"Health endpoint {0} did not respond in time\" -f $healthUri)",
            "}",
            "Write-Host (\"Health check returned {0}\" -f $response.StatusCode) -ForegroundColor Green"]


def build_installer_deploy(rng: random.Random) -> str:
    tier = _tier(rng)
    c = _install_ctx(rng)
    settings = _install_settings(rng, c)
    compact = tier == "short"
    pre, _ = _preamble(
        rng,
        synopsis="Installs the %s package and validates the resulting service." % c["Product"],
        description=[
            "Runs the vendor MSI unattended, ensures the service is registered, opens the "
            "local firewall port and waits for the health endpoint to answer.",
            "Every step writes to the installation log so a failed rollout can be traced "
            "on the target host.",
        ],
        examples=[".\\" + c["Script"] + " -InstallerPath " + c["InstallerPath"],
                  ".\\" + c["Script"] + " -Port %d" % c["Port"]],
        settings=settings,
        compact=compact,
    )
    lines = list(pre)
    if tier != "short":
        lines.extend(_extras(rng))

    if tier == "short":
        lines = _sec(rng, lines, _install_admin_check(rng),
                     ["if (-not (Test-Path -LiteralPath $InstallerPath)) {",
                      "    throw (\"Installer package not found: {0}\" -f $InstallerPath)",
                      "}",
                      "$process = Start-Process -FilePath 'msiexec.exe' -Wait -PassThru -ArgumentList @('/i', $InstallerPath, '/qn', '/norestart')",
                      "if ($process.ExitCode -ne 0) {",
                      "    throw (\"Installation failed with exit code {0}\" -f $process.ExitCode)",
                      "}",
                      "Get-Service -Name $ServiceName | Select-Object Name, Status"])
        return _render(lines)

    body = _sec(rng, lines, _install_admin_check(rng), _install_msi(rng, c), _install_service(rng))

    if tier == "medium":
        body = _sec(rng, body, _install_health(rng),
                    ["$installed = Get-Service -Name $ServiceName",
                     "Write-Host (\"{0} {1} is {2}\" -f $installed.Name, $installed.DisplayName, $installed.Status) -ForegroundColor Green"])
        if _chance(rng, 0.5):
            body = _sec(rng, body, _install_registry(rng, c), _install_firewall(rng, c))
        body = _pad(rng, body, 48, [])
        return _render(body)

    body = _sec(rng, body, _install_registry(rng, c), _install_firewall(rng, c),
                _install_health(rng))
    body = _sec(rng, body,
                ["$installed = Get-Service -Name $ServiceName",
                 "$details = [pscustomobject]@{",
                 "    Product   = '%s'" % c["Product"],
                 "    Version   = '%s'" % c["Version"],
                 "    Service   = $installed.Name",
                 "    Status    = $installed.Status",
                 "    Port      = $Port",
                 "    Installer = $InstallerPath",
                 "    LogPath   = $LogPath",
                 "    InstalledAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')",
                 "}",
                 "$details | ConvertTo-Json -Depth 3 | Set-Content -Path ($LogPath.Replace('.log', '.json')) -Encoding UTF8"])
    body = _sec(rng, body, _html_style(rng),
                ["@($details) | ConvertTo-Html -Title 'Installation summary' -Head $style |",
                 "    Set-Content -Path ($LogPath.Replace('.log', '.html')) -Encoding UTF8"])
    body = _sec(rng, body,
                ["$MailTo = %s" % _q(rng, c["MailTo"]),
                 "$subject = \"%s %s deployed on $env:COMPUTERNAME\"" % (c["Product"], c["Version"])],
                _mail_block(rng, "$MailTo", _q(rng, "deploy@" + c["MailTo"].split("@", 1)[1]),
                            _q(rng, "smtp." + c["MailTo"].split("@", 1)[1]), "$subject",
                            _q(rng, "Installation completed and the service is responding."),
                            _pick(rng, [25, 587])))
    body = _sec(rng, body,
                ["$stale = Get-ChildItem -Path $env:TEMP -Filter '%s-*' -Directory -ErrorAction SilentlyContinue |" % c["Product"].lower(),
                 "    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }",
                 "foreach ($dir in $stale) {",
                 "    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue",
                 "}",
                 "Write-Host (\"Deployment finished for {0}\" -f $ServiceName) -ForegroundColor Green"])

    pad_blocks = [
        ["$uninstallKey = 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall'",
         "$entry = Get-ChildItem -Path $uninstallKey -ErrorAction SilentlyContinue |",
         "    ForEach-Object { Get-ItemProperty $_.PSPath } |",
         "    Where-Object { $_.DisplayName -like '%s*' } | Select-Object -First 1" % c["Product"],
         "if ($entry) {",
         "    Write-Verbose (\"Registered version: {0}\" -f $entry.DisplayVersion)",
         "}"],
        ["$agentConfig = Join-Path $env:ProgramData '%s\\agent.json'" % c["Product"],
         "if (Test-Path -LiteralPath (Split-Path -Parent $agentConfig)) {",
         "    Write-Verbose (\"Config folder present: {0}\" -f (Split-Path -Parent $agentConfig))",
         "}"],
        ["$logTail = Get-Content -LiteralPath $LogPath -Tail 5 -ErrorAction SilentlyContinue",
         "if ($logTail) {",
         "    Write-Verbose (\"Last log lines: {0}\" -f ($logTail -join ' | '))",
         "}"],
        ["$rebootPending = Test-Path -Path 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Component Based Servicing\\RebootPending'",
         "if ($rebootPending) {",
         "    Write-Warning 'A reboot is pending before the next deployment.'",
         "}"],
        ["$disk = Get-PSDrive -Name C",
         "Write-Verbose (\"Free space on C: {0} GB\" -f [math]::Round($disk.Free / 1GB, 1))"],
    ]
    body = _pad(rng, body, 165, pad_blocks)
    return _render(body)


def _install_registry(rng, c):
    return ["$regPath = %s" % _q(rng, c["RegPath"]),
            "if (-not (Test-Path -Path $regPath)) {",
            "    New-Item -Path $regPath -Force | Out-Null",
            "}",
            "New-ItemProperty -Path $regPath -Name 'InstallVersion' -Value '%s' -PropertyType String -Force | Out-Null" % c["Version"],
            "New-ItemProperty -Path $regPath -Name 'InstallPath' -Value $InstallerPath -PropertyType String -Force | Out-Null"]


def _install_firewall(rng, c):
    return ["$rule = Get-NetFirewallRule -DisplayName %s -ErrorAction SilentlyContinue" % _q(rng, c["RuleName"]),
            "if (-not $rule) {",
            "    New-NetFirewallRule -DisplayName %s -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null" % _q(rng, c["RuleName"]),
            "    Write-Verbose 'Firewall rule created.'",
            "}"]


# ---------------------------------------------------------------------------
# 10. WinForms GUI helper
# ---------------------------------------------------------------------------


def _gui_ctx(rng):
    title = _pick(rng, ["Contoso Agent Console", "Server Check Tool", "Adatum Ops Panel",
                        "Ops Quick Check", "Agent Troubleshooter", "Infra Status Board",
                        "Service Probe", "Contoso Desk Helper", "Admin Toolkit"])
    return {
        "Title": title,
        "Width": _int(rng, 32, 45) * 20,
        "Height": _int(rng, 22, 30) * 20,
        "Button": _pick(rng, ["Check", "Probe", "Refresh", "Test", "Connectivity"]),
        "Service": _pick(rng, ["Spooler", "W3SVC", "WinRM", "Dnscache", "MSSQLSERVER"]),
        "SaveName": _pick(rng, ["server-check.csv", "health-export.csv",
                                "console-output.csv", "agent-state.csv"]),
        "Servers": rng.sample(_SERVERS, _int(rng, 3, 5)),
        "OutputPath": "C:\\Reports\\gui-check-" + _date(rng) + ".csv",
        "Script": _pick(rng, ["Start-AgentConsole.ps1", "Show-ServerPanel.ps1",
                              "Open-OpsTool.ps1"]),
    }


def build_winforms_tool(rng: random.Random) -> str:
    tier = _tier(rng)
    c = _gui_ctx(rng)
    pre, _ = _preamble(
        rng,
        synopsis="Small WinForms console that checks the state of the configured servers.",
        description=[
            "Builds the form in code, wires the button handlers and keeps the last result "
            "set in memory so it can be exported to CSV from the toolbar.",
        ],
        examples=[".\\" + c["Script"]],
        settings=[],
        compact=(tier == "short"),
        help_p=0.3,
        param_p=0.0,
    )
    head = list(pre)
    if tier != "short":
        head.extend(_extras(rng))
    head = _sec(rng, head,
                ["Add-Type -AssemblyName System.Windows.Forms",
                 "Add-Type -AssemblyName System.Drawing",
                 "[System.Windows.Forms.Application]::EnableVisualStyles()"])

    if tier == "short":
        lines = _sec(rng, head,
                     ["$form = New-Object System.Windows.Forms.Form",
                      "$form.Text = %s" % _q(rng, c["Title"]),
                      "$form.Size = New-Object System.Drawing.Size(%d, %d)" % (c["Width"], c["Height"]),
                      "$form.StartPosition = 'CenterScreen'",
                      "",
                      "$button = New-Object System.Windows.Forms.Button",
                      "$button.Text = %s" % _q(rng, c["Button"]),
                      "$button.Location = New-Object System.Drawing.Point(18, 18)",
                      "$button.Add_Click({",
                      "    Get-Service -Name %s | Select-Object Name, Status | Out-String | Write-Host" % _q(rng, c["Service"]),
                      "})",
                      "$form.Controls.Add($button)",
                      "",
                      "[void]$form.ShowDialog()",
                      "$form.Dispose()"])
        return _render(lines)

    body = _sec(rng, head, _gui_base(rng, c), _gui_status_label(rng))

    if tier == "medium":
        body = _sec(rng, body, _gui_button(rng, c), _gui_listbox(rng, c),
                    ["$form.Add_Shown({ $textBox.Focus() })",
                     "[void]$form.ShowDialog()",
                     "$form.Dispose()"])
        body = _pad(rng, body, 52, [])
        return _render(body)

    body = _sec(rng, body, _gui_base(rng, c), _gui_status_label(rng),
                _gui_button(rng, c), _gui_grid(rng, c), _gui_save(rng, c), _gui_menu(rng, c),
                _gui_timer(rng, c))
    body = _sec(rng, body,
                ["$form.Add_Shown({ $textBox.Focus() })",
                 "[void]$form.ShowDialog()",
                 "$form.Dispose()"])
    body = _sec(rng, body,
                ["Write-Host (\"Console closed at {0}\" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor DarkGray"])

    pad_blocks = [
        ["$toolTip = New-Object System.Windows.Forms.ToolTip",
         "$toolTip.SetToolTip($textBox, 'Enter a short host name such as srv01.')",
         "$toolTip.SetToolTip($button, 'Runs the connectivity check.')"],
        ["$progress = New-Object System.Windows.Forms.ProgressBar",
         "$progress.Location = New-Object System.Drawing.Point(18, 410)",
         "$progress.Size = New-Object System.Drawing.Size(660, 18)",
         "$form.Controls.Add($progress)"],
        ["$aboutItem = New-Object System.Windows.Forms.ToolStripMenuItem",
         "$aboutItem.Text = 'About'",
         "$aboutItem.Add_Click({",
         "    [System.Windows.Forms.MessageBox]::Show('Contoso operations helper', 'About')",
         "})"],
        ["$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip",
         "$copyItem = New-Object System.Windows.Forms.ToolStripMenuItem",
         "$copyItem.Text = 'Copy'",
         "[void]$contextMenu.Items.Add($copyItem)",
         "$listBox.ContextMenuStrip = $contextMenu"],
        ["$form.KeyPreview = $true",
         "$form.Add_KeyDown({",
         "    if ($_.KeyCode -eq 'Escape') { $form.Close() }",
         "})"],
    ]
    body = _pad(rng, body, 165, pad_blocks)
    return _render(body)


def _gui_base(rng, c):
    return ["$form = New-Object System.Windows.Forms.Form",
            "$form.Text = %s" % _q(rng, c["Title"]),
            "$form.Size = New-Object System.Drawing.Size(%d, %d)" % (c["Width"], c["Height"]),
            "$form.StartPosition = 'CenterScreen'",
            "$form.FormBorderStyle = 'FixedDialog'",
            "$form.MaximizeBox = $false",
            "$form.MinimizeBox = $true",
            "",
            "$label = New-Object System.Windows.Forms.Label",
            "$label.Text = 'Server name'",
            "$label.Location = New-Object System.Drawing.Point(18, 24)",
            "$label.AutoSize = $true",
            "$form.Controls.Add($label)",
            "",
            "$textBox = New-Object System.Windows.Forms.TextBox",
            "$textBox.Location = New-Object System.Drawing.Point(120, 20)",
            "$textBox.Size = New-Object System.Drawing.Size(300, 24)",
            "$form.Controls.Add($textBox)",
            "",
            "$script:servers = @(%s)" % ", ".join("'%s'" % s for s in c["Servers"])]


def _gui_status_label(rng):
    return ["$statusLabel = New-Object System.Windows.Forms.Label",
            "$statusLabel.Text = 'Ready'",
            "$statusLabel.Location = New-Object System.Drawing.Point(440, 24)",
            "$statusLabel.AutoSize = $true",
            "$statusLabel.ForeColor = [System.Drawing.Color]::DimGray",
            "$form.Controls.Add($statusLabel)"]


def _gui_button(rng, c):
    return ["$button = New-Object System.Windows.Forms.Button",
            "$button.Text = %s" % _q(rng, c["Button"]),
            "$button.Location = New-Object System.Drawing.Point(620, 18)",
            "$button.Size = New-Object System.Drawing.Size(100, 28)",
            "$button.Add_Click({",
            "    $button.Enabled = $false",
            "    $statusLabel.Text = 'Checking ...'",
            "    try {",
            "        $reachable = Test-Connection -ComputerName $textBox.Text -Count 2 -Quiet",
            "        if ($reachable) {",
            "            $statusLabel.Text = 'Online'",
            "            [void]$listBox.Items.Add((\"{0} - online\" -f $textBox.Text))",
            "        }",
            "        else {",
            "            $statusLabel.Text = 'Offline'",
            "            [void]$listBox.Items.Add((\"{0} - offline\" -f $textBox.Text))",
            "        }",
            "    }",
            "    catch {",
            "        $statusLabel.Text = 'Error'",
            "        Write-Warning $_.Exception.Message",
            "    }",
            "    finally {",
            "        $button.Enabled = $true",
            "    }",
            "})",
            "$form.Controls.Add($button)",
            "",
            "$listBox = New-Object System.Windows.Forms.ListBox",
            "$listBox.Location = New-Object System.Drawing.Point(18, 64)",
            "$listBox.Size = New-Object System.Drawing.Size(700, 300)",
            "$form.Controls.Add($listBox)"]


def _gui_listbox(rng, c):
    return ["foreach ($server in $script:servers) {",
            "    [void]$listBox.Items.Add($server)",
            "}"]


def _gui_grid(rng, c):
    return ["$grid = New-Object System.Windows.Forms.DataGridView",
            "$grid.Location = New-Object System.Drawing.Point(18, 96)",
            "$grid.Size = New-Object System.Drawing.Size(700, 300)",
            "$grid.ReadOnly = $true",
            "$grid.AllowUserToAddRows = $false",
            "$grid.AutoSizeColumnsMode = 'Fill'",
            "$form.Controls.Add($grid)",
            "",
            "$table = New-Object System.Data.DataTable",
            "[void]$table.Columns.Add('Server')",
            "[void]$table.Columns.Add('Status')",
            "[void]$table.Columns.Add('CheckedAt')",
            "foreach ($server in $script:servers) {",
            "    [void]$table.Rows.Add($server, 'Unknown', (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))",
            "}",
            "$grid.DataSource = $table"]


def _gui_save(rng, c):
    return ["$saveButton = New-Object System.Windows.Forms.Button",
            "$saveButton.Text = 'Export CSV'",
            "$saveButton.Location = New-Object System.Drawing.Point(18, 410)",
            "$saveButton.Size = New-Object System.Drawing.Size(120, 28)",
            "$saveButton.Add_Click({",
            "    $dialog = New-Object System.Windows.Forms.SaveFileDialog",
            "    $dialog.Filter = 'CSV files (*.csv)|*.csv'",
            "    $dialog.FileName = %s" % _q(rng, c["SaveName"]),
            "    if ($dialog.ShowDialog() -eq 'OK') {",
            "        $table | Export-Csv -Path $dialog.FileName -NoTypeInformation -Encoding UTF8",
            "        $statusLabel.Text = 'Exported'",
            "    }",
            "})",
            "$form.Controls.Add($saveButton)"]


def _gui_menu(rng, c):
    return ["$menu = New-Object System.Windows.Forms.MenuStrip",
            "$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem",
            "$fileMenu.Text = 'File'",
            "$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem",
            "$exitItem.Text = 'Exit'",
            "$exitItem.Add_Click({ $form.Close() })",
            "[void]$fileMenu.DropDownItems.Add($exitItem)",
            "[void]$menu.Items.Add($fileMenu)",
            "$form.Controls.Add($menu)"]


def _gui_timer(rng, c):
    return ["$timer = New-Object System.Windows.Forms.Timer",
            "$timer.Interval = %d" % (_pick(rng, [30, 60, 120]) * 1000),
            "$timer.Add_Tick({",
            "    $statusLabel.Text = 'Last refresh: ' + (Get-Date).ToString('HH:mm:ss')",
            "})",
            "$timer.Start()"]


# ---------------------------------------------------------------------------
# 11. Scheduled maintenance: TEMP cleanup
# ---------------------------------------------------------------------------


def _cleanup_ctx(rng):
    return {
        "TempRoot": "$env:TEMP",
        "AgeDays": _pick(rng, [3, 7, 14, 21, 30]),
        "MinSizeMB": _pick(rng, [1, 2, 5, 10]),
        "LogPath": "C:\\Logs\\temp-cleanup-" + _date(rng) + ".log",
        "TaskName": _pick(rng, ["Contoso-TempCleanup", "Ops-TempMaintenance",
                                "Weekly-TempSweep"]),
        "Script": _pick(rng, ["Clear-TempFiles.ps1", "Invoke-TempCleanup.ps1",
                              "Start-TempMaintenance.ps1"]),
        "MailTo": "ops@" + _pick(rng, _DOMAINS),
        "SmtpServer": "smtp." + _pick(rng, _DOMAINS),
    }


def _cleanup_settings(rng, c):
    return [
        _mk("TempRoot", "string", c["TempRoot"], _attrs(rng, "help", alias="ScratchPath")),
        _mk("AgeDays", "int", str(c["AgeDays"]), _attrs(rng, "optional", vrange=(1, 90))),
        _mk("MinSizeMB", "int", str(c["MinSizeMB"])),
        _mk("LogPath", "string", _q(rng, c["LogPath"])),
        _mk("DryRun", "switch", None),
    ]


def _cleanup_scan(rng):
    return ["if (-not (Test-Path -LiteralPath $TempRoot)) {",
            "    throw (\"Temp path not found: {0}\" -f $TempRoot)",
            "}",
            "$cutoff = (Get-Date).AddDays(-$AgeDays)",
            "$allFiles = @(Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -File -ErrorAction SilentlyContinue)",
            "$beforeMB = [math]::Round((($allFiles | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)",
            "$stale = $allFiles | Where-Object {",
            "    $_.LastWriteTime -lt $cutoff -and $_.Length -ge ($MinSizeMB * 1MB)",
            "}",
            "$reclaimMB = [math]::Round((($stale | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)"]


def _cleanup_delete(rng):
    return ["foreach ($file in $stale) {",
            "    if (-not $file.FullName.StartsWith($TempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {",
            "        continue",
            "    }",
            "    Remove-Item -LiteralPath $file.FullName -Force -WhatIf:$DryRun -ErrorAction SilentlyContinue",
            "}",
            "$remainingMB = [math]::Round((@(Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -File -ErrorAction SilentlyContinue) |",
            "    Measure-Object -Property Length -Sum).Sum / 1MB, 1)"]


def _cleanup_dirs(rng):
    return ["$emptyDirs = Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -Directory -ErrorAction SilentlyContinue |",
            "    Where-Object { @(Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0 }",
            "foreach ($dir in $emptyDirs) {",
            "    if ($dir.LastWriteTime -lt $cutoff) {",
            "        Remove-Item -LiteralPath $dir.FullName -Force -WhatIf:$DryRun -ErrorAction SilentlyContinue",
            "    }",
            "}"]


def build_temp_cleanup(rng: random.Random) -> str:
    tier = _tier(rng)
    c = _cleanup_ctx(rng)
    settings = _cleanup_settings(rng, c)
    compact = tier == "short"
    pre, _ = _preamble(
        rng,
        synopsis="Removes stale scratch files from the current user TEMP folder.",
        description=[
            "Selects files older than the configured age and larger than the size "
            "threshold, then deletes them from the TEMP folder only.",
            "Every candidate is re-checked against the TEMP prefix before removal, so a "
            "reparse point cannot redirect the sweep to another location.",
        ],
        examples=[".\\" + c["Script"] + " -AgeDays %d" % c["AgeDays"],
                  ".\\" + c["Script"] + " -DryRun -Verbose"],
        settings=settings,
        compact=compact,
    )
    lines = list(pre)
    if tier != "short":
        lines.extend(_extras(rng))

    if tier == "short":
        lines = _sec(rng, lines,
                     ["$cutoff = (Get-Date).AddDays(-$AgeDays)",
                      "$stale = Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -File -ErrorAction SilentlyContinue |",
                      "    Where-Object { $_.LastWriteTime -lt $cutoff -and $_.Length -ge ($MinSizeMB * 1MB) }",
                      "foreach ($file in $stale) {",
                      "    Remove-Item -LiteralPath $file.FullName -Force -WhatIf:$DryRun -ErrorAction SilentlyContinue",
                      "}",
                      "$reclaimMB = [math]::Round((($stale | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)",
                      "Write-Host (\"Removed {0} files, reclaimed {1} MB\" -f @($stale).Count, $reclaimMB) -ForegroundColor Green"])
        return _render(lines)

    body = _sec(rng, lines, _cleanup_scan(rng),
                ["Write-Host (\"Before: {0} MB | Reclaimable: {1} MB across {2} files\" -f $beforeMB, $reclaimMB, @($stale).Count) -ForegroundColor Cyan"])

    if tier == "medium":
        body = _sec(rng, body, _cleanup_delete(rng),
                    ["Write-Host (\"After cleanup: {0} MB\" -f $remainingMB) -ForegroundColor Green",
                     "$line = \"{0} reclaimed {1} MB from {2} files\" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $reclaimMB, @($stale).Count",
                     "Add-Content -Path $LogPath -Value $line -Encoding UTF8"])
        if _chance(rng, 0.5):
            body = _sec(rng, body, _cleanup_dirs(rng))
        body = _pad(rng, body, 48, [])
        return _render(body)

    log_name = _pick(rng, ["Write-CleanupLog", "Write-MaintenanceLog", "Write-LogEntry"])
    body = _sec(rng, body,
                _log_function(rng, log_name, "$LogPath"),
                ["& %s -Message (\"Cleanup started for {0}\" -f $TempRoot) -Level INFO" % log_name],
                _cleanup_delete(rng), _cleanup_dirs(rng))
    body = _sec(rng, body,
                ["$byExtension = $stale | Group-Object -Property Extension |",
                 "    Sort-Object -Property Count -Descending | Select-Object -First 5",
                 "$byExtension | Format-Table Name, Count -AutoSize"])
    body = _sec(rng, body,
                ["$report = [pscustomobject]@{",
                 "    TempRoot    = $TempRoot",
                 "    AgeDays     = $AgeDays",
                 "    Files       = @($stale).Count",
                 "    ReclaimedMB = $reclaimMB",
                 "    RemainingMB = $remainingMB",
                 "    CompletedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')",
                 "}",
                 "$report | ConvertTo-Json -Depth 3 | Set-Content -Path $LogPath.Replace('.log', '.json') -Encoding UTF8"])
    body = _sec(rng, body,
                ["$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -File C:\\Scripts\\Clear-TempFiles.ps1'",
                 "$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At %s" % _q(rng, _clock(rng)),
                 "Register-ScheduledTask -TaskName %s -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null" % _q(rng, c["TaskName"])])
    body = _sec(rng, body,
                ["$MailTo = %s" % _q(rng, c["MailTo"])],
                _mail_block(rng, "$MailTo", _q(rng, "ops@" + c["MailTo"].split("@", 1)[1]),
                            _q(rng, c["SmtpServer"]),
                            _q(rng, "TEMP cleanup summary"),
                            _q(rng, "The scheduled TEMP sweep completed. See the JSON report on the host."),
                            _pick(rng, [25, 587])))
    body = _sec(rng, body,
                ["& %s -Message (\"Cleanup finished: {0} MB reclaimed\" -f $reclaimMB) -Level INFO" % log_name,
                 "Write-Host (\"Cleanup finished on {0}\" -f $env:COMPUTERNAME) -ForegroundColor Green"])

    pad_blocks = [
        ["$largest = $stale | Sort-Object -Property Length -Descending | Select-Object -First 5",
         "$largest | Format-Table Name, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize"],
        ["$recent = $allFiles | Where-Object { $_.LastWriteTime -ge $cutoff }",
         "Write-Verbose (\"Files kept because they are recent: {0}\" -f @($recent).Count)"],
        ["$tempDrive = Get-PSDrive -Name ($TempRoot.Substring(0, 1)) -ErrorAction SilentlyContinue",
         "if ($tempDrive) {",
         "    Write-Verbose (\"Free space: {0} GB\" -f [math]::Round($tempDrive.Free / 1GB, 1))",
         "}"],
        ["$locked = @($stale | Where-Object { $_.IsReadOnly })",
         "Write-Verbose (\"Read-only candidates skipped: {0}\" -f $locked.Count)"],
        ["$sessionTemp = Join-Path $env:TEMP 'cleanup-session'",
         "Write-Verbose (\"Session folder: {0}\" -f $sessionTemp)"],
    ]
    body = _pad(rng, body, 165, pad_blocks)
    return _render(body)


# ---------------------------------------------------------------------------
# 12. Service health monitor
# ---------------------------------------------------------------------------


def _monitor_ctx(rng):
    domain = _pick(rng, _DOMAINS)
    return {
        "Servers": rng.sample(_SERVERS, _int(rng, 3, 5)),
        "Services": rng.sample(["W3SVC", "WinRM", "Spooler", "DNS", "MSSQLSERVER",
                                "Dhcp", "SNMP"], _int(rng, 2, 4)),
        "Port": _pick(rng, [5985, 5986, 443, 3389]),
        "TimeoutMs": _pick(rng, [1000, 2000, 3000, 5000]),
        "ReportPath": "C:\\Reports\\service-health-" + _date(rng) + ".csv",
        "MailTo": "monitoring@" + domain,
        "SmtpServer": "smtp." + domain,
        "Script": _pick(rng, ["Test-ServiceHealth.ps1", "Get-ServerHealth.ps1",
                              "Invoke-HealthCheck.ps1"]),
    }


def _monitor_settings(rng, c):
    servers = ", ".join("'%s'" % s for s in c["Servers"])
    services = ", ".join("'%s'" % s for s in c["Services"])
    return [
        _mk("Servers", "string[]", "@(%s)" % servers, _attrs(rng, "help")),
        _mk("Services", "string[]", "@(%s)" % services),
        _mk("Port", "int", str(c["Port"]), _attrs(rng, "optional", vrange=(1, 65535))),
        _mk("TimeoutMilliseconds", "int", str(c["TimeoutMs"])),
        _mk("ReportPath", "string", _q(rng, c["ReportPath"])),
    ]


def _monitor_probe(rng):
    return ["function Test-ServerPort {",
            "    [CmdletBinding()]",
            "    param(",
            "        [Parameter(Mandatory = $true)]",
            "        [string]$ComputerName,",
            "",
            "        [int]$Port = 5985,",
            "        [int]$TimeoutMilliseconds = 2000",
            "    )",
            "",
            "    $client = New-Object System.Net.Sockets.TcpClient",
            "    try {",
            "        $async = $client.BeginConnect($ComputerName, $Port, $null, $null)",
            "        $connected = $async.AsyncWaitHandle.WaitOne($TimeoutMilliseconds)",
            "        return ($connected -and $client.Connected)",
            "    }",
            "    catch {",
            "        return $false",
            "    }",
            "    finally {",
            "        $client.Close()",
            "    }",
            "}"]


def _monitor_collect(rng):
    return ["$results = foreach ($srv in $Servers) {",
            "    if (-not (Test-ServerPort -ComputerName $srv -Port $Port -TimeoutMilliseconds $TimeoutMilliseconds)) {",
            "        [pscustomobject]@{",
            "            Server    = $srv",
            "            Service   = '*'",
            "            Status    = 'Unreachable'",
            "            CheckedAt = Get-Date",
            "        }",
            "        continue",
            "    }",
            "    foreach ($svc in $Services) {",
            "        $service = Get-Service -ComputerName $srv -Name $svc -ErrorAction SilentlyContinue",
            "        [pscustomobject]@{",
            "            Server    = $srv",
            "            Service   = $svc",
            "            Status    = $(if ($service) { $service.Status } else { 'NotFound' })",
            "            CheckedAt = Get-Date",
            "        }",
            "    }",
            "}"]


def build_service_monitor(rng: random.Random) -> str:
    tier = _tier(rng)
    c = _monitor_ctx(rng)
    settings = _monitor_settings(rng, c)
    compact = tier == "short"
    pre, _ = _preamble(
        rng,
        synopsis="Checks the configured Windows services on a list of servers.",
        description=[
            "Probes the management port first, then queries each service and records the "
            "state in a result set that is exported to CSV.",
            "Any service that is not Running triggers a single alert mail with the "
            "offending rows.",
        ],
        examples=[".\\" + c["Script"] + " -Servers " + c["Servers"][0] + ", " + c["Servers"][1],
                  ".\\" + c["Script"] + " -Services " + c["Services"][0]],
        settings=settings,
        compact=compact,
    )
    lines = list(pre)
    if tier != "short":
        lines.extend(_extras(rng))

    if tier == "short":
        lines = _sec(rng, lines,
                     ["$results = foreach ($srv in $Servers) {",
                      "    foreach ($svc in $Services) {",
                      "        $service = Get-Service -ComputerName $srv -Name $svc -ErrorAction SilentlyContinue",
                      "        [pscustomobject]@{",
                      "            Server  = $srv",
                      "            Service = $svc",
                      "            Status  = $(if ($service) { $service.Status } else { 'NotFound' })",
                      "        }",
                      "    }",
                      "}",
                      "$results | Format-Table -AutoSize"])
        return _render(lines)

    body = _sec(rng, lines, _monitor_probe(rng), _monitor_collect(rng))

    if tier == "medium":
        body = _sec(rng, body,
                    _csv_export(rng, "$results", "$ReportPath"),
                    ["$down = @($results | Where-Object { $_.Status -ne 'Running' })",
                     "$down | Format-Table -AutoSize",
                     "Write-Host (\"{0} checks, {1} not running\" -f @($results).Count, $down.Count) -ForegroundColor Cyan"])
        if _chance(rng, 0.5):
            body = _sec(rng, body, _monitor_mail(rng, c))
        body = _pad(rng, body, 52, [])
        return _render(body)

    body = _sec(rng, body,
                ["$down = @($results | Where-Object { $_.Status -ne 'Running' })",
                 "$unreachable = @($results | Where-Object { $_.Status -eq 'Unreachable' })"],
                ["$retry = @($down | Where-Object { $_.Service -ne '*' })",
                 "for ($attempt = 1; $attempt -le 2; $attempt++) {",
                 "    if (@($retry).Count -eq 0) { break }",
                 "    Start-Sleep -Seconds 5",
                 "    Write-Verbose (\"Retry {0}: {1} services still down\" -f $attempt, @($retry).Count)",
                 "    $retry = @($retry | Where-Object {",
                 "        (Get-Service -ComputerName $_.Server -Name $_.Service -ErrorAction SilentlyContinue).Status -ne 'Running'",
                 "    })",
                 "}"])
    body = _sec(rng, body,
                _csv_export(rng, "$results", "$ReportPath"),
                ["$down | Export-Csv -Path $ReportPath.Replace('.csv', '-down.csv') -NoTypeInformation -Encoding UTF8"])
    body = _sec(rng, body,
                ["$byServer = $results | Group-Object -Property Server | ForEach-Object {",
                 "    [pscustomobject]@{",
                 "        Server = $_.Name",
                 "        Checks = $_.Count",
                 "        Failed = @($_.Group | Where-Object { $_.Status -ne 'Running' }).Count",
                 "    }",
                 "}",
                 "$byServer | Format-Table -AutoSize"])
    body = _sec(rng, body, _monitor_mail(rng, c))
    body = _sec(rng, body,
                ["$history = $ReportPath.Replace('.csv', '-history.csv')",
                 "$results | Export-Csv -Path $history -NoTypeInformation -Append -Encoding UTF8",
                 "Write-Host (\"Health check complete: {0} of {1} services running\" -f (@($results).Count - $down.Count), @($results).Count) -ForegroundColor Green"])

    pad_blocks = [
        ["$osInfo = foreach ($srv in $Servers) {",
         "    [pscustomobject]@{",
         "        Server = $srv",
         "        Reachable = Test-ServerPort -ComputerName $srv -Port $Port",
         "    }",
         "}",
         "$osInfo | Format-Table -AutoSize"],
        ["$uptime = @($results | Where-Object { $_.Status -eq 'Running' }).Count",
         "Write-Verbose (\"Running checks: {0}\" -f $uptime)"],
        ["$dashboard = $results | Group-Object -Property Service | ForEach-Object {",
         "    [pscustomobject]@{ Service = $_.Name; Running = @($_.Group | Where-Object { $_.Status -eq 'Running' }).Count }",
         "}",
         "$dashboard | Format-Table -AutoSize"],
        ["$errorRows = $results | Where-Object { $_.Status -eq 'NotFound' }",
         "if (@($errorRows).Count -gt 0) {",
         "    Write-Warning (\"Services not installed: {0}\" -f @($errorRows).Count)",
         "}"],
        ["$probe = Test-ServerPort -ComputerName $env:COMPUTERNAME -Port $Port",
         "Write-Verbose (\"Local port {0} reachable: {1}\" -f $Port, $probe)"],
    ]
    body = _pad(rng, body, 165, pad_blocks)
    return _render(body)


def _monitor_mail(rng, c):
    return ["$MailTo = %s" % _q(rng, c["MailTo"]),
            "$down = @($results | Where-Object { $_.Status -ne 'Running' })",
            "if ($down.Count -gt 0) {",
            "    $summaryBody = $down | ConvertTo-Html -Fragment | Out-String",
            "    Send-MailMessage -To $MailTo -From %s -Subject \"Service alert on $env:COMPUTERNAME\" -Body $summaryBody -SmtpServer %s -Port %d -UseSsl"
            % (_q(rng, "monitoring@" + c["MailTo"].split("@", 1)[1]), _q(rng, c["SmtpServer"]),
               _pick(rng, [25, 587])),
            "}"]


# ---------------------------------------------------------------------------
# 13. REST API client with retry
# ---------------------------------------------------------------------------


def _api_ctx(rng):
    domain = _pick(rng, _DOMAINS)
    return {
        "BaseUri": "https://api." + domain + "/v1",
        "KeyVar": "CONTOSO_API_KEY",
        "MaxRetries": _pick(rng, [2, 3, 4, 5]),
        "TimeoutSec": _pick(rng, [15, 30, 45, 60]),
        "PageSize": _pick(rng, [25, 50, 100, 200]),
        "ReportPath": "C:\\Reports\\api-servers-" + _date(rng) + ".csv",
        "Script": _pick(rng, ["Get-ApiServers.ps1", "Invoke-ContosoApi.ps1",
                              "Export-ApiInventory.ps1"]),
    }


def _api_settings(rng, c):
    return [
        _mk("BaseUri", "string", _q(rng, c["BaseUri"]), _attrs(rng, "help")),
        _mk("MaxRetries", "int", str(c["MaxRetries"]), _attrs(rng, "optional", vrange=(1, 10))),
        _mk("TimeoutSec", "int", str(c["TimeoutSec"])),
        _mk("PageSize", "int", str(c["PageSize"])),
        _mk("ReportPath", "string", _q(rng, c["ReportPath"])),
    ]


def _api_auth(rng):
    return ["$ApiKey = $env:%s" % "CONTOSO_API_KEY",
            "if ([string]::IsNullOrWhiteSpace($ApiKey)) {",
            "    throw 'API key is not set. Populate the CONTOSO_API_KEY environment variable.'",
            "}",
            "$headers = @{",
            "    Authorization = \"Bearer $ApiKey\"",
            "    Accept        = 'application/json'",
            "}"]


def _api_function(rng):
    return ["function Invoke-ContosoApi {",
            "    [CmdletBinding()]",
            "    param(",
            "        [Parameter(Mandatory = $true)]",
            "        [string]$Path,",
            "",
            "        [ValidateSet('Get', 'Post')]",
            "        [string]$Method = 'Get',",
            "",
            "        [object]$Body",
            "    )",
            "",
            "    $uri = \"$BaseUri$Path\"",
            "    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {",
            "        try {",
            "            $params = @{",
            "                Uri         = $uri",
            "                Method      = $Method",
            "                Headers     = $headers",
            "                TimeoutSec  = $TimeoutSec",
            "                ErrorAction = 'Stop'",
            "            }",
            "            if ($Body) {",
            "                $params.Body = $Body | ConvertTo-Json -Depth 5",
            "                $params.ContentType = 'application/json'",
            "            }",
            "            return Invoke-RestMethod @params",
            "        }",
            "        catch {",
            "            $status = 0",
            "            if ($_.Exception.Response) {",
            "                $status = [int]$_.Exception.Response.StatusCode",
            "            }",
            "            if (@(400, 401, 403, 404) -contains $status -or $attempt -eq $MaxRetries) {",
            "                throw",
            "            }",
            "            Start-Sleep -Seconds ([math]::Pow(2, $attempt))",
            "        }",
            "    }",
            "}"]


def build_api_client_retry(rng: random.Random) -> str:
    tier = _tier(rng)
    c = _api_ctx(rng)
    settings = _api_settings(rng, c)
    compact = tier == "short"
    pre, _ = _preamble(
        rng,
        synopsis="Calls the Contoso inventory API with retry and exports the server list.",
        description=[
            "Wraps Invoke-RestMethod in a retry helper that backs off on transient errors "
            "and gives up on client errors such as 401 or 404.",
            "Pages are followed through the nextLink property until the collection is "
            "exhausted, then the records are written to CSV.",
        ],
        examples=[".\\" + c["Script"] + " -PageSize %d" % c["PageSize"],
                  ".\\" + c["Script"] + " -Verbose"],
        settings=settings,
        compact=compact,
    )
    lines = list(pre)
    if tier != "short":
        lines.extend(_extras(rng))

    if tier == "short":
        lines = _sec(rng, lines, _api_auth(rng),
                     ["$uri = \"$BaseUri/servers?limit=$PageSize\"",
                      "$page = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -TimeoutSec $TimeoutSec",
                      "$page.items | Select-Object id, name, status |",
                      "    Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8",
                      "Write-Host (\"Exported {0} servers\" -f @($page.items).Count) -ForegroundColor Green"])
        return _render(lines)

    body = _sec(rng, lines, _api_auth(rng), _api_function(rng))

    if tier == "medium":
        body = _sec(rng, body,
                    ["$page = Invoke-ContosoApi -Path ('/servers?limit=' + $PageSize)",
                     "$records = @($page.items)",
                     "while ($page.nextLink) {",
                     "    $next = $page.nextLink.Replace($BaseUri, '')",
                     "    $page = Invoke-ContosoApi -Path $next",
                     "    $records += @($page.items)",
                     "}"],
                    ["$records | Select-Object id, name, status | Format-Table -AutoSize"],
                    _csv_export(rng, "$records | Select-Object id, name, status", "$ReportPath"))
        body = _pad(rng, body, 52, [])
        return _render(body)

    body = _sec(rng, body,
                ["$page = Invoke-ContosoApi -Path ('/servers?limit=' + $PageSize)",
                 "$records = @($page.items)",
                 "while ($page.nextLink) {",
                 "    $next = $page.nextLink.Replace($BaseUri, '')",
                 "    $page = Invoke-ContosoApi -Path $next",
                 "    $records += @($page.items)",
                 "    Write-Verbose (\"Collected {0} records\" -f @($records).Count)",
                 "}"])
    body = _sec(rng, body,
                ["$summary = $records | Group-Object -Property status | ForEach-Object {",
                 "    [pscustomobject]@{",
                 "        Status = $_.Name",
                 "        Count  = $_.Count",
                 "    }",
                 "}",
                 "$summary | Format-Table -AutoSize"],
                _csv_export(rng, "$records | Select-Object id, name, status", "$ReportPath"),
                ["$summary | Export-Csv -Path $ReportPath.Replace('.csv', '-summary.csv') -NoTypeInformation -Encoding UTF8"])
    body = _sec(rng, body,
                ["$newTag = @{ tags = @('inventory', 'automated') }",
                 "try {",
                 "    $tagged = Invoke-ContosoApi -Path '/servers/tags' -Method Post -Body $newTag",
                 "    Write-Verbose (\"Tag request returned {0}\" -f $tagged.status)",
                 "}",
                 "catch {",
                 "    Write-Warning (\"Tagging skipped: {0}\" -f $_.Exception.Message)",
                 "}"])
    body = _sec(rng, body, _html_style(rng),
                ["$summary | ConvertTo-Html -Title 'API inventory summary' -Head $style |",
                 "    Set-Content -Path $ReportPath.Replace('.csv', '.html') -Encoding UTF8"])
    api_domain = c["BaseUri"].split("//", 1)[1].split("/", 1)[0].split(".", 1)[1]
    body = _sec(rng, body,
                ["$MailTo = %s" % _q(rng, "api-ops@" + api_domain),
                 "$MailFrom = %s" % _q(rng, "api-report@" + api_domain),
                 "$mailBody = \"Inventory run finished with {0} records\" -f @($records).Count",
                 "Send-MailMessage -To $MailTo -From $MailFrom -Subject 'API inventory' -Body $mailBody -SmtpServer %s -Port 25"
                 % _q(rng, "smtp." + api_domain)])
    body = _sec(rng, body,
                ["Write-Host (\"API inventory complete: {0} records\" -f @($records).Count) -ForegroundColor Green",
                 "Write-Verbose (\"Elapsed requests: {0}\" -f [math]::Ceiling(@($records).Count / $PageSize))"])

    pad_blocks = [
        ["$rateLimit = $null",
         "if ($rateLimit) {",
         "    Write-Verbose (\"Remaining calls: {0}\" -f $rateLimit)",
         "}"],
        ["$endpoints = @('/servers', '/servers/tags', '/health')",
         "$endpoints | ForEach-Object { Write-Verbose (\"Endpoint: {0}\" -f $_) }"],
        ["$retryCount = @($records).Count - @($records | Select-Object -Unique) .Count",
         "Write-Verbose (\"Duplicate ids skipped: {0}\" -f $retryCount)"],
        ["$tokenLength = $ApiKey.Length",
         "Write-Verbose (\"API key length: {0}\" -f $tokenLength)"],
        ["$baseUriHost = ([uri]$BaseUri).Host",
         "Write-Verbose (\"Target host: {0}\" -f $baseUriHost)"],
    ]
    body = _pad(rng, body, 165, pad_blocks)
    return _render(body)


# ---------------------------------------------------------------------------
# 14. File organiser
# ---------------------------------------------------------------------------


def _organiser_ctx(rng):
    return {
        "SourcePath": _pick(rng, ["C:\\Users\\Public\\Downloads",
                                  "C:\\Users\\Public\\Documents\\Inbox",
                                  "D:\\Dropbox\\Incoming"]),
        "DestinationRoot": _pick(rng, ["D:\\Sorted", "D:\\Archive\\Sorted",
                                       "E:\\SortedFiles"]),
        "LogPath": "C:\\Logs\\organise-" + _date(rng) + ".log",
        "DryRun": "$true",
        "Script": _pick(rng, ["Sort-Downloads.ps1", "Move-FilesByType.ps1",
                              "Invoke-FileOrganiser.ps1"]),
    }


def _organiser_settings(rng, c):
    return [
        _mk("SourcePath", "string", _q(rng, c["SourcePath"]), _attrs(rng, "help")),
        _mk("DestinationRoot", "string", _q(rng, c["DestinationRoot"])),
        _mk("LogPath", "string", _q(rng, c["LogPath"])),
        _mk("DryRun", "switch", None),
    ]


def _organiser_map(rng):
    return ["$map = @{",
            "    '.pdf'  = 'Documents'",
            "    '.docx' = 'Documents'",
            "    '.xlsx' = 'Spreadsheets'",
            "    '.png'  = 'Images'",
            "    '.jpg'  = 'Images'",
            "    '.zip'  = 'Archives'",
            "    '.log'  = 'Logs'",
            "}"]


def _organiser_loop(rng):
    return ["$files = Get-ChildItem -LiteralPath $SourcePath -File -Force |",
            "    Where-Object { $map.ContainsKey($_.Extension.ToLower()) }",
            "$moved = @()",
            "foreach ($file in $files) {",
            "    $folder = Join-Path $DestinationRoot $map[$file.Extension.ToLower()]",
            "    if (-not (Test-Path -LiteralPath $folder)) {",
            "        New-Item -ItemType Directory -Path $folder -Force | Out-Null",
            "    }",
            "    $target = Join-Path $folder $file.Name",
            "    if (Test-Path -LiteralPath $target) {",
            "        $stamp = Get-Date -Format 'yyyyMMddHHmmss'",
            "        $target = Join-Path $folder ([System.IO.Path]::GetFileNameWithoutExtension($file.Name) + '-' + $stamp + $file.Extension)",
            "    }",
            "    Move-Item -LiteralPath $file.FullName -Destination $target -WhatIf:$DryRun",
            "    $moved += [pscustomobject]@{",
            "        Source  = $file.FullName",
            "        Target  = $target",
            "        MovedAt = Get-Date",
            "    }",
            "}"]


def build_file_organiser(rng: random.Random) -> str:
    tier = _tier(rng)
    c = _organiser_ctx(rng)
    settings = _organiser_settings(rng, c)
    compact = tier == "short"
    pre, _ = _preamble(
        rng,
        synopsis="Moves files from a drop folder into per-type destination folders.",
        description=[
            "Reads an extension map, creates the destination folders and moves each file "
            "into the matching folder without overwriting an existing name.",
            "The DryRun switch prints the planned moves and leaves the source folder "
            "untouched, which is the default for the first run on a new machine.",
        ],
        examples=[".\\" + c["Script"] + " -SourcePath " + c["SourcePath"],
                  ".\\" + c["Script"] + " -DryRun"],
        settings=settings,
        compact=compact,
    )
    lines = list(pre)
    if tier != "short":
        lines.extend(_extras(rng))

    if tier == "short":
        lines = _sec(rng, lines,
                     ["$map = @{",
                      "    '.pdf'  = 'Documents'",
                      "    '.xlsx' = 'Spreadsheets'",
                      "    '.png'  = 'Images'",
                      "    '.zip'  = 'Archives'",
                      "}"],
                     ["$files = Get-ChildItem -LiteralPath $SourcePath -File |",
                      "    Where-Object { $map.ContainsKey($_.Extension.ToLower()) }",
                      "foreach ($file in $files) {",
                      "    $folder = Join-Path $DestinationRoot $map[$file.Extension.ToLower()]",
                      "    New-Item -ItemType Directory -Path $folder -Force | Out-Null",
                      "    Move-Item -LiteralPath $file.FullName -Destination $folder -WhatIf:$DryRun",
                      "}",
                      "Write-Host (\"Processed {0} files\" -f @($files).Count) -ForegroundColor Cyan"])
        return _render(lines)

    body = _sec(rng, lines, _organiser_map(rng), _organiser_loop(rng))

    if tier == "medium":
        body = _sec(rng, body,
                    ["$byFolder = $moved | Group-Object -Property { Split-Path -Parent $_.Target } |",
                     "    Select-Object Name, Count",
                     "$byFolder | Format-Table -AutoSize",
                     "Write-Host (\"Moved {0} files\" -f @($moved).Count) -ForegroundColor Green"])
        if _chance(rng, 0.5):
            body = _sec(rng, body,
                        _csv_export(rng, "$moved", "$LogPath.Replace('.log', '.csv')"))
        body = _pad(rng, body, 52, [])
        return _render(body)

    body = _sec(rng, body,
                ["$byFolder = $moved | Group-Object -Property { Split-Path -Parent $_.Target } |",
                 "    Sort-Object -Property Count -Descending",
                 "$byFolder | Format-Table Name, Count -AutoSize"],
                ["$sizes = $files | Measure-Object -Property Length -Sum",
                 "Write-Verbose (\"Total size: {0:N1} MB\" -f ($sizes.Sum / 1MB))"])
    body = _sec(rng, body,
                ["$undoPath = $LogPath.Replace('.log', '-undo.csv')",
                 "$moved | Export-Csv -Path $undoPath -NoTypeInformation -Encoding UTF8",
                 "Write-Verbose (\"Undo file: {0}\" -f $undoPath)"])
    body = _sec(rng, body,
                ["$duplicates = $files | Group-Object -Property Name | Where-Object { $_.Count -gt 1 }",
                 "if (@($duplicates).Count -gt 0) {",
                 "    Write-Warning (\"Duplicate file names in source: {0}\" -f @($duplicates).Count)",
                 "}",
                 "$skipped = @(Get-ChildItem -LiteralPath $SourcePath -File |",
                 "    Where-Object { -not $map.ContainsKey($_.Extension.ToLower()) }).Count",
                 "Write-Verbose (\"Skipped unknown extensions: {0}\" -f $skipped)"])
    body = _sec(rng, body, _html_style(rng),
                ["$byFolder | ConvertTo-Html -Title 'Organiser summary' -Head $style |",
                 "    Set-Content -Path $LogPath.Replace('.log', '.html') -Encoding UTF8"])
    body = _sec(rng, body,
                ["$logLine = \"{0} organised {1} files\" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), @($moved).Count",
                 "Add-Content -Path $LogPath -Value $logLine -Encoding UTF8",
                 "Write-Host (\"Organiser finished: {0} files\" -f @($moved).Count) -ForegroundColor Green"])

    pad_blocks = [
        ["$oldFiles = Get-ChildItem -LiteralPath $SourcePath -File |",
         "    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-90) }",
         "Write-Verbose (\"Files older than 90 days: {0}\" -f @($oldFiles).Count)"],
        ["$largeFiles = $files | Sort-Object -Property Length -Descending | Select-Object -First 5",
         "$largeFiles | Format-Table Name, @{Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 2) }} -AutoSize"],
        ["$freeSpace = Get-PSDrive -Name ($DestinationRoot.Substring(0, 1)) -ErrorAction SilentlyContinue",
         "if ($freeSpace) {",
         "    Write-Verbose (\"Destination free space: {0} GB\" -f [math]::Round($freeSpace.Free / 1GB, 1))",
         "}"],
        ["$hashList = foreach ($item in $files | Select-Object -First 10) {",
         "    [pscustomobject]@{ Name = $item.Name; Hash = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash }",
         "}",
         "$hashList | Format-Table Name -AutoSize"],
        ["$emptyFolders = Get-ChildItem -LiteralPath $SourcePath -Directory -Force |",
         "    Where-Object { @(Get-ChildItem -LiteralPath $_.FullName -Force).Count -eq 0 }",
         "Write-Verbose (\"Empty source folders: {0}\" -f @($emptyFolders).Count)"],
    ]
    body = _pad(rng, body, 165, pad_blocks)
    return _render(body)


# ---------------------------------------------------------------------------
# 15. Config / JSON generator
# ---------------------------------------------------------------------------


def _config_ctx(rng):
    product = _pick(rng, ["ContosoAgent", "AdatumCollector", "InfraRelay"])
    return {
        "Product": product,
        "OutputPath": "C:\\ProgramData\\Contoso\\%s\\config.json" % product,
        "Environment": _pick(rng, _ENVS),
        "Port": _pick(rng, [8080, 8443, 9443, 5000]),
        "NodeCount": _int(rng, 2, 6),
        "TemplatePath": "C:\\Scripts\\templates\\agent.template.json",
        "Script": _pick(rng, ["New-AgentConfig.ps1", "Write-AgentConfig.ps1",
                              "Build-AgentConfig.ps1"]),
    }


def _config_settings(rng, c):
    return [
        _mk("OutputPath", "string", _q(rng, c["OutputPath"]), _attrs(rng, "help")),
        _mk("Environment", "string", _q(rng, c["Environment"]),
            _attrs(rng, "optional", validate=["Dev", "Test", "Staging", "Prod"])),
        _mk("ApiPort", "int", str(c["Port"]), _attrs(rng, "plain", vrange=(1024, 65535))),
        _mk("NodeCount", "int", str(c["NodeCount"])),
        _mk("Force", "switch", None),
    ]


def _config_object(rng, c):
    return ["$config = [ordered]@{",
            "    environment = $Environment",
            "    agent       = [ordered]@{",
            "        name     = '%s'" % c["Product"],
            "        port     = $ApiPort",
            "        logLevel = 'Information'",
            "        endpoints = @(",
            "            'https://api.%s/v1'" % _pick(rng, _DOMAINS),
            "            'https://telemetry.%s/v1'" % _pick(rng, _DOMAINS),
            "        )",
            "    }",
            "    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')",
            "    host        = $env:COMPUTERNAME",
            "}"]


def _config_write(rng, c):
    return ["$jsonBody = $config | ConvertTo-Json -Depth 6",
            "if ((Test-Path -LiteralPath $OutputPath) -and (-not $Force)) {",
            "    $backup = $OutputPath + '.' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.bak'",
            "    Copy-Item -LiteralPath $OutputPath -Destination $backup -Force",
            "    Write-Verbose (\"Existing config backed up to {0}\" -f $backup)",
            "}",
            "$outputDir = Split-Path -Parent $OutputPath",
            "if (-not (Test-Path -LiteralPath $outputDir)) {",
            "    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null",
            "}",
            "$jsonBody | Set-Content -LiteralPath $OutputPath -Encoding UTF8",
            "$roundTrip = Get-Content -LiteralPath $OutputPath -Raw | ConvertFrom-Json",
            "if (-not $roundTrip.agent.port) {",
            "    throw 'Generated configuration failed the round-trip check.'",
            "}",
            "Write-Verbose (\"Configuration written to {0}\" -f $OutputPath)"]


def build_config_generator(rng: random.Random) -> str:
    tier = _tier(rng)
    c = _config_ctx(rng)
    settings = _config_settings(rng, c)
    compact = tier == "short"
    pre, _ = _preamble(
        rng,
        synopsis="Generates the %s JSON configuration for the selected environment." % c["Product"],
        description=[
            "Builds an ordered configuration object, writes it next to the installed "
            "agent and validates the result by reading it back.",
            "An existing configuration is backed up before it is replaced, unless the "
            "Force switch is specified.",
        ],
        examples=[".\\" + c["Script"] + " -Environment " + c["Environment"],
                  ".\\" + c["Script"] + " -ApiPort %d -Force" % c["Port"]],
        settings=settings,
        compact=compact,
    )
    lines = list(pre)
    if tier != "short":
        lines.extend(_extras(rng))

    if tier == "short":
        lines = _sec(rng, lines,
                     ["$config = [ordered]@{",
                      "    environment = $Environment",
                      "    port        = $ApiPort",
                      "    name        = '%s'" % c["Product"],
                      "    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')",
                      "}"],
                     ["$config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath -Encoding UTF8",
                      "Write-Host (\"Wrote configuration to {0}\" -f $OutputPath) -ForegroundColor Green"])
        return _render(lines)

    body = _sec(rng, lines, _config_object(rng, c), _config_write(rng, c))

    if tier == "medium":
        body = _sec(rng, body,
                    ["$config.generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')",
                     "Write-Host (\"Environment: {0} | Port: {1}\" -f $roundTrip.environment, $roundTrip.agent.port) -ForegroundColor Cyan"])
        if _chance(rng, 0.5):
            body = _sec(rng, body, _config_herestring(rng, c))
        body = _pad(rng, body, 52, [])
        return _render(body)

    body = _sec(rng, body,
                ["$config.agent.logLevel = %s" % _q(rng, _pick(rng, _LEVELS)),
                 "$config | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8"])
    body = _sec(rng, body, _config_herestring(rng, c))
    body = _sec(rng, body,
                ["$environmentFile = $OutputPath.Replace('.json', '.env')",
                 "$lines = @(",
                 "    \"AGENT_ENV=$Environment\"",
                 "    \"AGENT_PORT=$ApiPort\"",
                 ")",
                 "$lines | Set-Content -LiteralPath $environmentFile -Encoding UTF8"])
    body = _sec(rng, body,
                ["$xmlPath = $OutputPath.Replace('.json', '.xml')",
                 "$xml = New-Object System.Xml.XmlDocument",
                 "$root = $xml.CreateElement('configuration')",
                 "$xml.AppendChild($root) | Out-Null",
                 "$entry = $xml.CreateElement('add')",
                 "$entry.SetAttribute('key', 'Environment')",
                 "$entry.SetAttribute('value', $Environment)",
                 "$root.AppendChild($entry) | Out-Null",
                 "$xml.Save($xmlPath)"])
    body = _sec(rng, body,
                ["$configHash = (Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash",
                 "Write-Verbose (\"Config SHA256: {0}\" -f $configHash)",
                 "$schemaFile = Join-Path $PSScriptRoot 'config.schema.json'",
                 "if (Test-Path -LiteralPath $schemaFile) {",
                 "    Write-Verbose (\"Schema available: {0}\" -f $schemaFile)",
                 "}"])
    body = _sec(rng, body,
                ["$summaryBody = \"Config generated for {0} on $env:COMPUTERNAME\" -f $Environment",
                 "Send-MailMessage -To 'ops@contoso.com' -From 'config@contoso.com' -Subject 'Agent configuration generated' -Body $summaryBody -SmtpServer 'smtp.contoso.com' -Port 25"])
    body = _sec(rng, body,
                ["$config | ConvertTo-Json -Depth 6",
                 "Write-Host (\"Configuration complete for {0}\" -f $Environment) -ForegroundColor Green"])

    pad_blocks = [
        ["$portInUse = Get-NetTCPConnection -LocalPort $ApiPort -ErrorAction SilentlyContinue",
         "if ($portInUse) {",
         "    Write-Warning (\"Port {0} is already in use\" -f $ApiPort)",
         "}"],
        ["$defaults = @{",
         "    retryCount = 3",
         "    backoffSec = 5",
         "    heartbeat  = 30",
         "}",
         "$defaults.GetEnumerator() | ForEach-Object { Write-Verbose (\"{0} = {1}\" -f $_.Key, $_.Value) }"],
        ["$previous = Join-Path (Split-Path -Parent $OutputPath) 'config.previous.json'",
         "if (Test-Path -LiteralPath $previous) {",
         "    Write-Verbose (\"Previous config: {0}\" -f $previous)",
         "}"],
        ["$encoding = [System.Text.UTF8Encoding]::new($false)",
         "$encoding.GetType().Name | Write-Verbose"],
        ["$nodeList = 1..$NodeCount | ForEach-Object { 'node-{0:d2}' -f $_ }",
         "Write-Verbose (\"Planned nodes: {0}\" -f ($nodeList -join ', '))"],
    ]
    body = _pad(rng, body, 165, pad_blocks)
    return _render(body)


def _config_herestring(rng, c):
    return ["$template = @\"",
            "{",
            "  \"environment\": \"$Environment\",",
            "  \"agent\": {",
            "    \"name\": \"%s\"," % c["Product"],
            "    \"port\": $ApiPort",
            "  }",
            "}",
            "\"@",
            "$template | Set-Content -LiteralPath $OutputPath.Replace('.json', '.template.json') -Encoding UTF8"]


# ---------------------------------------------------------------------------
# 16. Certificate expiry check
# ---------------------------------------------------------------------------


def _cert_ctx(rng):
    domain = _pick(rng, ["contoso.com", "adatum.com"])
    hosts = ["portal." + domain, "api." + domain, "vpn." + domain]
    return {
        "WarningDays": _pick(rng, [14, 21, 30, 45, 60]),
        "Hosts": hosts,
        "Port": _pick(rng, [443, 8443, 9443]),
        "ReportPath": "C:\\Reports\\cert-expiry-" + _date(rng) + ".csv",
        "MailTo": "pki@" + domain,
        "SmtpServer": "smtp." + domain,
        "Script": _pick(rng, ["Get-CertificateExpiry.ps1", "Test-CertExpiry.ps1",
                              "Export-CertReport.ps1"]),
    }


def _cert_settings(rng, c):
    hosts = ", ".join("'%s'" % h for h in c["Hosts"])
    return [
        _mk("WarningDays", "int", str(c["WarningDays"]), _attrs(rng, "help", vrange=(1, 365))),
        _mk("Hosts", "string[]", "@(%s)" % hosts),
        _mk("Port", "int", str(c["Port"])),
        _mk("ReportPath", "string", _q(rng, c["ReportPath"])),
    ]


def _cert_probe(rng):
    return ["function Get-CertificateExpiry {",
            "    [CmdletBinding()]",
            "    param(",
            "        [Parameter(Mandatory = $true)]",
            "        [string]$ComputerName,",
            "",
            "        [int]$Port = 443",
            "    )",
            "",
            "    $client = New-Object System.Net.Sockets.TcpClient",
            "    try {",
            "        $client.Connect($ComputerName, $Port)",
            "        $callback = [System.Net.Security.RemoteCertificateValidationCallback] {",
            "            param($sender, $certificate, $chain, $errors)",
            "            return $true",
            "        }",
            "        $stream = New-Object System.Net.Security.SslStream($client.GetStream(), $false, $callback)",
            "        $stream.AuthenticateAsClient($ComputerName)",
            "        $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]$stream.RemoteCertificate",
            "        [pscustomobject]@{",
            "            Host     = $ComputerName",
            "            Subject  = $cert.Subject",
            "            Issuer   = $cert.Issuer",
            "            NotAfter = $cert.NotAfter",
            "            DaysLeft = [math]::Floor(($cert.NotAfter - (Get-Date)).TotalDays)",
            "        }",
            "        $stream.Dispose()",
            "    }",
            "    finally {",
            "        $client.Close()",
            "    }",
            "}"]


def _cert_store(rng):
    return ["$stores = @('Cert:\\LocalMachine\\My', 'Cert:\\LocalMachine\\WebHosting')",
            "$localCerts = foreach ($store in $stores) {",
            "    Get-ChildItem -Path $store -ErrorAction SilentlyContinue |",
            "        Where-Object { $_.NotAfter -lt (Get-Date).AddDays($WarningDays) } |",
            "        Select-Object @{Name = 'Store'; Expression = { $store }}, Subject, NotAfter,",
            "            @{Name = 'DaysLeft'; Expression = { [math]::Floor(($_.NotAfter - (Get-Date)).TotalDays) }}",
            "}"]


def build_cert_expiry_check(rng: random.Random) -> str:
    tier = _tier(rng)
    c = _cert_ctx(rng)
    settings = _cert_settings(rng, c)
    compact = tier == "short"
    pre, _ = _preamble(
        rng,
        synopsis="Reports certificates that expire inside the warning window.",
        description=[
            "Inspects the local machine stores and optionally connects to each configured "
            "host to read the certificate presented on its TLS port.",
            "The report lists the subject, the expiry date and the remaining days so the "
            "PKI team can schedule the renewal.",
        ],
        examples=[".\\" + c["Script"] + " -WarningDays %d" % c["WarningDays"],
                  ".\\" + c["Script"] + " -Hosts " + c["Hosts"][0] + " -Port " + str(c["Port"])],
        settings=settings,
        compact=compact,
    )
    lines = list(pre)
    if tier != "short":
        lines.extend(_extras(rng))

    if tier == "short":
        lines = _sec(rng, lines,
                     ["$warnDate = (Get-Date).AddDays($WarningDays)",
                      "$expiring = Get-ChildItem -Path 'Cert:\\LocalMachine\\My' -ErrorAction SilentlyContinue |",
                      "    Where-Object { $_.NotAfter -lt $warnDate } |",
                      "    Select-Object Subject, NotAfter, @{Name = 'DaysLeft'; Expression = { [math]::Floor(($_.NotAfter - (Get-Date)).TotalDays) }}",
                      "$expiring | Format-Table -AutoSize",
                      "if (@($expiring).Count -gt 0) {",
                      "    Write-Warning (\"{0} certificates expire within {1} days\" -f @($expiring).Count, $WarningDays)",
                      "}"])
        return _render(lines)

    body = _sec(rng, lines, _cert_probe(rng), _cert_store(rng))

    if tier == "medium":
        body = _sec(rng, body,
                    ["$remote = foreach ($hostName in $Hosts) {",
                     "    try {",
                     "        Get-CertificateExpiry -ComputerName $hostName -Port $Port",
                     "    }",
                     "    catch {",
                     "        Write-Warning (\"Could not read certificate from {0}\" -f $hostName)",
                     "    }",
                     "}"],
                    _csv_export(rng, "$remote", "$ReportPath"),
                    ["$expiring = @($remote | Where-Object { $_.DaysLeft -le $WarningDays })",
                     "Write-Host (\"{0} of {1} certificates are inside the warning window\" -f $expiring.Count, @($remote).Count) -ForegroundColor Cyan"])
        body = _pad(rng, body, 52, [])
        return _render(body)

    body = _sec(rng, body,
                ["$remote = foreach ($hostName in $Hosts) {",
                 "    Write-Verbose (\"Probing {0}:{1}\" -f $hostName, $Port)",
                 "    try {",
                 "        Get-CertificateExpiry -ComputerName $hostName -Port $Port",
                 "    }",
                 "    catch {",
                 "        Write-Warning (\"Could not read certificate from {0}\" -f $hostName)",
                 "    }",
                 "}",
                 "$expiring = @($remote | Where-Object { $_.DaysLeft -le $WarningDays })"])
    body = _sec(rng, body,
                ["$remote | Sort-Object -Property DaysLeft |",
                 "    Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8",
                 "$expiring | Export-Csv -Path $ReportPath.Replace('.csv', '-warn.csv') -NoTypeInformation -Encoding UTF8"])
    body = _sec(rng, body,
                ["$byIssuer = $remote | Group-Object -Property Issuer |",
                 "    Sort-Object -Property Count -Descending | Select-Object -First 5",
                 "$byIssuer | Format-Table Name, Count -AutoSize"])
    body = _sec(rng, body, _html_style(rng),
                ["$remote | Sort-Object -Property DaysLeft |",
                 "    ConvertTo-Html -Title 'Certificate expiry' -Head $style |",
                 "    Set-Content -Path $ReportPath.Replace('.csv', '.html') -Encoding UTF8"])
    body = _sec(rng, body,
                ["$MailTo = %s" % _q(rng, c["MailTo"]),
                 "$summaryBody = $expiring | ConvertTo-Html -Fragment | Out-String"],
                _mail_block(rng, "$MailTo", _q(rng, "pki@" + c["MailTo"].split("@", 1)[1]),
                            _q(rng, c["SmtpServer"]),
                            _q(rng, "Certificate expiry warning"), "$summaryBody",
                            _pick(rng, [25, 587])))
    body = _sec(rng, body,
                ["$soonest = $remote | Sort-Object -Property DaysLeft | Select-Object -First 1",
                 "Write-Host (\"Next expiry: {0} on {1:yyyy-MM-dd}\" -f $soonest.Subject, $soonest.NotAfter) -ForegroundColor Yellow",
                 "Write-Verbose (\"Local store matches: {0}\" -f @($localCerts).Count)"])

    pad_blocks = [
        ["$renewal = $remote | Where-Object { $_.DaysLeft -lt 0 }",
         "if (@($renewal).Count -gt 0) {",
         "    Write-Warning (\"{0} certificates have already expired\" -f @($renewal).Count)",
         "}"],
        ["$selfSigned = $remote | Where-Object { $_.Subject -eq $_.Issuer }",
         "Write-Verbose (\"Self-signed certificates: {0}\" -f @($selfSigned).Count)"],
        ["$portCheck = Test-NetConnection -ComputerName $Hosts[0] -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue",
         "Write-Verbose (\"Port {0} reachable on {1}: {2}\" -f $Port, $Hosts[0], $portCheck)"],
        ["$schtasks = Get-ScheduledTask -TaskName 'Contoso-CertCheck' -ErrorAction SilentlyContinue",
         "if ($schtasks) {",
         "    Write-Verbose (\"Scheduled check state: {0}\" -f $schtasks.State)",
         "}"],
        ["$thumbprints = $remote | Select-Object Host, @{Name = 'Thumbprint'; Expression = { $_.Subject.Length }}",
         "$thumbprints | Format-Table -AutoSize"],
    ]
    body = _pad(rng, body, 165, pad_blocks)
    return _render(body)


# ---------------------------------------------------------------------------
# family registry
# ---------------------------------------------------------------------------

FAMILIES = [
    ("ad_user_audit", 60, build_ad_user_audit),
    ("backup_retention", 60, build_backup_retention),
    ("iis_log_parser", 55, build_iis_log_parser),
    ("csv_report_exporter", 55, build_csv_report_exporter),
    ("azure_provision_test", 50, build_azure_provision_test),
    ("cloud_cost_report", 55, build_cloud_cost_report),
    ("pester_tests", 55, build_pester_tests),
    ("module_export", 55, build_module_export),
    ("installer_deploy", 55, build_installer_deploy),
    ("winforms_tool", 45, build_winforms_tool),
    ("temp_cleanup", 60, build_temp_cleanup),
    ("service_monitor", 60, build_service_monitor),
    ("api_client_retry", 55, build_api_client_retry),
    ("file_organiser", 50, build_file_organiser),
    ("config_generator", 55, build_config_generator),
    ("cert_expiry_check", 55, build_cert_expiry_check),
]
