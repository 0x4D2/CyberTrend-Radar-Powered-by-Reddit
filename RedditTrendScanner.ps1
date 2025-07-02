<#
.SYNOPSIS
    Reddit Cybersecurity Trend Radar 3.2 
.DESCRIPTION
    Sammelt Top-Trends aus Security-Subreddits und exportiert Analysen
.NOTES
    Version: 3.2 
#>

param (
    [string[]]$Subreddits = @("cybersecurity", "hacking", "netsec", "privacy", "Malware"),
    [int]$Limit = 15,
    [switch]$ExportCSV,
    [string]$OutputFolder = ".\RedditTrends_$(Get-Date -Format 'yyyyMMdd_HHmm')"
)

# API-Abfrage 
function Get-SubredditData {
    param (
        [string]$Subreddit,
        [int]$Limit
    )
    try {
        $uri = "https://www.reddit.com/r/$Subreddit/hot.json?limit=$Limit"
        $response = Invoke-RestMethod -Uri $uri -Headers @{ "User-Agent" = "RedditTrendScanner/3.2" } -ErrorAction Stop
        return $response.data.children
    }
    catch {
        Write-Warning "[!] Fehler beim Abrufen von r/$Subreddit : $_"
        return $null
    }
}


try {
    # Output-Ordner erstellen
    if ($ExportCSV) {
        New-Item -ItemType Directory -Path $OutputFolder -Force -ErrorAction Stop | Out-Null
        Write-Host "[i] Exportordner erstellt: $OutputFolder" -ForegroundColor Cyan
    }

    # Daten sammeln
    Write-Host "[i] Sammle Daten von Reddit..." -ForegroundColor Cyan
    $allPosts = @()
    foreach ($sub in $Subreddits) {
        Write-Host "  [+] Verarbeite r/$sub..." -ForegroundColor DarkCyan
        $posts = Get-SubredditData -Subreddit $sub -Limit $Limit
        
        if ($posts) {
            foreach ($post in $posts) {
                try {
                    $postDate = (Get-Date "1970-01-01T00:00:00Z").AddSeconds($post.data.created_utc)
                    if ($postDate -gt (Get-Date).AddYears(-2)) {
                        $engagement = if ($post.data.score -gt 0) { 
                            [math]::Round(($post.data.num_comments / $post.data.score) * 100, 2) 
                        } else { 0 }

                        $allPosts += [PSCustomObject]@{
                            Subreddit  = $sub
                            Title      = $post.data.title
                            Upvotes    = $post.data.score
                            Comments   = $post.data.num_comments
                            CreatedUTC = $postDate.ToString("yyyy-MM-dd HH:mm:ss")
                            URL        = "https://reddit.com" + $post.data.permalink
                            Engagement = $engagement
                        }
                    }
                }
                catch {
                    Write-Warning "  [!] Fehler beim Verarbeiten eines Posts in r/$sub : $_"
                }
            }
        }
        Start-Sleep -Milliseconds 1000 # Rate-Limit
    }

    $trendReport = $allPosts | Sort-Object -Property Upvotes -Descending

    # Keyword-Erkennung
    $keywordPatterns = @(
        "NIS2", "ransomware|Babuk|LockBit", "zero.?day", "phishing", "AI|Künstliche Intelligenz", 
        "Microsoft|MSFT", "CVE-\d{4}-\d+", "MFA|2FA", "VPN", "cloud|Azure|AWS", "IoT"
    )

    $trendAnalysis = foreach ($pattern in $keywordPatterns) {
        $matchingPosts = $allPosts | Where-Object { $_.Title -match $pattern }
        if ($matchingPosts -and $matchingPosts.Count -gt 0) {
            [PSCustomObject]@{
                Trend        = $pattern
                Frequency   = $matchingPosts.Count
                AvgUpvotes  = [math]::Round(($matchingPosts.Upvotes | Measure-Object -Average).Average)
                AvgEngagement = [math]::Round(($matchingPosts.Engagement | Measure-Object -Average).Average)
                ExamplePost = ($matchingPosts | Sort-Object Upvotes -Descending)[0].Title
                ExampleURL  = ($matchingPosts | Sort-Object Upvotes -Descending)[0].URL
            }
        }
    }


    $contentHooks = $trendReport.Title | Select-Object -First 5 | ForEach-Object {
        "🔥 `"$($_.Split(':')[0].Trim()) – aber diese unbequeme Wahrheit verschweigt Reddit`""
    }

    # CSV-Export
    if ($ExportCSV -and $allPosts.Count -gt 0) {
        try {
            # Rohdaten
            $rawDataPath = Join-Path -Path $OutputFolder -ChildPath "RawTrendData.csv"
            $trendReport | Export-Csv -Path $rawDataPath -NoTypeInformation -Delimiter ";" -Encoding UTF8 -Force
            
            # Trend-Analyse
            $analysisPath = Join-Path -Path $OutputFolder -ChildPath "TrendAnalysis.csv"
            $trendAnalysis | Sort-Object Frequency -Descending | Export-Csv -Path $analysisPath -NoTypeInformation -Delimiter ";" -Encoding UTF8 -Force
            
            # Content-Hooks
            $hooksPath = Join-Path -Path $OutputFolder -ChildPath "ContentHooks.txt"
            $contentHooks | Out-File -FilePath $hooksPath -Encoding UTF8 -Force

            Write-Host "[✓] Export erfolgreich:" -ForegroundColor Green
            Write-Host "  - Rohdaten: $rawDataPath ($($allPosts.Count) Einträge)"
            Write-Host "  - Trend-Analyse: $analysisPath"
            Write-Host "  - Content-Hooks: $hooksPath"
        }
        catch {
            Write-Warning "[!] Fehler beim Export: $_"
        }
    }

    # Konsolenausgabe
    if ($allPosts.Count -gt 0) {
        Write-Host "`n=== TOP 5 TRENDS NACH ENGAGEMENT ===" -ForegroundColor Cyan
        $trendReport | Select-Object -First 5 | Format-Table -Property @(
            @{Label="Subreddit"; Expression={$_.Subreddit}},
            @{Label="Titel"; Expression={$_.Title.Substring(0, [math]::Min(50, $_.Title.Length)) + "..."}},
            @{Label="Upvotes"; Expression={$_.Upvotes}; Alignment="Right"},
            @{Label="Engagement"; Expression={"$($_.Engagement)%"}; Alignment="Right"}
        ) -AutoSize

        if ($trendAnalysis) {
            Write-Host "`n=== TOP 3 TREND-KEYWORDS ===" -ForegroundColor Cyan
            $trendAnalysis | Sort-Object Frequency -Descending | Select-Object -First 3 | Format-Table -AutoSize
        }

        Write-Host "`n=== CONTENT-HOOKS ===" -ForegroundColor Magenta
        $contentHooks | ForEach-Object {
            Write-Host "- $_" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "[!] Keine Posts gefunden oder alle gefiltert" -ForegroundColor Red
    }
}
catch {
    Write-Host "[!!!] KRITISCHER FEHLER: $_" -ForegroundColor Red
}
finally {
    Write-Host "`n[i] Skriptausführung beendet" -ForegroundColor Gray
}