[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('x64', 'x86', 'arm64')]
    [string] $Arch,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $SourceDir,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ArtefactsDir
)
$ErrorActionPreference = [Management.Automation.ActionPreference]::Stop
Set-StrictMode -Version Latest

$ArtefactsDir = [IO.Path]::GetFullPath($ArtefactsDir, $PWD)

$clFlags = '/utf-8 /MP /GA /GL /Gw /guard:cf /guard:ehcont /Qspectre'
$ld = 'link.exe /NOLOGO /LTCG /GUARD:CF'

if ($Arch -eq 'x64' -or $Arch -eq 'x86') {
    $clFlags += ' /QIntel-jcc-erratum'
    $ld += ' /CETCOMPAT'
}

$asm = switch -exact ($Arch) {
    'x64' { 'X64ASM=1' }
    'x86' { '' }
    default { 'NOASM=1' }
}

$vs = & "$PSScriptRoot\Invoke-CheckExitCode" vswhere.exe -latest -property installationPath
Import-Module (Join-Path $vs 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll')
Enter-VsDevShell -VsInstallPath $vs -SkipAutomaticLocation -HostArch amd64 `
                 -Arch ($Arch -eq 'x64' ? 'amd64' : $Arch) `
                 -DevCmdArguments '-vcvars_spectre_libs=spectre'

Push-Location $SourceDir
try {
    & "$PSScriptRoot\Invoke-CheckExitCode" nmake.exe /NOLOGO /F win32\makefile.w32 `
                                                     LOC=$clFlags LD=$ld CRTLIB=/MD $asm

    $artefacts = "$([IO.Path]::GetFileNameWithoutExtension($PWD.Path))-$Arch"
    New-Item -Type Directory "$artefacts"
    Move-Item *.exe "$artefacts"

    if (-not (Test-Path $ArtefactsDir)) {
        New-Item -Type Directory $ArtefactsDir
    }
    Compress-Archive "$artefacts" (Join-Path $ArtefactsDir "$artefacts.zip")

    Remove-Item -Recurse "$artefacts"
    & "$PSScriptRoot\Invoke-CheckExitCode" nmake.exe /NOLOGO /F win32\makefile.w32 clean
} finally {
    Pop-Location
}
