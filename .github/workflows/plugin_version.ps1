Function Build-Version {
    # If we're on main, invoke semantic release to get the next version
    if (${env:GITHUB_REF} -eq "refs/heads/main" -or ${env:GITHUB_REF} -eq "refs/heads/master" -or ${env:GITHUB_REF} -eq "refs/heads/alpha" -or ${env:GITHUB_REF} -eq "refs/heads/beta")
    {
        if (-not (Test-Path ".\\package.json"))
        {
            return "non-release-build"
        }

        $semanticRelease = yarn semantic-release --dry-run | Select-String -Pattern "Published release ((0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?)"
        if ($semanticRelease.Matches -eq $null)
        {
            return "non-release-build"
        }
        else
        {
            return $semanticRelease.Matches.Groups[1].value;
        }
    } else
    {
        return "non-release-build"
    }
}

$buildVersion = Build-Version;
echo "Building version $buildVersion"
$versionFile = ".\\vSMR\\SMRPlugin.hpp"
$pattern = '(^\s*#define\s+MY_PLUGIN_VERSION\s+").*("\s*$)'

if (-not (Test-Path $versionFile))
{
    throw "Cannot find plugin version file at $versionFile"
}

(Get-Content $versionFile) -replace $pattern, "`$1$buildVersion`$2" | Set-Content $versionFile
