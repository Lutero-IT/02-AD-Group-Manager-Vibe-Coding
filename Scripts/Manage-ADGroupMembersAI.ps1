# ==============================================================================
# Script Name: Manage-ADGroupMembers.ps1
# Description: Enterprise Active Directory Group Membership Manager (AI-Driven)
# ==============================================================================

param(
    [string]$TargetPath = "OU=User Groups,OU=Groups,OU=Camp,DC=oldcamp,DC=gothic,DC=inc"
)

# 1. ARCHITECTURAL DECOMPOSITION & IMPORT
# Import the universal TUI Arrow Navigation script using dot-sourcing
if (Test-Path ".\Show-ArrowMenuAI.ps1") {
    . ".\Show-ArrowMenuAI.ps1"
} else {
    Write-Error "CRITICAL: 'Show-ArrowMenuAI.ps1' not found in the current directory. Cannot launch program."
    Exit
}

# Interactive Menu Titles (Separate variables as required by specification)
$TitleChooseGroupMenu = "CHOOSE GROUP MENU"
$TitleMainMenu         = "MAIN MENU"
$TitleRemoveMenu       = "REMOVE MENU"

# Welcome Message
Clear-Host
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Welcome to AD Group Membership Manager " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Start-Sleep -Seconds 1

# ==============================================================================
# CORE HELPER FUNCTIONS
# ==============================================================================

function Get-ADGroupSelection {
    param([string]$OUPath)

    try {
        # Dynamically fetch groups from the specific OU
        $groups = Get-ADGroup -Filter * -SearchBase $OUPath | Sort-Object Name
        if (-not $groups) {
            Write-Warning "No Active Directory groups found in the specified OU."
            Read-Host "Press Enter to return..."
            return $null ###### CZEMU RETURN NULL???
        }

        # Build option list for TUI menu
        $groupNames = [System.Collections.Generic.List[string]]::new() ###### CO TO??? CO TO ROBI???
        foreach ($g in $groups) { $groupNames.Add($g.Name) }
        $groupNames.Add("Back")

        # Invoke Arrow Navigation Menu
        $selectedIndex = Show-ArrowMenu -MenuOptions $groupNames.ToArray() -CurrentGroup "None" -Title $TitleChooseGroupMenu

        if ($selectedIndex -eq ($groupNames.Count - 1)) {
            return $null # User chose 'Back'
        }

        return $groups[$selectedIndex]
    }
    catch {
        Write-Error "System Error while fetching AD Groups: $_"
        Read-Host "Press Enter to return..."
        return $null
    }
}

