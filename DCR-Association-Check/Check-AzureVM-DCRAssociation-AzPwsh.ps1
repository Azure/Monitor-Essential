# Ensure you're using Powershell 7 or higher

Connect-AzAccount 

$VMlist = Get-AzVM

$VMlist | ForEach-Object -Parallel {
    $vm = $_
    $vmId = $vm.Id

    $Associations = Get-AzDataCollectionRuleAssociation -ResourceUri $vmId

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
    $VMdata = [Ordered]@{
        VMName       = $vm.Name
        VMRGName     = ($vmId.ResourceGroupName -split '/')[2] + "/" + $vm.resourcegroupname
        Associations = $associationData 
    }
    $VMObject = New-Object PSObject -Property $VMdata
    $VMObject | ConvertTo-Json -Depth 10
} -ThrottleLimit 10