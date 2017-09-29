function Test-URLRedirect {
    <#
    .SYNOPSIS
       Tests a HTTP/S URL link to check if there is a redirect
    .PARAMTER URL
        Enter the name of the URL you wish to test for redirection
    .EXAMPLE
        Test-URLRedirect -URL https://www.google.com
    
        URLTest    urlResult                                                    URLRedirect
        -------    ---------                                                    -----------
        google.com http://www.google.co.uk/?gfe_rd=cr&ei=hAwGWYnkLIf38Aes8L_QAw        True
    .EXAMPLE
        Test-URLRedirect -URL bbd.com,dcdcd,https://www.facebook.com
    
        URLTest                  URIResult                 URLRedirect
        -------                  ---------                 -----------
        bbd.com                  http://bbd.com/                  True
        dcdcd                    N/A                             False
        https://www.facebook.com https://www.facebook.com/       False
    .NOTES
       All scripts and other PowerShell references are offered AS IS with no warranty.
       Written by Daniel Ayo.
       These script and functions have been tested in my environment 
       and should be tested prior to production use.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline,
            HelpMessage = 'Enter the name of the URL i.e http://www.bbc.co.uk')]
        [ValidateNotNullOrEmpty()]
        [string[]]$URL
    )
    begin {
        $stopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
        $stopWatch.Start()
        $log = Get-Date
        Write-Verbose "Process commenced: $log"
        [System.Collections.ArrayList]$urlTable = @()   
    }
    process {
        foreach ($uri in $URL) {
            try {
                $urlRedirect = $false
                $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -ErrorAction Stop
                $urlResult = $response.BaseResponse.ResponseUri               
                if ($urlResult -ne $uri) {
                    $urlRedirect = $true
                }
                $obj = [PSCustomObject]@{
                    URLTest     = $uri
                    URIResult   = $urlResult
                    URLRedirect = $urlRedirect
                }
                #Out-Null to suppress the result output from adding the object to the array
                $urlTable.Add($obj) | Out-Null
            }
            catch {
                Write-Warning "Error executing $((Get-PSCallStack)[0].Command)."
                Write-Warning "Exception message: $($_.Exception.Message)"
                Write-Warning "Command: `'$($_.InvocationInfo.Line.Trim())`'"
                Write-Warning "Line Number: $($_.InvocationInfo.ScriptLineNumber)"
                if (($_.Exception.Message) -match 'The remote name could not be resolved') {
                    $obj = [PSCustomObject]@{
                        URLTest     = $uri
                        URIResult   = 'N/A'
                        URLRedirect = $urlRedirect
                    }
                    $urlTable.Add($obj) | Out-Null
                }
                else {
                    break
                }
            }
        }
        Write-Output $urlTable
    }
    end {
        $StopWatch.Stop()
        Write-Verbose "Process time: $($StopWatch.Elapsed.TotalSeconds.ToString()) seconds"
    }
}