Write-Output "Configure ECS Agent"
$agentVersion = "latest"
$agentZipUri = "https://s3.amazonaws.com/amazon-ecs-agent/ecs-agent-windows-$agentVersion.zip"
$agentZipMD5Uri = "$agentZipUri.md5"
$ecsExeDir = "$env:ProgramFiles\Amazon\ECS"
$zipFile = "$env:TEMP\ecs-agent.zip"
$md5File = "$env:TEMP\ecs-agent.zip.md5"

Write-Output "Get the files from S3"
Invoke-RestMethod -OutFile $zipFile -Uri $agentZipUri
Invoke-RestMethod -OutFile $md5File -Uri $agentZipMD5Uri

Write-Output "MD5 Checksum"
$expectedMD5 = (Get-Content $md5File)
$md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
$actualMD5 = [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($zipFile))).replace('-', '')

if($expectedMD5 -ne $actualMD5) {
    Write-Output "Download doesn't match hash."
    Write-Output "Expected: $expectedMD5 - Got: $actualMD5"
    exit 1
}

Write-Output "Put the executables in the executable directory"
Expand-Archive -Path $zipFile -DestinationPath $ecsExeDir -Force

Write-Output "Download and compile latest amazon-ecs-agent from GitHub master"
New-Item "$env:GOROOT\src\github.com\aws" -ItemType Directory -Force
Set-Location "$env:GOROOT\src\github.com\aws"
git clone https://github.com/aws/amazon-ecs-agent
Set-Location "$env:GOROOT\src\github.com\aws\amazon-ecs-agent"
go build -o amazon-ecs-agent.exe ./agent
Move-Item "$ecsExeDir\amazon-ecs-agent.exe" "$ecsExeDir\amazon-ecs-agent-from-s3.exe" -Force
Move-Item "$env:GOROOT\src\github.com\aws\amazon-ecs-agent\amazon-ecs-agent.exe" $ecsExeDir -Force

if (Test-Path -Path "$ecsExeDir\amazon-ecs-agent.exe") {
    Write-Output "Configure ECS Agent - done"    
}
else {
    Write-Output "Configure ECS Agent - failed.  amazon-ecs-agent.exe not found."        
}
