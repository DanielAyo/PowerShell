function Test-URLRedirect {
<#
.SYNOPSIS
   Tests a HTTP/S URL link to check if there is a redirect
.PARAMTER URL
    Enter the name of the URL you wish to test for redirection
.EXAMPLE
    Test-URLRedirect -URL https://www.google.com

    URLTest    URLResult                                                    URLRedirect
    -------    ---------                                                    -----------
    google.com http://www.google.co.uk/?gfe_rd=cr&ei=hAwGWYnkLIf38Aes8L_QAw        True

.EXAMPLE
    Test-URLRedirect -URL google.com,http://www.bbc.co.uk,ghm,microsoft.com

    URLTest              URLResult                                                    URLRedirect
    -------              ---------                                                    -----------
    google.com           http://www.google.co.uk/?gfe_rd=cr&ei=fAsGWcTfGYPS8AfimqCABg        True
    http://www.bbc.co.uk http://www.bbc.co.uk/                                              False
    ghm                  N/A                                                                False
    microsoft.com        https://www.microsoft.com/en-gb/                                    True

.NOTES
   All scripts and other PowerShell references are offered AS IS with no warranty.
   Written by Daniel Ayo.
   These script and functions have been tested in my environment and should be tested prior to production use.
#>
    [CmdletBinding()]
    param (
         [Parameter(Mandatory,
                    ValueFromPipelineByPropertyName,
                    HelpMessage='Enter the name of the URL i.e http://www.bbc.co.uk')]
         [ValidateNotNullOrEmpty()]
         [string[]]$URL
    )
    begin {
        $StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
        $StopWatch.Start()
        $Log = Get-Date
        Write-Verbose "Process commenced: $Log"
        $URLTable = @()
        $Properties = [ordered] @{
            URLTest = [string]
            URLResult = [uri]
            URLRedirect = [bool]
        }
    }
    process {
        foreach ($URI in $URL) {
            try {
                $Request = Invoke-WebRequest -Uri $URI -UseBasicParsing -ErrorAction Stop
                $URLResult = $Request.BaseResponse.ResponseUri
                if($URLResult -eq $URI) {
                    $URLRedirect = $false
                }
                else {
                    $URLRedirect = $true
                }
                $Properties.URLTest = $URI
                $Properties.URLResult = $URLResult
                $Properties.URLRedirect = $URLRedirect
                $ObjRecord = New-Object -TypeName PsObject -Property $Properties
                $URLTable += $ObjRecord
            }
            catch {
                Write-Warning "Unexpected error occurred while executing $((Get-PSCallStack)[0].Command) with the exception message: $($_.Exception.Message)"
                Write-Warning "Command: `'$($_.InvocationInfo.Line.Trim())`'"
                Write-Warning "Line Number: $($_.InvocationInfo.ScriptLineNumber)"

                if(($_.Exception.Message) -like "*The remote name could not be resolved*") {
                    $Properties.URLTest = $URI
                    $Properties.URLResult = 'N/A'
                    $Properties.URLRedirect = $false
                    $ObjRecord = New-Object -TypeName PsObject -Property $Properties
                    $URLTable += $ObjRecord
                }
                else {
                    break
                }
            }
        }
        Write-Output $URLTable
    }
    end {
        $StopWatch.Stop()
        Write-Verbose "Cmdlet Time to Process: $($StopWatch.Elapsed.TotalSeconds.ToString()) seconds"
    }
}