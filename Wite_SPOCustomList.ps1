$SiteUrl = "https://xxxxx.sharepoint.com/sites/xxxxx"
$ListName = "<CustomList Title>"
$UserName  = "<Account MailAddress>"
$Password = Read-Host -Prompt "Enter Password" -AsSecureString

$LogonData = @{
	'SiteUrl' = $SiteUrl;
	'ListName' = $ListName;
	'UserName' = $UserName;
	'Password' = $Password
}

$Functions = {
	function Write-CustomList
	{
		param (
			$Prefix
			,$LogonData
		)

		$SiteUrl = $LogonData['SiteUrl']
		$ListName = $LogonData['ListName']
		$UserName = $LogonData['UserName']
		$Password = $LogonData['Password']

		Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking

		$Context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl)
		$Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $Password)
		$Context.Credentials = $Credentials
		$Context.RequestTimeOut = 5000 * 60 * 10;
		$Web = $Context.Web
		$List = $Web.Lists.GetByTitle($ListName)
		$Context.Load($List)
		$Context.ExecuteQuery()

		1..10 | %{
			$ListItemInfo = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
			$Item = $List.AddItem($ListItemInfo)
			$Title = $Prefix * 1000 + [int]$_
			$Item["Title"] = $Title
			$Item.Update()
			$Context.ExecuteQuery()

			sleep -Seconds 5
		}
	}
}

$Job = 1..5 | %{ 
	Start-Job -InitializationScript $Functions `
		-ScriptBlock{
			param ($Prefix, $LogonData)
			Write-CustomList $Prefix $LogonData
		} `
		-ArgumentList $_ , $LogonData
}

Wait-Job -Job $Job
Remove-Job -Job $Job

Write-Output "done"
