class VirtualBoxVM
{
    [ValidateNotNullOrEmpty()]
    [string]$Name
    [ValidateNotNullOrEmpty()]
    [string]$Uuid
    [string]$State
    [bool]$Running
    [string]$Info
    [string]$GuestOS
}

Update-TypeData -TypeName VirtualBoxVM -DefaultDisplayPropertySet @("Name","UUID","State") -Force

$ptIsolateUuid = "^(.*{)|}$"
$ptVMNameLineTag = "^Name:    "
$ptVMUuidLineTag = "^UUID:    "
$ptVMStateLineTag = "^State:     "
$ptGuestOSLineTag = "^Guest OS:     "

function New-VirtualBoxVMObject
{
    param(
        $aVMInfo
    )

    $sVMName = ([string](($aVMInfo | Where-Object {$_ -match $ptVMNameLineTag}) -replace $ptVMNameLineTag)).Trim()
    $sVMUuid = ([string](($aVMInfo | Where-Object {$_ -match $ptVMUuidLineTag}) -replace $ptVMUuidLineTag)).Trim()
    $sVMState = ([string](($aVMInfo | Where-Object {$_ -match $ptVMStateLineTag}) -replace $ptVMStateLineTag)).Trim()
    $sGuestOS = ([string](($aVMInfo | Where-Object {$_ -match $ptGuestOSLineTag}) -replace $ptGuestOSLineTag)).Trim()
    $vm = New-Object VirtualBoxVM
    $vm.Name = $sVMName
    $vm.Uuid = $sVMUuid
    $vm.State = $sVMState
    $vm.GuestOS = $sGuestOS
    if ($vm.State -like "Running*") {
        $vm.Running = $true
    } else {
        $vm.Running = $false
    }#if
    $vm.Info = $aVMInfo

    return $vm

}

