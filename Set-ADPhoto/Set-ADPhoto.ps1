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
