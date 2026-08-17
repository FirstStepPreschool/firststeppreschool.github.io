$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$siteRoot = Split-Path -Parent $root
$utf8 = New-Object System.Text.UTF8Encoding($false)

function New-PlaceholderSvg {
  param(
    [string]$Path,
    [string]$Title,
    [string]$Sub = 'Replace with a real First Step photo'
  )
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  $escTitle = $Title.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')
  $escSub = $Sub.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')

  $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600" viewBox="0 0 800 600" role="img" aria-label="Placeholder image: $escTitle">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#4f0490"/>
      <stop offset="1" stop-color="#371063"/>
    </linearGradient>
    <radialGradient id="blob1" cx="0.2" cy="0.15" r="0.8">
      <stop offset="0" stop-color="#f9b73f" stop-opacity="0.35"/>
      <stop offset="1" stop-color="#f9b73f" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="blob2" cx="0.9" cy="0.9" r="0.8">
      <stop offset="0" stop-color="#f9b73f" stop-opacity="0.22"/>
      <stop offset="1" stop-color="#f9b73f" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="800" height="600" fill="url(#bg)"/>
  <rect width="800" height="600" fill="url(#blob1)"/>
  <rect width="800" height="600" fill="url(#blob2)"/>
  <circle cx="400" cy="250" r="86" fill="#f9b73f"/>
  <circle cx="400" cy="250" r="68" fill="#fdf4e3"/>
  <circle cx="376" cy="238" r="7" fill="#4f0490"/>
  <circle cx="424" cy="238" r="7" fill="#4f0490"/>
  <path d="M368 270 Q400 300 432 270" stroke="#4f0490" stroke-width="6" stroke-linecap="round" fill="none"/>
  <text x="400" y="392" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="30" font-weight="700" fill="#fdf4e3">$escTitle</text>
  <text x="400" y="428" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="18" fill="#f9b73f">$escSub</text>
  <g transform="translate(640,42)">
    <rect width="132" height="34" rx="17" fill="rgba(255,255,255,0.14)" stroke="rgba(255,255,255,0.35)"/>
    <text x="66" y="22" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="13" font-weight="600" fill="#f9b73f">Placeholder</text>
  </g>
</svg>
"@
  [System.IO.File]::WriteAllText($Path, $svg, $utf8)
  Write-Host "Generated: $Path"
}

# ---- Gallery (First Step Moments) ----
$gallery = @(
  @{ n = 'campus-1';  t = 'Campus' },
  @{ n = 'campus-2';  t = 'Campus' },
  @{ n = 'classrooms-1'; t = 'Classroom' },
  @{ n = 'classrooms-2'; t = 'Classroom' },
  @{ n = 'activities-1'; t = 'Activities' },
  @{ n = 'activities-2'; t = 'Activities' },
  @{ n = 'outdoor-1';  t = 'Outdoor play' },
  @{ n = 'outdoor-2';  t = 'Outdoor play' },
  @{ n = 'celebrations-1'; t = 'Celebrations' },
  @{ n = 'celebrations-2'; t = 'Celebrations' },
  @{ n = 'programmes-1'; t = 'Special programmes' },
  @{ n = 'programmes-2'; t = 'Special programmes' }
)
foreach ($g in $gallery) {
  New-PlaceholderSvg -Path (Join-Path $siteRoot ("assets\gallery\" + $g.n + ".svg")) -Title $g.t
}

# ---- Journal covers ----
$journal = @(
  @{ n = 'why-play';        t = 'Play' },
  @{ n = 'first-day';       t = 'First day' },
  @{ n = 'separation';      t = 'Separation anxiety' },
  @{ n = 'screen-time';     t = 'Screen time' },
  @{ n = 'storytelling';    t = 'Storytelling' },
  @{ n = 'independence';    t = 'Independence' },
  @{ n = 'outdoor';         t = 'Outdoor play' },
  @{ n = 'emotions';        t = 'Emotions' },
  @{ n = 'festivals';       t = 'Festivals' },
  @{ n = 'teacher';         t = 'Preschool teaching' }
)
foreach ($g in $journal) {
  New-PlaceholderSvg -Path (Join-Path $siteRoot ("assets\journal\" + $g.n + ".svg")) -Title $g.t
}

# ---- Teacher training ----
$training = @(
  @{ n = 'training-1'; t = 'Training session' },
  @{ n = 'training-2'; t = 'Workshop' },
  @{ n = 'training-3'; t = 'Classroom practice' },
  @{ n = 'training-4'; t = 'Activities' },
  @{ n = 'training-5'; t = 'Group learning' },
  @{ n = 'training-6'; t = 'Certificate distribution' }
)
foreach ($g in $training) {
  New-PlaceholderSvg -Path (Join-Path $siteRoot ("assets\training\" + $g.n + ".svg")) -Title $g.t
}

Write-Host "All placeholder images generated."