function Get-VirtualBoxVM
{

    param(
        [Parameter(Position=0,ParameterSetName="Name")]
        [string]$Name,
        [Parameter(ParameterSetName="Uuid")]
        [string]$Uuid,
        [Parameter(Position=0,ParameterSetName="VirtualBoxVM",ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [VirtualBoxVM]$VirtualBoxVM,
        [Parameter(Mandatory=$false)]
        [Switch]$PowerOn,
        [Parameter(Mandatory=$false)]
        [Switch]$ShowConsole,
        [Parameter(Mandatory=$false)]
        [Switch]$PowerOff,
        [Parameter(Mandatory=$false)]
        [Switch]$ShutDown,
        [Parameter(Mandatory=$false)]
        [Switch]$GetExtraData,
        [Parameter(Mandatory=$false)]
        [Switch]$SetExtraData,
        [Parameter(Mandatory=$false)]
        [string]$ExtraDataKey,
        [Parameter(Mandatory=$false)]
        [string]$ExtraDataValue,
        [Parameter(Mandatory=$false)]
        [string]$ModifyVM
    )

    if (!(VBoxManage)) {
        Write-Output "Set path to VBoxManage."
        return 3
    }#if

    if ($VirtualBoxVM) { $Name = $VirtualBoxVM.Name }
    if ($Uuid) { $Name = $Uuid }
    if (!$Name) { $Name = "*" }

    if ($Name.Contains("*")){

        $aVirtualBoxVM = @()
        $aVMList = [array](VBoxManage list vms | Where-Object {($_ -replace """" -replace " {.*") -like $Name})
        $aVMList | ForEach-Object {

            $sVMEntry = $_
            $sVMUuid = $sVMEntry -replace $ptIsolateUuid
            $vm = Get-VirtualBoxVM $sVMUuid
            $aVirtualBoxVM += $vm

        }#foreach

        return $aVirtualBoxVM

    } else {

        if ($PowerOn) {
            Write-Output (VBoxManage startvm $Name --type headless)
        } elseif ($ShowConsole) {
            Write-Output (VBoxManage startvm $Name --type separate)
        } elseif ($PowerOff) {
            Write-Output "Powering off VM ""$Name""."
            VBoxManage controlvm $Name poweroff
        } elseif ($ShutDown) {
            Write-Output "Shutting down VM ""$Name""."
            VBoxManage controlvm $Name acpipowerbutton
        } elseif ($GetExtraData) {
            return VBoxManage getextradata $Name $ExtraDataKey
        } elseif ($SetExtraData) {
            return VBoxManage setextradata $Name $ExtraDataKey $ExtraDataValue
        } elseif ($ModifyVM) {
            $vboxmanage = New-Object System.Diagnostics.Process
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "VBoxManage"
            $psi.Arguments = $ModifyVM
            $psi.CreateNoWindow = $true
            $vboxmanage.StartInfo = $psi
            $vboxmanage.Start()
            $vboxmanage.WaitForExit()
        }#if

        $aVMInfo = VBoxManage showvminfo $Name
        $vm = New-VirtualBoxVMObject $aVMInfo
        
        return $vm

    }#if
    
}

function Start-VirtualBoxVM
{
    param(
        [Parameter(Position=0,ParameterSetName="Name")]
        [string]$Name,
        [Parameter(ParameterSetName="Uuid")]
        [string]$Uuid,
        [Parameter(Position=0,ParameterSetName="VirtualBoxVM",ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [VirtualBoxVM]$VirtualBoxVM,
        [Parameter(Mandatory=$false)]
        [Switch]$ShowConsole
    )

    if ($VirtualBoxVM) { $Name = $VirtualBoxVM.Name }
    if ($Uuid) { $Name = $Uuid }

    if ($ShowConsole) {
        return Get-VirtualBoxVM -Name $Name -ShowConsole
    } else {
        return Get-VirtualBoxVM -Name $Name -PowerOn
    }#if
    
}

function Stop-VirtualBoxVM
{
    param(
        [Parameter(Position=0,ParameterSetName="Name")]
        [string]$Name,
        [Parameter(ParameterSetName="Uuid")]
        [string]$Uuid,
        [Parameter(Position=0,ParameterSetName="VirtualBoxVM",ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [VirtualBoxVM]$VirtualBoxVM,
        [Parameter(Mandatory=$false)]
        [Switch]$PowerOff
    )

    if ($VirtualBoxVM) { $Name = $VirtualBoxVM.Name }
    if ($Uuid) { $Name = $Uuid }
    
    if ($PowerOff) {
        return Get-VirtualBoxVM -Name $Name -PowerOff
    } else {
        return Get-VirtualBoxVM -Name $Name -ShutDown
    }#if
    
}

function Open-VirtualBoxVMConsole
{
    param(
        [Parameter(Position=0,ParameterSetName="Name")]
        [string]$Name,
        [Parameter(ParameterSetName="Uuid")]
        [string]$Uuid,
        [Parameter(Position=0,ParameterSetName="VirtualBoxVM",ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [VirtualBoxVM]$VirtualBoxVM,
        [Parameter(Mandatory=$false)]
        [Switch]$PowerOff
    )

    if ($VirtualBoxVM) { $Name = $VirtualBoxVM.Name }
    if ($Uuid) { $Name = $Uuid }

    return Start-VirtualBoxVM -Name $Name -ShowConsole
}

function Invoke-VirtualBoxVMProcess
{
    param(
        [Parameter(Position=0,ParameterSetName="Name")]
        [string]$Name,
        [Parameter(ParameterSetName="Uuid")]
        [string]$Uuid,
        [Parameter(Position=0,ParameterSetName="VirtualBoxVM",ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [VirtualBoxVM]$VirtualBoxVM,
        [Parameter(Position=1,Mandatory=$true)]
        [string]$PathToExecutable,
        [Parameter(Position=2)]
        [string[]]$Arguments,
        [Parameter(Position=3)]
        [pscredential]$Credential,
        [Parameter(Mandatory=$false)]
        [Switch]$AsJob
    )

    if ($VirtualBoxVM) { $Name = $VirtualBoxVM.Name }
    if ($Uuid) { $Name = $Uuid }
    
    if (!$Credential) {
        $sUserName = $env:USERNAME 
        if (!$sUserName) { $sUserName = $env:LOGNAME }
        $secPassword = Read-Host "Password for [$sUserName]" -AsSecureString
        $Credential = New-Object pscredential($sUserName,$secPassword)
    }#if

    $secPassword = $Credential.Password
    $usPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secPassword))

    if ($AsJob) {

        Start-Job {

            param(
                [string]$Name,
                [string]$PathToExecutable,
                [string[]]$Arguments,
                [pscredential]$Credential                
            )

            Invoke-VirtualBoxVMProcess -Name $Name -PathToExecutable $PathToExecutable -Arguments $Arguments -Credential $Credential

        } -ArgumentList $Name,$PathToExecutable,$Arguments,$Credential

    } else {
        Write-Output $Arguments
        return VBoxManage guestcontrol $Name --username $Credential.UserName --password $usPassword run --exe $PathToExecutable -- $Arguments

    }#if
}

function Submit-VirtualBoxVMProcess
{
    param(
        [Parameter(Position=0,ParameterSetName="Name")]
        [string]$Name,
        [Parameter(ParameterSetName="Uuid")]
        [string]$Uuid,
        [Parameter(Position=0,ParameterSetName="VirtualBoxVM",ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [VirtualBoxVM]$VirtualBoxVM,
        [Parameter(Position=1,Mandatory=$true)]
        [string]$PathToExecutable,
        [Parameter(Position=2)]
        [string[]]$Arguments,
        [Parameter(Position=3)]
        [pscredential]$Credential

    )
    
    if ($VirtualBoxVM) { $Name = $VirtualBoxVM.Name }
    if ($Uuid) { $Name = $Uuid }

    if (!$Credential) {
        $sUserName = $env:USERNAME
        if (!$sUserName) { $sUserName = $env:LOGNAME }
        $secPassword = Read-Host "Password for [$sUserName]" -AsSecureString
        $Credential = New-Object pscredential($sUserName,$secPassword)
    }#if

    Invoke-VirtualBoxVMProcess -Name $Name -PathToExecutable $PathToExecutable -Arguments $Arguments -Credential $Credential -AsJob

}

function Invoke-VirtualBoxVMPowerShellScript
{
    param(
        [Parameter(Position=0,ParameterSetName="Name")]
        [string]$Name,
        [Parameter(ParameterSetName="Uuid")]
        [string]$Uuid,
        [Parameter(Position=0,ParameterSetName="VirtualBoxVM",ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [VirtualBoxVM]$VirtualBoxVM,
        [Parameter(Position=1,Mandatory=$true)]
        [string]$ScriptBlock,
        [Parameter(Position=3)]
        [pscredential]$Credential,
        [Parameter(Mandatory=$false)]
        [switch]$AsJob
    )
    
    if ([System.Environment]::OSVersion.Platform -eq 'Win32NT')
    {
        $cmd="cmd.exe"
        $cmd_args="/c powershell -command".Split(" ")
    } else {
        $cmd="sh"
        $cmd_args="-c pwsh -command".Split(" ")
    }

    if ($VirtualBoxVM) { $Name = $VirtualBoxVM.Name }
    if ($Uuid) { $Name = $Uuid }

    if ($AsJob) {
        return Invoke-VirtualBoxVMProcess -Name $Name -PathToExecutable $cmd -Arguments $cmd_args,$ScriptBlock -Credential $Credential -AsJob

    } else {
        return Invoke-VirtualBoxVMProcess -Name $Name -PathToExecutable $cmd -Arguments $cmd_args,$ScriptBlock -Credential $Credential

    }#if
    
}

function Submit-VirtualBoxVMPowerShellScript
{
    param(
        [Parameter(Position=0,ParameterSetName="Name")]
        [string]$Name,
        [Parameter(ParameterSetName="Uuid")]
        [string]$Uuid,
        [Parameter(Position=0,ParameterSetName="VirtualBoxVM",ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [VirtualBoxVM]$VirtualBoxVM,
        [Parameter(Position=1,Mandatory=$true)]
        [string]$ScriptBlock,
        [Parameter(Position=3)]
        [pscredential]$Credential
    )

    if ($VirtualBoxVM) { $Name = $VirtualBoxVM.Name }
    if ($Uuid) { $Name = $Uuid }

    Invoke-VirtualBoxVMPowerShellScript -Name $Name -ScriptBlock $ScriptBlock -Credential $Credential -AsJob
}
