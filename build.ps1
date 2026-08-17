$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$parts = Join-Path $root '_parts'
$contentDir = Join-Path $parts 'content'
$dataDir = Join-Path $root '_data'
$journalDir = Join-Path $root 'journal'

function Read-Text([string]$Path) {
  return [System.IO.File]::ReadAllText($Path)
}

$top = Read-Text (Join-Path $parts 'top.html')
$bottom = Read-Text (Join-Path $parts 'bottom.html')
$utf8 = New-Object System.Text.UTF8Encoding($false)

$tokens = 'INDEX', 'ABOUT', 'PROGRAMS', 'FRAMEWORK', 'SAFETY', 'CONTACT', 'JOURNAL', 'MOMENTS', 'TRAINING'

function Build-Page {
  param(
    [string]$Title,
    [string]$Desc,
    [string]$Prefix,
    [string]$Active,
    [string[]]$Contents,
    [string]$Out,
    [string]$Page = '',
    [hashtable]$Replace = @{},
    [string]$Body = ''
  )
  $h = $top
  $h = $h.Replace('{{TITLE}}', $Title).Replace('{{DESC}}', $Desc).Replace('{{P}}', $Prefix).Replace('{{PAGE}}', $Page)
  foreach ($t in $tokens) {
    $tok = '{{ACTIVE_' + $t + '}}'
    if ($t -eq $Active) {
      $h = $h.Replace($tok, 'class="active"')
    } else {
      $h = $h.Replace($tok, '')
    }
  }
  if ($Body) {
    $body = $Body.Replace('{{P}}', $Prefix)
  } else {
    $body = ''
    foreach ($c in $Contents) {
      $f = Join-Path $contentDir ($c + '.html')
      $body += (Read-Text $f).Replace('{{P}}', $Prefix)
    }
  }
  foreach ($k in $Replace.Keys) {
    $body = $body.Replace($k, [string]$Replace[$k])
  }
  $b = $bottom.Replace('{{P}}', $Prefix)
  [System.IO.File]::WriteAllText($Out, $h + $body + $b, $utf8)
  Write-Host "Built: $Out"
}

# ---------- data ----------
$journal = Read-Text (Join-Path $dataDir 'journal.json') | ConvertFrom-Json
$moments = Read-Text (Join-Path $dataDir 'moments.json') | ConvertFrom-Json
$training = Read-Text (Join-Path $dataDir 'training.json') | ConvertFrom-Json

