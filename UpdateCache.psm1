#Functions
Function RunLog-Command([string]$Description, [ScriptBlock]$Command, [string]$LogFile, [string]$Color){
    If (!($Color)) {$Color="Yellow"}
    Try{
        $Output = $Description+'  ... '
        Write-Host $Output -ForegroundColor $Color
        ((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force
        $Result = Invoke-Command -ScriptBlock $Command 
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $Output = 'Error '+$ErrorMessage
        ((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force
        $Result = ""
    }
    Finally {
        if ($ErrorMessage -eq $null) {
            $Output = "[Completed]  $Description  ... "} else {$Output = "[Failed]  $Description  ... "
        }
        ((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force
    }
    Return $Result
}


Function WriteLog([string]$Description, [string]$LogFile, [string]$Color){
    If (!($Color)) {$Color="Yellow"}
    Try{
        $Output = $Description+'  ... '
        Write-Host $Output -ForegroundColor $Color
        ((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force
        #$Result = Invoke-Command -ScriptBlock $Command 
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $Output = 'Error '+$ErrorMessage
        ((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force
        $Result = ""
    }
    Finally {
        if ($ErrorMessage -eq $null) {
            $Output = "[Completed]  $Description  ... "} else {$Output = "[Failed]  $Description  ... "
        }
        ((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force
    }
    Return $Result
}
    
    
Function LogintoAzure(){
    $Error_WrongCredentials = $True
    $AzureAccount = $null
    while ($Error_WrongCredentials) {
        Try {
            Write-Host "Info : Please, Enter the credentials of an Admin account of Azure" -ForegroundColor Cyan
            #$AzureCredentials = Get-Credential -Message "Please, Enter the credentials of an Admin account of your subscription"      
            $AzureAccount = Add-AzAccount

            if ($AzureAccount.Context.Tenant -eq $null) 
                        {
                        $Error_WrongCredentials = $True
                        $Output = " Warning : The Credentials for [" + $AzureAccount.Context.Account.id +"] are not valid or the user does not have Azure subscriptions "
                        Write-Host $Output -BackgroundColor Red -ForegroundColor Yellow
                        } 
                        else
                        {$Error_WrongCredentials = $false ; return $AzureAccount}
            }

        Catch {
            $Output = " Warning : The Credentials for [" + $AzureAccount.Context.Account.id +"] are not valid or the user does not have Azure subscriptions "
            Write-Host $Output -BackgroundColor Red -ForegroundColor Yellow
            Generate-LogVerbose -Output $logFile -Message  $Output 
            }

        Finally {
                }
    }
    return $AzureAccount

}
    
Function Select-Subscription ($SubscriptionName, $AzureAccount){
            Select-AzSubscription -SubscriptionName $SubscriptionName -TenantId $AzureAccount.Context.Tenant.TenantId
}

Function LoadModule{
    param (
        [parameter(Mandatory = $true)][string] $name
    )
    $retVal = $true
    if (!(Get-Module -Name $name)){
        $retVal = Get-Module -ListAvailable | where { $_.Name -eq $name }
        if ($retVal) {
            try {
                Import-Module $name -ErrorAction SilentlyContinue
            }
            catch {
                $retVal = $false
            }
        }
    }
    return $retVal
}