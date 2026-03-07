$ErrorActionPreference = "Stop"

# Validate JSON profiles can be parsed and are not empty.
$profiles = Get-Content -Raw -Path "vSMR/vSMR_Profiles.json" | ConvertFrom-Json
if (-not $profiles -or $profiles.Count -lt 1) {
  throw "vSMR_Profiles.json did not contain any profiles."
}

# Validate aircraft-data.csv has stable structure and positive numeric dimensions.
$csvRows = Get-Content -Path "vSMR/aircraft-data.csv" | Where-Object { $_.Trim().Length -gt 0 }
if ($csvRows.Count -lt 1) {
  throw "aircraft-data.csv is empty."
}

$seenIcaos = @{}
$lineNumber = 0
foreach ($row in $csvRows) {
  $lineNumber++
  $parts = $row.Split(",")
  if ($parts.Count -ne 4) {
    throw "aircraft-data.csv line $lineNumber has $($parts.Count) fields; expected 4."
  }

  $icao = $parts[0].Trim()
  if ([string]::IsNullOrWhiteSpace($icao)) {
    throw "aircraft-data.csv line $lineNumber has an empty ICAO code."
  }

  if ($seenIcaos.ContainsKey($icao)) {
    throw "aircraft-data.csv has duplicate ICAO '$icao' on line $lineNumber."
  }
  $seenIcaos[$icao] = $true

  for ($i = 1; $i -le 3; $i++) {
    $parsed = 0.0
    $isValid = [double]::TryParse(
      $parts[$i],
      [System.Globalization.NumberStyles]::Float,
      [System.Globalization.CultureInfo]::InvariantCulture,
      [ref]$parsed
    )

    if (-not $isValid) {
      throw "aircraft-data.csv line $lineNumber has invalid numeric field '$($parts[$i])'."
    }

    if ($parsed -le 0) {
      throw "aircraft-data.csv line $lineNumber has non-positive dimension '$($parts[$i])'."
    }
  }
}

# Lint-like hygiene check: prevent hardcoded local user paths in project files.
$projectContent = Get-Content -Raw -Path "vSMR/vSMR.vcxproj"
if ($projectContent -match "[A-Za-z]:\\Users\\") {
  throw "vSMR.vcxproj contains a hardcoded user profile path."
}

Write-Host "Smoke checks passed: JSON, CSV, and project path hygiene."
