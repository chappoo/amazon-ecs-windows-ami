Write-Output "Installing Chocolatey"
Set-ExecutionPolicy Unrestricted
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

Write-Output "Installing Git"
choco install git -y

Write-Output "Installing Go"
choco install golang -y
