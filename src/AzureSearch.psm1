Set-StrictMode -Version Latest

# Dynamically load all ps1 files.
$files = Get-ChildItem -Path "$PSScriptRoot\lib" -Filter '*.ps1' -Recurse

foreach ($file in $files) {
    Write-Verbose "Loading '$($file.Name)'."
    . $file.FullName
}