function Show-Members {
    param([Microsoft.ActiveDirectory.Management.ADGroup]$Group)
    
    Clear-Host
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host " Members of group: '$($Group.Name)'" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Cyan
    
    try {
        $members = Get-ADGroupMember -Identity $Group.DistinguishedName | Sort-Object Name
        if ($members) {
            foreach ($m in $members) {
                Write-Host " - $($m.SamAccountName) ($($m.Name))" -ForegroundColor White
            }
        } else {
            Write-Host " This group has no members." -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Error "Could not retrieve members: $_"
    }
    Write-Host ""
    Read-Host "Press Enter to return to the menu..."
}

# ==============================================================================
# MAIN PROGRAM LOOP
# ==============================================================================
$ProgramRunning = $true
$CurrentGroupObject = $null

while ($ProgramRunning) {
    # If no group is currently picked, display the Initial Program Start Menu
    if ($null -eq $CurrentGroupObject) {
        $StartOptions = @("Choose Active Directory Group", "Exit")
        $startChoice = Show-ArrowMenu -MenuOptions $StartOptions -CurrentGroup "None" -Title $TitleChooseGroupMenu

        if ($startChoice -eq 1) {
            $ProgramRunning = $false
            Clear-Host
            Write-Host "Exiting program. Goodbye!" -ForegroundColor Green
            Break
        }

        if ($startChoice -eq 0) {
            $CurrentGroupObject = Get-ADGroupSelection -OUPath $TargetPath
            Continue
        }
    }

    # If a group is selected, enter the Main Menu Loop
    $CurrentGroupName = $CurrentGroupObject.Name
    $MainMenuOptions = @("Add Member (or Members)", "Remove Member (or Members)", "Show Group Members", "Change Group", "Exit")
    
    $mainChoice = Show-ArrowMenu -MenuOptions $MainMenuOptions -CurrentGroup $CurrentGroupName -Title $TitleMainMenu

    switch ($mainChoice) {
        # ----------------------------------------------------------------------
        # OPTION 1: ADD MEMBER
        # ----------------------------------------------------------------------
        0 {
            $AddLoop = $true
            while ($AddLoop) {
                Clear-Host
                Write-Host "=== ADD MEMBER TO GROUP: '$CurrentGroupName' ===" -ForegroundColor Yellow
                $inputString = Read-Host "Enter username (or comma-separated list, or type 'cancel'/'c' to quit)"
                
                # Global Rule 1: Case-insensitive comparisons
                $cleanInput = $inputString.Trim()
                if ($cleanInput -ieq "cancel" -or $cleanInput -ieq "c") {
                    Write-Host "Operation canceled by user. Returning to Main Menu..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                    $AddLoop = $false
                    Continue ###### CO TO ROBI???
                }

                if ([string]::IsNullOrEmpty($cleanInput)) { ###### CO TO W CONDITION???
                    Write-Warning "Input cannot be empty. Please try again."
                    Start-Sleep -Seconds 1.5
                    Continue # Loop back to prompt
                }

                # Split comma-separated values and trim whitespaces (Bulk Support)
                $userList = $cleanInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

                foreach ($username in $userList) {
                    Write-Host "`nProcessing user: '$username'..." -ForegroundColor Cyan
                    
                    # Validate if account exists in AD
                    $adUser = $null
                    try {
                        $adUser = Get-ADUser -Identity $username
                    }
                    catch {
                        # 2 FOLLOW-SCENARIO: Non-existent AD account
                        Write-Host "[-] FAILURE: User '$username' does not exist in the Active Directory database." -ForegroundColor Red
                        Continue # CRITICAL BULK RULE: skip to next user on the list
                    }

                    if ($adUser) {
                        # Check whether account is already a member of the target group
                        $isMember = Get-ADGroup -Identity $CurrentGroupObject.DistinguishedName -Properties Member | 
                                    Select-Object -ExpandProperty Member | 
                                    Where-Object { $_ -eq $adUser.DistinguishedName }

                        if ($isMember) {
                            Write-Host "[!] INFO: Account '$username' is already a member of '$CurrentGroupName'." -ForegroundColor Yellow
                            Continue # Skip to next user
                        } else {
                            # Ask to confirm operation
                            Write-Host "[+] Account '$username' found and is eligible for addition." -ForegroundColor Green
                            $confirm = Read-Host "Are you sure you want to add '$username' to '$CurrentGroupName'? [Y/N]"
                            
                            if ($confirm -ieq "yes" -or $confirm -ieq "y") {
                                # Wrapped modification in strict try/catch block for system errors
                                try {
                                    Add-ADGroupMember -Identity $CurrentGroupObject.DistinguishedName -Members $adUser.DistinguishedName -ErrorAction Stop
                                    Write-Host "[+] SUCCESS: User '$username' has been added to '$CurrentGroupName'." -ForegroundColor Green
                                }
                                catch {
                                    Write-Host "[-] SYSTEM ERROR: Failed to add '$username'. Reason: $_" -ForegroundColor Red
                                } ###### CZYM JEST ZNAK '$_'??? CZY W TYM PRZYPADKU TO KOMUNIKAT BŁĘDU Z KOMENDY
                                ###### 'ADD-ADGROUPMEMBER'???
                            } else {
                                Write-Host "[!] Operation negated for user '$username'." -ForegroundColor Yellow
                            }
                        }
                    }
                }

                # After processing all inputs on the list, terminate operation and go back
                Write-Host "`nBulk processing completed." -ForegroundColor Cyan
                Read-Host "Press Enter to return to the Main Menu..."
                $AddLoop = $false
            }
        }

        # ----------------------------------------------------------------------
        # OPTION 2: REMOVE MEMBER
        # ----------------------------------------------------------------------
        1 {
            $RemoveLoop = $true
            while ($RemoveLoop) {
                $RemoveMenuOptions = @("Remove member", "Show group members", "Back to Main Menu")
                $removeChoice = Show-ArrowMenu -MenuOptions $RemoveMenuOptions -CurrentGroup $CurrentGroupName -Title $TitleRemoveMenu

                switch ($removeChoice) {
                    # REMOVE MENU - OPTION 1: REMOVE MEMBER
                    0 {
                        Clear-Host
                        Write-Host "=== REMOVE MEMBER FROM GROUP: '$CurrentGroupName' ===" -ForegroundColor Yellow
                        $inputString = Read-Host "Enter username (or comma-separated list, or type 'cancel'/'c' to quit)"
                        
                        $cleanInput = $inputString.Trim()
                        if ($cleanInput -ieq "cancel" -or $cleanInput -ieq "c") {
                            Write-Host "Operation canceled by user. Returning to Remove Menu..." -ForegroundColor Yellow
                            Start-Sleep -Seconds 1
                            Continue
                        }

                        if ([string]::IsNullOrEmpty($cleanInput)) {
                            Write-Warning "Input cannot be empty. Please try again."
                            Start-Sleep -Seconds 1.5
                            Continue
                        }

                        # Split comma-separated values and trim whitespaces (Bulk Support)
                        $userList = $cleanInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

                        foreach ($username in $userList) {
                            Write-Host "`nProcessing removal for user: '$username'..." -ForegroundColor Cyan

                            # Validate if account exists in AD
                            $adUser = $null
                            try {
                                $adUser = Get-ADUser -Identity $username
                            }
                            catch {
                                Write-Host "[-] FAILURE: User '$username' does not exist in the Active Directory database." -ForegroundColor Red
                                Continue # CRITICAL BULK RULE: skip to next user on the list
                            }

                            if ($adUser) {
                                # Check whether account is already a member of the target group
                                $isMember = Get-ADGroup -Identity $CurrentGroupObject.DistinguishedName -Properties Member | 
                                            Select-Object -ExpandProperty Member | 
                                            Where-Object { $_ -eq $adUser.DistinguishedName }

                                if (-not $isMember) {
                                    Write-Host "[-] FAILURE: Account '$username' is NOT a member of '$CurrentGroupName'." -ForegroundColor Red
                                    Continue # Skip to next user
                                } else {
                                    # Ask to confirm operation
                                    Write-Host "[!] Account '$username' is a current member of the group." -ForegroundColor Yellow
                                    $confirm = Read-Host "Are you sure you want to remove '$username' from '$CurrentGroupName'? [Y/N]"
                                    
                                    if ($confirm -ieq "yes" -or $confirm -ieq "y") {
                                        # Wrapped modification in strict try/catch block
                                        try {
                                            Remove-ADGroupMember -Identity $CurrentGroupObject.DistinguishedName -Members $adUser.DistinguishedName -Confirm:$false -ErrorAction Stop
                                            Write-Host "[+] SUCCESS: User '$username' has been removed from '$CurrentGroupName'." -ForegroundColor Green
                                        }
                                        catch {
                                            Write-Host "[-] SYSTEM ERROR: Failed to remove '$username'. Reason: $_" -ForegroundColor Red
                                        }
                                    } else {
                                        Write-Host "[!] Operation negated for user '$username'." -ForegroundColor Yellow
                                    }
                                }
                            }
                        }
                        Write-Host "`nBulk processing completed." -ForegroundColor Cyan
                        Read-Host "Press Enter to return to the Remove Menu..."
                    }

                    # REMOVE MENU - OPTION 2: SHOW GROUP MEMBERS
                    1 {
                        Show-Members -Group $CurrentGroupObject
                    }

                    # REMOVE MENU - OPTION 3: BACK TO MAIN MENU
                    2 {
                        $RemoveLoop = $false
                    }
                }
            }
        }

        # ----------------------------------------------------------------------
        # OPTION 3: SHOW GROUP MEMBERS
        # ----------------------------------------------------------------------
        2 {
            Show-Members -Group $CurrentGroupObject
        }

        # ----------------------------------------------------------------------
        # OPTION 4: CHANGE GROUP
        # ----------------------------------------------------------------------
        3 {
            # Reuse the group choice mechanism by simply resetting the group object
            $CurrentGroupObject = Get-ADGroupSelection -OUPath $TargetPath
        }

        # ----------------------------------------------------------------------
        # OPTION 5: EXIT PROGRAM
        # ----------------------------------------------------------------------
        4 {
            $ProgramRunning = $false
            Clear-Host
            Write-Host "Exiting program. Goodbye!" -ForegroundColor Green
        }
    }
}