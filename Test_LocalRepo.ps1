#Taken from https://adamtheautomator.com/powershell-modules/
if ([System.Environment]::OSVersion.Platform -eq 'Win32NT')
{
    rmdir /Q C:\Repo
    New-Item -Path C:\ -Name Repo -ItemType Directory
    Register-PSRepository -Name 'LocalRepo' -SourceLocation 'C:\Repo' -PublishLocation 'C:\Repo' -InstallationPolicy Trusted
} else {
    rm -rf /tmp/Repo
    New-Item -Path /tmp/ -Name Repo -ItemType Directory
    Register-PSRepository -Name 'LocalRepo' -SourceLocation '/tmp/Repo' -PublishLocation '/tmp/Repo' -InstallationPolicy Trusted
}
Publish-Module -Name .\Scripts\VirtualBox -Repository LocalRepo
Find-Module VirtualBox | Install-Module

Get-VirtualBoxVM *
Invoke-VirtualBoxVMPowerShellScript -Name dev -ScriptBlock "{ uname -a }"

Uninstall-Module VirtualBox
Unregister-PSRepository -Name 'LocalRepo'
