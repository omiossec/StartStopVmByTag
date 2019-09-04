# PowerShell Azure Function  Sample to start/stop VMs based on a tag

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3a%2f%2fraw.githubusercontent.com%2fomiossec%2fStartStopVmByTag%2fmaster%2fazuredeploy.json) 
<a href="http://armviz.io/#/?load=https%3a%2f%2fraw.githubusercontent.com%2fomiossec%2fStartStopVmByTag%2fmaster%2fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>


This sample allows you to Start and Stop VM on a Schedule based on a tag.

The function will list all VM in the subscription with a specific tag, by default RestartPolicy. VM with this tag are deallocated by the StopVmByTag function. VM are started by the StartVmByTag function. This function looks at the value of the tag. If the value is "workday" VM are only started from Monday to Friday. In other case, VM are started every day. 

You can change the tag used in this function by changing the value of TagName in Application Settings.

The result of Start And Stop actions are logged into the storage associated with the Azure function, in a blob container named logs. Each run will produce a json file named restartvmlog-{DateTime}.json. The Json file contains:

* the action name Start or Stop
* If the action ran on the schedule or later 
* The date and time of the action 
* And the list of the VM and their resource group


## Deploy and configure

To deploy this Azure Functions App you can run the following command 

```powershell
New-AzResourceGroupDeployment -name StopAndStartVM -ResourceGroupName RGName -TemplateParameterObject @{"functionAppName" = "<your function app name>"} -TemplateUri "https://raw.githubusercontent.com/omiossec/StartStopPowerShellFunction/master/azuredeploy.json" 
```

You need to grant access to the managed system identity to your subscription 
The Managed identity should have at least

* Microsoft.Compute/virtualMachines/read
* Microsoft.Compute/virtualMachines/restart/action
* Microsoft.Compute/virtualMachines/deallocate/action

You can also use VM Contributor. 


### changing the schedule

The function StartVmByTag start the VM at 7:30 and the function StopVmByTag stop the vm at 21:30
you can change the schedule used in this example by editing the function.json.

For StartVmByTag
```json
{
        "name": "Timer",
        "type": "timerTrigger",
        "direction": "in",
        "schedule": "0 30 7 * * *"
      }
```

For StartVmByTag
```json
{
        "name": "Timer",
        "type": "timerTrigger",
        "direction": "in",
        "schedule": "0 30 21 * * *"
      }
```

You can also use the online editor in the Portal
