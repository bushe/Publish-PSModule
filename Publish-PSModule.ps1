<#
.SYNOPSIS
    Easily build PowerShell modules for a set of functions contained in individual PS1 files

.DESCRIPTION
    Put a collection of your favorite functions into their own PS1 files create a PowerShell module.  The module will 
    be named after the folder name they're placed under. Key folders can be used to specify different file types. Unless
    the path name contains one of the below key names, all functions will be exported by the module and available to the
    user.

    *Private* - if Private is in the path name, all functions found in this path will be not be exported and will not
                be available to the user. However, they will be available as internal functions to the module.
    *Exclude* - any files found with Exclude in the path name will not be included in the module at all.
    *Tests*   - any files found with Tests in the path name will not be included in the module at all (put your Pester
                tests here).

    Manifest file for the module will also be created with the correct PowerShell version requirement (assuming you
    specified this with the "#requires -Version" code in your functions).

    Manifest file can also be edited to suit your requirements.

.PARAMETER Path
    The path where you module folders and PS1 files containing your functions is located.

.PARAMETER ModuleName
    What you want to call your module. By default the module will be named after the folder you point
    to in Path.

.INPUTS
    None
.OUTPUTS
    None
.EXAMPLE

.NOTES
    Author:             Martin Pugh
    Twitter:            @thesurlyadm1n
    Spiceworks:         Martin9700
    Blog:               www.thesurlyadmin.com
      
    Changelog:
        1.0             Initial Release
.LINK
    https://github.com/martin9700/Publish-PSModule
#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$Path,
    [string]$ModuleName
)
Write-Verbose "$(Get-Date): Publish-Module.ps1 started"

If (-not $ModuleName)
{
    $ModuleName = Get-ItemProperty -Path $Path | Select -ExpandProperty BaseName
}

$Module = New-Object -TypeName System.Collections.ArrayList
$FunctionNames = New-Object -TypeName System.Collections.ArrayList
$HighVersion = [version]"2.0"

#Retrieve Include.txt file(s)
$Files = Get-ChildItem $Path\Include.txt -Recurse | Sort FullName
ForEach ($File in $Files)
{
    $Raw = Get-Content $File
    $null = $Module.Add($Raw)
}

#Retrieve ps1 files
$Files = Get-ChildItem $Path\*.ps1 -File -Recurse | Where FullName -NotMatch "Exclude|Tests" | Sort FullName
ForEach ($File in $Files)
{
    $Raw = Get-Content $File
    $Private = $false
    If ($File.DirectoryName -like "*Private*")
    {
        $Private = $true
    }
    $null = $Module.Add($Raw)

    ForEach ($Line in $Raw)
    {
        If ($Line -match "^( *|\t*)Function (?<Name>.*)")
        {
            If ($Matches.Name -like "*{*")
            {
                $Matches.Name = $Matches.Name.Substring(0,$Matches.Name.IndexOf("{"))
            }
            If ($FunctionNames.Name -contains $Matches.Name.Trim())
            {
                Write-Error "Your module contains multiple functions with the same name: $($Matches.Name.Trim())" -ErrorAction Stop
            }
            Else
            {
                $null = $FunctionNames.Add([PSCustomObject]@{
                    Name = $Matches.Name.Trim()
                    Private = $Private
                })
            }
        }
        ElseIf ($Line -match "#requires -version (?<Version>.*)")
        {
            $temp = $Matches.Version + ".0"
            $Version = [version]$temp
            If ($Version -gt $HighVersion)
            {
                $HighVersion = $Version
            }
        }
    }
}

#Create the manifest file
$ManifestPath = Join-Path $Path -ChildPath "$ModuleName.psd1"
If (Test-Path $ManifestPath)
{
    $Manifest = @{
        Path = $ManifestPath
        PowerShellVersion = $HighVersion
        FunctionsToExport = $FunctionNames | Where Private -eq $false | Select -ExpandProperty Name
    }
    Update-ModuleManifest @Manifest
}
Else
{
    $Manifest = @{
        RootModule = $ModuleName
        Path = $ManifestPath
        PowerShellVersion = "$($HighVersion.Major).$($HighVersion.Minor)"
        FunctionsToExport = $FunctionNames | Where Private -eq $false | Select -ExpandProperty Name
    }
    New-ModuleManifest @Manifest
}

#Save the Module file
$ModulePath = Join-Path -Path $Path -ChildPath "$ModuleName.psm1"
$Module | Out-File $ModulePath -Encoding ascii

Write-Verbose "$(Get-Date): Module created at: $Path as $ModuleName"
