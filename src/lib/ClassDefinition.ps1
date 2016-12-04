Clear-Host

class AzureSearch {

    # Property: 
    [String] $Name
    [string] $CurrentIndex;
    [string] $ApiVersion = '2016-09-01'
    [string] $ApiKey
    [Object[]] $Response

    # Constructor: 
    AzureSearch([String] $Name, [string] $IndexName, [string] $ApiKey) {
        Write-Verbose -Message "Setting instance name to '$Name'"
        $this.Name = $Name

        $this.CurrentIndex = $IndexName

        $this.ApiKey = $ApiKey
    }

    # Method: do a search query
    [AzureSearch] Search() {
        # https://docs.microsoft.com/en-us/azure/search/search-query-rest-api
        # https://az42.search.windows.net/indexes/realestate-us-sample/docs?api-version=2015-02-28&search=*

        <#
        $Headers = @{
            'Accept'       = 'application/json'

        }

        $Uri = "https://{0}.search.windows.net/indexes/{1}/docs?api-version={2}&api-key={3}&search=*" -f $this.Name, $this.CurrentIndex, $this.ApiVersion, $this.ApiKey
        $this.Response = (Invoke-WebRequest -Uri $Uri -UseBasicParsing -Method Get -Headers $Headers | ConvertFrom-Json)."value"
        Return $this
        #>

        #<# POST fails with some odd error

        $Params = @{
            search      = '*'
        }
        #$Params = @{}
        $Body = [System.Text.Encoding]::UTF8.GetBytes(($Params | ConvertTo-Json))
        
        $Headers = @{
            'Content-Type' = 'application/json'
            'Accept'       = 'application/json'
            'api-key'   = $this.ApiKey

        }

        $Uri = "https://{0}.search.windows.net/indexes/{1}/docs?api-version={2}" -f $this.Name, $this.CurrentIndex, $this.ApiVersion
        try
        {
            Write-Verbose "querying '$Uri'"
            $this.Response = (Invoke-WebRequest -Uri $Uri -UseBasicParsing -Method Post -Body $Body -Headers $Headers | ConvertFrom-Json)."value"
        }
        catch
        {
            $this.Response = @{Error = "Failed to do search query against '$Uri'. Error was:´n$_"}
        }
        #>
        Return $this
    }

    # Method: gets response from last search query
    [Object[]] GetResponse() {

        #Return ($this.Response | ConvertFrom-Json)."value"
        Return $this.Response
    }
}

function New-AzureSearch
{
    [CmdletBinding()]
    Param(
        [String] $Name,
        [String] $IndexName,
        [string] $ApiKey
    )

    $AzureSearch = [AzureSearch]::new($Name, $IndexName, $ApiKey)
    $AzureSearch
}

$AzureSearch = New-AzureSearch -Name 'az42' -IndexName 'realestate-us-sample' -ApiKey 'C8359312BD7BEEDD221214656B234599' -Verbose
$Response = $AzureSearch.Search().GetResponse()

$Response

$Response[0].Error