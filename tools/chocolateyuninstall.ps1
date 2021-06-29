$packageName= 'amazon-appstream'

$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
write-host $toolsdir

Write-Host "Uninstalling AppStream Client USB drivers."
$exePath = Get-ChildItem $toolsDir | Where-Object {$_.name -match ".*\.exe"} | Select-Object -First 1
start-process -filepath $exePath.fullname -argumentlist "/quiet /uninstall /norestart" -wait

Write-Host "Uninstalling AppStream machine-wide installer."
$msiPath = Get-ChildItem $toolsDir | Where-Object {$_.name -match ".*\.msi"} | Select-Object -First 1
start-process -filepath msiexec.exe -argumentlist "/qn /x $($msiPath.fullname) /L*V `"$toolsDir\ASClientUninstall.log`"" -wait

Write-Host -ForegroundColor Magenta @"
AppStream Client and USB drivers uninstalled. You must reboot your PC to finalize the driver removal.
"@