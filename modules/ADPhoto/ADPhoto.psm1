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