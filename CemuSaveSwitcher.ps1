# -- Config object

Class Config {

	static [string]$filename = ".\CemuSaveSwitcher.config.xml"
	[string]$mlc01Path
	[string[]]$users
	[int]$currentUserIndex

	Config() {
		$this.users = @()
	}

	[bool] ContainsUser([string]$user) {
		return $this.users.Contains($user.ToLower())
	}

	[bool] ContainsUser([int]$userIndex) {
		return $this.users.count > $userIndex
	}

	[bool] AddUser([string]$user) {
		if ($this.ContainsUser($user)) {
			return $false
		}
		$this.users += $user.ToLower()
		return $true
	}

	[bool] SetCurrentUser([string]$user) {
		if (!$this.ContainsUser($user)) {
			return $false
		}
		$this.currentUserIndex = $this.users.IndexOf($user.ToLower())
		return $true
	}

	[bool] SetCurrentUser([int]$userIndex) {
		if ($this.ContainsUser($userIndex)) {
			return $false
		}
		$this.currentUserIndex = $userIndex
		return $true
	}

	[string] GetCurrentUser() {
		return $this.users[$this.currentUserIndex]
	}

	[int] GetUsersCount() {
		return $this.users.count
	}

	[string] GetSavePath() {
		return ("{0}\usr\save" -f $this.mlc01Path)
	}

	[string] GetBackupSavePath() {
		return ("{0}\usr\save_{1}" -f $this.mlc01Path, $this.GetCurrentUser())
	}

	PrintExistingUsers() {
		Write-Host ("[i] Existing users : {0}" -f $this.GetUsersCount()) -ForegroundColor Cyan
		Foreach ($user in $this.users)
		{
			Write-Host (" - {0}" -f (ToTitleCase $user))
		}
	}

	Save() {
		$this | Export-Clixml -Path $this::filename
		Remove-Item $this.currentUserIndex
	}

	PromptMlcPath() {
		$this.mlc01Path = SelectFolder
	}

	PromptCurrentOwner() {
		Write-Host "[>] Who is the owner of current save files ?" -ForegroundColor Cyan
		while ($true) {
				$input = Read-Host " + "
				if ( [string]::IsNullOrEmpty($input) ) {
						Write-Host "[!] Empty values not allowed, try again" -ForegroundColor Red
				} else {
				$this.AddUser($input)
				$this.SetCurrentUser($input)
				break
			}
		}
	}

	PromptAddUsers() {
		Write-Host "[>] Enter as many more users as you like, press <enter> to terminate" -ForegroundColor Cyan
		while ($true) {
	    	$input = Read-Host " + "
	    	if ( [string]::IsNullOrEmpty($input) ) {
	        	break
	    	}
				if (!$this.AddUser($input)) {
					Write-Host "[!] User already exists, select another nickname" -ForegroundColor Red
				}
		}
	}


	static [Config] Create() {
		$dst = [Config]::new()
		$dst.PromptMlcPath()
		$dst.PromptCurrentOwner()
		$dst.PromptAddUsers()
		return $dst
	}

	static [Config] Load() {
		$f = [Config]::filename
		[Config]$cfg = Import-Clixml -Path $f
		return $cfg
	}

}

# -- Useful functions

function AddChoice {
	Param($list,$item)
	$newChoice = New-Object System.Management.Automation.Host.ChoiceDescription $item
	$list.Add($newChoice)
}

function PopulateFrom {
	Param($tuples, [System.Collections.Generic.List[String]]$values, [String]$format)
	$dst = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription]
	if ($values -and $format) {
		Foreach ($item in $values)
		{
			$key = "#&{1}: {0}" -f ((ToTitleCase $item), ($values.IndexOf($item) + 1))
			$desc = $format -f $item
			AddChoice -item ($key, $desc) -list $dst
		}
	} else {
		Foreach ($item in $tuples)
		{
			AddChoice -item $item -list $dst
		}
	}
	return $dst
}

