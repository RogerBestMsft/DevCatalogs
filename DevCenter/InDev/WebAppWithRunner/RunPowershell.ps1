[CmdletBinding()]
  Param([string]$TenantId, [string]$Path)

Connect-AzureAD -TenantId *Insert Directory ID here*
$appName = "rbestbravo"
$appURI = "https://rbestbravo.azurewebsites.net"
$appHomePageUrl = "http://www.microsoft.com.com/"
$appReplyURLs = @($appURI, $appHomePageURL, "https://localhost:1234")
if(!($myApp = Get-AzureADApplication -Filter "DisplayName eq '$($appName)'"  -ErrorAction SilentlyContinue))
{
    $myApp = New-AzureADApplication -DisplayName $appName -IdentifierUris $appURI -Homepage $appHomePageUrl -ReplyUrls $appReplyURLs    
}
$Guid = New-Guid
$startDate = Get-Date
    
$PasswordCredential = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordCredential
$PasswordCredential.StartDate = $startDate
$PasswordCredential.EndDate = $startDate.AddYears(1)
$PasswordCredential.KeyId = $Guid
$PasswordCredential.Value = ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($Guid))))