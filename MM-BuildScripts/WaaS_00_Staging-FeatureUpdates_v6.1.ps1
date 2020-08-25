# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# File:  WaaS_00_Staging-FeatureUpdates_v#.#.ps1
# Version: 6.0
# Date:    13 Jul 2020
# Author:  Mike Marable
#
# Complete rewrite of the code to take into consideration lessons learned from WaaS 1809
# and to make the switch from IPU sequences to Feature Updates
#

# Version: 6.1
# Date:    24 Jul 2020
# Author:  Mike Marable
#
# Switched to using v 1.1 of CoreVariables

# Version:
# Date:
# Author:


# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

<#
.SYNOPSIS
    Stages out the needed collections, folders, queries and deployments for the WaaS process up to the upgrades
.DESCRIPTION
    Will create the folders, collects, etc. needed for a new branch of WaaS
.PARAMETER WaaSBranch
    An abbreviation indicating what branch (Dev/QA/Pilot/Prod) to build out
    Possible values are: DEV | QA | Pilot | Prod
.PARAMETER BuildNum
    The "friendly" build number for the intended Windows 10 build to be deployed
    Possible values are: 1809 | 1909 | 2004 | 20H2
.PARAMETER StartDate
    The date that the Feature Udpate deployments should begin
.PARAMETER EndDate
    The date that the Feature Udpate deployments should finish
.NOTES

.EXAMPLE
    Create the Pilot branch for the 1909 WaaS project and create deplyments starting 1-Sep and ending 1-Nov
    WaaS_00_Staging-FeatureUpdates_v6.0.ps1 -WaaSBranch Pilot -BuildNum 1909 -StartDate 9/1/2020 -EndDate 11/1/2020

#>

Param(
    [parameter(mandatory=$false)] 
    [ValidateSet("DEV","QA","PILOT","PROD")] 
    [String] $WaaSBranch = "DEV",

    [ValidateSet("1909","2004","20H2")] 
    [String] $BuildNum = "1909",

    [String] $StartDate,

    [String] $EndDate

    )

# Import the CoreFunctions script/functions used common in all the scripts
# If the version of the CoreFunctions script changes this path will need to be updated to match
. (Join-Path -Path $PSScriptRoot -ChildPath ".\WaaS_00_CoreFunctions_v1.0.ps1")

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Functions

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# *** Entry Point to Script ***

########################
# Start of Code Block ##
########################
$MyVersion = "6.0"
$MyModule = "WaaS_Staging_FeatureUpdates"
$DailyDigits = 0..999

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Set-location C:\
#Clear-Host

Write-Host "-----------------------------------------------" -ForegroundColor Cyan
Write-Host "Starting: $MyModule ver. $MyVersion"             -ForegroundColor Cyan
Write-Host "-----------------------------------------------" -ForegroundColor Cyan

#Get the location the script is running from
Write-Host "Getting Script Dir..."
$scriptFolder = Get-ScriptDirectory
Write-Host "  Script Dir set to: $ScriptFolder"
Write-Host ""

# Set the location of our configuration folder
Write-Host "Getting Config Dir..."
$ConfigFolder = "$scriptFolder\Config"
Write-Host "  Config Dir set to: $ConfigFolder"
Write-Host ""

# Set the configuration filename and path
$XMLFile = "$ConfigFolder\$BuildNum.xml"
#$XMLBldNumFile = "$ConfigFolder\BuildNumbers.xml"
Write-Host "  Configuraiton File: $XMLFile"
#Write-Host "  Build Index File:   $XMLBldNumFile"
#Write-Host ""

# Pull Site Info from XML config file
Write-Host "Reading from "$ConfigFolder\Config.xml""
[xml]$Config = Get-Content "$ConfigFolder\Config.xml" -ErrorAction Stop -WarningAction Stop
# Site configuration
$SiteCode            = $Config.Settings.SiteInfo.SiteCode # Site code 
$ProviderMachineName = $Config.Settings.SiteInfo.ServerName # SMS Provider machine name

# Import the ConfigurationManager.psd1 module 
IF ((Get-Module ConfigurationManager) -eq $null) 
    {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" #@initParams
    }

# Connect to the site's drive if it is not already present
IF ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) 
    {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName #@initParams
    }

