$ErrorActionPreference = 'Stop';

# Get Package parameters
$parameters = Get-PackageParameters

$packageName= 'amazon-appstream'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://clients.amazonappstream.com/installers/windows/AmazonAppStreamClient_EnterpriseSetup_1.1.294.zip'
$downloadedZip = Join-Path $toolsDir 'AmazonAppStreamClient_EnterpriseSetup.zip'

$packageArgs = @{
  packageName   = $packageName
  filefullpath  = $downloadedZip
  url           = $url
  checksum      = 'E6340D40D88994BAC6C18BEB3F49791D79E4192448352954C9536A4D824E2DC8'
  checksumType  = 'sha256'
}

Get-ChocolateyWebFile @packageArgs
Get-ChocolateyUnzip -FileFullPath $downloadedZip -Destination $toolsDir

<#
$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url           = $url
  softwareName  = 'amazon-appstream*' #part or all of the Display Name as you see it in Programs and Features. It should be enough to be unique
  checksum      = 'E6340D40D88994BAC6C18BEB3F49791D79E4192448352954C9536A4D824E2DC8'
  checksumType  = 'sha256' #default is md5, can also be sha1, sha256 or sha512
}

## Download and unpack a zip file - https://chocolatey.org/docs/helpers-install-chocolatey-zip-package
#Install-ChocolateyZipPackage -PackageName $packageName -Url $url -UnzipLocation $toolsDir
Install-ChocolateyZipPackage @packageArgs
#>

Write-Host "Installing AppStream machine-wide installer."
$msiPath = Get-ChildItem $toolsDir | Where-Object {$_.name -match ".*\.msi"} | Select-Object -First 1
try {
  start-process -filepath msiexec.exe -argumentlist "/qn /i $($msiPath.fullname) /L*V `"$toolsDir\ASClientInstall.log`"" -wait
}catch{
  write-host "Installation of AppStream machine-wide installer failed, please check logs."
}
Write-Host "Installing AppStream Client USB drivers."
$exePath = Get-ChildItem $toolsDir | Where-Object {$_.name -match ".*\.exe"} | Select-Object -First 1
try {
  start-process -filepath $exePath.fullname -argumentlist "/quiet /norestart" -wait
}catch{
  write-host "Installation of AppStream USB drivers failed, please check logs."
}

Write-Host "Finished installation of AppStream software."

# Set Registry Values
$registryPath="HKLM:\Software\Amazon\AppStream Client"
if(!(Test-Path $registryPath)){
New-Item -Path "HKLM:\Software\Amazon" -Name "AppStream Client" -Force | Out-Null
}

  # Set StartURL Registry Value
  if($parameters['StartURL']){
    Write-Host "Received StartURL parameter value of $($parameters['StartURL']), adding to registry."
    New-ItemProperty -Path $registryPath -Name "StartUrl" -Value $($parameters['StartURL']) -PropertyType String -Force | Out-Null
  }

  # Disable automatic client updates if specified
  if($parameters['AutoUpdateDisabled'] -eq "true"){
    Write-Host "Received AutoUpdateDisabled parameter value of true, adding to registry to disable auto client updates."
    New-ItemProperty -Path $registryPath -Name "AutoUpdateDisabled" -Value "True" -PropertyType String -Force | Out-Null
  }

  # Disable automatic client updates if specified
  if($parameters['TrustedDomains']){
    Write-Host "Received TrustedDomains parameter value of $($parameters['TrustedDomains']), adding to registry."
    New-ItemProperty -Path $registryPath -Name "TrustedDomains" -Value $($parameters['TrustedDomains']) -PropertyType String -Force | Out-Null
  }

Write-Host -ForegroundColor Magenta @"
  AppStream Client and USB drivers installed.
  You must reboot your PC to finalize the driver installation.
  Users must log off and back on for the installer to run and add the icon to their desktop.
  See https://docs.aws.amazon.com/appstream2/latest/developerguide/install-client-configure-settings.html#run-powershell-script-install-client-usb-driver-silently for details.
"@
