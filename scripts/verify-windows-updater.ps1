param([Parameter(Mandatory=$true)][string]$PriorUrl,[Parameter(Mandatory=$true)][string]$ExpectedVersion,[Parameter(Mandatory=$true)][string]$PriorSha256)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
function Find-Control([string]$Name) {
  $condition=[System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::NameProperty,$Name)
  try {
    return [System.Windows.Automation.AutomationElement]::RootElement.FindFirst([System.Windows.Automation.TreeScope]::Descendants,$condition)
  } catch {
    # Restart replaces the app and installer windows while we enumerate them.
    # Retry from RootElement on the next bounded poll; preserve other failures.
    if ($_.Exception.GetBaseException() -is [System.Windows.Automation.ElementNotAvailableException]) { return $null }
    throw
  }
}
function Invoke-Control($Control) {
  if (!$Control) { return $false }
  try { $pattern=$Control.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern); $pattern.Invoke(); return $true } catch { return $false }
}
Invoke-WebRequest -Uri $PriorUrl -OutFile prior.exe
if ((Get-FileHash prior.exe -Algorithm SHA256).Hash.ToLowerInvariant() -ne $PriorSha256.ToLowerInvariant()) { throw 'Prior installer digest mismatch' }
if ((Get-AuthenticodeSignature prior.exe).Status -ne 'Valid') { throw 'Prior installer signature invalid' }
$p=Start-Process -FilePath (Join-Path $PWD prior.exe) -ArgumentList '/S' -PassThru -Wait
if ($p.ExitCode -ne 0) { throw "Prior install failed $($p.ExitCode)" }
$exe=Join-Path $env:ProgramFiles 'MyLinedChart\MyLinedChart.exe'
if (!(Test-Path $exe)) { throw 'Installed executable missing' }
$old=(Get-Item $exe).VersionInfo.ProductVersion
Write-Host "Installed prior version $old"
if ($old.StartsWith($ExpectedVersion)) { throw 'Prior version is already the target' }
Start-Process -FilePath $exe -RedirectStandardOutput updater-stdout.log -RedirectStandardError updater-stderr.log | Out-Null
# Exercise the shipped background check, downloaded-update dialog and updater
# installer. Never download/install the target ourselves: the old app must do it.
$deadline=(Get-Date).AddMinutes(8);$restarted=$false
while ((Get-Date) -lt $deadline) {
  $restart=Find-Control 'Restart now'
  if ($restart) {
    $feed=Invoke-RestMethod 'https://github.com/none298-dotcom/MyLinedChart-installers/releases/download/latest/latest.yml'
    if ($feed -notmatch "version: $([regex]::Escape($ExpectedVersion))") { throw 'Public feed version mismatch' }
    $digestMatch=[regex]::Match($feed,'sha512:\s*(\S+)')
    if (!$digestMatch.Success) { throw 'Public feed digest missing' }
    $verified=$false
    $roots=Get-ChildItem $env:LOCALAPPDATA -Directory -Filter '*updater*'
    foreach ($root in $roots) {
      foreach ($package in (Get-ChildItem $root.FullName -Recurse -Filter '*.exe')) {
        $bytes=[System.IO.File]::ReadAllBytes($package.FullName)
        $sha=[System.Security.Cryptography.SHA512]::Create()
        $digest=[Convert]::ToBase64String($sha.ComputeHash($bytes))
        if ($digest -eq $digestMatch.Groups[1].Value) {
          if ((Get-AuthenticodeSignature $package.FullName).Status -ne 'Valid') { throw 'Updater download signature invalid' }
          $verified=$true; Write-Host 'Actual updater download matches public SHA512 and valid Authenticode signature'
        }
      }
    }
    if (!$verified) { throw 'Actual updater download not found or digest mismatch' }
  }
  if ($restart -and (Invoke-Control $restart)) { $restarted=$true; Write-Host 'Invoked actual downloaded-update Restart now button'; break }
  Start-Sleep -Seconds 2
}
if (!$restarted) { throw 'Old app never offered a downloaded update' }
$deadline=(Get-Date).AddMinutes(5)
while ((Get-Date) -lt $deadline) {
  $version=if(Test-Path $exe){(Get-Item $exe).VersionInfo.ProductVersion}else{''}
  if ($version.StartsWith($ExpectedVersion)) { break }
  # Assisted NSIS update can display normal installer progress/wizard buttons.
  foreach ($name in @('Next >','&Next >','Install','&Install','Finish','&Finish','Yes')) {
    $control=Find-Control $name
    if ($control) { Invoke-Control $control | Out-Null }
  }
  Start-Sleep -Seconds 2
}
$version=(Get-Item $exe).VersionInfo.ProductVersion
if (!$version.StartsWith($ExpectedVersion)) { throw "Updater left version $version" }
# Azure signs the distributed installer; the unpacked Electron executable is
# covered by that signed package. Verify the actual downloaded package above.
Write-Host "Installed executable signature status: $((Get-AuthenticodeSignature $exe).Status)"
$deadline=(Get-Date).AddSeconds(45)
while ((Get-Date) -lt $deadline) {
 # NSIS can write the new version before its Finish page is dismissed. Keep
 # driving ordinary wizard controls until the updater's requested relaunch.
 foreach ($name in @('Next >','&Next >','Install','&Install','Finish','&Finish','Yes')) {
   $control=Find-Control $name
   if ($control) { Invoke-Control $control | Out-Null }
 }
 $running=Get-Process MyLinedChart -ErrorAction SilentlyContinue | Where-Object {$_.Path -eq $exe}
 if ($running) { break }; Start-Sleep -Seconds 2
}
if (!$running) { throw 'Updated app did not relaunch' }
Write-Host "PASS: shipped prior $old updater downloaded, installed and relaunched $version from the public update feed"
