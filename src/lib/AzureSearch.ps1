function Get-AzureSearchIndexFields
{
    [CmdletBinding()]
    Param(
        [String]   $ServiceName,
        [String]   $IndexName,
        [string]   $AdminApiKey,
        [string]   $ApiVersion = '2015-02-28', # latest? '2016-09-01'
        [switch]   $Searchable,
        [switch]   $Filterable,
        [switch]   $Retrieveable,
        [switch]   $Sortable,
        [switch]   $Facetable,
        [switch]   $IsKey
        )

    # https://docs.microsoft.com/en-us/rest/api/searchservice/get-index
        
    $Headers = @{
        'api-key'   = $AdminApiKey
    }

    $Uri = "https://{0}.search.windows.net/indexes/{1}/?api-version={2}" -f $ServiceName, $IndexName, $ApiVersion
    try
    {
        Write-Verbose "querying '$Uri'"
        $Fields = (Invoke-WebRequest -Uri $Uri -UseBasicParsing -Method Get -Headers $Headers | ConvertFrom-Json).fields
    }
    catch
    {
        Throw "Failed to do get index from '$Uri'. Error was:´n$_"
    }

    $_Fields = @()
    if($Searchable.IsPresent)
    {
        $_Fields += $Fields| Where-Object {$_.searchable}
    }
    if($Filterable.IsPresent)
    {
        $_Fields += $Fields| Where-Object {$_.filterable}
    }
    if($Retrieveable.IsPresent)
    {
        $_Fields += $Fields| Where-Object {$_.retrievable}
    }
    if($Sortable.IsPresent)
    {
        $_Fields += $Fields| Where-Object {$_.sortable}
    }
    if($Facetable.IsPresent)
    {
        $_Fields += $Fields| Where-Object {$_.facetable}
    }
    if($IsKey.IsPresent)
    {
        $_Fields += $Fields| Where-Object {$_.key}
    }

    if($_Fields)
    {
        Return $_Fields # | Select-Object -ExpandProperty name
    }
    Return $Fields # | Select-Object -ExpandProperty name
}

function New-AzureSearch
{
    [CmdletBinding()]
    Param(
        [String]   $ServiceName,
        [String]   $IndexName,
        [string]   $ApiKey,
        [string]   $AdminApiKey = '',
        [ValidateSet('2015-02-28')]
        [string]   $ApiVersion = '2015-02-28', # latest? '2016-09-01'
        [string]   $Search = '*',
        [int]      $Take = 50,
        [string[]] $Select = @(),
        [string[]] $OrderBy = @(),
        [string]   $SearchMode = 'any', # any or all Specifies whether any or all of the search terms must be matched in order to count the document as a match.
        [string]   $Filter = '' # A structured search expression in standard OData syntax.
    )

    # https://docs.microsoft.com/en-us/azure/search/search-query-rest-api

    if($AdminApiKey)
    {
        $Fields = Get-AzureSearchIndexFields -ServiceName $ServiceName -IndexName $IndexName -AdminApiKey $AdminApiKey
        #$SortableFields = Get-AzureSearchIndexFields -ServiceName $ServiceName -IndexName $IndexName -AdminApiKey $AdminApiKey -Sortable
        #$FilterableFields = Get-AzureSearchIndexFields -ServiceName $ServiceName -IndexName $IndexName -AdminApiKey $AdminApiKey -Filterable
        $SortableFields   = $Fields | Where-Object {$_.sortable} | Select-Object -ExpandProperty name
        $FilterableFields = $Fields | Where-Object {$_.filterable} | Select-Object -ExpandProperty name
    }

    $Params = @{
        search      = $Search
        top         = $Take
        searchMode  = $SearchMode
    }

    if($Select)
    {
        $Params['select'] = $Select -join ','
    }

    # Test is sortable fields
    if($SortableFields -and $OrderBy)
    {
        $NonSortableFields = $OrderBy | Where-Object {$_ -notin $SortableFields}
        if($NonSortableFields)
        {
            Throw "Cannot order by '$( $NonSortableFields -join ',')'"
        }
    }

    if($OrderBy)
    {
        $Params['orderby'] = $OrderBy -join ','
    }

    # Test is filterable fields. 
    if($FilterableFields -and $Filter)
    {
        # need to extract fields from $Filter # TODO: must be some library to do this
        # remove any operators
        [Array]$FilterFields = $Filter -split ' ' | Where-Object {$_ -notin ('and or not eq ne gt lt ge le' -split ' ')}
        # then select every other element
        $FilterFields = $FilterFields[(0..($FilterFields.Count -1) | ? {-not ($_ % 2)})]

        # get any filter fields that are not in the filterable fields
        $NonFilterableFields = $FilterFields | Where-Object {$_ -notin $FilterableFields}
        if($NonFilterableFields)
        {
            Throw "Cannot filter on fields: '$( $NonFilterableFields -join ',')'"
        }
    }
    # TODO validate query is a valid OData expression/filter

    if($Filter)
    {
        $Params['filter'] = $Filter
    }

    $Body = [System.Text.Encoding]::UTF8.GetBytes(($Params | ConvertTo-Json))
        
    $Headers = @{
        'Content-Type' = 'application/json'
        'Accept'       = 'application/json'
        'api-key'   = $ApiKey
    }

    $Uri = "https://{0}.search.windows.net/indexes/{1}/docs/search?api-version={2}" -f $ServiceName, $IndexName, $ApiVersion
    try
    {
        Write-Verbose "querying '$Uri'"
        $Response = (Invoke-WebRequest -Uri $Uri -UseBasicParsing -Method Post -Body $Body -Headers $Headers | ConvertFrom-Json)."value"
    }
    catch
    {
        Throw "Failed to do search query against '$Uri'. Error was:´n$_"
    }
    Return $Response
}