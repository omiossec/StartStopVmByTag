    <#
    .SYNOPSIS
    
    This Azure Function Start VM based on a tag 
    
    .DESCRIPTION
    
    This Azure Function Start VM based on a tag 
    The function use 2 app seeting variable TagName and TagValue to find  deallocated VM and start them
    TagValue can be everyday to start the VM every week day 
    or workday to start the vm only on work day (Monday to Friday)
    
    .OUTPUT
    The function create a json file at each run 
    this file contains 
    datetime
    is the operation pastdue
    VM name
    Ressource group name

    #>

param($timer) 


$AzSubscriptionContext = Get-AzContext -ErrorAction SilentlyContinue

if ($null -eq $ENV:TagName){
    throw "This Azure Function need 2 App Seeting variables TagName and TagValue"
}

if ($null -eq $AzSubscriptionContex) {
    throw "This Azure Function need a managed system identity"
}

try  {

    $currentUTCtime = (Get-Date).ToUniversalTime()
    
    $LogInfoHash = @{"Action-passdue"= $timer.IsPastDue; "Action-StartTime"= $currentUTCtime; "Action"= "Start"}
    $ArrayListloginfos = New-Object System.Collections.ArrayList

    $TaggedVmList = @()

    $TaggedVmList += Get-AzResource -Tag @{ $ENV:TagName="everyday" } -ResourceType "Microsoft.Compute/virtualMachines" | Select-Object name,ResourceGroupName

    if ((get-date).DayOfWeek -notin ("Saturday","sunday")) {
        $TaggedVmList += Get-AzResource -Tag @{ $ENV:TagName="workday" } -ResourceType "Microsoft.Compute/virtualMachines" | Select-Object name,ResourceGroupName
    }

    foreach ($vm in $TaggedVmList) {

        if ((get-azvm -name $vm.name -ResourceGroupName $vm.ResourceGroupName -Status).Statuses[1].code -eq "PowerState/deallocated") {
            Start-AzVM -name $vm.name -ResourceGroupName $vm.ResourceGroupName -AsJob | Write-Information
            $currentUTCtime = (Get-Date).ToUniversalTime()
            $hashVmInfos = @{"Vm"=$vm.name; "ResourceGroup"= $vm.ResourceGroupName; "action-datetime"=$currentUTCtime}
            [void] $ArrayListloginfos.add($hashVmInfos)  
        }

        Start-Sleep -Seconds 5

    }

    $LogInfoHash.add($ArrayListloginfos)
        
    $LogInfoJson = $LogInfoHash | converto-json

    Push-OutputBinding -name LogOutput -value $LogInfoJson

}
catch {
    Write-Error -Message " Exception Type: $($_.Exception.GetType().FullName) $($_.Exception.Message)"
}