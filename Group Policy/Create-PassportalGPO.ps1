[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$PolicyUri = 'https://folders.inlinecomputers.ca/f/aaf3b3358fc7427dba59/?dl=1'
$FilePath = "$env:TEMP\Passportal.zip"

Try { Invoke-WebRequest -Uri $PolicyUri -OutFile $FilePath -ErrorAction SilentlyContinue }
Catch { Throw $Error }
If (!(Test-Path -Path $FilePath -PathType Leaf -ErrorAction SilentlyContinue))
{
  Throw "Cannot find downloaded file"
}
Expand-Archive -Path $FilePath -DestinationPath "$env:TEMP\$($FilePath.Split('\')[-1].Substring(0,$FilePath.Split('\')[-1].Length - 4))"
Import-GPO -BackupGpoName 'Passportal' -TargetName 'Passportal' -CreateIfNeeded -Path "$env:TEMP\$($FilePath.Split('\')[-1].Substring(0,$FilePath.Split('\')[-1].Length - 4))"
Remove-Item -Path "$env:TEMP\$($FilePath.Split('\')[-1].Substring(0,$FilePath.Split('\')[-1].Length - 4))" -Recurse -Force
Remove-Item -Path $FilePath -Force