#If we're running from MM1 temporarly set it to C: to allow external path lookups to function properly
$ResetLocation = $null
If (((Get-Location) -split ":")[0] -eq "$SiteCode")
    {
    $ResetLocation = Get-Location
    Set-Location c:\
    }

#Read Settings from XML
Write-Host "Reading from $XMLFile"
[xml]$Settings = Get-Content $XMLFile -ErrorAction Stop -WarningAction Stop

$FeatureUpdatePkgID = $Settings.Settings.TSIDs.$WaaSBranch.FeatureUpdate

Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "Task Sequence IDs"                               -ForegroundColor Green
Write-Host "    Feature Update ID: $FeatureUpdatePkgID"      -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host ""


# -------------------------------------
    Write-Host "-------------------------------------"
    Write-Host "Staging WaaS for Build $BuildNum ($WaaSBranch)"


# Import the CoreVariables script for common folder and colleciton names in all the scripts
. (Join-Path -Path $PSScriptRoot -ChildPath ".\WaaS_00_CoreVariables_v1.1.ps1")

# Force the entered dates from Strings to Date/Time
$StartDate = Get-Date $StartDate -Format "dd-MMM-yyyy"
$EndDate   = Get-Date $EndDate  -Format "dd-MMM-yyyy"
$TotalDays = ( New-TimeSpan -Start $StartDate -End $EndDate ).Days
# The calculation of the number of days between the two dates does not include the starting date, so we'll add that back in.
$TotalDays++

# Pull the list of Holidays and freeze dates
$HolidayData = ( Import-Csv -Path "$ConfigFolder\Holidays.csv" )

# Calculate the number of good deployment days (non weekends and non holidays)
# We'll need this number for the ResID query offset
Write-Host "Calculating the total number of valid deployment dates..."
$d                              = $TotalDays
[DateTime]$PossibleDeadlineDate = $EndDate
$GoodDeployDateCount            = 0

WHILE ($d -gt 0)
    {
    $GoodDeployDate = $TRUE
    #Write-Host "($d of $TotalDays) $PossibleDeadlineDate"

    FOREACH ($holiday in $HolidayData)
        {
        IF ( (Get-Date -Date $holiday.Date) -eq (Get-Date -Date $PossibleDeadlineDate) )
            {
            #Write-Host "Skipping $($holiday.Date) [$($holiday.Desc)]" -ForegroundColor Red
            $GoodDeployDate = $FALSE
            BREAK
            }
        ELSE
            {
            }
            #end IF check for holiday
        }
        #end FOREACH cycle through holiday list

    # Check for weekends
    $DayofWeek = (Get-Date $PossibleDeadlineDate).DayOfWeek
    IF (($DayofWeek -eq "Saturday") -or ($DayofWeek -eq "Sunday"))
        {
        #Write-Host "Skipping weekend date $PossibleDeadlineDate [$($DayofWeek)]" -ForegroundColor Yellow
        $GoodDeployDate = $FALSE
        }
    ELSE
        {
        }
        #end Check for weekends

    IF ($GoodDeployDate -eq $TRUE)
        {
        $GoodDeployDateCount++
        }
    
    
    # Set up for the next prior day
    $PossibleDeadlineDate = ( $PossibleDeadlineDate.AddDays(-1) )
    $d--
    #Write-Host " "
    }

Write-Host "-----------------------------------------------" -ForegroundColor Magenta
Write-Host "Starting Date: $StartDate"                       -ForegroundColor Magenta
Write-Host "Ending Date:   $EndDate"                         -ForegroundColor Magenta
Write-Host "Calendar Days: $TotalDays"                       -ForegroundColor Magenta
Write-Host "-----------------------------------------------" -ForegroundColor Magenta
Write-Host "Total Deployment Days: $GoodDeployDateCount"     -ForegroundColor Magenta
Write-Host "-----------------------------------------------" -ForegroundColor Magenta
Write-Host ""

Set-Location "$($SiteCode):\" #@initParams

# < < < < < < < < < < Deployment Folders > > > > > > > > >
# Year and Month Folders
Write-Host "    Build out the Feature Update deployment folders $WaaSBranch . . ." -ForegroundColor Cyan -BackgroundColor Black
Write-Host "    ------------------------------------------------------------------" -ForegroundColor Cyan -BackgroundColor Black

# Create the root folder for the deployment collections
New-CMFolder -Folder "$RootDeploymentFolderPath"

