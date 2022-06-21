[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Templates = @(
  "$(((Invoke-WebRequest -Uri 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=103667' -UseBasicParsing).Links | Where-Object {$_.href -like '*.msi'}).href | Select-Object -Index 2)"
)

$PolicyStore = "$((Get-ChildItem (Get-SmbShare -Name 'SYSVOL').Path).FullName)\Policies\PolicyDefinitions"
If (!(Test-Path $PolicyStore -PathType Container -ErrorAction SilentlyContinue))
{
  New-Item -ItemType "directory" -Path $PolicyStore | Out-Null
  New-Item -ItemType "directory" -Path "$PolicyStore\en-US" | Out-Null
}

ForEach ($Template in $Templates)
{
  $Dest = "$env:TEMP\win10"
  New-Item -Path $Dest -ItemType "directory" | Out-Null
  Try { Invoke-WebRequest -Uri $Template -OutFile "$Dest\win10.msi" -ErrorAction SilentlyContinue }
  Catch { Throw $Error }
  If (!(Test-Path -Path "$Dest\win10.msi" -PathType Leaf -ErrorAction SilentlyContinue))
  {
    Throw "Cannot find downloaded file"
  }
  New-Item -Path "$Dest\extract" -ItemType "directory" | Out-Null
  Start-Process -FilePath "$env:SYSTEMROOT\system32\msiexec.exe" -ArgumentList "/a $Dest\win10.msi",'/quiet /norestart',"TARGETDIR=$Dest\extract" -Wait -NoNewWindow
  Get-ChildItem $Dest -Recurse -Filter "*.admx" | Move-Item -Destination $PolicyStore -Force -Verbose
  Get-ChildItem $Dest -Recurse -Filter "*.adml" | Where-Object {$_.FullName -like "*\en-US\*"} | Move-Item -Destination "$PolicyStore\en-US" -Force -Verbose
  Remove-Item -Path $Dest -Recurse -Force
}