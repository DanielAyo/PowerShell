#Requires -Version 3.0 -Modules activedirectory
function Get-ADPhoto {
    <#
    .SYNOPSIS
    Gets the current thumbnail photo for a user.
    
    .DESCRIPTION
    
    .EXAMPLE
    Get-ADPhoto -Identity 'john.doe' -FilePath 'C:\users\john.doe\newpic.jpg'
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline,
            HelpMessage = 'Enter the SamAccountName of the user')]
        [ValidateNotNullOrEmpty()]
        [Alias('User', 'Username', 'SamAccountName')]
        [string]$Identity,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName,
            HelpMessage = 'Enter the file path of where the photo will be stored')]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )
    begin {   
    }
    process {
        $user = Get-ADUser -Identity $Identity -Properties thumbnailPhoto
        $user.thumbnailPhoto | Set-Content -Path $FilePath -Encoding Byte -PassThru
    }
    end {
    } 
}
function Set-ADPhoto {
    <#
    .SYNOPSIS
    Sets the thumbnail photo for a user.
    
    .DESCRIPTION
    
    .EXAMPLE
    Set-ADPhoto -Identity 'john.doe' -FilePath 'C:\users\john.doe\newpic.jpg'
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline,
            HelpMessage = 'Enter the SamAccountName of the user')]
        [ValidateNotNullOrEmpty()]
        [Alias('User', 'Username', 'SamAccountName')]
        [string]$Identity,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName,
            HelpMessage = 'Enter the file path of the photo')]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )
    begin {   
    }
    process {
        $photo = [byte[]](Get-Content -Path $FilePath -Encoding byte)
        Set-ADUser -Identity $Identity -Replace @{thumbnailPhoto = $photo} -PassThru
    }
    end {
    } 
}
function Get-O365Photo {
    <#
    .SYNOPSIS
    Imports User Profile Picture from Exchange Online
    .DESCRIPTION
    Extracts user photo from Exchange Online using EWS API.
    .EXAMPLE
    Get-O365Photo -Mail user@contoso.com -Directory C:\Temp -Credential "user@contoso.com"
    Extracts user photo from Exchange Online and saves it in the path specfied as Name.jpg
    .EXAMPLE
    "user1@contoso.com" , "user2@contoso.com" | Get-O365Photo -Directory C:\temp -Credential "user@contoso.com"
    Extracts multiple user photos and saves it in the path specfied
    .NOTES
    https://msdn.microsoft.com/en-us/library/office/jj190905(v=exchg.150).aspx
    #>
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Mail,
        [ValidateSet("96x96", "240x240", "648x648")]
        [string] $Size = "648x648",
        [Parameter(Mandatory, ValueFromPipelineByPropertyName,
            HelpMessage = 'Enter the directory where the photo will be stored')]
        [string] $Directory,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    begin {}
    process {
        try {
            $adObj = ([adsisearcher]"(&(objectclass=user)(objectclass=person)(mail=$Mail))").FindOne().GetDirectoryEntry()
            Write-Verbose "$($adObj.Name) extracted" 
            $uri = [string]::Concat("https://outlook.office365.com/ews/Exchange.asmx/s/GetUserPhoto?email=", $Mail, "&size=HR", $Size)
            if (Test-Path -Path $Directory) {
                $File = [string]::Concat($Directory, "\", $adObj.Name, ".jpg")
                Invoke-WebRequest -Uri $uri -Credential $Credential -OutFile $File
            }
            else {
                Write-Warning "Please check that the path exists prior to running the function"
            }
        }
        catch {
            $_.Exception.Message 
        }
    }
    end {}
}
function Get-PhotoJPEG {
    <#
    .SYNOPSIS
    Retrieves photo names from a photo store
    
    .DESCRIPTION
    Obtians the photos from a specified filestore, checks against on-prem AD users and only returns photos that have a name 
    match found in on-prem AD
    
    .EXAMPLE
    Get-PhotoJPEG
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName,
            HelpMessage = 'Enter the directory where the photo is stored')]
        [ValidateNotNullOrEmpty()]
        [string]$Directory,
        [Parameter(ValueFromPipelineByPropertyName,
            HelpMessage = 'Enter the directory where the logs will be stored')]
        [string]$LogPath = $env:temp 
    )
    begin {
        $StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
        $StopWatch.Start()
        $start = [DateTime]::Now
        Write-Verbose "Process Started: $start" 
        [nullable[double]]$secondsRemaining = $null
    }
    process {
        $photos = Get-ChildItem -Path $Directory -Filter "*.jpg"
        $total = $photos.count
        $baseNames = ($photos.BaseName)
        Write-Verbose "$total photos found"       
        $acceptedNames = [System.Collections.ArrayList] @()
        $badNames = [System.Collections.ArrayList] @()
        $counter = 0
        $activity = 'Processing Names'
        foreach ($name in $baseNames) {
            try {
                $counter++
                $percentComplete = $counter / $total * 100
                $progressParams = @{
                    Activity         = $activity
                    Status           = "[$counter / $total] - $([math]::Round($percentComplete))%"
                    CurrentOperation = "Name: $name"
                    PercentComplete  = $percentComplete
                }
                # if we have an estimate for the time remaining, add it to the Write-Progress parameters
                if ($secondsRemaining) {
                    $progressParams.SecondsRemaining = $secondsRemaining
                }
                Write-Progress @progressParams

                #Set regex patterns to validate "name space surname" only               
                $regexName = "^[a-z ,.'-]+$"
                if ($name -match $regexName) {
                    [void]$acceptedNames.Add($name)
                }
                else {
                    [void]$badNames.Add($name)
                }
                # estimate the time remainingcounter
                $secondsElapsed = [DateTime]::Now - $start
                $secondsRemaining = ($secondsElapsed.TotalSeconds / $counter) * ($total - $counter)
            }
            catch {
                Write-Warning $_
            }
        }
        Write-Progress -Activity $activity -Completed
        if ($badNames.Count -gt 0 ) {
            Write-Verbose "$($badNames.Count) unusuable names found > $LogPath\UnusableNames.csv"
            $badNames |  Out-File -FilePath "$LogPath\UnusableNames.csv"
            #attempt to remove the 0X... format from bad names
            $fixedNames = foreach ($n in $badNames) {
                $split = $n -split '\s'
                $final = $split | ForEach-Object { $_ | Select-String -Pattern "^[a-z,.'-]+$"}
                $final = $final -join ' '
                $final
            }
            #add the results into a single collection
            $acceptedNames = $acceptedNames + $fixedNames
        }
        #Get all AD users
        try {
            $adNames = Get-ADUser -Filter {UserPrincipalName -like '*'} -ErrorAction Stop | Select-Object -ExpandProperty Name | Sort-Object
            Write-Verbose "$($adNames.count) AD users found"
        }
        catch {
            Write-Warning $_
            break
        }

        #compare AD names against sateon name list
        Write-Verbose "Comparing photo names and AD user object names"
        $validatedNames = Compare-Object -ReferenceObject $acceptedNames -DifferenceObject $adNames -IncludeEqual -ExcludeDifferent |
            Select-Object -ExpandProperty InputObject |
            Sort-Object
        
        Write-Verbose "$($validatedNames.count) users common in both databases"
        #Make note of any duplicate names that appear and export a log file
        $groupedNames = $validatedNames | Group-Object

        $duplicates = $groupedNames | Where-object {$_.Count -gt 1 } | Select-Object -ExpandProperty Name
        if ($duplicates) {
            Write-Verbose "$($duplicates.Count) duplicate name(s) found > $LogPath\UnusableNames.csv"
            $duplicates | Out-File -FilePath "$LogPath\UnusableNames.csv" -Append
        }
        else {
            Write-Verbose "No duplicates found"
        }
        #singleton only users
        $singletonNames = $groupedNames | Where-object {$_.Count -eq 1 } | Select-Object -ExpandProperty Name
        Write-Verbose 'Keeping only photos names that are referenced in both databases'
        #keep only photos that can be associated with on-prem AD users
        $adPhotoUsers = `
            foreach ($val in $singletonNames) {
            foreach ($photo in $photos) { 
                #making sure the photo name matches the ad name regardless of any additional metadata on the photo name
                if ($photo.BaseName -match $val) {
                    $photo
                    break
                }
            }
        }
        Write-Verbose "$($adPhotoUsers.Count) photos matched with on-prem AD users > $LogPath\ADPhotoUsers.csv"
        $adPhotoUsers | Out-File -FilePath "$LogPath\ADPhotoUsers.csv"
        #Output
        $adPhotoUsers
    }
    end {
        $StopWatch.Stop()
        Write-Verbose "Get-PhotoJPEG Process time: $($StopWatch.Elapsed.TotalSeconds.ToString()) seconds"
    }
}
function Connect-ExchangeOnline {
    <#
    .SYNOPSIS
    Connect to Exchange Online tenant
    
    .DESCRIPTION
    Long description
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName,
            HelpMessage = 'Enter your O365 credentials')]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    #Creates an Exchange Online session using defined credential which allows the import of larger photo files.
    $ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/?proxyMethod=RPS" -Credential $Credential -Authentication Basic -AllowRedirection
    Import-PSSession $ExchangeSession
}
function Set-O365Photo {
    <#
    .SYNOPSIS
    Sets the photo for the Exchange Mailbox of a user

    .DESCRIPTION
    Long description

    .EXAMPLE
    An example

    .NOTES
    Must connect to Exchange Online session prior to use
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject[]]$Photos,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Office = "*",
        [Parameter(ValueFromPipelineByPropertyName,
            HelpMessage = 'Enter the directory where the logs will be stored')]
        [string]$LogPath = $env:TEMP       
    )
    begin {
        $StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
        $StopWatch.Start()
        $start = [DateTime]::Now
        Write-Verbose "Process Started: $start"
        $results = [System.Collections.ArrayList] @()
    }
    process {
        $o365Users = Get-Mailbox -ResultSize unlimited | Where-Object {$_.Office -match $Office} |
            Select-Object Name, HasPicture, IsDirSynced, UserPrincipalName, Office
        #get 0365 users with no photo
        $noPhotoUsers = $o365Users | Where-Object {$_.HasPicture -ne $True}
        $total = $(@($noPhotoUsers).Count)
        Write-Verbose "$total user(s) with no photo"
        $activity = 'Processing Photos'
        $counter = 0
        foreach ($user in $noPhotoUsers) {
            $properties = [ordered]@{
                Name     = ''
                Username = ''
                Office   = ''
                OnPrem   = $false
                Changed  = $false
                Photo    = ''
            }
            
            #check if the o365 user is synced with on-Prem AD
            $counter++
            $percentComplete = $counter / $total * 100
            $progressParams = @{
                Activity         = $activity
                Status           = "[$counter / $total] - $([math]::Round($percentComplete))%"
                CurrentOperation = "Name: $($user.Name)"
                PercentComplete  = $percentComplete
            }
            # if we have an estimate for the time remaining, add it to the Write-Progress parameters
            if ($secondsRemaining) {
                $progressParams.SecondsRemaining = $secondsRemaining
            }
            Write-Progress @progressParams

            $properties.Name = $user.Name
            $properties.Username = $user.UserPrincipalName
            $properties.Office = $user.Office

            if ($user.IsdirSynced) {
                $properties.OnPrem = $true
                #loop through photos to find name match
                foreach ($photo in $Photos) {
                    if ($photo.basename -match $user.Name) {
                        #If they match - set that photo, for that user
                        try {
                            Set-UserPhoto -Identity $user.UserPrincipalName -PictureData ([System.IO.File]::ReadAllBytes($photo.fullname)) -confirm:$False -ErrorAction Stop
                            if ([bool](Get-UserPhoto -Identity $user.Name)) {
                                Write-Verbose "$($user.Name) photo set"
                                $properties.Changed = $true
                                $properties.Photo = $photo.fullname
                                break
                            }
                        }
                        catch {
                            Write-Warning $_
                        }
                    }
                }
            }

            $objectRow = New-Object -TypeName PsObject -Property $properties
            [void]$results.Add($objectRow)
            
            # estimate the time remainingcounter
            $secondsElapsed = [DateTime]::Now - $start
            $secondsRemaining = ($secondsElapsed.TotalSeconds / $counter) * ($total - $counter)    
        }
        $results
    }
    end {
        $StopWatch.Stop()
        Write-Verbose "Set-O365Photo Process time: $($StopWatch.Elapsed.TotalSeconds.ToString()) seconds"
    }
}