# Create the folders for each year and month of the IPU Deployment
$CollectionFolderPath   = $NULL

    FOR ($m=0; $m -le 24; $m++)
        {
            $DeployMonth = ( (Get-Date -Date $StartDate).AddMonths($m) )
            IF ( $DeployMonth -lt $EndDate )
                {
                    $DeploymentYear       = $NULL
                    $DeploymentMonth      = $NULL
                    $DeploymentMonthNum   = $NULL
                    $CollectionFolderPath = $NULL
                    Write-Host "Deployment Month: $m" -ForegroundColor Cyan -BackgroundColor Black
                    Write-Host "$DeployMonth" -ForegroundColor Cyan -BackgroundColor Black
                    $DeploymentYear      = ( Get-Date -Date $DeployMonth -Format "yyyy" )
                    $DeploymentMonth     = ( Get-Date -Date $DeployMonth -Format "MMM" )
                    $DeploymentMonthNum  = ( Get-Date -Date $DeployMonth -Format "MM")
                    Write-Host "Target Folder: $DeploymentYear\$DeploymentMonthNum`-$DeploymentMonth" -ForegroundColor Cyan -BackgroundColor Black

                    # Create the Year if needed
                    $CollectionFolderPath   = "$RootDeploymentFolderPath\$DeploymentYear"
                    New-CMFolder -Folder "$CollectionFolderPath"

                    # Create the Month if needed
                    $CollectionFolderPath   = "$RootDeploymentFolderPath\$DeploymentYear\$DeploymentMonthNum`-$DeploymentMonth"
                    New-CMFolder -Folder "$CollectionFolderPath"

                    Write-Host "" -ForegroundColor Cyan -BackgroundColor Black
                }
            ELSE
                {
                }
            #Write-Host ""
        }

# < < < < < < < < < < < < < < > > > > > > > > > > > > > > 















# < < < < < < < < < < Deployment Collections > > > > > > > > >
# < < < < < < < < < < < < < Deployments > > > > > > > > > > > 

#################################################################################################################################################################
# Processing Potential Deployment Dates
$DailyIDStart           = 0
$TotalDeployments       = 0
$d                      = $TotalDays
[DateTime]$DeadlineDate = $EndDate