# ---------- helpers ----------
function Format-Date {
  param([string]$Iso)
  $d = [datetime]::ParseExact($Iso, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
  return $d.ToString('d MMM yyyy', [System.Globalization.CultureInfo]::GetCultureInfo('en-GB'))
}

function Escape-JsonString {
  param([string]$Value)
  return $Value.Replace('\', '\\').Replace('"', '\"').Replace("`r", ' ').Replace("`n", ' ')
}

function Convert-JournalBody {
  param([object[]]$Blocks)
  $html = ''
  foreach ($b in $Blocks) {
    switch ($b.t) {
      'p'     { $html += '<p>' + $b.v + '</p>' + "`n" }
      'h2'    { $html += '<h2>' + $b.v + '</h2>' + "`n" }
      'quote' { $html += '<blockquote>' + $b.v + '</blockquote>' + "`n" }
      'ul'    { $items = ($b.v | ForEach-Object { '<li>' + $_ + '</li>' }) -join ''; $html += '<ul>' + $items + '</ul>' + "`n" }
      'ol'    { $items = ($b.v | ForEach-Object { '<li>' + $_ + '</li>' }) -join ''; $html += '<ol>' + $items + '</ol>' + "`n" }
    }
  }
  return $html.TrimEnd("`r`n")
}

function Get-CategoryLabel {
  param($Slug)
  $cat = $journal.categories | Where-Object { $_.slug -eq $Slug }
  if ($cat) { return $cat.label }
  return $Slug
}

$arrowSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="size-4" aria-hidden="true"><path d="M5 12h14"></path><path d="m12 5 7 7-7 7"></path></svg>'

function Render-JournalCard {
  param($A, [string]$Prefix)
  $url = $Prefix + 'journal/' + $A.slug + '.html'
  if ($Prefix -eq '../') { $url = '../journal/' + $A.slug + '.html' }
  if ($Prefix -eq '') { $url = 'journal/' + $A.slug + '.html' }
  if ($Prefix -eq '~') { $url = $A.slug + '.html' }
  $img = $Prefix + $A.image
  if ($Prefix -eq '~') { $img = '../' + $A.image }
  return @"
<article class="journal-card" data-category="$($A.category)">
  <a class="journal-card-media" href="$url" tabindex="-1" aria-hidden="true">
    <img src="$img" alt="$($A.imageAlt)" loading="lazy" />
    <span class="journal-card-cat" data-i18n="journal.cat.$($A.category).label">$(Get-CategoryLabel $A.category)</span>
  </a>
  <div class="journal-card-body">
    <h3 class="journal-card-title"><a href="$url" data-i18n="journal.$($A.slug).title">$($A.title)</a></h3>
    <p class="journal-card-excerpt" data-i18n="journal.$($A.slug).excerpt">$($A.excerpt)</p>
    <div class="journal-card-meta">
      <time class="js-date" datetime="$($A.date)" data-iso="$($A.date)">$(Format-Date $A.date)</time>
      <span class="read-time">$($A.readMinutes) <span data-i18n="article.minRead">min read</span></span>
    </div>
    <a class="journal-card-link" href="$url"><span data-i18n="common.readMore">Read article</span> $arrowSvg</a>
  </div>
</article>
"@
}

function Render-FeaturedCard {
  param($A)
  return @"
<article class="journal-featured">
  <a class="journal-featured-media" href="journal/$($A.slug).html" tabindex="-1" aria-hidden="true">
    <img src="$($A.image)" alt="$($A.imageAlt)" />
    <span class="badge-pill badge-featured">Featured</span>
  </a>
  <div class="journal-featured-body">
    <span class="journal-card-cat" data-i18n="journal.cat.$($A.category).label">$(Get-CategoryLabel $A.category)</span>
    <h2 class="journal-featured-title"><a href="journal/$($A.slug).html" data-i18n="journal.$($A.slug).title">$($A.title)</a></h2>
    <p class="journal-featured-excerpt" data-i18n="journal.$($A.slug).excerpt">$($A.excerpt)</p>
    <div class="journal-card-meta">
      <time class="js-date" datetime="$($A.date)" data-iso="$($A.date)">$(Format-Date $A.date)</time>
      <span class="read-time">$($A.readMinutes) <span data-i18n="article.minRead">min read</span></span>
    </div>
    <a href="journal/$($A.slug).html" class="btn btn-primary"><span data-i18n="common.readMore">Read article</span> $arrowSvg</a>
  </div>
</article>
"@
}

function Render-Chip {
  param($Slug, [string]$I18nKey, [string]$Label)
  return "<button type=`"button`" class=`"chip`" data-filter=`"$Slug`" aria-pressed=`"false`"><span data-i18n=`"$I18nKey`">$Label</span></button>"
}

function Render-MomentsItem {
  param($Img, [int]$Index)
  $label = $moments.gallery.categories | Where-Object { $_.slug -eq $Img.category }
  $labelText = if ($label) { $label.label } else { $Img.category }
  return @"
<figure class="gallery-item" data-category="$($Img.category)" data-full="$($Img.src)" data-title="$($Img.title)">
  <img src="$($Img.src)" alt="$($Img.alt)" loading="lazy" />
  <figcaption>
    <span class="gallery-cat" data-i18n="moments.cat.$($Img.category).label">$labelText</span>
    <span class="gallery-title" data-i18n="moments.item.$Index.title">$($Img.title)</span>
  </figcaption>
</figure>
"@
}

function Render-TrainingItem {
  param($Img, [int]$Index)
  $label = $training.gallery.categories | Where-Object { $_.slug -eq $Img.category }
  $labelText = if ($label) { $label.label } else { $Img.category }
  return @"
<figure class="gallery-item" data-category="$($Img.category)" data-full="$($Img.src)" data-title="$($Img.title)">
  <img src="$($Img.src)" alt="$($Img.alt)" loading="lazy" />
  <figcaption>
    <span class="gallery-cat" data-i18n="training.cat.$($Img.category).label">$labelText</span>
    <span class="gallery-title" data-i18n="training.item.$Index.title">$($Img.title)</span>
  </figcaption>
</figure>
"@
}

function Render-Testimonial {
  param($T, [int]$Index, [string]$I18nPrefix)
  return @"
<figure class="testimonial-card">
  <span class="quote-mark" aria-hidden="true">&ldquo;</span>
  <blockquote data-i18n="$I18nPrefix$Index.quote">$($T.quote)</blockquote>
  <figcaption>
    <strong data-i18n="$I18nPrefix$Index.name">$($T.name)</strong>
    <span data-i18n="$I18nPrefix$Index.role">$($T.role)</span>
  </figcaption>
</figure>
"@
}

# ---------- derived fragments ----------
# Moments gallery (homepage)
$momentChips = ''
foreach ($c in $moments.gallery.categories) {
  $momentChips += Render-Chip -Slug $c.slug -I18nKey ('moments.cat.' + $c.slug + '.label') -Label $c.label
}
$momentGrid = ''
$idx = 0
foreach ($img in $moments.gallery.images) {
  $momentGrid += Render-MomentsItem -Img $img -Index $idx
  $idx++
}
$parentTestimonials = ''
$idx = 0
foreach ($t in $moments.testimonials) {
  $parentTestimonials += Render-Testimonial -T $t -Index $idx -I18nPrefix 'moments.testimonial.'
  $idx++
}

# Moments page events
function Render-MomentEvent {
  param($E, [int]$Index)
  $dateDisplay = Format-Date $E.date
  $photosHtml = ''
  $pIdx = 0
  foreach ($p in $E.photos) {
    $photosHtml += '<figure class="event-photo" data-full="' + $p.src + '" data-title="' + $p.title + '"><img src="' + $p.src + '" alt="' + $p.alt + '" loading="lazy" /><figcaption>' + $p.title + '</figcaption></figure>' + "`n"
    $pIdx++
  }
  $videosHtml = ''
  foreach ($v in $E.videos) {
    $videosHtml += '<div class="event-video"><iframe src="' + $v.src + '" title="' + $v.title + '" frameborder="0" allowfullscreen loading="lazy"></iframe></div>' + "`n"
  }
  return @"
<div class="event-card">
  <div class="event-meta">
    <time class="js-date event-date" datetime="$($E.date)" data-iso="$($E.date)">$dateDisplay</time>
  </div>
  <h2 class="event-title" data-i18n="moments.event.$Index.title">$($E.title)</h2>
  <p class="event-desc" data-i18n="moments.event.$Index.desc">$($E.description)</p>
  <div class="event-photos" data-lightbox>
    $photosHtml
  </div>
  $videosHtml
</div>
"@
}

$eventsHtml = ''
$eIdx = 0
foreach ($e in $moments.events) {
  $eventsHtml += Render-MomentEvent -E $e -Index $eIdx
  $eIdx++
}

# Training gallery
$trainingChips = ''
foreach ($c in $training.gallery.categories) {
  $trainingChips += Render-Chip -Slug $c.slug -I18nKey ('training.cat.' + $c.slug + '.label') -Label $c.label
}
$trainingGrid = ''
$idx = 0
foreach ($img in $training.gallery.images) {
  $trainingGrid += Render-TrainingItem -Img $img -Index $idx
  $idx++
}
$trainingTestimonials = ''
$idx = 0
foreach ($t in $training.testimonials) {
  $trainingTestimonials += Render-Testimonial -T $t -Index $idx -I18nPrefix 'training.testimonial.'
  $idx++
}

# Journal cards (sorted newest first)
$sorted = @($journal.articles | Sort-Object -Property date -Descending)
$featured = $sorted | Where-Object { $_.featured } | Select-Object -First 1
$featuredCard = Render-FeaturedCard -A $featured
$journalCards = ''
foreach ($a in $sorted) {
  if ($a.slug -eq $featured.slug) { continue }
  $journalCards += Render-JournalCard -A $a -Prefix ''
}
$journalChips = ''
foreach ($c in $journal.categories) {
  $journalChips += Render-Chip -Slug $c.slug -I18nKey ('journal.cat.' + $c.slug + '.label') -Label $c.label
}

# Homepage journal preview: latest 3
$journalPreview = ''
foreach ($a in ($sorted | Select-Object -First 3)) {
  $journalPreview += Render-JournalCard -A $a -Prefix ''
}

# Homepage training preview images: first 3 training images
$trainingPreview = ''
foreach ($img in ($training.gallery.images | Select-Object -First 3)) {
  $trainingPreview += '<img src="' + $img.src + '" alt="' + $img.alt + '" loading="lazy" />' + "`n"
}

# ---------- titles ----------
$rootTitle = 'First Step Preschool'
$rootDesc = "Shri Swami Samarth Krupa Foundation's First Step Preschool, Nashik. Playgroup, Nursery, Junior KG and Senior KG for children aged 2 to 6 years."

$aboutTitle = 'First Step Preschool'
$aboutDesc = 'First Step Preschool is run by Shri Swami Samarth Krupa Foundation in Satpur, Nashik. Our story, vision, mission and the values we bring to every child.'

$programsTitle = 'First Step Preschool'
$programsDesc = 'Four programs at First Step Preschool, Satpur Nashik: Playgroup, Nursery, Junior KG and Senior KG for children aged 2 to 6 years.'

$frameworkTitle = 'First Step Preschool'
$frameworkDesc = 'The First Step Growth Framework: six areas of development - language, numeracy, movement, social skills, confidence, creativity - that guide learning for children aged 2 to 6.'

$safetyTitle = 'First Step Preschool'
$safetyDesc = 'Safety and care at First Step Preschool, Satpur Nashik: large separate classrooms, 5500 sq ft campus, CCTV coverage, government registration and van service.'

$admissionsTitle = 'First Step Preschool'
$admissionsDesc = 'Admission open at First Step Preschool, Satpur Nashik for children aged 2 to 6 years. Send your enquiry on WhatsApp and visit the school.'

$contactTitle = 'First Step Preschool'
$contactDesc = 'Contact First Step Preschool, Satpur, Nashik. Visit us, call +91 88500 75624, or message us on WhatsApp.'

$journalTitle = 'First Step Preschool - Journal'
$journalDesc = 'First Step Journal: practical articles for parents on child development, parenting, school readiness, early learning and life at First Step Preschool.'

$trainingTitle = 'First Step Preschool - Teacher Training'
$trainingDesc = 'First Step Preschool Teacher Training Program by Shri Swami Samarth Krupa Foundation: a 9-month practical preschool teacher training programme with hands-on experience and certification.'

$momentsTitle = 'First Step Preschool - Moments'
$momentsDesc = 'Photos, videos and memories from celebrations, activities and everyday life at First Step Preschool, Satpur Nashik.'

# ---------- pages ----------
Build-Page -Title $rootTitle -Desc $rootDesc -Prefix '' -Active INDEX -Contents @('index-1', 'index-2', 'index-3') -Out $root\index.html -Page 'home' -Replace @{
  '{{MOMENT_FILTERS}}'    = $momentChips
  '{{MOMENT_GRID}}'       = $momentGrid
  '{{PARENT_TESTIMONIALS}}' = $parentTestimonials
  '{{JOURNAL_PREVIEW}}'   = $journalPreview
  '{{TRAINING_PREVIEW_IMAGES}}' = $trainingPreview
}
Build-Page -Title $aboutTitle -Desc $aboutDesc -Prefix '' -Active ABOUT -Contents @('about') -Out $root\about.html -Page 'about'
Build-Page -Title $programsTitle -Desc $programsDesc -Prefix '' -Active PROGRAMS -Contents @('programs') -Out $root\programs.html -Page 'programs'
Build-Page -Title $frameworkTitle -Desc $frameworkDesc -Prefix '' -Active FRAMEWORK -Contents @('framework') -Out $root\framework.html -Page 'framework'
Build-Page -Title $safetyTitle -Desc $safetyDesc -Prefix '' -Active SAFETY -Contents @('safety') -Out $root\safety.html -Page 'safety'
Build-Page -Title $admissionsTitle -Desc $admissionsDesc -Prefix '' -Contents @('admissions') -Out $root\admissions.html -Page 'admissions'
Build-Page -Title $contactTitle -Desc $contactDesc -Prefix '' -Active CONTACT -Contents @('contact') -Out $root\contact.html -Page 'contact'

Build-Page -Title $journalTitle -Desc $journalDesc -Prefix '' -Active JOURNAL -Contents @('journal') -Out $root\journal.html -Page 'journal' -Replace @{
  '{{JOURNAL_FEATURED}}' = $featuredCard
  '{{JOURNAL_FILTERS}}'  = $journalChips
  '{{JOURNAL_CARDS}}'    = $journalCards
}

Build-Page -Title $momentsTitle -Desc $momentsDesc -Prefix '' -Active MOMENTS -Contents @('moments') -Out $root\moments.html -Page 'moments' -Replace @{
  '{{EVENTS}}' = $eventsHtml
}

$trainingJsonLd = @"
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Course",
  "name": "First Step Preschool Teacher Training Program",
  "description": "A 9-month practical preschool teacher training programme with hands-on classroom experience and certification.",
  "provider": {
    "@type": "Organization",
    "name": "Shri Swami Samarth Krupa Foundation's First Step Preschool"
  },
  "learningResourceType": "Preschool teacher training"
}
</script>
"@

Build-Page -Title $trainingTitle -Desc $trainingDesc -Prefix '' -Active TRAINING -Contents @('teacher-training') -Out $root\teacher-training.html -Page 'training' -Replace @{
  '{{TRAINING_FILTERS}}'    = $trainingChips
  '{{TRAINING_GALLERY}}'    = $trainingGrid
  '{{TRAINING_TESTIMONIALS}}' = $trainingTestimonials
  '{{TRAINING_JSONLD}}'     = $trainingJsonLd
}

# programs - subdirectory
Build-Page -Title "$programsTitle - Playgroup" -Desc $programsDesc -Prefix '../' -Active PROGRAMS -Contents @('program-playgroup') -Out $root\programs\playgroup.html -Page 'programs'
Build-Page -Title "$programsTitle - Nursery" -Desc $programsDesc -Prefix '../' -Active PROGRAMS -Contents @('program-nursery') -Out $root\programs\nursery.html -Page 'programs'
Build-Page -Title "$programsTitle - Junior KG" -Desc $programsDesc -Prefix '../' -Active PROGRAMS -Contents @('program-junior-kg') -Out $root\programs\junior-kg.html -Page 'programs'
Build-Page -Title "$programsTitle - Senior KG" -Desc $programsDesc -Prefix '../' -Active PROGRAMS -Contents @('program-senior-kg') -Out $root\programs\senior-kg.html -Page 'programs'

# ---------- journal article pages ----------
if (-not (Test-Path -LiteralPath $journalDir)) { New-Item -ItemType Directory -Path $journalDir | Out-Null }
$articleTemplate = Read-Text (Join-Path $contentDir 'journal-article.html')

foreach ($a in $journal.articles) {
  $related = @()
  $sameCat = $sorted | Where-Object { $_.slug -ne $a.slug -and $_.category -eq $a.category } | Select-Object -First 3
  foreach ($r in $sameCat) { $related += $r }
  if ($related.Count -lt 3) {
    $fill = $sorted | Where-Object { $_.slug -ne $a.slug -and $_.category -ne $a.category } | Select-Object -First (3 - $related.Count)
    foreach ($r in $fill) { $related += $r }
  }
  $relatedHtml = ''
  foreach ($r in $related) { $relatedHtml += Render-JournalCard -A $r -Prefix '~' }

  $langBodies = ''
  if ($a.hiBody) {
    $langBodies += '<template data-lang-body="hi">' + "`n" + (Convert-JournalBody $a.hiBody) + "`n</template>" + "`n"
  }
  if ($a.mrBody) {
    $langBodies += '<template data-lang-body="mr">' + "`n" + (Convert-JournalBody $a.mrBody) + "`n</template>" + "`n"
  }

  $jsonLd = @"
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "$(Escape-JsonString $a.title)",
  "description": "$(Escape-JsonString $a.excerpt)",
  "datePublished": "$($a.date)",
  "author": {
    "@type": "Organization",
    "name": "Shri Swami Samarth Krupa Foundation's First Step Preschool"
  },
  "publisher": {
    "@type": "Organization",
    "name": "First Step Preschool"
  }
}
</script>
"@

  $body = $articleTemplate
  $body = $body.Replace('{{A_TITLE_KEY}}', 'journal.' + $a.slug + '.title')
  $body = $body.Replace('{{A_TITLE}}', $a.title)
  $body = $body.Replace('{{A_CATEGORY_KEY}}', 'journal.cat.' + $a.category + '.label')
  $body = $body.Replace('{{A_CATEGORY_LABEL}}', (Get-CategoryLabel $a.category))
  $body = $body.Replace('{{A_DATE_ISO}}', $a.date)
  $body = $body.Replace('{{A_DATE_DISPLAY}}', (Format-Date $a.date))
  $body = $body.Replace('{{A_READ_MINUTES}}', [string]$a.readMinutes)
  $body = $body.Replace('{{A_IMAGE}}', $a.image)
  $body = $body.Replace('{{A_IMAGE_ALT}}', $a.imageAlt)
  $body = $body.Replace('{{A_BODY}}', (Convert-JournalBody $a.body))
  $body = $body.Replace('{{A_LANG_BODIES}}', $langBodies)
  $body = $body.Replace('{{RELATED_CARDS}}', $relatedHtml)
  $body = $body.Replace('{{A_JSONLD}}', $jsonLd)

  Build-Page -Title ($a.title + ' | First Step Preschool') -Desc $a.excerpt -Prefix '../' -Active JOURNAL -Out (Join-Path $journalDir ($a.slug + '.html')) -Page 'article' -Body $body
}

Write-Host 'All pages built.'
