
Param (
    [parameter()]
    $VMName,
    [parameter(Mandatory=$true)]
    $ResourceGroup,
    [parameter(Mandatory=$true)]
    [ValidateSet('None','ReadOnly','ReadWrite')]
    $CacheMode,
    [parameter()]
    $Login,
    [parameter()]
    $ProductionRun,
    [parameter()]
    $parallel
)   

write-host ""
write-host ""
Import-Module .\UpdateCache.psm1
#Cosmetic stuff
write-host ""
write-host ""
write-host "                               _____        __                                " -ForegroundColor Green
write-host "     /\                       |_   _|      / _|                               " -ForegroundColor Yellow
write-host "    /  \    _____   _ _ __ ___  | |  _ __ | |_ _ __ __ _   ___ ___  _ __ ___  " -ForegroundColor Red
write-host "   / /\ \  |_  / | | | '__/ _ \ | | | '_ \|  _| '__/ _' | / __/ _ \| '_ ' _ \ " -ForegroundColor Cyan
write-host "  / ____ \  / /| |_| | | |  __/_| |_| | | | | | | | (_| || (_| (_) | | | | | |" -ForegroundColor DarkCyan
write-host " /_/    \_\/___|\__,_|_|  \___|_____|_| |_|_| |_|  \__,_(_)___\___/|_| |_| |_|" -ForegroundColor Magenta
write-host "     "
write-host " This script reconfigures all VM's in a Resource Group or individual VM" -ForegroundColor "Green"


#Importing the functions module and primary modules for AAD and AD
If (!((LoadModule -name Az.Compute))){
    Write-host "Az.Compute Module was not found - cannot continue - please install the module using install-module AZ"
    Exit
}

##Setting Global Paramaters##
$ErrorActionPreference = "Stop"
$date = Get-Date -UFormat "%Y-%m-%d-%H-%M"
$workfolder = Split-Path $script:MyInvocation.MyCommand.Path
$logFile = $workfolder+'\ChangeSize'+$date+'.log'
Write-Output "Steps will be tracked on the log file : [ $logFile ]" 

##Login to Azure##
If ($Login) {
    $Description = "Connecting to Azure"
    $Command = {LogintoAzure}
    $AzureAccount = RunLog-Command -Description $Description -Command $Command -LogFile $LogFile -Color "Green"
}

If ($VMName) {
    write-host "$ResourceGroup"
    [array]$VMs=Get-AzVM -Name $VMName -ResourceGroup $ResourceGroup
}else{
    [array]$VMs=Get-AzVM -ResourceGroup $ResourceGroup
}

$AllVMsToUpdate = New-Object System.Collections.ArrayList

#OS disk and Data Disks need to be investigated ; building array of VM's where its enabled on one or more disks
$update=$false
ForEach ($vm in $VMs) {
    $VMName=$vm.Name
    WriteLog "Scanning $vmname" -LogFile $LogFile -Color "Cyan"
#    If ($vm.StorageProfile.OsDisk.Caching -ne $CacheMode ) {
#        $update=$true
#        $VM.StorageProfile.OsDisk.Caching = $CacheMode
#    }
    ForEach ($disk in $vm.StorageProfile.DataDisks){
        If ($disk.Caching -ne $CacheMode) {
        $update=$true
        $disk.Caching = $CacheMode

        }
    
    }
    If ($update -eq $true) {
        WriteLog "$vmname added to update list" -LogFile $LogFile -Color "Green"
        $void=$AllVMsToUpdate.add($vm)
    }else{
        WriteLog "$vmname cache ok" -LogFile $LogFile -Color "Cyan"
    }
}


If ($ProductionRun -eq $true -and $update -eq $true) {
WriteLog "Updating all VM's in list to cache mode $CacheMode" -LogFile $LogFile -Color "Yellow"
    ForEach ($VMtoUpdate in $AllVMsToUpdate) {
        $VmName=$VMtoUpdate.Name
        WriteLog "Updating $VMName"  -LogFile $LogFile -Color "Yellow"
        Update-AzVM -ResourceGroupName $VMtoUpdate.resourcegroupname -VM $VMtoUpdate

        If ($parallel -eq $true) {
            Update-AzVM -ResourceGroupName $VMtoUpdate.resourcegroupname -VM $VMtoUpdate -AsJob    
        }else{
            Update-AzVM -ResourceGroupName $VMtoUpdate.resourcegroupname -VM $VMtoUpdate
        }
    }
}


    If ($Update -ne $true ) {
    WriteLog "No VM to update - nothing to do" -LogFile $LogFile -Color "Green"
}
If ($ProductionRun -ne $true ) {
    WriteLog "Production Run not specified - nothing to do" -LogFile $LogFile -Color "Green"
}
