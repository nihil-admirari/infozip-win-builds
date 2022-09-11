[CmdletBinding()]
$ErrorActionPreference = [Management.Automation.ActionPreference]::Stop
Set-StrictMode -Version Latest

class RemoteFile {
    [ValidateNotNullOrEmpty()]
    [string] $Uri

    [ValidateNotNullOrEmpty()]
    [string] $OutFile

    [ValidateNotNullOrEmpty()]
    [string] $Sha512

    RemoteFile([string] $uri, [string] $outFile, [string] $sha512) {
        $this.Uri = $uri
        $this.OutFile = $outFile
        $this.Sha512 = $sha512
    }
}

$patchDir = Join-Path $PSScriptRoot patches

$uris = (
    [RemoteFile]::new(
        'https://sourceforge.net/projects/infozip/files/Zip%203.x%20%28latest%29/3.0/zip30.zip/download',
        (Join-Path $PSScriptRoot zip30.zip),
        '642ea6768d79adc1499251a3fb7bfc7ddc8d708699cbf9e0cfe849deda94165cb93e21dc2606bea1166ae5d8531e1e2cb056a7246bf2ab86ea7587bd4712d8d8'
    ),

    [RemoteFile]::new(
        'https://src.fedoraproject.org/rpms/zip/raw/rawhide/f/zip-3.0-currdir.patch',
        "$patchDir\zip-3.0-currdir.patch",
        'ffc5d2905cffb1f39ffb219511898dd3e17eb465f371a43b64f0ca9a293d518d64c753d9bc392db54b7ba7fd6ae0c13da3aeb38960465e99b45ceac3f0495b23'
    ),

    [RemoteFile]::new(
        'https://src.fedoraproject.org/rpms/zip/raw/rawhide/f/zip-3.0-format-security.patch',
        "$patchDir\zip-3.0-format-security.patch",
        'ce600d1a3565581fa094c7d7d6c280c06422cd7e96581e22daea3361b8f1e90b6956c268268d71259484d4cc900afc42a2ba17046cbc23c2bceacc2f14a3ea2d'
    ),

    [RemoteFile]::new(
        'https://src.fedoraproject.org/rpms/zip/raw/rawhide/f/zipnote.patch',
        "$patchDir\zipnote.patch",
        'f1608eb54cc60d42fe413bfb566a568de2d3fd1c7e494f1658444b2d6e12c9f818ef6f437392f5d49f5f1f30f023ad9eded69c3878bae998d28c53157a5d0583'
    )
)

$uris | ForEach-Object -Parallel {
    Invoke-WebRequest -UserAgent wget -Uri $_.Uri -OutFile $_.OutFile
    Unblock-File $_.OutFile
    if ((Get-FileHash -Algorithm SHA512 $_.OutFile).Hash -ine $_.Sha512) {
        throw [Exception]::new("$($_.OutFile): incorrect SHA512")
    }
} -AsJob | Receive-Job -Wait -Force

Expand-Archive zip30.zip .

Push-Location zip30
try {
    # Git applies patches from the root of the repository,
    # i.e. from the folder that contains this script;
    # thus it must be forced to stay inside zip30.
    & "$PSScriptRoot\Invoke-CheckExitCode" git.exe init

    Get-ChildItem $patchDir\* | % {
        & "$PSScriptRoot\Invoke-CheckExitCode" `
            git.exe apply --verbose --ignore-whitespace $_.FullName
    }
} finally {
    Pop-Location
}
