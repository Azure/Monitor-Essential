# Ensure you're using Powershell 7 or higher

az login

$VMlist = az vm list --query "[].{Name:name, Id:id, ResourceGroup:resourceGroup}" --output json | ConvertFrom-Json


$VMlist | ForEach-Object -Parallel {
    $vm = $_

    $vmId = $vm.Id

    $Associations = az monitor data-collection rule association list --resource $vmId --query "[].{DCRId:dataCollectionRuleId, DCEId:dataCollectionEndpointId}" --output json | ConvertFrom-Json

    $associationData = @()
    foreach ($association in $Associations) {
        $DCRSub = ($association.DCRId -split '/')[2]
        $DCRRG = ($association.DCRId -split '/')[4]
        $DCRName = ($association.DCRId -split '/')[-1]

        $Dcr = az monitor data-collection rule show --subscription $DCRSub --resource-group $DCRRG --name $DCRName --output json | ConvertFrom-Json
        
        $Stream = $Dcr.dataFlows.streams
        $WorkspaceID = $Dcr.destinations.logAnalytics[0].workspaceResourceId

        $associationData += [PSCustomObject]@{
            DcrName       = $DCRName
            DcrRG         = $DCRSub + "/" + $DCRRG
            DceID         = $association.DCEId
            Stream        = $Stream
            WorkspaceName = ($WorkspaceID -split '/')[-1]
            WorkspaceRG   = ($WorkspaceID -split '/')[2] + "/" + ($WorkspaceID -split '/')[4]
        }
    }

    $VMdata = [Ordered]@{
        VMName       = $vm.Name
        VMRGName     = "$($vm.Id -split '/')[2]/$($vm.ResourceGroup)"
        Associations = $associationData 
    }

    $VMObject = New-Object PSObject -Property $VMdata
    $VMObject | ConvertTo-Json -Depth 10
} -ThrottleLimit 10