function ToTitleCase {
	return (Get-Culture).TextInfo.ToTitleCase($args[0].ToLower())
}

function SelectFolder {
    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $browse = New-Object System.Windows.Forms.FolderBrowserDialog
    $browse.SelectedPath = "C:\"
    $browse.ShowNewFolderButton = $false
    $browse.Description = "Select your Cemu mlc01 folder"
    while($true)
    {
        if ($browse.ShowDialog() -eq "OK")
        {
        	break
        } else
        {
            $res = [System.Windows.Forms.MessageBox]::Show("You clicked Cancel. Would you like to try again or exit?", "Select a location", [System.Windows.Forms.MessageBoxButtons]::RetryCancel)
            if($res -eq "Cancel")
            {
                #Ends script
                return
            }
        }
    }
    $ret = $browse.SelectedPath
    $browse.Dispose()
		return $ret
}

# function CreateShortcut {
# 	$ShortcutFile = "{0}\{1}" -f [Environment]::GetFolderPath("Desktop"), "CemuSaveSwitcher.lnk"
# 	$WScriptShell = New-Object -ComObject WScript.Shell
# 	$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
# 	$Shortcut.TargetPath = "{0}\CemuSaveSwitcher.ps1" -f $PSScriptRoot
# 	$Shortcut.Save()
# }

# -- Script main functions

function LoadConfig {
	try {
		$cfg = [Config]::Load()
	} catch {
		Write-Host "[i] No config found, creating a fresh one" -ForegroundColor Yellow
		$cfg = [Config]::Create()
		$cfg.Save()
		# CreateShortcut
	}
	return $cfg
}


function MainMenu() {
	$title = "[?] What do you want to do ?"
	$message = ""
	$choices = PopulateFrom -tuples @(
		("&Switch saves", "Select save of another user and set it as current"),
		("&Add users", "Add more users"),
		("&Exit", "Exit the program")
	)
	return $host.ui.PromptForChoice($title, $message, $choices, 0)
}

function SwitchUser {
	Param([Config]$cfg)
	Clear-Host
	$title = "[?] Select a user to load the saves from"
	$message = ("[i] Current user : {0}" -f (ToTitleCase $cfg.GetCurrentUser()))
	$choices = PopulateFrom -values $cfg.users -format "Select {0} save folder"
	$result = $host.ui.PromptForChoice($title, $message, $choices, $cfg.currentUserIndex)
	if ($result -eq $cfg.currentUserIndex) {
		Write-Host ("[i] {0} is already the current user, nothing done" -f (ToTitleCase $cfg.GetCurrentUser())) -ForegroundColor Yellow
		return
	}
	Write-Host ("[i] Saving current save folder to {0}" -f $cfg.GetBackupSavePath()) -ForegroundColor Cyan
	Rename-Item $cfg.GetSavePath() $cfg.GetBackupSavePath()
	$cfg.SetCurrentUser($result)
	Write-Host ("[i] Switching to user {0}" -f (ToTitleCase $cfg.GetCurrentUser())) -ForegroundColor Cyan
	if(Test-Path $cfg.GetBackupSavePath())	{
		Write-Host ("[i] Retrieving existing save folder at {0}" -f $cfg.GetBackupSavePath()) -ForegroundColor Cyan
    Rename-Item $cfg.GetBackupSavePath() $cfg.GetSavePath()
	}
	$cfg.Save()
}

function AddUsers {
	Param([Config]$cfg)
	Clear-Host
	$cfg.PrintExistingUsers()
	$cfg.PromptAddUsers()
	$cfg.Save()
}


# -- START OF SCRIPT --

Clear-Host
Write-Host "[ CEMU SAVES SWITCHER ]" -ForegroundColor Cyan

$config = LoadConfig
Write-Host ("[i] Mlc01 : {0}" -f $config.mlc01Path) -ForegroundColor Green

switch (MainMenu)
{
	0 {SwitchUser -cfg $config}
	1 {AddUsers -cfg $config}
	2 {}
}

Write-Host "[DONE]" -ForegroundColor Green
