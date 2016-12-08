Clear-Host

Remove-Module AzureSearch -ErrorAction SilentlyContinue
Import-Module "..\AzureSearch.psm1"


$ApiKey = 'C8359312BD7BEEDD221214656B234599'
$ServiceName = 'az42'
$IndexName = 'realestate-us-sample'

$AzureSearch = New-AzureSearch -Name $ServiceName -IndexName $IndexName -ApiKey $ApiKey -Verbose
$Response = $AzureSearch.Search().GetResponse()

$Response