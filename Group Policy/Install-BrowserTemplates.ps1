[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Templates = @(
  'https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/53997d39-d98b-4a30-890b-35145821ed21/MicrosoftEdgePolicyTemplates.cab',
  'https://dl.google.com/dl/edgedl/chrome/policy/policy_templates.zip',
  "https://github.com$(((Invoke-WebRequest -Uri 'https://github.com/mozilla/policy-templates/releases/latest' -UseBasicParsing).Links | Where-Object {$_.Href -like "*.zip"}).Href | Select-Object -First 1)"
)

$PolicyStore = "$((Get-ChildItem (Get-SmbShare -Name 'SYSVOL').Path).FullName)\Policies\PolicyDefinitions"
If (!(Test-Path $PolicyStore -PathType Container -ErrorAction SilentlyContinue))
{
  New-Item -ItemType "directory" -Path $PolicyStore | Out-Null
  New-Item -ItemType "directory" -Path "$PolicyStore\en-US" | Out-Null
}

ForEach ($Template in $Templates)
{
  $Dest = "$env:TEMP\$($Template.Split('/')[-1].Substring(0,$Template.Split('/')[-1].Length - 4))"
  New-Item -Path $Dest -ItemType "directory" | Out-Null
  Try { Invoke-WebRequest -Uri $Template -OutFile "$Dest\$($Template.Split('/')[-1])" -ErrorAction SilentlyContinue }
  Catch { Throw $Error }
  If (!(Test-Path -Path "$Dest\$($Template.Split('/')[-1])" -PathType Leaf -ErrorAction SilentlyContinue))
  {
    Throw "Cannot find downloaded file"
  }
  If ($Template.Split('/')[-1].Substring($Template.Split('/')[-1].Length - 3) -eq 'cab')
  {
    cmd.exe /c "$env:SYSTEMROOT\System32\expand.exe $Dest\$($Template.Split('/')[-1]) $Dest\$($Template.Split('/')[-1].Substring(0,$Template.Split('/')[-1].Length - 4)).zip"
  }
  Expand-Archive -Path $((Get-ChildItem -Path $Dest -Filter "*.zip").FullName) -DestinationPath $Dest
  Get-ChildItem $Dest -Recurse -Filter "*.admx" | Move-Item -Destination $PolicyStore -Force -Verbose
  Get-ChildItem $Dest -Recurse -Filter "*.adml" | Where-Object {$_.FullName -like "*\en-US\*"} | Move-Item -Destination "$PolicyStore\en-US" -Force -Verbose
  Remove-Item -Path $Dest -Recurse -Force
}