$resourceGroupName = "WebApps"
$kuduPath="nayeem" # D:\home\site\wwwroot\test'
$ApplicationId="f500db6b-2fcf-448b-a752-d85277d35efa"
$Key="+y?@Px-IEcrd6Dq4Dip9SMsxAk0bc+]="
$tenantId ="332cf3d3-680b-476e-ad0a-659e90b87300"
$WebappNames=New-Object System.Collections.Generic.Dictionary"[String,bool]"
$webAppNames.Add("copyfileAPIapp",$false)
$WebappNames.Add("copyfilefunctionapp",$false)
$WebappNames.Add("copyfilewebapp",$false)

$securePassword= $key | ConvertTo-SecureString -AsPlainText -Force
$crd= New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId,$securePassword
Add-AzAccount -Credential $crd -TenantId $tenantId -ServicePrincipal

function Get-AzureRmWebAppPublishingCredentials($resourceGroupName, $webAppName, $slotName = $null){
    if ([string]::IsNullOrWhiteSpace($slotName)){
        $resourceType = "Microsoft.Web/sites/config"
        $resourceName = "$webAppName/publishingcredentials"
    }
    else{
        $resourceType = "Microsoft.Web/sites/slots/config"
        $resourceName = "$webAppName/$slotName/publishingcredentials"
    }
    $publishingCredentials = Invoke-AzResourceAction -ResourceGroupName $resourceGroupName -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion 2015-08-01 -Force
    Write-Host $publishingCredentials   
    return $publishingCredentials
}
function Get-KuduApiAuthorisationHeaderValue($resourceGroupName, $webAppName, $slotName = $null){
    $publishingCredentials = Get-AzureRmWebAppPublishingCredentials $resourceGroupName $webAppName $slotName
    Write-Host $publishingCredentials.Properties.PublishingUserName
    Write-Host $publishingCredentials.Properties.PublishingPassword
    return ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName, $publishingCredentials.Properties.PublishingPassword))))
}
function Copy-FileFromWebApp($resourceGroupName, $webAppName, $slotName = "", $kuduPath){

    foreach($webApp in $WebappNames.Keys){
    
    $kuduApiAuthorisationToken = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webApp $slotName
    if ($WebappNames[$webApp]){
        
        $kuduApiUrl = "https://$webApp.cloudmoyo.com/api/command"#"vfs/site/wwwroot/$kuduPath"
    }
    else{
        $kuduApiUrl = "https://$webApp.scm.azurewebsites.net/api/command"#"vfs/site/wwwroot/$kuduPath/"
    }
    Write-Host $kuduApiUrl

    Write-Output $recusive
    Write-Output $kuduApiAuthorisationToken
      $WebConfigBody = 
          @{
           "command"="copy testfile1.txt ..\..\nayeem";
           "dir"="site\wwwroot\nayeem"
           } 
        $bodyContent=@($WebConfigBody) | ConvertTo-Json
        Write-Host $bodyContent
         Invoke-RestMethod -Uri $kuduApiUrl `
                            -Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} `
                            -Method POST -ContentType "application/json" -Body $bodyContent
      $appJsonBody = 
          @{
           "command"="copy testfile1.txt ..\..\nayeem";
           "dir"="site\wwwroot\nayeem"
           } 
        $bodyContent=@($appJsonBody) | ConvertTo-Json
        Write-Host $bodyContent
         Invoke-RestMethod -Uri $kuduApiUrl `
                            -Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} `
                            -Method POST -ContentType "application/json" -Body $bodyContent

    }
}
$slotName=""
Copy-FileFromWebApp $resourceGroupName $webAppName $slotName $kuduPath
