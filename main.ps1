#Fetches and displays all users that haven't been online in X days
Param(
	[Parameter(Mandatory = $true)][int][ValidateNotNullOrEmpty()]$Threshold, # Throw a warning for accounts older than X days
    [Parameter(Mandatory = $true)][String][ValidateNotNullOrEmpty()]$SearchBase
) #end param

$output=@();
$users = @();
$OutputHTML = $NULL;

$date = (Get-Date).adddays(-($Threshold));
Write-Host "Users not online in past " $Threshold " days that are still Enabled";
Write-Host "Haven't logged in since at minimum " $date
$users = Get-ADUser -searchBase $SearchBase -filter { (lastLogonTimeStamp -le $date) -and (enabled -eq "true") } -properties lastLogonTimeStamp,lastLogon,eduPersonAffiliation,Mail,department,title,Description,employeeNumber

foreach ($usr in $users) {
	if ($usr.lastLogonTimeStamp -gt 0) {
		if ( -not ($usr.DistinguishedName -match "OU=Resources")) {
			if ($null -ne $usr.employeeNumber) {
				if ($usr.eduPersonAffiliation -notcontains 'retiree') {
					$usr.lastADLogon = [datetime]::FromFileTime($usr.lastLogonTimeStamp).toString()
					$output += $usr
				}
			}
		}
	}
}

if ($output.Count -gt 0) {
	$outputHTML += ("Report for last " + $Threshold + " days: " + $Output.Count + " users total.")
	$OutputHTML += ("`nHaven't logged on since (minimum) " + $date)
	$OutputHTML += ("`nThis is accurate within 19 days: https://docs.microsoft.com/en-us/windows/win32/adschema/a-lastlogontimestamp")
	$OutputHTML += ($output | Select-Object -Property Name,Description,Mail,eduPersonAffiliation,DistinguishedName,lastADLogon | Sort-Object -Property Description | Out-String)
	Send-MailMessage -From $env:MailFrom -To $env:MailTo -SmtpServer "mailhost.unt.edu" -Subject ("Inactive Accounts Last " + $Threshold + " Days") -Body $OutputHTML
} else {
	Write-Host "User count not greater than 0"
}