Clear-Host

Remove-Module AzureSearch -ErrorAction SilentlyContinue
Import-Module "..\AzureSearch.psm1"


$ApiKey = 'C8359312BD7BEEDD221214656B234599'
$ServiceName = 'az42'
$IndexName = 'realestate-us-sample'

# get facetable fields
#Get-AzureSearchIndex -ServiceName $ServiceName -IndexName $IndexName -AdminApiKey $AdminKey -Facetable -Verbose; break

New-AzureSearch -ServiceName $ServiceName -IndexName $IndexName -ApiKey $ApiKey -Take 2 -OrderBy 'daysOnMarket' -Filter 'beds gt 2 and daysOnMarket lt 200 and daysOnMarket gt 0' -AdminApiKey $AdminKey -Verbose