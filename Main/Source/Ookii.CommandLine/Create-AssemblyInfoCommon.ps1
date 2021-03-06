# This script is used to create the AssemblyInfoCommon.cs file that contains the generated assembly version.
# It is executed as part of the pre-build step for the Ookii.CommandLine project.
param(
    [parameter(Mandatory=$true, Position=1)][string]$tf,
    [parameter(Mandatory=$true, Position=2)][string]$config
)

$scriptPath = Split-Path $MyInvocation.MyCommand.Path
$inputFile = Join-Path $scriptPath AssemblyInfoCommon.cs.template
$outputFile = Join-Path $scriptPath AssemblyInfoCommon.cs

$year = ([DateTime]::Today.Year - 2000) % 6
$build = "$year" + [DateTime]::Today.ToString("MMdd")

# Use 0 as revision for non-release builds to speed up debug builds
if( $config -ine "release" )
    { $revision = 0 }
else
{
    Write-Host "Determining highest workspace file version"
    $versions = &$tf localversions $scriptPath /recursive /format:detailed
    $revision = ($versions | foreach { if( $_ -match "C(\d+)$" ) { [int]$Matches[1] } } | sort -Descending)[0]
    Write-Host "Revision number is $revision"
}

$newContent = Get-Content $inputFile | foreach { ($_ -replace "\`$BUILD", $build) -replace "\`$REVISION", $revision }
$needUpdate = $true
if( Test-Path $outputFile )
{
    # Only update the file if the contents have changed so we don't cause unnecessary rebuilds
    $needUpdate = $false
    $oldContent = Get-Content $outputFile
    if( $newContent.Length -ne $oldContent.Length )
        { $needUpdate = $true }
    else
    {
        for( $x = 0; $x -lt $newContent.Length; $x++ )
        {
            if( $oldContent[$x] -ne $newContent[$x] )
            {
                $needUpdate = $true
                break
            }
        }
    }
}

if( $needUpdate )
{
    Write-Host "Updating AssemblyInfoCommon.cs"
    $newContent | sc $outputFile
}
