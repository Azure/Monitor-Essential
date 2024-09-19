# Ensure you're using Powershell 7 or higher

Connect-AzAccount

$ArcVMlist = Get-AzResource | Where-Object { $_.ResourceType -eq "Microsoft.HybridCompute/machines" }

$ArcVMlist| ForEach-Object -Parallel {
    $arcname = $_
    $Associations = Get-AzDataCollectionRuleAssociation -ResourceUri $arcname.Id

    $associationData = @()
    foreach ($association in $Associations) {

        $DCRSub = ($association.DataCollectionRuleId -split '/')[2]
        $DCRRG  = ($association.DataCollectionRuleId -split '/')[4]
        $DCRName = ($association.DataCollectionRuleId -split '/')[-1]

        $Dcr = Get-AzDataCollectionRule -SubscriptionId $DCRSub -ResourceGroupName $DCRRG -Name $DCRName
        $Stream = $dcr.DataFlow.Stream
        $WorkspaceID = $dcr.DestinationLogAnalytic.WorkspaceResourceId

        $associationData += [PSCustomObject]@{
            DcrName       = $DCRName
            DcrRG         = $DCRSub + "/" + $DcrRG
            DceID         = $association.DataCollectionEndpointId
            Stream        = $Stream
            WorkspaceName = ($WorkspaceID -split '/')[-1]
            WorkspaceRG   = ($WorkspaceID -split '/')[2] + "/" + ($WorkspaceID -split '/')[4]
        }
    }
    $Arcdata = [Ordered]@{
        ArcName       = $arcname.Name
        ArcRGName     = ($arcname.Id -split '/')[2] + "/" + $arcname.resourcegroupname
        Associations  = $associationData 
    }
    $ArcObject = New-Object PSObject -Property $Arcdata
    $ArcObject | ConvertTo-Json -Depth 10
} -ThrottleLimit 10