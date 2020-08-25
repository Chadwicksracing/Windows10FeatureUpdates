# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# File:  WaaS_00_CoreVariables_v#.#.ps1
# Version: 1.0
# Date:    13 Jul 2020
# Author:  Mike Marable
#
# Central repository of all the common variable names used by all of the WaaS build-out scripts
#

# Version: 1.1
# Date:    24 Jul 2020
# Author:  Mike Marable
#
# Added Phase 3 Automated and Manual deployment collections
# Moved Adhoc and AppCompat exclusions to Phase 3

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

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# *** Entry Point to Script ***

########################
# Start of Code Block ##
########################
$MyVersion = "1.1"
$MyModule = "WaaS_CoreVariables"

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#Clear-Host

Write-Host "-----------------------------------------------" -ForegroundColor Cyan
Write-Host "Starting: $MyModule ver. $MyVersion"             -ForegroundColor Cyan
Write-Host "-----------------------------------------------" -ForegroundColor Cyan

# Variables
# Folder Names
    # Common Folder Names
    # Root Level
    $RootFolder = "$($SiteCode):\DeviceCollection\WaaS"
    $FolderMask = "$($SiteCode):\DeviceCollection"
    $WaaSBranchFolderPath = "$RootFolder\$BuildNum\$WaaSBranch"

    # Phase 0
    $ReferenceFolderPath                                  = "$WaaSBranchFolderPath\Phase 0 - Reference"

    # Phase 1
    $PreAssessmentFolderPath                              = "$WaaSBranchFolderPath\Phase 1 - Pre-Assessment"
    $PreAssessmentRemediationFolderPath                   = "$PreAssessmentFolderPath\Remediation"
    $PreAssessmentReferenceFolderPath                     = "$PreAssessmentFolderPath\Reference"

    # Phase 2
    $PreStagingFolderPath                                 = "$WaaSBranchFolderPath\Phase 2 - Pre-Staging"
    $PreStagingDeploymentsFolderPath                      = "$PreStagingFolderPath\Pre-StageDeployments"

    # Phase 3
    $DeploymentFolderPath                                 = "$WaaSBranchFolderPath\Phase 3 - Deployment"
    $ToastExceptionFolderPath                             = "$DeploymentFolderPath\IPUNotificationExceptions"
    $RootDeploymentFolderPath                             = "$DeploymentFolderPath\FeatureUpdateDeployments"
    $ReferenceAppCompatFolderPath                         = "$DeploymentFolderPath\AppCompat"
    $ReferenceAppCompatExclusionsFolderPath               = "$ReferenceAppCompatFolderPath\Exclusions"
    $ReferenceAppCompatExclusionByPassFolderPath          = "$ReferenceAppCompatFolderPath\ByPass"
    $ReferenceAppCompatExclusionByPassGeneralFolderPath   = "$ReferenceAppCompatExclusionByPassFolderPath\General"
    $ReferenceAppCompatExclusionByPassScheduledFolderPath = "$ReferenceAppCompatExclusionByPassFolderPath\Scheduled"
    $ReferenceAppCompatExclusionByPassStagingFolderPath   = "$ReferenceAppCompatExclusionByPassFolderPath\Staging"
    $ReferenceAdHocFolderPath                             = "$DeploymentFolderPath\AdHoc"
    $ReferenceAdHocExclusionsFolderPath                   = "$ReferenceAdHocFolderPath\Exclusions"


