param([Parameter(Mandatory=$true)][string]$PriorUrl,[Parameter(Mandatory=$true)][string]$ExpectedVersion,[Parameter(Mandatory=$true)][string]$PriorSha256)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
function Find-Control([string]$Name) {
  $condition=[System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::NameProperty,$Name)
  return [System.Windows.Automation.AutomationElement]::RootElement.FindFirst([System.Windows.Automation.TreeScope]::Descendants,$condition)
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
if ((Get-AuthenticodeSignature $exe).Status -ne 'Valid') { throw 'Updated app signature invalid' }
$deadline=(Get-Date).AddSeconds(45)
while ((Get-Date) -lt $deadline) {
 $running=Get-Process MyLinedChart -ErrorAction SilentlyContinue | Where-Object {$_.Path -eq $exe}
 if ($running) { break }; Start-Sleep -Seconds 2
}
if (!$running) { throw 'Updated app did not relaunch' }
Write-Host "PASS: shipped prior $old updater downloaded, installed and relaunched $version from the public update feed"
