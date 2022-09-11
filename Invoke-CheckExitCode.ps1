# [CmdletBinding()] and [Parameter()] are omitted to make sure
# "-i" is not interpreted as "-InformationAction" etc.
$eap = $ErrorActionPreference
try {
    # Don't throw immediately on stderr output.
    $ErrorActionPreference = [Management.Automation.ActionPreference]::Continue

    $command, $arguments = $args
    & $command $arguments
} finally {
    $ErrorActionPreference = $eap
}

if ($LASTEXITCODE) {
    throw [Exception]::new("$command exited with code $LASTEXITCODE")
}
