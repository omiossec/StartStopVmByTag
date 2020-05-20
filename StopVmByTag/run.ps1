    <#
    .SYNOPSIS
    
    This Azure Function Stop VM based on a tag 
    
    .DESCRIPTION
    
    This Azure Function Stop VM based on a tag 
    The function use 1 app seeting variable TagName to find  VM and stop them
    TagValue can be "everyday" to start/stop  VM every  day 
    or "workday" to start  vm only on work day (Monday to Friday)
    Result are logged into a storage account blob container named logs
    
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
    
    if ($null -eq $AzSubscriptionContext) {
        throw "This Azure Function need a managed system identity"
    }
    
    try  {

        $currentUTCtime = (Get-Date).ToUniversalTime()
    

        $ArrayListloginfos = New-Object System.Collections.ArrayList


        #$TaggedVmList = Get-AzVm | where-object  {$_.Tags.Keys -eq $ENV:TagName}
    
        $TaggedVmList = @()

        $TaggedVmList += Get-AzResource -Tag @{ $ENV:TagName="everyday" } -ResourceType "Microsoft.Compute/virtualMachines"  -ErrorAction SilentlyContinue | Select-Object name,ResourceGroupName
        $TaggedVmList += Get-AzResource -Tag @{ $ENV:TagName="workday" } -ResourceType "Microsoft.Compute/virtualMachines"  -ErrorAction SilentlyContinue | Select-Object name,ResourceGroupName
    

        if ((get-date).DayOfWeek -in ("friday","saturday","sunday")) {
            $TaggedVmList += Get-AzResource -Tag @{ $ENV:TagName="weekend" } -ResourceType "Microsoft.Compute/virtualMachines" -ErrorAction SilentlyContinue | Select-Object name,ResourceGroupName
        }
    
  
        
        foreach ($vm in $TaggedVmList) {
    
            if ((get-azvm -name $vm.name -ResourceGroupName $vm.ResourceGroupName -Status).Statuses[1].code -eq "PowerState/running") {
                stop-AzVM -name $vm.name -ResourceGroupName $vm.ResourceGroupName -force -AsJob | Write-Debug
                $currentUTCtime = (Get-Date).ToUniversalTime()
                $hashVmInfos = @{"Vm"=$vm.name; "ResourceGroup"= $vm.ResourceGroupName; "action-datetime"=$currentUTCtime}
                [void] $ArrayListloginfos.add($hashVmInfos)  
            }
                Start-Sleep -Seconds 5
        }

        $LogInfoHash = @{"Action-passdue"= $timer.IsPastDue; "Action-StartTime"= $currentUTCtime; "Action"= "Stop";"vm-list"=$ArrayListloginfos}

    
        $LogInfoJson = $LogInfoHash | ConvertTo-Json -Depth 4

        Push-OutputBinding -name LogOutput -value $LogInfoJson
       
    }
    catch {
        Write-Error -Message " Exception Type: $($_.Exception.GetType().FullName) $($_.Exception.Message)"
    }