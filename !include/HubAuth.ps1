# Turbo Server sign-in for servers and clients on either side of the 2.0 sign-in change.
#
# Kept identical in turboapps/powershell-tests (!include), turboapps/powershell-builds (!include)
# and codesystems/applab (AppPipeline/Shared): change all three together.
#
# A credential is one string, so it goes wherever an API key already goes (an -ApiKey
# parameter, a repo secret, secrets.txt):
#   <api key>                           a Turbo Server before 2.0
#   client:<client id>:<client secret>  a registered OAuth client on a 2.0 server
#                                       (Admin > Identity > Clients)
#
# Turbo Client 26.10 retired `turbo login --api-key`; older clients have no `--client-id`.
# Connect-TurboServer picks what works for the client and server in hand:
#   client credential                -> turbo login --client-id --client-secret (26.10+ client)
#   API key, client before 26.10     -> turbo login --api-key
#   API key, client 26.10+           -> the key is exchanged for the server's 1.0 ticket, which that
#                                       client reads from TURBO_ACCESS_TOKEN (process scope: only
#                                       turbo commands started from this process inherit it)
# A client before 26.10 cannot sign in to a 2.0 server at all.

function ConvertFrom-TurboCredential {
    param ([string]$Credential)
    if ($Credential -match '^client:([^:]+):(.+)$') {
        return @{ ClientId = $Matches[1]; ClientSecret = $Matches[2]; ApiKey = $null }
    }
    return @{ ClientId = $null; ClientSecret = $null; ApiKey = $Credential }
}

function Get-TurboServerUrl {
    param ([string]$Server)
    $url = $Server.Trim().TrimEnd('/')
    if ($url -notmatch '^https?://') { $url = "https://$url" }
    return $url
}

# The 1.0 ticket an API key buys. A 1.0 server redirects this request to /api/api-keys/login, so
# redirects are followed. A 2.0 server has no such exchange and its redirect ends at the sign-in
# page, which is why an empty answer or one with markup or spaces in it is an error rather than a
# ticket. Only that is checked: a ticket's own format is the server's business.
function Get-TurboApiKeyTicket {
    param ([string]$Server, [string]$ApiKey)
    $ticket = Invoke-RestMethod -Uri ((Get-TurboServerUrl $Server) + '/0.1/api-keys/login') -Method Get `
                  -Headers @{ 'X-Turbo-Api-Key' = $ApiKey } -ErrorAction Stop
    $ticket = "$ticket".Trim().Trim('"')
    if (-not $ticket -or $ticket -match '[<>\s]') {
        throw "$Server did not answer the API key exchange with a ticket (a 2.0 server needs a client:<id>:<secret> credential)"
    }
    return $ticket
}

# An access token for a registered client (OAuth client_credentials). It lasts minutes: fetch one
# per call rather than keeping it.
function Get-TurboAccessToken {
    param ([string]$Server, [string]$ClientId, [string]$ClientSecret)
    $body = @{ grant_type = 'client_credentials'; client_id = $ClientId; client_secret = $ClientSecret; scope = 'turbo' }
    $response = Invoke-RestMethod -Uri ((Get-TurboServerUrl $Server) + '/api/v1/oauth/token') -Method Post `
                    -Body $body -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop
    if (-not $response.access_token) { throw "$Server issued no access token to client $ClientId" }
    return $response.access_token
}

