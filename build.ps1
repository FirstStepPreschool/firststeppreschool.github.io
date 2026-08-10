$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$parts = Join-Path $root '_parts'
$contentDir = Join-Path $parts 'content'

$top = Get-Content (Join-Path $parts 'top.html') -Raw
$bottom = Get-Content (Join-Path $parts 'bottom.html') -Raw

$utf8 = New-Object System.Text.UTF8Encoding($false)

$tokens = 'INDEX', 'ABOUT', 'PROGRAMS', 'FRAMEWORK', 'SAFETY', 'ADMISSIONS', 'CONTACT'

function Build-Page {
  param(
    [string]$Title,
    [string]$Desc,
    [string]$Prefix,
    [string]$Active,
    [string[]]$Contents,
    [string]$Out
  )
  $h = $top
  $h = $h.Replace('{{TITLE}}', $Title).Replace('{{DESC}}', $Desc).Replace('{{P}}', $Prefix)
  foreach ($t in $tokens) {
    $tok = '{{ACTIVE_' + $t + '}}'
    if ($t -eq $Active) {
      $h = $h.Replace($tok, 'class="active"')
    } else {
      $h = $h.Replace($tok, '')
    }
  }
  $body = ''
  foreach ($c in $Contents) {
    $f = Join-Path $contentDir $c
    $body += (Get-Content $f -Raw).Replace('{{P}}', $Prefix)
  }
  $b = $bottom.Replace('{{P}}', $Prefix)
  [System.IO.File]::WriteAllText($Out, $h + $body + $b, $utf8)
  Write-Host "Built: $Out"
}

$rootTitle = 'First Step Preschool, Satpur Nashik | Playgroup to Senior KG'
$rootDesc = "Shri Swami Samarth Krupa Foundation's First Step Preschool, Nashik. Playgroup, Nursery, Junior KG and Senior KG for children aged 2 to 6 years."

$aboutTitle = 'About First Step Preschool | Satpur, Nashik'
$aboutDesc = 'First Step Preschool is run by Shri Swami Samarth Krupa Foundation in Satpur, Nashik. Our story, vision, mission and the values we bring to every child.'

$programsTitle = 'Programs | Playgroup, Nursery, Junior KG, Senior KG - Nashik'
$programsDesc = 'Four programs at First Step Preschool, Satpur Nashik: Playgroup, Nursery, Junior KG and Senior KG, for children aged 2 to 6 years.'

$frameworkTitle = 'Our Approach & Growth Framework | First Step Preschool'
$frameworkDesc = 'The First Step Growth Framework: six areas of child development for ages 2 to 6 - language, numeracy, movement, social skills, confidence and creativity.'

$safetyTitle = 'Safety, Care & Facilities | First Step Preschool, Nashik'
$safetyDesc = 'A 5500 sq ft campus with 2500 sq ft of classrooms, a 3000 sq ft private playground, full CCTV coverage, digital learning setup and van service at First Step Preschool, Satpur, Nashik.'

$admissionsTitle = 'Admissions Open 2026 | First Step Preschool, Satpur Nashik'
$admissionsDesc = 'Admission enquiry for Playgroup, Nursery, Junior KG and Senior KG at First Step Preschool, Shramik Nagar, Satpur, Nashik. Ages 2 to 6 years.'

$contactTitle = 'Contact & Location | First Step Preschool, Satpur Nashik'
$contactDesc = 'Visit First Step Preschool at Plot No. 8, Jay Ganesh Colony No. 1, Shramik Nagar, Satpur, Nashik 422007. Call +91 88500 75624 or WhatsApp us.'

Build-Page -Title $rootTitle -Desc $rootDesc -Prefix '' -Active 'INDEX' -Contents @('index-1.html', 'index-2.html') -Out (Join-Path $root 'index.html')
Build-Page -Title $aboutTitle -Desc $aboutDesc -Prefix '' -Active 'ABOUT' -Contents @('about.html') -Out (Join-Path $root 'about.html')
Build-Page -Title $programsTitle -Desc $programsDesc -Prefix '' -Active 'PROGRAMS' -Contents @('programs.html') -Out (Join-Path $root 'programs.html')
Build-Page -Title $frameworkTitle -Desc $frameworkDesc -Prefix '' -Active 'FRAMEWORK' -Contents @('framework.html') -Out (Join-Path $root 'framework.html')
Build-Page -Title $safetyTitle -Desc $safetyDesc -Prefix '' -Active 'SAFETY' -Contents @('safety.html') -Out (Join-Path $root 'safety.html')
Build-Page -Title $admissionsTitle -Desc $admissionsDesc -Prefix '' -Active 'ADMISSIONS' -Contents @('admissions.html') -Out (Join-Path $root 'admissions.html')
Build-Page -Title $contactTitle -Desc $contactDesc -Prefix '' -Active 'CONTACT' -Contents @('contact.html') -Out (Join-Path $root 'contact.html')

Build-Page -Title 'Playgroup (2+ years) | First Step Preschool, Nashik' -Desc 'The gentlest possible start. Playgroup is about a child feeling safe away from home for the first time - learning that school is a warm, happy place.' -Prefix '../' -Active 'PROGRAMS' -Contents @('program-playgroup.html') -Out (Join-Path $root 'programs\playgroup.html')
Build-Page -Title 'Nursery (3+ years) | First Step Preschool, Nashik' -Desc 'Curiosity year. Children ask a hundred questions a day, and Nursery is built around answering them through doing rather than telling.' -Prefix '../' -Active 'PROGRAMS' -Contents @('program-nursery.html') -Out (Join-Path $root 'programs\nursery.html')
Build-Page -Title 'Junior KG (4+ years) | First Step Preschool, Nashik' -Desc 'The year skills come together. Junior KG turns play into early reading, early writing and early thinking - without ever losing the play.' -Prefix '../' -Active 'PROGRAMS' -Contents @('program-junior-kg.html') -Out (Join-Path $root 'programs\junior-kg.html')
Build-Page -Title 'Senior KG (5+ years) | First Step Preschool, Nashik' -Desc 'The bridge to big school. Senior KG prepares a child academically, socially and emotionally for Standard 1 - so the change feels exciting, not frightening.' -Prefix '../' -Active 'PROGRAMS' -Contents @('program-senior-kg.html') -Out (Join-Path $root 'programs\senior-kg.html')
