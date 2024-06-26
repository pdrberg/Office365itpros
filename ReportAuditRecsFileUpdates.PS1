# ReportAuditRecsFileUpdates.PS1
# https://github.com/12Knocksinna/Office365itpros/blob/master/ReportAuditRecsFileUpdates.PS1
# Example of using audit records to find out who changed a file
# Updated 28-June-2024 for the 2025 Book

$Modules = Get-Module | Select-Object -ExpandProperty Name
If ("ExchangeOnlineManagement" -notin $Modules) {
    Write-Host "Loading Exchange Online Management module"
    Connect-ExchangeOnline -SkipLoadingCmdletHelp
}

$FileName = (Read-Host "Enter file name to search")
[array]$Records = Search-UnifiedAuditLog -Operations FileModified, FileAccessed, FileUploaded `
  -ObjectIds $FileName -ResultSize 5000 -StartDate (Get-Date).AddDays(-180) -EndDate (Get-Date).AddDays(+1) `
  -SessionCommand ReturnLargeSet

If ($Records.Count -eq 0) {
    Write-Host "No audit records found for file names beginning with" $FileName 
    Break
}
# Remove any duplicates
$Records = $Records | Sort-Object Identity -Unique | Sort-Object { $_.CreationDate -as [datetime]} -Descending
Write-Host ("Processing {0} audit records..." -f $Records.Count)
$Report = [System.Collections.Generic.List[Object]]::new()
ForEach ($Rec in $Records) {
  $AuditData = ConvertFrom-Json $Rec.Auditdata
  $ReportLine = [PSCustomObject]@{
    TimeStamp   = $Rec.CreationDate
    User        = $AuditData.UserId
    Action      = $AuditData.Operation
    SiteUrl     = $AuditData.SiteUrl
    Site        = $AuditData.SourceRelativeUrl
    File        = $AuditData.SourceFileName
    IpAddress   = $AuditData.ClientIP
    App         = $AuditData.UserAgent 
  }
  $Report.Add($ReportLine) 
}

Write-Host “All done”
$Report | Out-GridView -Title "File operation audit records"

# An example script used to illustrate a concept. More information about the topic can be found in the Office 365 for IT Pros eBook https://gum.co/O365IT/
# and/or a relevant article on https://office365itpros.com or https://www.practical365.com. See our post about the Office 365 for IT Pros repository # https://office365itpros.com/office-365-github-repository/ for information about the scripts we write.

# Do not use our scripts in production until you are satisfied that the code meets the need of your organization. Never run any code downloaded from the Internet without
# first validating the code in a non-production environment.
