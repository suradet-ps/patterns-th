param(
    [string]$Orig = '',
    [string]$Trans = (Join-Path $PSScriptRoot '..\src')
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$trans = [System.IO.Path]::GetFullPath($Trans)

if ([string]::IsNullOrWhiteSpace($Orig)) {
    $candidates = @(
        (Join-Path $PSScriptRoot '..\..\patterns\src'),
        (Join-Path $PSScriptRoot '..\patterns\src'),
        (Join-Path (Get-Location) 'patterns\src')
    )
    foreach ($cand in $candidates) {
        if (Test-Path -LiteralPath $cand) {
            $Orig = $cand
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($Orig) -or (-not (Test-Path -LiteralPath $Orig))) {
    Write-Error "Cannot find upstream patterns src directory.`nPlease provide the path using: ./scripts/verify-translation.ps1 -Orig <path-to-patterns/src>"
    exit 1
}

$orig = [System.IO.Path]::GetFullPath($Orig)
Write-Output "Comparing translation against upstream:"
Write-Output "  Upstream:    $orig"
Write-Output "  Translation: $trans"

function Read-Normalized($path) {
    return ([System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)).Replace("`r`n", "`n")
}

function Get-CodeBlocks($path) {
    $content = Read-Normalized $path
    $rx = [regex]'```(?s:.*?)```'
    return @($rx.Matches($content) | ForEach-Object { $_.Value })
}

function Get-Headings($path) {
    $content = Read-Normalized $path
    $rx = [regex]'(?m)^#{1,6} .*$'
    return @($rx.Matches($content) | ForEach-Object { $_.Value })
}

function Get-RefLinks($path) {
    $content = Read-Normalized $path
    # Footnote definitions ([^name]: ...) are prose, not link targets; skip them.
    $rx = [regex]'(?m)^\[(?!\^)[^\]]+\]:\s+\S+.*$'
    return @($rx.Matches($content) | ForEach-Object { $_.Value -replace '\s+$','' })
}

function Get-InlineLinkTargets($path) {
    $content = Read-Normalized $path
    $rx = [regex]'\[[^\]]*\]\(([^)]+)\)'
    return @($rx.Matches($content) | ForEach-Object { $_.Groups[1].Value -replace '\s+$','' })
}

function Get-Autolinks($path) {
    $content = Read-Normalized $path
    $rx = [regex]'<(https?://[^>\s]+)>'
    return @($rx.Matches($content) | ForEach-Object { $_.Groups[1].Value })
}

function Normalize-LinkTarget($url) {
    if ([string]::IsNullOrWhiteSpace($url)) {
        return ''
    }
    $trimmed = $url.Trim()
    # In-page anchor link (anchors are translated to Thai slugs and checked by check-links.ps1)
    if ($trimmed.StartsWith('#')) {
        return '#anchor'
    }
    # Relative file link with in-page anchor (e.g. usage.md#regression-check vs
    # usage.md#การตรวจสอบรีเกรสชัน): the file part must match, the Thai anchor is
    # verified separately by check-links.ps1.
    if ($trimmed -notmatch '^[a-z][a-z0-9+.-]*:' -and $trimmed -match '^([^#]+)#(.+)$') {
        return $Matches[1]
    }
    # External links keep their full URL, anchors included.
    return $trimmed
}

$origFiles = Get-ChildItem -Recurse -File $orig -Filter *.md
$fail = 0
$total = 0
$blockCount = 0
$linkCount = 0

foreach ($f in $origFiles) {
    $rel = $f.FullName.Substring($orig.Length + 1)
    $tPath = Join-Path $trans $rel
    $total++
    if (-not (Test-Path -LiteralPath $tPath)) {
        Write-Output "[FAIL] $rel : missing translated file"
        $fail++
        continue
    }

    $oc = Get-CodeBlocks $f.FullName
    $tc = Get-CodeBlocks $tPath
    $blockCount += $oc.Count
    if ($oc.Count -ne $tc.Count) {
        Write-Output "[FAIL] $rel : code block count differs (orig=$($oc.Count) trans=$($tc.Count))"
        $fail++
    } else {
        for ($i = 0; $i -lt $oc.Count; $i++) {
            if ($oc[$i] -cne $tc[$i]) {
                Write-Output "[FAIL] $rel : code block #$($i+1) differs"
                $fail++
            }
        }
    }

    $oh = Get-Headings $f.FullName
    $th = Get-Headings $tPath
    if ($oh.Count -ne $th.Count) {
        Write-Output "[FAIL] $rel : heading count differs (orig=$($oh.Count) trans=$($th.Count))"
        $fail++
    } else {
        for ($i = 0; $i -lt $oh.Count; $i++) {
            $ol = ($oh[$i] -split ' ')[0]
            $tl = ($th[$i] -split ' ')[0]
            if ($ol -cne $tl) {
                Write-Output "[FAIL] $rel : heading #$($i+1) level differs (orig='$($oh[$i])' trans='$($th[$i])')"
                $fail++
            }
        }
    }

    $or = Get-RefLinks $f.FullName
    $tr = Get-RefLinks $tPath
    $linkCount += $or.Count
    if ($or.Count -ne $tr.Count) {
        Write-Output "[FAIL] $rel : ref-link count differs (orig=$($or.Count) trans=$($tr.Count))"
        $fail++
    } else {
        for ($i = 0; $i -lt $or.Count; $i++) {
            $ourl = Normalize-LinkTarget (($or[$i] -split ':\s*',2)[1])
            $turl = Normalize-LinkTarget (($tr[$i] -split ':\s*',2)[1])
            if ($ourl -cne $turl) {
                Write-Output "[FAIL] $rel : ref-link #$($i+1) url differs (orig='$ourl' trans='$turl')"
                $fail++
            }
        }
    }

    $oi = @(Get-InlineLinkTargets $f.FullName | ForEach-Object { Normalize-LinkTarget $_ })
    $ti = @(Get-InlineLinkTargets $tPath | ForEach-Object { Normalize-LinkTarget $_ })
    $linkCount += $oi.Count
    if ($oi.Count -ne $ti.Count) {
        Write-Output "[FAIL] $rel : inline link count differs (orig=$($oi.Count) trans=$($ti.Count))"
        $fail++
    } else {
        for ($i = 0; $i -lt $oi.Count; $i++) {
            if ($oi[$i] -cne $ti[$i]) {
                Write-Output "[FAIL] $rel : inline link #$($i+1) target differs (orig='$($oi[$i])' trans='$($ti[$i])')"
                $fail++
            }
        }
    }

    $oa = Get-Autolinks $f.FullName
    $ta = Get-Autolinks $tPath
    $linkCount += $oa.Count
    if ($oa.Count -ne $ta.Count) {
        Write-Output "[FAIL] $rel : autolink count differs (orig=$($oa.Count) trans=$($ta.Count))"
        $fail++
    } else {
        for ($i = 0; $i -lt $oa.Count; $i++) {
            if ($oa[$i] -cne $ta[$i]) {
                Write-Output "[FAIL] $rel : autolink #$($i+1) differs (orig='$($oa[$i])' trans='$($ta[$i])')"
                $fail++
            }
        }
    }
}

Write-Output "---"
Write-Output "Checked $total files, $blockCount code blocks, $linkCount links, $fail problem(s)"
if ($fail -eq 0) { Write-Output "ALL OK: code blocks, headings, links match 100%" }
exit ($fail -gt 0)