# Collection Names
    # Collection Prefix
    $Phase0 = "WaaS_$WaaSBranch`_$BuildNum`_Phase0-Reference"
    $Phase1 = "WaaS_$WaaSBranch`_$BuildNum`_Phase1-PreAssessment"
    $Phase2 = "WaaS_$WaaSBranch`_$BuildNum`_Phase2-PreStage"
    $Phase3 = "WaaS_$WaaSBranch`_$BuildNum`_Phase3-FeatureUpdate"

    # Phase 0
    $StartingPointCollectionName            = "$Phase0`_00_StartingPoint"
    $InelligibleOSW7CollectionName          = "$Phase0`_01_Ineligible-OS-Windows7"
    $InelligibleOSW10CurrentCollectionName  = "$Phase0`_02_Ineligible-OS-Windows10-CurrentBuild"
    $InelligibleUnSupportedHWCollectionName = "$Phase0`_03_Ineligible-UnsupportedHardware"
    $AllSuppHWCollectionName                = "$Phase0`_98_AllSupportedHardware"
    $PassedScrutineeringName                = "$Phase0`_99_PassedScrutineering"

    # Phase 1
    $ReadyForPreAssessmentCollectionName   = "$Phase1`_00_ReadyforPreAssessment"
    $FailedPreAssessmentCollectionName     = "$Phase1`_50_FailedPreAssessment"
    $PassedPreAssessmentCollectionName     = "$Phase1`_99_PassedPreAssessment"
    # Remediation Collections
    $PreAssessmentReferenceLaptopsCollectionName             = "$Phase1`_Reference_Laptops"
    $PreAssessmentRemediateDiskSpaceCollectionName           = "$Phase1`_Remediation_DiskSpace"
    $PreAssessmentRemediateInactiveADCollectionName          = "$Phase1`_Remediation_InactiveInAD"
    $PreAssessmentRemediateMemoryCollectionName              = "$Phase1`_Remediation_Memory"
    $PreAssessmentRemediateMissingHWInvCollectionName        = "$Phase1`_Remediation_MissingHWInventory"
    $PreAssessmentRemediateWSOutdatedHWInvCollectionName     = "$Phase1`_Remediation_WorkstationOutdatedHWInventory"

    # Phase 2
    $ReadyForPreStagingCollectionName           = "$Phase2`_00_ReadyforPreStaging"
    $PreStagingDeploymentCollectionName         = "$Phase2`_01_PreStaging"
    $FailedPreStagingCollectionName             = "$Phase2`_50_FailedPreStaging"
    $PreStagingCWDbSecurityHoldCollectionName   = "$Phase2`_60_CWDbSecurityHold"
    $PassedPreStagingCollectionName             = "$Phase2`_99_PassedPreStaging"

    # Phase 3
    $ReadyForDeploymentCollectionName       = "$Phase3`_00_ReadyforDeployment"
    $AutomatedDeploymentCollectionName      = "$Phase3`_01_AutomatedDeployment"
    $ManualDeploymentCollectionName         = "$Phase3`_02_ManualDeployment"
    $FailedDeploymentCollectionName         = "$Phase3`_50_FailedDeployment"
    $PassedDeploymentCollectionName         = "$Phase3`_99_PassedDeployment"
    $ToastExceptionCollectionName           = "$Phase3`_Exception_AllNotifications"
    $GreenITCollectionName                  = "$Phase3`_Exception_GreenITMachines"
    $ExclusionsAppCompatName                = "$Phase3`_10_Exclusions-AllAppCompat"
    $ExclusionsAdHocName                    = "$Phase3`_11_Exclusions-AdHoc"
    $ByPassGeneralAppCompatCollectionName   = "$Phase3`_Exclusions_Rollup [Bypass - General]"
    $ByPassScheduleAppCompatCollectionName  = "$Phase3`_Exclusions_Rollup [Bypass - Scheduled]"
    # AdHoc Exclusions
    $AdHocExclusionARLICollectionName       =  "$Phase3`_Exclusions_ARLI Mode"
    $AdHocExclusionFLEXCollectionName       =  "$Phase3`_Exclusions_FLEX Mode"



Write-Host "-----------------------------------------------" -ForegroundColor Cyan
Write-Host "Finished: $MyModule ver. $MyVersion"             -ForegroundColor Cyan
Write-Host "-----------------------------------------------" -ForegroundColor Cyan
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
