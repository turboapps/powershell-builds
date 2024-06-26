Function RunVersionCheck {

#############################################
## Get the current Hub version for the app ##
#############################################

$HubVersion = GetCurrentHubVersion $HubOrg

#############################################
## Get latest version from the vendor site ##
#############################################

# Scrape the official MS office release page to get the latest "Current Channel" build version
# This code was parsed from https://github.com/DataForNerds/public/blob/main/scripts/ms/msapps/m365buildnumbers.ps1
$rootPage = "https://docs.microsoft.com/en-us/officeupdates/update-history-microsoft365-apps-by-date"

$pageData = Invoke-WebRequest $rootPage -UseBasicParsing

If($pageData.StatusCode -ne 200) {
    Throw "Error $($pageData.StatusCode) Getting Page Data"
}

$tables = [regex]::New('(?msi)<table>(?:.*?)<tbody>(.*?)<\/tbody>').Matches($pageData.Content)
$versionHistoryRows = [regex]::New('(?msi)<tr>(.*?)<\/tr>').Matches($tables[1].Groups[1].Value)
$m365Releases = New-Object System.Collections.ArrayList

$rxInnerLink = [Regex]::New('(?msi)<a(?:[^>])*>(.*?)<\/a>')
$rxVersionBuild = [Regex]::New('(?msi)Version (.*?) \(Build {1,}(.*?)\)')

$versionHistoryRows.ForEach{

    $cellData = [regex]::New('(?msi)<td(?:[^>]*)>(.*?)<\/td>').Matches($_.Groups[1].Value)
    $channelCurrentLinks = $rxInnerLink.Matches($cellData[2].Groups[1].Value)
    $allLinks = New-Object System.Collections.ArrayList
    $allLinks.AddRange(@($channelCurrentLinks.groups.where{$_.Name -eq 1} | Select-Object @{Name="Channel";Expression={"Current"}},@{Name="Value";Expression={$_.Value}}))

    $allLinks.ForEach{
        $versionBuild = $rxVersionBuild.Matches($_.Value)
            
        $thisChannel = $_.Channel

        $versionBuild.ForEach{
            $m365Releases.Add(
                [PSCustomObject]@{
                    FullBuild = "16.0.$($_.Groups[2].Value)"
                }
            ) | Out-Null
        }
    }

}

$m365Releases = $m365Releases | Select-Object FullBuild -Unique -First 1

$LatestWebVersion = $m365Releases.FullBuild
$LatestWebVersion = RemoveTrailingZeros "$LatestWebVersion"

WriteLog "WebVersion=$LatestWebVersion"


###########################################
## Compare latest version to hub version ##
###########################################

Compare-Versions $HubVersion $LatestWebVersion #Script will exit if Hub version is the same or newer.

}
