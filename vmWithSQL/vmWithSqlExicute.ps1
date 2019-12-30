Param(
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
[string]$enterResourceGroupName,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
[string]$enterSubscriptionId,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
[string]$enterStorageAccountName,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
[string]$enterVmName,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
[string]$enterVmUserName,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
[string]$enterVmPassword,

[Parameter(Mandatory=$true)]
[ValidateSet("2012-Datacenter","2012-R2-Datacenter","2019-Datacenter")] 
[string]$enterWindowsOSVersion='2012-R2-Datacenter',

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
[string]$enterDnsPrefix,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
[string]$enterLocation

)


Login-AzAccount -Subscription $enterSubscriptionId

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

New-AzResourceGroup -Name $enterResourceGroupName -Location $enterLocation

$storageAccount = New-AzStorageAccount -Name $enterStorageAccountName -ResourceGroupName $enterResourceGroupName `
 -Location $enterLocation -SkuName Standard_LRS -Kind StorageV2 -AccessTier Cool

$ctx = $storageAccount.Context
$containerName = 'sqldscfiles'
New-AzStorageContainer -Name $containerName -Context $ctx -Permission Container 

Set-AzStorageBlobContent -File "$scriptPath\SQL-Configuration.zip" `
  -Container $containerName `
  -Blob "SQL-Configuration.zip" `
  -Context $ctx
 
 $blobUrl=(Get-AzStorageBlob -Blob SQL-Configuration.zip -Container $containerName -Context $ctx).ICloudBlob.Uri.AbsoluteUri

 #$Password = ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9 | sort {Get-Random})[0..15] -join '' `
  #| ConvertTo-SecureString -AsPlainText -Force 
$parameters=@{
'adminUsername'=$enterVmUserName
'adminPassword'=$enterVmPassword
'dnsLabelPrefix'=$enterDnsPrefix
'windowsOSVersion' =$enterWindowsOSVersion
'vmName'=$enterVmName
'storageAccountName'=$enterStorageAccountName
'blobUrl'= $blobUrl
}

$templatePath=($PSScriptRoot | Get-ChildItem -Include 'vmTemplate.*' -recurse).FullName
New-AzResourceGroupDeployment -ResourceGroupName $enterResourceGroupName `
-TemplateFile $templatePath `
-TemplateParameterObject $parameters
