# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# File:  WaaS_00_CoreFunctions_v#.#.ps1
# Version: 1.0
# Date:    7 Jul 2020
# Author:  Mike Marable
#
# Central repository of all the common functions used by all of the WaaS build-out scripts
#

# Version:
# Date:
# Author:


# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

<#
.SYNOPSIS

.DESCRIPTION

.PARAMETER

.NOTES

.EXAMPLE

#>

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Functions

#----------------------------
FUNCTION Get-ScriptDirectory
#----------------------------
    { 
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
    } 
    #end function Get-ScriptDirectory

#----------------------------
FUNCTION New-CMFolder
#----------------------------
    {
    Param(
        [parameter(
            mandatory=$True,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=1
            )
        ]
        [String] $Folder
    )

        IF (!(Test-Path "$Folder")) 
            {
            Write-Host "    $Folder folder does not exist, creating..."
            New-Item -Path "$Folder" -ItemType Directory
            }
        ELSE
            {
            Write-Host "    $Folder folder already exists." -ForegroundColor Green
            }
    }
    #end function New-CMFolder

#----------------------------
FUNCTION New-Collection
#----------------------------
    {
    Param(
        [parameter(mandatory=$True)]
        [String] $CollectionName,
        [String] $LimitingCollectionName,
        [String] $FolderPath,
        [ValidateSet("Manual","Scheduled")] 
        [String] $RefreshType = "Scheduled"
        )
    
    $CollectionExist = $NULL
    $CollectionExist = Get-CMDeviceCollection -Name $CollectionName
    IF ($CollectionExist) 
        {
        Write-Host "    The collection $CollectionName already exist" -ForegroundColor Yellow
        }
    ELSE 
        {
        Write-Host "    The collection $CollectionName does not already exist"
        Write-Host "    Creating collection..."
        Try {
            IF ($RefreshType -eq "Manual")
                {
                    # Manual Refresh
                    $CollectionItem = New-CMDeviceCollection -LimitingCollectionName $LimitingCollectionName -name $CollectionName -RefreshType manual
                }
            IF ($RefreshType -eq "Scheduled")
                {
                    # Scheduled Refresh
                    $CollectionItem = New-CMDeviceCollection -LimitingCollectionName $LimitingCollectionName -name $CollectionName  -RefreshSchedule $Schedule -RefreshType 2
                }
	        
            Move-CMObject -folderpath $FolderPath -inputobject $CollectionItem
	        Write-Host "    Collection $CollectionName created" -ForegroundColor Green
            } 
        Catch 
            {
	        Write-Host "    Exception caught in creating collection : $error[0]" -ForegroundColor Red
            }
        }
    }
    #end function New-Collection

#----------------------------
FUNCTION New-QueryRule
#----------------------------	
    {
    Param(
        [parameter(mandatory=$True)]
        [String] $CollectionName  
        )  

    $QueryExists = Get-CMDeviceCollectionQueryMembershipRule -CollectionName $CollectionName -RuleName $RuleName
    IF ($QueryExists)
        {
        Write-Host "    Query already exists"
        }
    ELSE
        {
        Write-Host "    Query does not already exist.  Creating..." 
        Try
            {
            Add-CMDeviceCollectionQueryMembershipRule -CollectionName $CollectionName -RuleName $RuleName -QueryExpression $QueryExpression
            Write-Host "    Query $RuleName created" -ForegroundColor Green
            }
        CATCH
            {
            Write-Host "    Exception caught in creating query : $error[0]" -ForegroundColor Red
            }
        }
    }
    #end function New-QueryRule

#----------------------------
FUNCTION Get-NthWeekday ( [int] $yr, [int] $mo, [int] $nth, [string] $WeekDayToFind )
#----------------------------
    {
    # Error checking
    if ($yr -lt 1990 -or $yr -gt 2038)
        {
            Write-Host "Year must be 1990 to 2038";throw "*** YEAR NOT BETWEEN 1990 and 2038! ***"
        }
    if ($mo -lt 1 -or $mo -gt 12)
        {
            Write-Host "Bad month! Try again."; throw "*** BAD MONTH! ***"
        }
    if ($nth -lt 1 -or $nth -gt 5)
        {
            Write-Host "Nth must be between 1 and 5"; throw "*** BAD Nth! ***" 
        }
    if ( 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday' -notcontains $WeekDayToFind  )
        {
            Write-Host "Not a weekday!"; throw "*** NOT A WEEKDAY! ***"
        }

    # start from the first day of the month
    $TargetMonthFirstDate = New-Object System.DateTime $yr, $mo, 1

    # $TargetMonthFirstWeekday
    $WorkingDate = $TargetMonthFirstDate

    # loop until we get to the $nth instance of $WeekDayToFind
    while ($nth)
        {
        if ($WorkingDate.DayOfWeek -eq $WeekDayToFind)
            {
                $nth = $nth-1
            }
        # this second IF is needed if the 1st falls on the $WeekDayToFind
        # to get the correct result.
        if ($nth -gt 0) 
            {
                $WorkingDate = $WorkingDate.AddDays(1)
            }
        }   

    $WorkingDate

    }
    #end function Get-NthWeekday

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# *** Entry Point to Script ***

########################
# Start of Code Block ##
########################
$MyVersion = "1.0"
$MyModule = "WaaS_CoreFunctions"

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Clear-Host

Write-Host "-----------------------------------------------" -ForegroundColor Cyan
Write-Host "Starting: $MyModule ver. $MyVersion"             -ForegroundColor Cyan
Write-Host "-----------------------------------------------" -ForegroundColor Cyan

Write-Host "-----------------------------------------------" -ForegroundColor Cyan
Write-Host "Finished: $MyModule ver. $MyVersion"             -ForegroundColor Cyan
Write-Host "-----------------------------------------------" -ForegroundColor Cyan
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
