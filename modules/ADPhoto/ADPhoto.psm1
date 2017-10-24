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
    Returns all existing Exchange Online users with photos as JPEG output.
    
    .DESCRIPTION
    Long description
    
    .EXAMPLE
    Get-O365Photo -Directory C:\users\test\desktop\Photo 
    
    .NOTES
    Must connect to Exchange Online session prior to use.
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty]
        [string]$Directory = "C:\temp\Photos"
    )
    begin {
    }
    process {
        $photoUsers = get-mailbox -ResultSize Unlimited | Where-Object {$_.HasPicture -eq $True} | Select-Object -ExpandProperty UserPrincipalName
        foreach ($photoUser in $photoUsers) {
            $user = Get-UserPhoto $photoUser
            $user.PictureData | Set-Content "$Directory\$($User.Identity).jpg" -Encoding byte
        }
    }
    end {
    }
}