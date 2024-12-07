<#
.SYNOPSIS
    This script takes a list of Spotify track links from a text file, retrieves links for specified music platforms (e.g., Apple Music, Tidal, etc.) using the Song.link API,
    and generates a report with track information and the platform-specific link.

.DESCRIPTION
    The script processes each Spotify track link by querying the Song.link API to fetch the song details and platform-specific URLs. The output includes:
	Target Platform (e.g., Apple Music, Tidal,)
	Artist Name
	Track Title
	Link to the specified platform
	Results are displayed in the console as a table and saved to a CSV file for further use.
	
	The input file should be a plain text file where each line contains a Spotify track link. Here's an example of the file content:
	spotify_links.txt
	https://open.spotify.com/track/65g4Cb7UOVsJlPiXfAElCF  
	https://open.spotify.com/track/3n3Ppam7vgaVa1iaRUc9Lp  
	https://open.spotify.com/track/1Jk7hKV07oNwS6C6AABz2o 
	

.EXAMPLE
    .\Get-SongLinks.ps1 -InputFile "C:\songs\spotify_links.txt" -Platform "tidal"

.NOTES
    Version : 07.12.2024
    Responsible person : Vitales
#>


param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile, # Path to file with list of links (each link from new line)

    [Parameter(Mandatory=$true)]
    [string]$Platform  # Platform name ( "spotify", "appleMusic", "tidal", "youtubeMusic")
)

# Function to execute API request and answer processing
function Get-SongLinks {
    param(
        [string]$Url,
        [string]$TargetPlatform
    )

    $ApiUrl = "https://api.song.link/v1-alpha.1/links?url=$Url"

    try {
        # Get-request execution
        $Response = Invoke-RestMethod -Uri $ApiUrl -Method Get

        # Platform data availability check
        if ($Response.linksByPlatform.$TargetPlatform) {
            $SongData = $Response.linksByPlatform.$TargetPlatform

            # Extracting the artist and track information from entities
            $EntityId = $SongData.entityUniqueId
            $Entity = $Response.entitiesByUniqueId.$EntityId

            # Result of request
            $Result = [PSCustomObject]@{
                "Artist"        = $Entity.artistName + " - " + $Entity.title
                "Platform Link" = $SongData.url
            }

            return $Result
        } else {
            Write-Warning "Platform '$TargetPlatform' not found for URL '$Url'."
        }
    }
    catch {
        Write-Error "Error fetching data for URL '$Url': $_"
    }
}

# Reading the file’s list of links
if (-Not (Test-Path $InputFile)) {
    Write-Error "Input file not found: $InputFile"
    exit
}

$Links = Get-Content -Path $InputFile

# Collect results in list
$Results = @()

foreach ($Link in $Links) {
    if (-Not [string]::IsNullOrWhiteSpace($Link)) {
        Write-Host "Processing link: $Link" -ForegroundColor Cyan
        $Result = Get-SongLinks -Url $Link -TargetPlatform $Platform
        if ($Result) {
            $Results += $Result
        }
    }
}

# Output results to table
if ($Results) {
    Write-Host "`nResults:" -ForegroundColor Green
    $Results | Format-Table -AutoSize
} else {
    Write-Host "No results found." -ForegroundColor Yellow
}

# Optional: export results to CSV
$OutputFile = "SongLinks_Output.csv"
$Results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
Write-Host "`nResults saved to $OutputFile" -ForegroundColor Green