# Start at the end and work backwards
WHILE ($d -gt 0)
    {

    # Set our deployment date flag to TRUE
    $GoodDeployDate = $TRUE

    Write-Host "($d of $TotalDays) $DeadlineDate"

    # Check for holidays or freeze dates
    FOREACH ($holiday in $HolidayData)
        {
        IF ( (Get-Date -Date $holiday.Date) -eq (Get-Date -Date $DeadlineDate) )
            {
            Write-Host "Skipping $($holiday.Date) [$($holiday.Desc)]" -ForegroundColor Red
            $GoodDeployDate = $FALSE
            BREAK
            }
        ELSE
            {
            #$GoodDeployDate = $TRUE
            }
            #end IF check for holiday
            
        }
        #end FOREACH cycle through holiday list

    # Check for weekends
    $DayofWeek = (Get-Date $DeadlineDate).DayOfWeek
    IF (($DayofWeek -eq "Saturday") -or ($DayofWeek -eq "Sunday"))
        {
        Write-Host "Skipping weekend date $DeadlineDate [$($DayofWeek)]" -ForegroundColor Yellow
        $GoodDeployDate = $FALSE
        }
    ELSE
        {
        }
        #end Check for weekends

    # If we have a good deployment date, create the ConfigMgr pieces
    IF ($GoodDeployDate -eq $TRUE)
        {
        # Break down the date into individual components so we can work with them
        $DeploymentDate = $NULL
        $DeploymentDay = $NULL
        $DeploymentMonth = $NULL
        $DeploymentMonthNum = $NULL
        $DeploymentYear  = $NULL
        $DeploymentDay = Get-Date ($DeadlineDate) -Format dd
        $DeploymentMonth = Get-Date ($DeadlineDate) -Format MMM
        $DeploymentMonthNum = Get-Date ($DeadlineDate) -Format MM
        $DeploymentYear = Get-Date ($DeadlineDate) -Format yyyy
        $DeploymentDate = Get-Date ("$DeploymentMonth $DeploymentDay, $DeploymentYear")
        #$DeadlineDate = $NULL
        $DeadlineDate = Get-Date "$DeploymentDate" -Format "MM/dd/yyyy"

        # Set the target folder for the daily collections to be placed
        $CollectionFolderPath = "$RootDeploymentFolderPath\$DeploymentYear\$DeploymentMonthNum`-$DeploymentMonth"

        # 3:00 am Collection
        $TotalDeployments++
        $IPUDailyCollectionName = "$Phase3`_$(Get-Date $DeadlineDate -Format "MMM")-$(Get-Date $DeadlineDate -Format "dd")-$(Get-Date $DeadlineDate -Format "ddd")_3AM"
        $Schedule = New-CMSchedule -RecurInterval Days -RecurCount 1 -Start "1:15 AM"
        Write-Host "      $IPUDailyCollectionName" -ForegroundColor Magenta
        New-Collection -CollectionName "$IPUDailyCollectionName" -LimitingCollectionName "$ReadyForDeploymentCollectionName" -FolderPath "$CollectionFolderPath" -RefreshType "Scheduled"

        # Create the collecton variable for the deadline
        $CollVariableExists = $null
        $WaaSMandatoryDate = ($DeadlineDate).AddHours(3)
        #Create a WMI date object since the format lends itself to less special characters
        $wmidate = new-object -com Wbemscripting.swbemdatetime
        $date = get-date($WaaSMandatoryDate)
        $wmidate.SetVarDate($date,$true)
        #Create the Collection variable name
        $CollVarName = "MandatoryRunTime-$(($wmidate.value).split(".")[0])"
        Write-Host "        This is the Collection variable name: $CollVarName"
        $CollVariableExists = Get-CMDeviceCollectionVariable -CollectionName $IPUDailyCollectionName -VariableName "$CollVarName"

        IF ($CollVariableExists) 
            {
            Write-Host "    The Collection Variable already exist" -ForegroundColor Yellow
            Try {
                Set-CMDeviceCollectionVariable -CollectionName $IPUDailyCollectionName -VariableName "$CollVarName" -IsMask $FALSE -NewVariableValue "$WaaSMandatoryDate"
                Write-Host "    The Collection Variable was updated" -ForegroundColor DarkGreen
                }
            Catch
                {
                Write-Host "    Exception caught in updating Collection Variable : $error[0]" -ForegroundColor Red
                }                    
            }
        ELSE 
            {
            Write-Host "    The Collection Variable does not already exist"
            Write-Host "    Creating Collection Variable..."
            Try {
                New-CMDeviceCollectionVariable -CollectionName $IPUDailyCollectionName -VariableName "$CollVarName" -IsMask $FALSE -Value "$WaaSMandatoryDate"
                Write-Host "    The Collection Variable was created" -ForegroundColor Green
                }
            Catch
                {
                Write-Host "    Exception caught in creating Collection Variable : $error[0]" -ForegroundColor Red
                }
            }

        # Create the queries to pull in machines
        FOR ($i = $DailyIDStart; $i -lt $DailyDigits.Length; $i+=$GoodDeployDateCount)
            {
            $ResIDNum = $NULL
            $ResIDNum = "{0:000}" -f $DailyDigits[$i]
            $RuleName = "$WaaSBranch $BuildNum ResourceID Last 3 Digits = $ResIDNum"
            #$QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceId = SMS_R_System.ResourceId where SMS_G_System_COMPUTER_SYSTEM.ResourceID like ""%$($ResIDNum)_"""
            $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceId = SMS_R_System.ResourceId where SMS_G_System_COMPUTER_SYSTEM.ResourceID like ""%$($ResIDNum)"""
            Write-Host "    $RuleName"
            New-QueryRule -CollectionName $IPUDailyCollectionName
            }
        $DailyIDStart++


        # + + + + + + + + + + + + + + + + + + + +
        # Feature Update Mandatory
        # This is deployed as the mandatory
        #$FeatureUpdateDeploymentStart = $MULL
        #$TodayDate = (Get-Date -Format MM-dd-yyy)
        #$FeatureUpdateDeploymentStart = Get-Date -Date "$WaaSMandatoryDate"
        #$FeatureUpdateDeploymentSchedule = New-CMSchedule -Start $FeatureUpdateDeploymentStart -Nonrecurring
        #$FeatureUpdateDeploymentSchedule = New-CMSchedule -Start $FeatureUpdateDeploymentStart -DurationInterval Hours -DurationCount 8  -RecurCount 1 -RecurInterval Days
        $FeatureUpdateDeploymentExists = $null
        #$FeatureUpdateDeploymentExists = Get-CMPackageDeployment -CollectionName $IPUDailyCollectionName -PackageId $ToastPkgID -ProgramName "FeatureUpdate Notifier"
        $FeatureUpdateDeploymentExists = Get-CMSoftwareUpdateDeployment -CollectionName $IPUDailyCollectionName

        Write-Host $WaaSMandatoryDate
        write-Host $FeatureUpdateDeploymentStart

        IF ($FeatureUpdateDeploymentExists)
            {
                Write-Host "    The FeatureUpdate Deployment already exist" -ForegroundColor Yellow
                Write-Host "    Removing so we can update the deployment" -ForegroundColor Yellow
                Try {
                    Remove-CMSoftwareUpdateDeployment -CollectionName $IPUDailyCollectionName -InputObject $FeatureUpdateDeploymentExists -Force
                    New-CMSoftwareUpdateDeployment -SoftwareUpdateName "Feature update to Windows 10 (business editions), version 1909, en-us x64" -CollectionName "$IPUDailyCollectionName" -DeploymentName "WaaS - Feature Update Staging (1909)" -Description "Mandatory deployment of the Feature Update" -DeploymentType Required -DeadlineDateTime $WaaSMandatoryDate -SavedPackageId $FeatureUpdatePkgID -UserNotification DisplayAll -DownloadFromMicrosoftUpdate $TRUE -VerbosityLevel AllMessages -UnprotectedType UnprotectedDistributionPoint -ProtectedType RemoteDistributionPoint -RequirePostRebootFullScan $TRUE -SendWakeupPacket $TRUE  -AllowRestart $False -RestartServer $False -RestartWorkstation $False
                    Write-Host "    The FeatureUpdate Deployment was created" -ForegroundColor Green
                    }
                Catch
                    {
                        Write-Host "    Exception caught in creating FeatureUpdate Deployment : $error[0]" -ForegroundColor Red
                    }
            }
        ELSE 
            {
                Write-Host "    The FeatureUpdate Deployment does not already exist"
                Write-Host "    Creating Mandatory Deployment..."
                Try {
                    New-CMSoftwareUpdateDeployment -SoftwareUpdateName "Feature update to Windows 10 (business editions), version 1909, en-us x64" -CollectionName "$IPUDailyCollectionName" -DeploymentName "WaaS - Feature Update Staging (1909)" -Description "Mandatory deployment of the Feature Update" -DeploymentType Required -DeadlineDateTime $WaaSMandatoryDate -SavedPackageId $FeatureUpdatePkgID -UserNotification DisplayAll -DownloadFromMicrosoftUpdate $TRUE -VerbosityLevel AllMessages -UnprotectedType UnprotectedDistributionPoint -ProtectedType RemoteDistributionPoint -RequirePostRebootFullScan $TRUE -SendWakeupPacket $TRUE  -AllowRestart $False -RestartServer $False -RestartWorkstation $False
                    Write-Host "    The FeatureUpdate Deployment was created" -ForegroundColor Green
                    }
                Catch
                    {
                        Write-Host "    Exception caught in creating FeatureUpdate Deployment : $error[0]" -ForegroundColor Red
                    }
            }
        }

    # Set up for the next prior day
    $DeadlineDate = ( $DeadlineDate.AddDays(-1) )
    $d--
    Write-Host " "
    }
    #end cycling through "bucket" of possible deployment dates

# < < < < < < < < < < < < < < > > > > > > > > > > > > > > 


















Set-location C:\

Write-Host " "
Write-Host "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
Write-Host "Starting Date: $StartDate"
Write-Host "Ending Date:   $EndDate"
Write-Host "Calendar Days: $TotalDays"
Write-Host "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
Write-Host "Total Deployment Days: $TotalDeployments"
Write-Host "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
Write-Host ""



# -------------------------------------

Set-location C:\

Write-Host "-----------------------------------------------" -ForegroundColor Cyan
Write-Host "Finished: $MyModule ver. $MyVersion"             -ForegroundColor Cyan
Write-Host "-----------------------------------------------" -ForegroundColor Cyan
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
