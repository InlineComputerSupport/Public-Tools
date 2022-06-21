[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$PolicyUri = 'https://folders.inlinecomputers.ca/f/da90e8d6466e4b2cbef1/?dl=1'
$FilePath = "$env:TEMP\BlockWin11.zip"

Try { Invoke-WebRequest -Uri $PolicyUri -OutFile $FilePath -ErrorAction SilentlyContinue }
Catch { Throw $Error }
If (!(Test-Path -Path $FilePath -PathType Leaf -ErrorAction SilentlyContinue))
{
  Throw "Cannot find downloaded file"
}
Expand-Archive -Path $FilePath -DestinationPath "$env:TEMP\$($FilePath.Split('\')[-1].Substring(0,$FilePath.Split('\')[-1].Length - 4))"
Import-GPO -BackupGpoName 'Block Windows 11 Upgrade' -TargetName 'Block Windows 11 Upgrade' -CreateIfNeeded -Path "$env:TEMP\$($FilePath.Split('\')[-1].Substring(0,$FilePath.Split('\')[-1].Length - 4))"
Remove-Item -Path "$env:TEMP\$($FilePath.Split('\')[-1].Substring(0,$FilePath.Split('\')[-1].Length - 4))" -Recurse -Force
Remove-Item -Path $FilePath -Force