
Login-AzureRmAccount

$resourceGroupName = "AADF"
$location = "North Europe"
$blobName = "storageaadf"
$containerName = "contains"
$localFileDirectory = "C:\Users\XXXXXXXXXX\Desktop\templates\"
$scriptFilename = "U-Sql.txt"
$inputData = "testdata1.csv"
$inputDataLocalFile = $localFileDirectory + $inputData
$scriptLocalFile = $localFileDirectory + $scriptFilename
$adlsStoreName = "adlsdf"
$adlaName = "aadf"
$dataFactoryName = "df17"


# Resource group creation 

New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

# Creating, Uploading and creating the keys

$storageAccount = New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $blobName -SkuName "Standard_LRS" -Location $location
$ctx = $storageAccount.Context
New-AzureStorageContainer -Name $containerName -Permission "Container" -Context $ctx
Set-AzureStorageBlobContent -File $scriptLocalFile -Container $containerName -Blob $scriptFilename -Context $ctx
$key = Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $blobName
$connection_string = "DefaultEndpointsProtocol=https;AccountName={0};AccountKey={1};EndpointSuffix=core.windows.net" -f $blobName,$key.Value[0]

# Azure Data Lake store creation and uploading the input file and creating the destination folder

New-AzureRmDataLakeStoreAccount -ResourceGroupName $resourceGroupName -Name $adlsStoreName -Location $location
$inputDataInADLS = New-AzureRmDataLakeStoreItem -Account $adlsStoreName -Path "/testdata" -Folder
$outputDataInADLS = New-AzureRmDataLakeStoreItem -Account $adlsStoreName -Path "/newdata" -Folder
Import-AzureRmDataLakeStoreItem -Account $adlsStoreName -Path $inputDataLocalFile -Destination "/testdata/testdata1.csv"
New-AzureRmDataLakeAnalyticsAccount -ResourceGroupName $resourceGroupName -Name $adlaName -Location $location -DefaultDataLakeStore $adlsStoreName

# Allowing ADLS access to Analytics

$spiObjectId = (Get-AzureRmADServicePrincipal -SearchString @YourSPI-Name).Id
New-AzureRmRoleAssignment -ObjectId $spiObjectId -ResourceGroupName $resourceGroupName -ResourceName $adlsStoreName -RoleDefinitionName "Owner" -ResourceType Microsoft.DataLakeStore/accounts
New-AzureRmRoleAssignment -ObjectId $spiObjectId -ResourceGroupName $resourceGroupName -ResourceName $adlaName -RoleDefinitionName "Owner" -ResourceType Microsoft.DataLakeAnalytics/accounts


# Execution of Data Factory template for creating the pipeline

New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile C:\Users\XXXXXXXXXXXX\Desktop\templates\df.json -dataFactoryName $dataFactoryName -connectionString $connection_string -dataLakeStoreName $adlsStoreName -dataLakeAnalyticsName $adlaName -testDataFolder $inputDataInADLS -resultDataFolder $outputDataInADLS  