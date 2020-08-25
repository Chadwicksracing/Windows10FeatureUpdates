# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# File:  WaaS_00_Staging-Core_v#.#.ps1
# Version: 6.0
# Date:    7 Jul 2020
# Author:  Mike Marable
#
# Complete rewrite of the code to take into consideration lessons learned from WaaS 1809
# and to make the switch from IPU sequences to Feature Updates
#

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
.PARAMETER Phase
    The WaaS phase to build out
    Possible values are: 0 | 1 | 2 | 3
        Phase 0 - Reference
        Phase 1 - Pre-Assessment
        Phase 2 - Pre-Staging
        Phase 3 - Feature Updates
.NOTES

.EXAMPLE
    Create the Pilot branch for the 1909 WaaS project and build out the Phase 0 (Reference) collections
    WaaS_00_Staging-Core_v6.0.ps1 -WaaSBranch Pilot -BuildNum 1909 -Phase 0

#>

Param(
    [parameter(mandatory=$false)] 
    [ValidateSet("DEV","QA","PILOT","PROD")] 
    [String] $WaaSBranch = "DEV",

    [ValidateSet("1909","2004","20H2")] 
    [String] $BuildNum = "1909",

    [ValidateSet("0","1","2","3")] 
    [String] $Phase

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
$MyVersion = "6.1"
$MyModule = "WaaS_Staging_Core"

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
$XMLBldNumFile = "$ConfigFolder\BuildNumbers.xml"
Write-Host "  Configuraiton File: $XMLFile"
Write-Host "  Build Index File:   $XMLBldNumFile"
Write-Host ""

# Pull Site Info from XML config file
Write-Host "Reading from "$ConfigFolder\Config.xml""
[xml]$Config = Get-Content "$ConfigFolder\Config.xml" -ErrorAction Stop -WarningAction Stop
# Site configuration
$SiteCode            = $Config.Settings.SiteInfo.SiteCode # Site code 
$ProviderMachineName = $Config.Settings.SiteInfo.ServerName # SMS Provider machine name

# CSV of supported hardware models for Windows 10
$CSVfile = "$ConfigFolder\Windows10Hardware.csv"
# Import the CSV of approved hardware
$ApprovedHardware = (Import-Csv -Path $CSVfile)

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
Write-Host "Reading from $XMLBldNumFile"
[xml]$Settings = Get-Content $XMLFile -ErrorAction Stop -WarningAction Stop
[xml]$BuildNumbers = Get-Content $XMLBldNumFile -ErrorAction Stop -WarningAction Stop

$PSID               = $Settings.Settings.TSIDs.$WaaSBranch.PreStage
$FeatureUpdatePkgID = $Settings.Settings.TSIDs.$WaaSBranch.FeatureUpdate

Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host "Task Sequence IDs"                               -ForegroundColor Green
Write-Host "    Pre-Stage ID:      $PSID"                    -ForegroundColor Green
Write-Host "    Feature Update ID: $FeatureUpdatePkgID"      -ForegroundColor Green
Write-Host "-----------------------------------------------" -ForegroundColor Green
Write-Host ""

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" #@initParams

# -------------------------------------
    Write-Host "-------------------------------------"
    Write-Host "Staging WaaS for Build $BuildNum ($WaaSBranch)"

# Import the CoreVariables script for common folder and colleciton names in all the scripts
. (Join-Path -Path $PSScriptRoot -ChildPath ".\WaaS_00_CoreVariables_v1.1.ps1")

    # < < < < < < < < < < Branch Folders > > > > > > > > >
    # Create all of the folders required for this build-out

    Write-Host "Creating root folders in the console..."

    # WaaS Folder
        New-CMFolder -Folder $RootFolder

    # Build Number Folder
        New-CMFolder -Folder "$RootFolder\$BuildNum"

    # WaaS Branch Folder
        New-CMFolder -Folder "$RootFolder\$BuildNum\$WaaSBranch"
    
    
    # -------------------------------------------------------------------------
    # Phase 0 - Reference Folders
    IF ($Phase -eq 0)
        {
            # Create the Phase 0 folders
            Write-Host "-------------------------------------------------------------------------"
            Write-Host "Creating the Phase 0 - Reference Folders"
            # Reference Collections Folder
            New-CMFolder -Folder "$ReferenceFolderPath"
            Write-Host "-------------------------------------------------------------------------"
        }

    # -------------------------------------------------------------------------

    # -------------------------------------------------------------------------
    # Phase 1 - Pre-Assessment Folders
    IF ($Phase -eq 1)
        {
            # Create the Phase 1 folders
            Write-Host "-------------------------------------------------------------------------"
            Write-Host "Creating the Phase 1 - Pre-Assessment Folders"
            # Pre-Assessment Collections Folder
            New-CMFolder -Folder "$PreAssessmentFolderPath"
            # Remediation Collections Folder
            New-CMFolder -Folder "$PreAssessmentRemediationFolderPath"
            # Pre-Assessment Reference Collections Folder
            New-CMFolder -Folder "$PreAssessmentReferenceFolderPath"
            Write-Host "-------------------------------------------------------------------------"
        }

    # -------------------------------------------------------------------------

    # -------------------------------------------------------------------------
    # Phase 2 - PreStage Folders
    IF ($Phase -eq 2)
        {
            # Create the Phase 2 folders
            Write-Host "-------------------------------------------------------------------------"
            Write-Host "Creating the Phase 2 - Pre-Staging Folders"
            # Pre-Staging Collections Folder
            New-CMFolder -Folder "$PreStagingFolderPath"
            # Pre-Staging Deployments Folder
            New-CMFolder -Folder "$PreStagingDeploymentsFolderPath"
            Write-Host "-------------------------------------------------------------------------"
        }

    # -------------------------------------------------------------------------


    # -------------------------------------------------------------------------
    # Phase 3 - Deployment Folders
    IF ($Phase -eq 3)
        {
            # Create the Phase 3 folders
            Write-Host "-------------------------------------------------------------------------"
            Write-Host "Creating the Phase 3 - Deployment Folders"
            # Deployment Collections Folder
            New-CMFolder -Folder "$DeploymentFolderPath"
            New-CMFolder -Folder "$ToastExceptionFolderPath"
        
            # AppCompat Folder Tree
            New-CMFolder -Folder "$ReferenceAppCompatFolderPath"
            New-CMFolder -Folder "$ReferenceAppCompatExclusionsFolderPath"
            New-CMFolder -Folder "$ReferenceAppCompatExclusionByPassFolderPath"
            New-CMFolder -Folder "$ReferenceAppCompatExclusionByPassGeneralFolderPath"
            New-CMFolder -Folder "$ReferenceAppCompatExclusionByPassScheduledFolderPath"
            New-CMFolder -Folder "$ReferenceAppCompatExclusionByPassStagingFolderPath"
            New-CMFolder -Folder "$ReferenceAdHocFolderPath"
            New-CMFolder -Folder "$ReferenceAdHocExclusionsFolderPath"


            Write-Host "-------------------------------------------------------------------------"

        }


    # -------------------------------------------------------------------------


    # < < < < < < < < < < < < > > > > > > > > > > > > > > >

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    # < < < < < < < < < < Collections > > > > > > > > > > >

    [int]$TargetBuild = $BuildNum


    # -------------------------------------------------------------------------
    # Phase 0 - Reference Collections
    IF ($Phase -eq 0)
        {
            # Create the Phase 0 Collections
            Write-Host "-------------------------------------------------------------------------"
            Write-Host "Creating the Phase 0 - Reference Collections"

                # Starting Point
                Write-Host "-------------------------------------"
                $Schedule = New-CMSchedule -RecurInterval Days -RecurCount 1 -Start "12:30 AM"
                New-Collection -CollectionName "$StartingPointCollectionName" -LimitingCollectionName "All Systems" -FolderPath "$ReferenceFolderPath" -RefreshType "Scheduled"
                Write-Host " "

                # Ineligible - Windows 7
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$InelligibleOSW7CollectionName" -LimitingCollectionName "$StartingPointCollectionName" -FolderPath "$ReferenceFolderPath" -RefreshType "Manual"
                    Write-Host "Adding Device Queries for Windows 7..."
                    $RuleName = "Windows 7"
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.operatingSystemVersion = ""6.1 (7601)"""
                    New-QueryRule -CollectionName "$InelligibleOSW7CollectionName"
                Write-Host " "

                # Ineligible - Windows 10 Current
                Write-Host "-------------------------------------"
                $Schedule = New-CMSchedule -RecurInterval Days -RecurCount 1 -Start "12:40 AM"
                New-Collection -CollectionName "$InelligibleOSW10CurrentCollectionName" -LimitingCollectionName "$StartingPointCollectionName" -FolderPath "$ReferenceFolderPath" -RefreshType "Manual"
                    Write-Host "Adding Device Queries for the current Windows 10 build..."
                    # Pull the array of all build numbers from the buildnumbers' XML file
                    $arrAllBuilds = $BuildNumbers.BuildNumbers.Build
                    FOREACH ($BuildVer in $arrAllBuilds)
                        {
                        IF ($TargetBuild -le $BuildVer.ID)
                            {
                            $bldver    = $BuildVer.ID
                            $BVer      = $BuildVer.Ver
                            Write-Host "    Build $bldver" -ForegroundColor Cyan
                            $RuleName = "Windows 10 v$bldver"
                            # This query relies on Hardware Inventory, which if missing would mean a machine won't show up in any OS colleciton
                            #$QueryExpression = "select *  from  SMS_R_System inner join SMS_G_System_OPERATING_SYSTEM on SMS_G_System_OPERATING_SYSTEM.ResourceId = SMS_R_System.ResourceId where SMS_G_System_OPERATING_SYSTEM.BuildNumber = '$BVer'"
                            # This query relies on Discovery data, so even if Hardware Inventory is missing it will still show up in the OS collections
                            $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.operatingSystemVersion = ""10.0 ($BVer)"""
                            New-QueryRule -CollectionName "$InelligibleOSW10CurrentCollectionName"
                            }
                        }
                Write-Host " "

                # All Supported Hardware
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$AllSuppHWCollectionName" -LimitingCollectionName "$StartingPointCollectionName" -FolderPath "$ReferenceFolderPath" -RefreshType "Manual"
                Write-host  "Number of approved hardware models: $($ApprovedHardware.count)"
                    FOREACH ($model in $ApprovedHardware)
                        {
                        $Baseboard = $NULL
                        $ModelName = $NULL
                        $Baseboard = $model.Baseboard
                        $ModelName = $model.Model
                        IF ($Baseboard.length -eq 0)
                            {
                            Write-Host "$ModelName does not have a baseboard number" -ForegroundColor Yellow
                            $RuleName = "[$BuildNum] $ModelName"
                            $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceId = SMS_R_System.ResourceId where SMS_G_System_COMPUTER_SYSTEM.Model = ""$ModelName"""
                            }
                        ELSE
                            {
                            Write-Host "$ModelName = $Baseboard" -ForegroundColor Green
                            $RuleName = "[$BuildNum] $ModelName"
                            $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_BASEBOARD on SMS_G_System_BASEBOARD.ResourceId = SMS_R_System.ResourceId where SMS_G_System_BASEBOARD.Product = ""$Baseboard"""
                            }
                        Write-Host "    Creating Model Query rule..." -ForegroundColor Cyan
                        New-QueryRule -CollectionName "$AllSuppHWCollectionName"
                        Write-Host ""
                        }
                Write-Host ""

                # Ineligible - Unsupported Hardware
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$InelligibleUnSupportedHWCollectionName" -LimitingCollectionName "$StartingPointCollectionName" -FolderPath "$ReferenceFolderPath" -RefreshType "Manual"
                    Write-Host "    Creating exclusion query rule..." -ForegroundColor Cyan
                    $RuleName = "[$BuildNum] Exclude Supported Hardware"
                    # Pull the Collection ID for the "All Supported Hardware" collection so we can reference it in our query
                    $AllSuppHWCollectionID = (Get-CMDeviceCollection -Name $AllSuppHWCollectionName).CollectionID
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.ResourceId not in (select ResourceID from SMS_CM_RES_COLL_$AllSuppHWCollectionID)"
                    New-QueryRule -CollectionName "$InelligibleUnSupportedHWCollectionName"
                Write-Host " "


                # Passed Scrutineering
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$PassedScrutineeringName" -LimitingCollectionName "$StartingPointCollectionName" -FolderPath "$ReferenceFolderPath" -RefreshType "Manual"
                    Write-Host "    Creating exclusion query rule..." -ForegroundColor Cyan
                    $RuleName = "[$BuildNum] Exclude Scrutineering Failures"
                    # Pull the needed Collection IDs for the query
                    $InelligibleOSW7CollectionID          = (Get-CMDeviceCollection -Name $InelligibleOSW7CollectionName).CollectionID
                    $InelligibleOSW10CurrentCollectionID  = (Get-CMDeviceCollection -Name $InelligibleOSW10CurrentCollectionName).CollectionID
                    $InelligibleUnSupportedHWCollectionID = (Get-CMDeviceCollection -Name $InelligibleUnSupportedHWCollectionName).CollectionID
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.ResourceId not in (select ResourceID from SMS_CM_RES_COLL_$InelligibleOSW7CollectionID) and SMS_R_System.ResourceId not in (select ResourceID from SMS_CM_RES_COLL_$InelligibleOSW10CurrentCollectionID) and SMS_R_System.ResourceId not in (select ResourceID from SMS_CM_RES_COLL_$InelligibleUnSupportedHWCollectionID)"
                    New-QueryRule -CollectionName "$PassedScrutineeringName"
                Write-Host " "

            Write-Host "-------------------------------------------------------------------------"
        }

    # -------------------------------------------------------------------------

    # -------------------------------------------------------------------------
    # Phase 1 - Pre-Assessment Collections
    IF ($Phase -eq 1)
        {
            # Create the Phase 1 Collections
            Write-Host "-------------------------------------------------------------------------"
            Write-Host "Creating the Phase 1 - Pre-Assessment Collections"
                
                # Ready for Pre-Assessment
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$ReadyForPreAssessmentCollectionName" -LimitingCollectionName "$PassedScrutineeringName" -FolderPath "$PreAssessmentFolderPath" -RefreshType "Manual"
                Write-Host " "

                # Failed Pre-Assessment
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$FailedPreAssessmentCollectionName" -LimitingCollectionName "$ReadyForPreAssessmentCollectionName" -FolderPath "$PreAssessmentFolderPath" -RefreshType "Manual"
                    # Generate the path within the console for the query statement
                    $tmpFolder = $NULL
                    $tmpFolder = $PreAssessmentRemediationFolderPath.Substring($($FolderMask.Length))
                    $consolepath = $NULL
                    $consolepath = ( $tmpFolder.Replace("\","/") )
                    $RuleName = "[$BuildNum] Object Path Query"
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.ResourceId in (select ResourceID from sms_fullcollectionmembership where collectionID in (select CollectionID from SMS_Collection where ObjectPath = '$($consolepath)'))"
                    New-QueryRule -CollectionName "$FailedPreAssessmentCollectionName"
                Write-Host " "

                # Passed Pre-Assessment
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$PassedPreAssessmentCollectionName" -LimitingCollectionName "$ReadyForPreAssessmentCollectionName" -FolderPath "$PreAssessmentFolderPath" -RefreshType "Manual"
                    Write-Host "    Creating exclusion query rule..." -ForegroundColor Cyan
                    $RuleName = "[$BuildNum] Exclude Pre-Assessment Failures"
                    # Pull the needed Collection IDs for the query
                    $FailedPreAssessmentCollectionID          = (Get-CMDeviceCollection -Name $FailedPreAssessmentCollectionName).CollectionID
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.ResourceId not in (select ResourceID from SMS_CM_RES_COLL_$FailedPreAssessmentCollectionID)"
                    New-QueryRule -CollectionName "$PassedPreAssessmentCollectionName"
                Write-Host " "

                # Reference Collections
                # Laptops
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$PreAssessmentReferenceLaptopsCollectionName" -LimitingCollectionName "$ReadyForPreAssessmentCollectionName" -FolderPath "$PreAssessmentReferenceFolderPath" -RefreshType "Manual"
                    Write-Host "    Creating Laptop rule..." -ForegroundColor Cyan
                    $RuleName = "[$BuildNum] Laptops"
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_SYSTEM_ENCLOSURE on SMS_G_System_SYSTEM_ENCLOSURE.ResourceId = SMS_R_System.ResourceId where SMS_G_System_SYSTEM_ENCLOSURE.ChassisTypes = ""8"" OR SMS_G_System_SYSTEM_ENCLOSURE.ChassisTypes = ""9"" OR SMS_G_System_SYSTEM_ENCLOSURE.ChassisTypes = ""10"" OR SMS_G_System_SYSTEM_ENCLOSURE.ChassisTypes = ""30"" OR SMS_G_System_SYSTEM_ENCLOSURE.ChassisTypes = ""31"""
                    New-QueryRule -CollectionName "$PreAssessmentReferenceLaptopsCollectionName"
                Write-Host " "

                # Remediation Collections
                # Disk Space
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$PreAssessmentRemediateDiskSpaceCollectionName" -LimitingCollectionName "$ReadyForPreAssessmentCollectionName" -FolderPath "$PreAssessmentRemediationFolderPath" -RefreshType "Manual"
                    # Add a query to pull machines that have less then 25GB of free space on C
                    Write-Host "    Creating low free space rule..." -ForegroundColor Cyan
                    $RuleName = "[$BuildNum] Low Free Space"
                    $QueryExpression = "select *  from  SMS_R_System inner join SMS_G_System_LOGICAL_DISK on SMS_G_System_LOGICAL_DISK.ResourceId = SMS_R_System.ResourceId where SMS_G_System_LOGICAL_DISK.DeviceID = 'C:' and SMS_G_System_LOGICAL_DISK.FreeSpace < 25600"
                    New-QueryRule -CollectionName "$PreAssessmentRemediateDiskSpaceCollectionName"
                Write-Host " "

                # Memory
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$PreAssessmentRemediateMemoryCollectionName" -LimitingCollectionName "$ReadyForPreAssessmentCollectionName" -FolderPath "$PreAssessmentRemediationFolderPath" -RefreshType "Manual"
                    Write-Host "    Creating Less than 3GB RAM rule..." -ForegroundColor Cyan
                    $RuleName = "[$BuildNum] Less than 3GB RAM"
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_X86_PC_MEMORY on SMS_G_System_X86_PC_MEMORY.ResourceId = SMS_R_System.ResourceId where SMS_G_System_X86_PC_MEMORY.TotalPhysicalMemory < 3145728"
                    New-QueryRule -CollectionName "$PreAssessmentRemediateMemoryCollectionName"
                Write-Host " "

                # Inactive in AD
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$PreAssessmentRemediateInactiveADCollectionName" -LimitingCollectionName "$ReadyForPreAssessmentCollectionName" -FolderPath "$PreAssessmentRemediationFolderPath" -RefreshType "Manual"
                    Write-Host "    Creating Inactive In AD rule..." -ForegroundColor Cyan
                    $RuleName = "[$BuildNum] Inactive In AD"
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_WORKSTATION_STATUS on SMS_G_System_WORKSTATION_STATUS.ResourceId = SMS_R_System.ResourceId where SMS_G_System_WORKSTATION_STATUS.LastHardwareScan < DateAdd(dd,-14,GetDate()) AND SMS_R_System.ResourceId not in (select SMS_R_System.ResourceID from  SMS_R_System inner join SMS_G_System_CH_ClientSummary on SMS_G_System_CH_ClientSummary.ResourceID = SMS_R_System.ResourceId where SMS_G_System_CH_ClientSummary.LastPolicyRequest > DateAdd(dd,-14,GetDate())) and SMS_R_System.ResourceId not in (select SMS_R_System.ResourceID from  SMS_R_System where SMS_R_System.LastLogonTimestamp > DateAdd(dd,-14,GetDate()))"
                    New-QueryRule -CollectionName "$PreAssessmentRemediateInactiveADCollectionName"
                Write-Host " "

                # Missing Hardware Inventory
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$PreAssessmentRemediateMissingHWInvCollectionName" -LimitingCollectionName "$ReadyForPreAssessmentCollectionName" -FolderPath "$PreAssessmentRemediationFolderPath" -RefreshType "Manual"
                    # Add query to pull systems that have no HWInv at all
                    Write-Host "    Creating Missing HWInv rule..." -ForegroundColor Cyan
                    $RuleName = "[$BuildNum] Missing HWInv"
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.ResourceID not in (select SMS_R_System.ResourceID from  SMS_R_System inner join SMS_G_System_WORKSTATION_STATUS on SMS_G_System_WORKSTATION_STATUS.ResourceID = SMS_R_System.ResourceId where SMS_G_System_WORKSTATION_STATUS.LastHardwareScan != """")"
                    New-QueryRule -CollectionName "$PreAssessmentRemediateMissingHWInvCollectionName"
                Write-Host " "

                # Workstations with Outdated Hardware Inventory
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$PreAssessmentRemediateWSOutdatedHWInvCollectionName" -LimitingCollectionName "$ReadyForPreAssessmentCollectionName" -FolderPath "$PreAssessmentRemediationFolderPath" -RefreshType "Manual"
                    # Create the query to pull devices that have not reported HWInv within the specified number of days (currently 14)
                    Write-Host "    Creating Outdated HWInv rule..." -ForegroundColor Cyan
                    $RuleName = "[$BuildNum] Outdated HWInv"
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_WORKSTATION_STATUS on SMS_G_System_WORKSTATION_STATUS.ResourceId = SMS_R_System.ResourceId where SMS_G_System_WORKSTATION_STATUS.LastHardwareScan < DateAdd(dd,-14,GetDate()) AND (SMS_R_System.LastLogonTimestamp > DateAdd(dd,-14,GetDate()) OR SMS_R_System.ResourceID in (select SMS_R_System.ResourceID from  SMS_R_System inner join SMS_G_System_CH_ClientSummary on SMS_G_System_CH_ClientSummary.ResourceID = SMS_R_System.ResourceId where SMS_G_System_CH_ClientSummary.LastPolicyRequest > DateAdd(dd,-14,GetDate())))"
                    New-QueryRule -CollectionName "$PreAssessmentRemediateWSOutdatedHWInvCollectionName"
                    # Add the laptop colleciton as an exclude to the WSOutdatedHWInv colleciton
                    Add-CMDeviceCollectionExcludeMembershipRule -CollectionName "$PreAssessmentRemediateWSOutdatedHWInvCollectionName" -ExcludeCollectionName "$PreAssessmentReferenceLaptopsCollectionName" -ErrorAction SilentlyContinue

                Write-Host " "

        }
    # -------------------------------------------------------------------------

    # -------------------------------------------------------------------------
    # Phase 2 - Pre-Staging Collections
    IF ($Phase -eq 2)
        {
            # Create the Phase 2 Collections
            Write-Host "-------------------------------------------------------------------------"
            Write-Host "Creating the Phase 2 - Pre-Staging Collections"
                
                # Ready for Pre-Staging
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$ReadyForPreStagingCollectionName" -LimitingCollectionName "$PassedPreAssessmentCollectionName" -FolderPath "$PreStagingFolderPath" -RefreshType "Manual"
                Write-Host " "

                # Pre-Staging Deployment
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$PreStagingDeploymentCollectionName" -LimitingCollectionName "$ReadyForPreStagingCollectionName" -FolderPath "$PreStagingFolderPath" -RefreshType "Manual"
                Write-Host " "

                # Failed Pre-Staging
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$FailedPreStagingCollectionName" -LimitingCollectionName "$ReadyForPreStagingCollectionName" -FolderPath "$PreStagingFolderPath" -RefreshType "Manual"
                    # Create the query rule to pull in machines that failed to pass Pre-Staging
                    Write-Host "    Creating Pre-Staging Not Passed rule..." -ForegroundColor Cyan
                    $RuleName = "[$BuildNum] Pre-Staging Not Passed"
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_ClassicDeploymentAssetDetails on SMS_ClassicDeploymentAssetDetails.DeviceID = SMS_R_System.ResourceId where PackageID = '$PSID' and StatusDescription = 'PreStaging did NOT Pass'"
                    New-QueryRule -CollectionName "$FailedPreStagingCollectionName"
                Write-Host " "

                # CWDb Security Hold
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$PreStagingCWDbSecurityHoldCollectionName" -LimitingCollectionName "$ReadyForPreStagingCollectionName" -FolderPath "$PreStagingFolderPath" -RefreshType "Manual"
                    # Create the query rule to pull in machines that failed to pass Pre-Staging due to CWDb Security Hold
                    Write-Host "    Creating Pre-Staging Not Passed rule..." -ForegroundColor Cyan
                    $RuleName = "[$BuildNum] Pre-Staging Not Passed (CWDb Security Hold)"
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_ClassicDeploymentAssetDetails on SMS_ClassicDeploymentAssetDetails.DeviceID = SMS_R_System.ResourceId where PackageID = '$PSID' and StatusDescription = 'PreStaging CWDb Security Hold'"
                    New-QueryRule -CollectionName "$PreStagingCWDbSecurityHoldCollectionName"
                Write-Host " "

                # Passed Pre-Staging
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$PassedPreStagingCollectionName" -LimitingCollectionName "$ReadyForPreStagingCollectionName" -FolderPath "$PreStagingFolderPath" -RefreshType "Manual"
                    # Create the query rule to pull in machines that passed Pre-Staging
                    Write-Host "    Creating Pre-Staging Passed rule..." -ForegroundColor Cyan
                    $RuleName = "[$BuildNum] Pre-Staging Passed"
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_ClassicDeploymentAssetDetails on SMS_ClassicDeploymentAssetDetails.DeviceID = SMS_R_System.ResourceId where PackageID = '$PSID' and StatusDescription = 'PreStaging Passed'"
                    New-QueryRule -CollectionName "$PassedPreStagingCollectionName"
                Write-Host " "


        }
    # -------------------------------------------------------------------------

    # -------------------------------------------------------------------------
    # Phase 3 - Deployment Collections
    IF ($Phase -eq 3)
        {
            # Create the Phase 3 Collections
            Write-Host "-------------------------------------------------------------------------"
            Write-Host "Creating the Phase 3 - Deployment Collections"

                # Ready for Deployment
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$ReadyForDeploymentCollectionName" -LimitingCollectionName "$PassedPreStagingCollectionName" -FolderPath "$DeploymentFolderPath" -RefreshType "Manual"
                Write-Host " "

                # Exclusions - AdHoc (Rollup)
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$ExclusionsAdHocName" -LimitingCollectionName "$ReadyForDeploymentCollectionName" -FolderPath "$DeploymentFolderPath" -RefreshType "Manual"
                # Generate the path within the console for the query statement
                    $tmpFolder = $NULL
                    $tmpFolder = $ReferenceAdHocExclusionsFolderPath.Substring($($FolderMask.Length))
                    $consolepath = $NULL
                    $consolepath = ( $tmpFolder.Replace("\","/") )
                    $RuleName = "[$BuildNum] Object Path Query"
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.ResourceId in (select ResourceID from sms_fullcollectionmembership where collectionID in (select CollectionID from SMS_Collection where ObjectPath = '$($consolepath)'))"
                    New-QueryRule -CollectionName "$ExclusionsAdHocName"
                Write-Host ""

                # AdHoc Exclusion - ARLI Mode
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$AdHocExclusionARLICollectionName" -LimitingCollectionName "$ReadyForDeploymentCollectionName" -FolderPath "$ReferenceAdHocExclusionsFolderPath" -RefreshType "Manual"
                    $RuleName = "[$BuildNum] ARLI Mode"
                    $QueryExpression = "select *  from  SMS_R_System inner join SMS_G_System_COREDATA on SMS_G_System_COREDATA.ResourceId = SMS_R_System.ResourceId where SMS_G_System_COREDATA.MODE = ""ARLI"""
                    New-QueryRule -CollectionName "$AdHocExclusionARLICollectionName"
                Write-Host " "

                # AdHoc Exclusion - FLEX Mode
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$AdHocExclusionFLEXCollectionName" -LimitingCollectionName "$ReadyForDeploymentCollectionName" -FolderPath "$ReferenceAdHocExclusionsFolderPath" -RefreshType "Manual"
                    $RuleName = "[$BuildNum] FLEX Mode"
                    $QueryExpression = "select *  from  SMS_R_System inner join SMS_G_System_COREDATA on SMS_G_System_COREDATA.ResourceId = SMS_R_System.ResourceId where SMS_G_System_COREDATA.MODE = ""FLEX"""
                    New-QueryRule -CollectionName "$AdHocExclusionFLEXCollectionName"
                Write-Host " "



                # AppCompat Exclusion ByPass Rollups
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$ByPassGeneralAppCompatCollectionName" -LimitingCollectionName "$ReadyForDeploymentCollectionName" -FolderPath "$ReferenceAppCompatExclusionByPassFolderPath" -RefreshType "Manual"
                # Generate the path within the console for the query statement
                    $tmpFolder = $NULL
                    $tmpFolder = $ReferenceAppCompatExclusionByPassGeneralFolderPath.Substring($($FolderMask.Length))
                    $consolepath = $NULL
                    $consolepath = ( $tmpFolder.Replace("\","/") )
                    $RuleName = "[$BuildNum] Object Path Query"
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.ResourceId in (select ResourceID from sms_fullcollectionmembership where collectionID in (select CollectionID from SMS_Collection where ObjectPath = '$($consolepath)'))"
                    New-QueryRule -CollectionName "$ByPassGeneralAppCompatCollectionName"
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$ByPassScheduleAppCompatCollectionName" -LimitingCollectionName "$ReadyForDeploymentCollectionName" -FolderPath "$ReferenceAppCompatExclusionByPassFolderPath" -RefreshType "Manual"
                    $tmpFolder = $NULL
                    $tmpFolder = $ReferenceAppCompatExclusionByPassScheduledFolderPath.Substring($($FolderMask.Length))
                    $consolepath = $NULL
                    $consolepath = ( $tmpFolder.Replace("\","/") )
                    $RuleName = "[$BuildNum] Object Path Query"
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.ResourceId in (select ResourceID from sms_fullcollectionmembership where collectionID in (select CollectionID from SMS_Collection where ObjectPath = '$($consolepath)'))"
                    New-QueryRule -CollectionName "$ByPassScheduleAppCompatCollectionName"
                Write-Host " "

                # Exclusions - AppCompat (Rollup)
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$ExclusionsAppCompatName" -LimitingCollectionName "$ReadyForDeploymentCollectionName" -FolderPath "$DeploymentFolderPath" -RefreshType "Manual"
                # Generate the path within the console for the query statement
                    $tmpFolder = $NULL
                    $tmpFolder = $ReferenceAppCompatExclusionsFolderPath.Substring($($FolderMask.Length))
                    $consolepath = $NULL
                    $consolepath = ( $tmpFolder.Replace("\","/") )
                    $RuleName = "[$BuildNum] Object Path Query"
                    # Pull the needed Collection IDs for the query
                    $ByPassGeneralAppCompatCollectionID          = (Get-CMDeviceCollection -Name $ByPassGeneralAppCompatCollectionName).CollectionID
                    $ByPassScheduleAppCompatCollectionID         = (Get-CMDeviceCollection -Name $ByPassScheduleAppCompatCollectionName).CollectionID
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.ResourceId in (select ResourceID from sms_fullcollectionmembership where collectionID in (select CollectionID from SMS_Collection where ObjectPath = '$($consolepath)')) and SMS_R_System.ResourceId not in (select ResourceID from SMS_CM_RES_COLL_$ByPassGeneralAppCompatCollectionID) and SMS_R_System.ResourceId not in (select ResourceID from SMS_CM_RES_COLL_$ByPassScheduleAppCompatCollectionID)"
                    New-QueryRule -CollectionName "$ExclusionsAppCompatName"
                Write-Host ""

                # Manual Deployment
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$ManualDeploymentCollectionName" -LimitingCollectionName "$ReadyForDeploymentCollectionName" -FolderPath "$DeploymentFolderPath" -RefreshType "Manual"

                    Write-Host "    Creating inclusion query rule..." -ForegroundColor Cyan
                    $RuleName = "[$BuildNum] Include Adhoc Collections"
                    # Pull the needed Collection IDs for the query
                    $ExclusionsAdHocID          = (Get-CMDeviceCollection -Name $ExclusionsAdHocName).CollectionID
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.ResourceId in (select ResourceID from SMS_CM_RES_COLL_$ExclusionsAdHocID)"
                    New-QueryRule -CollectionName "$ManualDeploymentCollectionName"

                    Write-Host "    Creating inclusion query rule..." -ForegroundColor Cyan
                    $RuleName = "[$BuildNum] Include AppCompat Collections"
                    # Pull the needed Collection IDs for the query
                    $ExclusionsAppCompatID          = (Get-CMDeviceCollection -Name $ExclusionsAppCompatName).CollectionID
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.ResourceId in (select ResourceID from SMS_CM_RES_COLL_$ExclusionsAdHocID)"
                    New-QueryRule -CollectionName "$ManualDeploymentCollectionName"


                    # Set the collection variable to trigger a bypass of the Punt reboot notification
                    $CollVariableExists = $null
                    $CollVariableExists = Get-CMDeviceCollectionVariable -CollectionName $ManualDeploymentCollectionName -VariableName "PuntBypass"
                    IF ($CollVariableExists)
                        {
                            Write-Host "    The Collection Variable already exist" -ForegroundColor Yellow
                    Try {
                            Set-CMDeviceCollectionVariable -CollectionName $ManualDeploymentCollectionName -VariableName "PuntBypass" -IsMask $FALSE -NewVariableValue "TRUE"
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
                    #cd\
                    Try {
                        New-CMDeviceCollectionVariable -CollectionName $ManualDeploymentCollectionName -VariableName "PuntBypass" -IsMask $FALSE -Value "TRUE"
                        Write-Host "    The Collection Variable was created" -ForegroundColor Green
                        }
                    Catch
                        {
                        Write-Host "    Exception caught in creating Collection Variable : $error[0]" -ForegroundColor Red
                        }
                }






                Write-Host " "

                # Automated Deployment
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$AutomatedDeploymentCollectionName" -LimitingCollectionName "$ReadyForDeploymentCollectionName" -FolderPath "$DeploymentFolderPath" -RefreshType "Manual"
                    Write-Host "    Creating exclusion query rule..." -ForegroundColor Cyan
                    $RuleName = "[$BuildNum] Exclude Manual Deployment Groups"
                    # Pull the Collection ID for the "All Supported Hardware" collection so we can reference it in our query
                    $AllSuppHWCollectionID = (Get-CMDeviceCollection -Name $ManualDeploymentCollectionName).CollectionID
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.ResourceId not in (select ResourceID from SMS_CM_RES_COLL_$AllSuppHWCollectionID)"
                    New-QueryRule -CollectionName "$AutomatedDeploymentCollectionName"
                Write-Host " "

                # Failed Update
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$FailedDeploymentCollectionName" -LimitingCollectionName "$ReadyForDeploymentCollectionName" -FolderPath "$DeploymentFolderPath" -RefreshType "Manual"
                Write-Host " "

                # Successful Update
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$PassedDeploymentCollectionName" -LimitingCollectionName "$ReadyForDeploymentCollectionName" -FolderPath "$DeploymentFolderPath" -RefreshType "Manual"
                Write-Host " "

                # Deployment Notification (Toast) Exceptions
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$ToastExceptionCollectionName" -LimitingCollectionName "$ReadyForDeploymentCollectionName" -FolderPath "$DeploymentFolderPath" -RefreshType "Manual"
                # Generate the path within the console for the query statement
                    $tmpFolder = $NULL
                    $tmpFolder = $ToastExceptionFolderPath.Substring($($FolderMask.Length))
                    $consolepath = $NULL
                    $consolepath = ( $tmpFolder.Replace("\","/") )
                    $RuleName = "[$BuildNum] Object Path Query"
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.ResourceId in (select ResourceID from sms_fullcollectionmembership where collectionID in (select CollectionID from SMS_Collection where ObjectPath = '$($consolepath)'))"
                    New-QueryRule -CollectionName "$ToastExceptionCollectionName"

                # Set the collection variable to trigger a bypass of the Toast notification chain
                    $CollVariableExists = $null
                    $CollVariableExists = Get-CMDeviceCollectionVariable -CollectionName $ToastExceptionCollectionName -VariableName "IPUNotificationException"
                    IF ($CollVariableExists)
                        {
                            Write-Host "    The Collection Variable already exist" -ForegroundColor Yellow
                            Try {
                                Set-CMDeviceCollectionVariable -CollectionName $ToastExceptionCollectionName -VariableName "IPUNotificationException" -IsMask $FALSE -NewVariableValue "TRUE"
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
                            #cd\
                            Try {
                                New-CMDeviceCollectionVariable -CollectionName $ToastExceptionCollectionName -VariableName "IPUNotificationException" -IsMask $FALSE -Value "TRUE"
                                Write-Host "    The Collection Variable was created" -ForegroundColor Green
                                }
                            Catch
                                {
                                Write-Host "    Exception caught in creating Collection Variable : $error[0]" -ForegroundColor Red
                                }
                        }
                Write-Host " "

                # GreenIT Managed Machines
                Write-Host "-------------------------------------"
                New-Collection -CollectionName "$GreenITCollectionName" -LimitingCollectionName "$ReadyForDeploymentCollectionName" -FolderPath "$ToastExceptionFolderPath" -RefreshType "Manual"
                    $RuleName = "[$BuildNum] GreenIT Machines"
                    $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_UMHSPWR on SMS_G_System_UMHSPWR.ResourceId = SMS_R_System.ResourceId where SMS_G_System_UMHSPWR.PwrCPU = ""YES"""
                    New-QueryRule -CollectionName "$GreenITCollectionName"
                Write-Host " "


        }
    # -------------------------------------------------------------------------


    # < < < < < < < < < < < < > > > > > > > > > > > > > > >

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    # < < < < < < < < < < Deployments > > > > > > > > > > >

    # -------------------------------------------------------------------------
    # Phase 2 - Pre-Staging Deployments
    IF ($Phase -eq 2)
        {
            # Create the Phase 2 Deployment(s)
            Write-Host "-------------------------------------------------------------------------"
            Write-Host "Creating the Phase 2 - Pre-Staging Deployment(s)"

            # Pre-Staging Task Sequence
                $StartDate = (Get-Date -Format "MM/dd/yyyy")
                $PreStageDeploymentstart = $NULL
                #Set the starting date to 10am tomorrow so ConfigMgr won't move up the start time to the execution time of the script
                $PreStageDeploymentstart = (Get-Date -Date $StartDate).AddHours(34)
                $PreStageDeploymentSchedule = New-CMSchedule -Start $PreStageDeploymentstart -DurationInterval Hours -DurationCount 8  -RecurCount 1 -RecurInterval Days

                # Create 10 collections with deployments spaced 15 minutes apart to spread out the workload
                FOR ($a=0; $a -le 9; $a++)
                    {
                        Write-Host "Deployment for ResID $a"
                        Write-Host "Deployment Start Time: $PreStageDeploymentstart"
                        New-Collection -CollectionName "$PreStagingDeploymentCollectionName-ResID-$a" -LimitingCollectionName "$ReadyForPreStagingCollectionName" -FolderPath "$PreStagingDeploymentsFolderPath" -RefreshType "Manual"

                        # Create the query rule
                        $RuleName = "$WaaSBranch $BuildNum ResourceID Last Digit = $a"
                        $QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceId = SMS_R_System.ResourceId where SMS_G_System_COMPUTER_SYSTEM.ResourceID like ""%$a"""
                        New-QueryRule -CollectionName "$PreStagingDeploymentCollectionName-ResID-$a"

                        # Create/Update the Deployment for the Pre-Stage sequence
                        $PreStageDeploymentExists = $null
                        $PreStageDeploymentExists = Get-CMTaskSequenceDeployment -CollectionName "$PreStagingDeploymentCollectionName-ResID-$a" -TaskSequenceId $PSID

                        IF ($PreStageDeploymentExists)
                            {
                                Write-Host "The Deployment already exist" -ForegroundColor Yellow
                                Write-Host "    Removing so we can update the deployment" -ForegroundColor Yellow
                                TRY {
                                        Remove-CMTaskSequenceDeployment -TaskSequenceId $PSID -CollectionName "$PreStagingDeploymentCollectionName-ResID-$a" -Force
                                        New-CMTaskSequenceDeployment -TaskSequencePackageId $PSID -Availability Clients -DeployPurpose Required -Schedule $PreStageDeploymentSchedule -CollectionName "$PreStagingDeploymentCollectionName-ResID-$a" -SendWakeupPacket $TRUE -RerunBehavior AlwaysRerunProgram -DeploymentOption DownloadContentLocallyWhenNeededByRunningTaskSequence -AllowFallback $TRUE -AllowUseRemote $TRUE -ShowTaskSequenceProgress $FALSE
                                        Write-Host "    The Pre-Staging Deployment was created" -ForegroundColor Green
                                    }
                                CATCH
                                    {
                                        Write-Host "    Exception caught in creating Pre-Staging Deployment : $error[0]" -ForegroundColor Red
                                    }
                            }
                        ELSE
                            {
                                Write-Host "The Deployment does not already exist"
                                Write-Host "Creating Pre-Staging Deployment..."
                                TRY {
                                        New-CMTaskSequenceDeployment -TaskSequencePackageId $PSID -Availability Clients -DeployPurpose Required -Schedule $PreStageDeploymentSchedule -CollectionName "$PreStagingDeploymentCollectionName-ResID-$a" -SendWakeupPacket $TRUE -RerunBehavior AlwaysRerunProgram -DeploymentOption DownloadContentLocallyWhenNeededByRunningTaskSequence -AllowFallback $TRUE -AllowUseRemote $TRUE -ShowTaskSequenceProgress $FALSE
                                        Write-Host "The Deployment was created" -ForegroundColor Green
                                    }
                                CATCH
                                    {
                                        Write-Host "Exception caught in creating Deployment : $error[0]" -ForegroundColor Red
                                    }
                            }

                        $PreStageDeploymentstart = (Get-Date -Date $PreStageDeploymentstart).AddMinutes(15)
                        $PreStageDeploymentSchedule = New-CMSchedule -Start $PreStageDeploymentstart -DurationInterval Hours -DurationCount 8  -RecurCount 1 -RecurInterval Days
                    }

            # The "Pre-Staging" of the Feature Update
            # This is a "dummy" deployment of the Feature Update set to run far, FAR in the future
            # The sole purpose of this deployment is to get the Feature Update content cached in advance of the 
            # actual Feature Update deployment in Phase 3
            $FeatureUpdateMandatoryStart = Get-Date -Date "8/1/2033 20:00:00"
            New-CMSoftwareUpdateDeployment -SoftwareUpdateName "Feature update to Windows 10 (business editions), version 1909, en-us x64" -CollectionName "$PreStagingDeploymentCollectionName" -DeploymentName "WaaS - Feature Update Staging (1909)" -Description "Dummy deployment only intended to cache Feature Update content" -DeploymentType Required -DeadlineDateTime $FeatureUpdateMandatoryStart -SavedPackageId $FeatureUpdatePkgID -UserNotification HideAll -DownloadFromMicrosoftUpdate $TRUE -VerbosityLevel AllMessages -UnprotectedType UnprotectedDistributionPoint -ProtectedType RemoteDistributionPoint -AllowRestart $TRUE -RequirePostRebootFullScan $TRUE
            #New-CMSoftwareUpdateDeployment -CollectionName "$PreStagingDeploymentCollectionName" -DeploymentName "WaaS - Feature Update Staging ($BuildNum)" -Description "Dummy deployment only intended to cache Feature Update content" -DeploymentType Required -DeadlineDateTime $FeatureUpdateMandatoryStart -SavedPackageId $FeatureUpdatePkgID -UserNotification DisplayAll -DownloadFromMicrosoftUpdate $TRUE -VerbosityLevel AllMessages -UnprotectedType UnprotectedDistributionPoint -ProtectedType RemoteDistributionPoint -AllowRestart $TRUE -RequirePostRebootFullScan $TRUE
            Write-Host "-------------------------------------------------------------------------"
        }


    # -------------------------------------------------------------------------

    # < < < < < < < < < < < < > > > > > > > > > > > > > > >

# -------------------------------------

Set-location C:\

Write-Host "-----------------------------------------------" -ForegroundColor Cyan
Write-Host "Finished: $MyModule ver. $MyVersion"             -ForegroundColor Cyan
Write-Host "-----------------------------------------------" -ForegroundColor Cyan
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
