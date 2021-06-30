$ErrorActionPreference = 'Stop';

$parameters = Get-PackageParameters

$packageName   = 'amazon-appstream'
$toolsDir      = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url           = 'https://clients.amazonappstream.com/installers/windows/AmazonAppStreamClient_EnterpriseSetup_1.1.294.zip'
$downloadedZip = Join-Path $toolsDir 'AmazonAppStreamClient_EnterpriseSetup.zip'
$fileLocation  = Join-Path $toolsDir 'AmazonAppStreamClientSetup_1.1.294.msi'

$packageArgs = @{
  packageName   = $packageName
  filefullpath  = $downloadedZip
  url           = $url
  checksum      = 'E6340D40D88994BAC6C18BEB3F49791D79E4192448352954C9536A4D824E2DC8'
  checksumType  = 'sha256'
}

Get-ChocolateyWebFile @packageArgs

Get-ChocolateyUnzip -FileFullPath $downloadedZip -Destination $toolsDir

$installerArgs  = @{
  packageName   = $packageName
  silentArgs    = "/qn /norestart /l*v `"$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion).MsiInstall.log`""
  validExitCodes= @(0, 3010, 1641)
  file          = $fileLocation
  fileType      = 'msi'
}

Install-ChocolateyInstallPackage @installerArgs

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
  AppStream Client Machine-wide installer finished installation.
  Users must log off and back on for the icon to their desktop.
  See https://docs.aws.amazon.com/appstream2/latest/developerguide/install-client-configure-settings.html#run-powershell-script-install-client-usb-driver-silently for details.
"@
