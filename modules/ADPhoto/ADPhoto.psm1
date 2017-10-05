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
