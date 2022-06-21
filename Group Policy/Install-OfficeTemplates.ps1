[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Templates = @(
  "$(((Invoke-WebRequest -Uri 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=49030&6B49FDFB-8E5B-4B07-BC31-15695C5A2143=1' -UseBasicParsing).Links | Where-Object {$_.href -like '*.exe'}).href | Select-Object -Index 2)"
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
  Start-Process -FilePath $((Get-ChildItem -Path $Dest -Filter "*.exe").FullName) -ArgumentList "/extract:$Dest",'/quiet' -Wait -NoNewWindow
  Get-ChildItem $Dest -Recurse -Filter "*.admx" | Move-Item -Destination $PolicyStore -Force -Verbose
  Get-ChildItem $Dest -Recurse -Filter "*.adml" | Where-Object {$_.FullName -like "*\en-US\*"} | Move-Item -Destination "$PolicyStore\en-US" -Force -Verbose
  Remove-Item -Path $Dest -Recurse -Force
}