# The revisions of a hub repo, each with imageId and tags, or $null when the repo does not exist.
# A 1.0 hub answers a repo it does not have with 404, a 2.0 hub with an empty list; both are "no
# such repo". Every other failure, including a credential the server refuses, is thrown.
function Get-TurboHubRevisions {
    param ([string]$Server, [string]$Credential, [string]$Owner, [string]$Name)
    $base = Get-TurboServerUrl $Server
    $cred = ConvertFrom-TurboCredential $Credential
    if ($cred.ClientId) {
        $token   = Get-TurboAccessToken -Server $base -ClientId $cred.ClientId -ClientSecret $cred.ClientSecret
        $headers = @{ 'Authorization' = "Bearer $token" }
        $url     = "$base/hub/v2/_turbo/repos/$Owner/$Name/revisions"
    } else {
        $headers = @{
            'X-Turbo-Ticket'      = (Get-TurboApiKeyTicket -Server $base -ApiKey $cred.ApiKey)
            'X-Turbo-Api-Id'      = 'turbo.net'
            'X-Turbo-Api-Version' = '1'
        }
        $url = "$base/io/_hub/repo/$Owner/$Name/revisions?withTags"
    }
    try {
        # Assigned before piping: Windows PowerShell 5.1 writes a JSON array to the pipeline as
        # one object, and only a variable holding it unrolls into one item per revision.
        $response  = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
        $revisions = @($response | Where-Object { $_ })
        if ($revisions.Count -eq 0) { return $null }
        return $revisions
    } catch {
        # WebException (PS 5.1) and HttpResponseException (pwsh) both cast to int.
        $status = $null
        try { $status = [int]$_.Exception.Response.StatusCode } catch {}
        if ($status -eq 404) { return $null }
        throw
    }
}

# The client's version from `turbo version` (first dotted number in its output), or $null when it
# cannot be read.
function Get-TurboClientVersion {
    param ([string]$Turbo = 'turbo')
    try {
        $out = (& $Turbo version 2>$null | Out-String)
        if ($out -match '(\d+\.\d+(?:\.\d+){0,2})') { return [version]$Matches[1] }
    } catch {}
    return $null
}

# Points the client at $Server and signs in with $Credential (see the top of this file). Returns
# $true when signed in. The secret never reaches a command line that is logged here; the client
# masks its own arguments in its logs.
function Connect-TurboServer {
    param ([string]$Server, [string]$Credential, [string]$Turbo = 'turbo')

    # A ticket left by an earlier call outranks every stored login, whichever server it is for.
    Remove-Item Env:TURBO_ACCESS_TOKEN -ErrorAction SilentlyContinue

    # $global: a caller that assigns $LASTEXITCODE in its own scope shadows the automatic
    # variable, and a bare read here would see that copy instead of turbo's exit code.
    & $Turbo config "--domain=$Server" | Out-Host
    if ($global:LASTEXITCODE -ne 0) {
        Write-Host "turbo config --domain=$Server failed with exit code $global:LASTEXITCODE"
        return $false
    }

    $cred = ConvertFrom-TurboCredential $Credential
    if ($cred.ClientId) {
        & $Turbo login --client-id $cred.ClientId --client-secret $cred.ClientSecret | Out-Host
        if ($global:LASTEXITCODE -ne 0) {
            Write-Host "turbo login as client $($cred.ClientId) to $Server failed with exit code $global:LASTEXITCODE (needs Turbo Client 26.10 or later and a 2.0 server)"
            return $false
        }
        return $true
    }

    # The client generation decides the path, not a failed --api-key login: a client before 26.10
    # ignores TURBO_ACCESS_TOKEN, so falling back to the ticket after any failure (network, server,
    # locked config) would report it signed in when it is not.
    $clientVersion = Get-TurboClientVersion -Turbo $Turbo
    if (-not $clientVersion -or $clientVersion -lt [version]'26.10') {
        & $Turbo login --api-key $cred.ApiKey | Out-Host
        if ($global:LASTEXITCODE -eq 0) { return $true }
        if ($clientVersion) {
            Write-Host "turbo login --api-key to $Server failed with exit code $global:LASTEXITCODE (Turbo Client $clientVersion)"
            return $false
        }
        # Version unreadable: a 26.10+ client rejects --api-key, so the ticket is still worth a try.
        Write-Host "turbo login --api-key failed (exit $global:LASTEXITCODE) and the client version is unknown; exchanging the key for a ticket"
    }

    try {
        $env:TURBO_ACCESS_TOKEN = Get-TurboApiKeyTicket -Server $Server -ApiKey $cred.ApiKey
    } catch {
        Write-Host "Could not sign in to $Server with its API key: $_"
        return $false
    }
    Write-Host "Signed in to $Server through TURBO_ACCESS_TOKEN"
    return $true
}
