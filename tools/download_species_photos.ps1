# Download species photos via Wikimedia Commons API -> assets/species/{id}.jpg
# Usage: .\tools\download_species_photos.ps1 [-Force]

param([switch]$Force)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$jsonPath = Join-Path $repoRoot 'assets\data\species_ibero.json'
$outDir = Join-Path $repoRoot 'assets\species'
$userAgent = 'AQUANAUTIX/1.0 (species-photo-bundle; contact@aquanautix.app)'

if (-not (Test-Path $jsonPath)) {
    Write-Error "Missing file: $jsonPath"
}

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$data = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$ok = 0
$fail = 0
$skipped = 0

function Invoke-CommonsApi {
    param([string]$Uri)
    return Invoke-RestMethod -Uri $Uri -Headers @{ 'User-Agent' = $userAgent }
}

function Get-FileNameFromPhotoUrl {
    param([string]$PhotoUrl)
    if ($PhotoUrl -match '/([^/]+\.(?:jpg|jpeg|png|JPG|JPEG|PNG))(?:/|$)') {
        return $matches[1]
    }
    return $null
}

function Get-CommonsUrlByFileName {
    param([string]$FileName)
    $encoded = [uri]::EscapeDataString($FileName)
    $api = "https://commons.wikimedia.org/w/api.php?action=query&titles=File:$encoded&prop=imageinfo&iiprop=url&iiurlwidth=800&format=json"
    $resp = Invoke-CommonsApi -Uri $api
    foreach ($p in $resp.query.pages.PSObject.Properties) {
        if ($p.Value.missing) { continue }
        $info = $p.Value.imageinfo
        if ($null -ne $info -and $info.Count -gt 0) {
            if ($info[0].thumburl) { return $info[0].thumburl }
            if ($info[0].url) { return $info[0].url }
        }
    }
    return $null
}

function Get-CommonsUrlByScientificName {
    param([string]$ScientificName)

    $genus = ($ScientificName -split '\s+')[0]
    $species = ($ScientificName -split '\s+')[1]
    $queries = @($ScientificName, "$genus $species", $genus)
    $queries = $queries | Where-Object { $_ -and $_.Trim().Length -gt 2 } | Select-Object -Unique

    foreach ($q in $queries) {
        $encoded = [uri]::EscapeDataString($q)
        $api = "https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrsearch=$encoded&gsrnamespace=6&gsrlimit=8&prop=imageinfo&iiprop=url&iiurlwidth=800&format=json"
        $resp = Invoke-CommonsApi -Uri $api
        if (-not $resp.query.pages) { continue }

        foreach ($p in $resp.query.pages.PSObject.Properties) {
            $title = [string]$p.Value.title
            $titleLower = $title.ToLowerInvariant()
            $genusLower = $genus.ToLowerInvariant()
            if ($titleLower -notmatch [regex]::Escape($genusLower)) { continue }
            if ($species -and $species -ne 'spp.' -and $titleLower -notmatch [regex]::Escape($species.ToLowerInvariant())) {
                continue
            }
            $info = $p.Value.imageinfo
            if ($null -eq $info -or $info.Count -eq 0) { continue }
            if ($info[0].thumburl) { return $info[0].thumburl }
            if ($info[0].url) { return $info[0].url }
        }
    }
    return $null
}

function Resolve-CommonsDownloadUrl {
    param(
        [string]$PhotoUrl,
        [string]$ScientificName
    )

    $fileName = Get-FileNameFromPhotoUrl -PhotoUrl $PhotoUrl
    if ($fileName) {
        $byFile = Get-CommonsUrlByFileName -FileName $fileName
        if ($byFile) { return $byFile }
    }

    return Get-CommonsUrlByScientificName -ScientificName $ScientificName
}

foreach ($sp in $data.species) {
    $id = $sp.id
    $url = $sp.photoUrl
    $scientific = $sp.cientifico
    $dest = Join-Path $outDir "$id.jpg"

    if ((Test-Path $dest) -and -not $Force) {
        $skipped++
        continue
    }

    if ([string]::IsNullOrWhiteSpace($url)) {
        Write-Warning "SKIP $id - no photoUrl"
        $fail++
        continue
    }

    try {
        $downloadUrl = Resolve-CommonsDownloadUrl -PhotoUrl $url -ScientificName $scientific
        if (-not $downloadUrl) {
            Write-Warning "SKIP $id - could not resolve ($scientific)"
            $fail++
            continue
        }

        Write-Host "GET $id"
        curl.exe -sL -A $userAgent -o $dest $downloadUrl
        if (-not (Test-Path $dest)) {
            Write-Warning "FAIL $id - no output file"
            $fail++
            continue
        }
        $bytes = (Get-Item $dest).Length
        if ($bytes -lt 2048) {
            Write-Warning "SKIP $id - file too small ($bytes bytes)"
            Remove-Item $dest -Force
            $fail++
            continue
        }
        $ok++
    }
    catch {
        Write-Warning "FAIL $id - $($_.Exception.Message)"
        if (Test-Path $dest) { Remove-Item $dest -Force }
        $fail++
    }

    Start-Sleep -Milliseconds 450
}

Write-Host ""
Write-Host "Done: $ok downloaded, $skipped skipped, $fail failed"
Write-Host "Output: $outDir"
if ($fail -gt 0) { exit 1 }
