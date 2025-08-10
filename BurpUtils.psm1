function Get-LatestStableBurpVersion {
    $url = "https://portswigger.net/burp/releases#professional"
    $html = Invoke-WebRequest -Uri $url -UseBasicParsing
    $versionMatches = [regex]::Matches($html.Content, 'Professional / Community ([0-9]+\.[0-9]+(\.[0-9]+)?)')

    if ($versionMatches.Count -ge 2) {
        return $versionMatches[1].Groups[1].Value
    }
    else {
        return $null
    }
}

Export-ModuleMember -Function Get-LatestStableBurpVersion
