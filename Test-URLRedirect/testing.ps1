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
            [System.Collections.ArrayList]$URLTable = @()
        }
        process {
            foreach ($URI in $URL) {
                try {
                    $Request = Invoke-WebRequest -Uri $URI -UseBasicParsing -ErrorAction Stop
                    $URLResult = $Request.BaseResponse.ResponseUri
                    if($URLResult -eq $URI) {
                        $URLRedirect = $false
                    } else {
                        $URLRedirect = $true
                    }
                    $obj = [PSCustomObject]@{
                        URLTest = $URI
                        URIResult = $URLResult
                        URLRedirect = $URLRedirect
                    }
                    ##Piping to Out-Null to suppress the result output from adding the object to the array
                    $URLTable.Add($obj) | Out-Null
                }
                catch {
                    Write-Warning "Unexpected error occurred while executing $((Get-PSCallStack)[0].Command) with the exception message: $($_.Exception.Message)"
                    Write-Warning "Command: `'$($_.InvocationInfo.Line.Trim())`'"
                    Write-Warning "Line Number: $($_.InvocationInfo.ScriptLineNumber)"
                    if(($_.Exception.Message) -like "*The remote name could not be resolved*") {
                        $obj = [PSCustomObject]@{
                            URLTest = $URI
                            URIResult = 'N/A'
                            URLRedirect = $false
                        }
                        $URLTable.Add($obj) | Out-Null
                    } else {
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
