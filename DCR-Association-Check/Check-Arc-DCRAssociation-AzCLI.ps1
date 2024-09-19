# Ensure you're using Powershell 7 or higher

az login

$ArcVMlist = az resource list --resource-type "Microsoft.HybridCompute/machines" --query "[].{Name:name, Id:id, ResourceGroup:resourceGroup}" --output json | ConvertFrom-Json

$ArcVMlist | ForEach-Object -Parallel {
    $arcname = $_

    $Associations = az monitor data-collection rule association list --resource $arcname.Id --query "[].{DCRId:dataCollectionRuleId, DCEId:dataCollectionEndpointId}" --output json | ConvertFrom-Json

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

    $Arcdata = [Ordered]@{
        ArcName       = $arcname.Name
        ArcRGName     = ($arcname.Id -split '/')[2] + "/" + $arcname.ResourceGroup
        Associations  = $associationData 
    }

    $ArcObject = New-Object PSObject -Property $Arcdata
    $ArcObject | ConvertTo-Json -Depth 10
} -ThrottleLimit 10
