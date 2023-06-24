function Enable-UWFFeature {

    <# 
        .SYNOPSIS
        Installs UWF.

        .DESCRIPTION
        Installs UWF and all required installs needed. Reboots when finished.

        .PARAMETER ComputerName
        The name of the computer that the command is being ran on. If no computer name is given, then it runs locally.

    #>

    [Cmdletbinding()]
    param(
        [string]$ComputerName = "localhost"
    )

    $compSession = New-PSSession -ComputerName $ComputerName

    Invoke-Command -Session $compSession -ScriptBlock { 
        Enable-WindowsOptionalFeature -FeatureName "Client-UnifiedWriteFilter" -Online -All -NoRestart
        Restart-Computer -Force
    }

}

function Set-UWFVolumeProtection {

    <# 
        .SYNOPSIS
        Sets a volume to be protected by UWF.

        .DESCRIPTION
        Sets a volume to be protected by UWF. Along with protecting a drive, you can also unprotect a drive.

        .PARAMETER ComputerName
        The name of the computer that the command is being ran on. If no computer name is given, then it runs locally.

        .PARAMETER DriveLetter
        The volume's drive letter to protect. If no drive letter is given, C: is used.

        .PARAMETER Protect
        Switch used to enable volume protection.

        .PARAMETER Unprotect
        Switch used to disable volume protection.
    #>

    param(
        [string]$ComputerName = "localhost",
        [string]$DriveLetter = "C:",
        [switch]$Protect,
        [switch]$Unprotect
    )

    $namespace = "root\standardcimv2\embedded"

    $returnObject = New-Object -TypeName psobject

    try {
        $uwfvolume = Get-WMIObject -Class "UWF_Volume" -Namespace $namespace -ComputerName $ComputerName -ErrorAction Stop | Where-Object -Property "CurrentSession" -eq $false
    }
    catch {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Error"

        return $returnObject
    }
    if ($uwfvolume) {
        if ($Protect) {
            $opReturn = $uwfvolume.Protect()
        }
        if ($Unprotect) {
            $opReturn = $uwfvolume.Unprotect()
        }
    }
    else {
        $compSess = New-PSSession -ComputerName $ComputerName
        Write-Warning "No volumes have been protected before on this machine. Falling back to uwfmgr."
        if ($Protect) {
            Invoke-Command -Session $compSess -ArgumentList $DriveLetter -ScriptBlock { 
                param($DriveLetter)
                uwfmgr volume protect $DriveLetter 
            }
        }
        if ($Unprotect) {
            Invoke-Command -Session $compSess -ArgumentList $DriveLetter -ScriptBlock { 
                param($DriveLetter)
                uwfmgr volume protect $DriveLetter 
            }
        }
    }
}

function Enable-UWF {

    <# 
        .SYNOPSIS
        Enables the UWF filter.

        .DESCRIPTION
        Enables the UWF filter for the next reboot. 

        .PARAMETER ComputerName
        The name of the computer that the command is being ran on. If no computer name is given, then it runs locally.

        .PARAMETER Reboot
        Switch to reboot the computer when ran.
    #>

    param(
        [string]$ComputerName = "localhost",
        [switch]$Reboot
    )

    $namespace = "root\standardcimv2\embedded"

    $returnObject = New-Object -TypeName psobject

    try {
        $uwffilter = Get-WMIObject -Class "UWF_Filter" -Namespace $namespace -ComputerName $ComputerName -ErrorAction Stop
    }
    catch {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Error"

        return $returnObject
    }
    
    $enableUWF = $uwffilter.Enable()

    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName

    if ($enableUWF.ReturnValue -eq 0) {
        If ($Reboot) {
            Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Enabled (Rebooting)"
            $uwffilter.RestartSystem() | Out-Null
        }
        else {
            Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Enabled (Requires Reboot)"
        }
    }
    else {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Failed"
    }
    return $returnObject
}

function Disable-UWF {

    <# 
        .SYNOPSIS
        Disables the UWF filter.

        .DESCRIPTION
        Disables the UWF filter for the next reboot. 

        .PARAMETER ComputerName
        The name of the computer that the command is being ran on. If no computer name is given, then it runs locally.

        .PARAMETER Reboot
        Switch to reboot the computer when ran.
    #>

    param(
        [string]$ComputerName = "localhost",
        [switch]$Reboot
    )

    $namespace = "root\standardcimv2\embedded"

    $returnObject = New-Object -TypeName psobject

    try {
        $uwffilter = Get-WMIObject -Class "UWF_Filter" -Namespace $namespace -ComputerName $ComputerName -ErrorAction Stop
    }
    catch {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Error"

        return $returnObject
    }
    
    $enableUWF = $uwffilter.Disable()

    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName

    if ($enableUWF.ReturnValue -eq 0) {
        If ($Reboot) {
            Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Enabled (Rebooting)"
            $uwffilter.RestartSystem() | Out-Null
        }
        else {
            Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Enabled (Requires Reboot)"
        }
    }
    else {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Failed"
    }
    return $returnObject
}

function Enable-UWFServicing {

    <# 
        .SYNOPSIS
        Enables UWF servicing.

        .DESCRIPTION
        Enables UWF servicing for the next reboot. 

        .PARAMETER ComputerName
        The name of the computer that the command is being ran on. If no computer name is given, then it runs locally.

        .PARAMETER Reboot
        Switch to reboot the computer when ran.
    #>

    param(
        [string]$ComputerName = "localhost",
        [switch]$Reboot
    )

    $namespace = "root\standardcimv2\embedded"

    $returnObject = New-Object -TypeName psobject

    try {
        $uwfservicing = Get-WMIObject -Class "UWF_Servicing" -Namespace $namespace -ComputerName $ComputerName -ErrorAction Stop | where { $_.CurrentSession -eq $false }
        $uwffilter = Get-WMIObject -Class "UWF_Filter" -Namespace $namespace -ComputerName $ComputerName -ErrorAction Stop
    }
    catch {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Error"

        return $returnObject
    }
    
    $enableServicing = $uwfservicing.Enable()

    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName

    if ($enableServicing.ReturnValue -eq 0) {
        If ($Reboot) {
            Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Enabled (Rebooting)"
            $uwffilter.RestartSystem() | Out-Null
        }
        else {
            Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Enabled (Requires Reboot)"
        }
    }
    else {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Failed"
    }

    return $returnObject
}

function Add-UWFFileExclusion {

    <# 
        .SYNOPSIS
        Add a file/folder exclusion for the UWF filter.

        .DESCRIPTION
        Add a file/folder exclusion for the UWF filter. Changes are applied at the next reboot.

        .PARAMETER ComputerName
        The name of the computer that the command is being ran on. If no computer name is given, then it runs locally.

        .PARAMETER Exclusion
        Path to file/folder to be excluded. (Note: Do not include the drive letter.)

        .PARAMETER DriveLetter
        The volume the exclusion is being applied to. If no drive letter is provided, C: is used.
    #>

    param(
        [string]$ComputerName = "localhost",
        [string]$Exclusion,
        [string]$DriveLetter = "C:"
    )

    $namespace = "root\standardcimv2\embedded"

    $returnObject = New-Object -TypeName psobject

    try {
        $uwfvolume = Get-WMIObject -Class "UWF_Volume" -Namespace $namespace -ComputerName $ComputerName -ErrorAction Stop | where { $_.CurrentSession -eq $false -and $_.DriveLetter -eq $DriveLetter}
    }
    catch {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Error"

        return $returnObject
    }

    $addMethod = $uwfvolume.AddExclusion($Exclusion)

    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName

    if ($addMethod.ReturnValue -eq 0) {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Successful"
    }
    else {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Failed"
    }

    return $returnObject
}

function Add-UWFRegistryExclusion {

    <# 
        .SYNOPSIS
        Add a registry key exclusion for the UWF filter.

        .DESCRIPTION
        Add a registry key exclusion for the UWF filter. Changes are applied at the next reboot.

        .PARAMETER ComputerName
        The name of the computer that the command is being ran on. If no computer name is given, then it runs locally.

        .PARAMETER Exclusion
        Path to registry key to be excluded.
    #>

    param(
        [string]$ComputerName = "localhost",
        [string]$Exclusion
    )

    $namespace = "root\standardcimv2\embedded"

    $returnObject = New-Object -TypeName psobject

    try {
        $uwfvolume = Get-WMIObject -Class "UWF_RegistryFilter" -Namespace $namespace -ComputerName $ComputerName -ErrorAction Stop | where { $_.CurrentSession -eq $false }
    }
    catch {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Error"

        return $returnObject
    }

    $addMethod = $uwfvolume.AddExclusion($Exclusion)

    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName

    if ($addMethod.ReturnValue -eq 0) {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Successful"
    }
    else {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Failed"
    }

    return $returnObject
}

function Set-UWFOverlay {

    <# 
        .SYNOPSIS
        Set the overlay type and size.

        .DESCRIPTION
        Set the overlay type to either a RAM or disk based overlay and also to set the size of the overlay.

        .PARAMETER ComputerName
        The name of the computer that the command is being ran on. If no computer name is given, then it runs locally.

        .PARAMETER OverlayType
        Type of overlay to use.

        .PARAMETER OverlaySize
        The size given for the overlay. If no size is given, it uses 1024 MB (1 GB).
    #>

    param(
        [string]$ComputerName = "localhost",
        [ValidateSet("RAM", "Disk")][string]$OverlayType,
        [uint32]$OverlaySize = 1024
    )

    $namespace = "root\standardcimv2\embedded"

    $returnObject = New-Object -TypeName psobject

    try {
        $uwfoverlay = Get-WMIObject -Class "UWF_OverlayConfig" -Namespace $namespace -ComputerName $ComputerName -ErrorAction Stop | where { $_.CurrentSession -eq $false }
    }
    catch {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Error"
    
        return $returnObject
    }
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName

    if ($OverlayType -eq "RAM") {
        $typeMethod = $uwfoverlay.SetType(0)
    }
    elseif ($OverlayType -eq "Disk") {
        $typeMethod = $uwfoverlay.SetType(1)
    }

    $sizeMethod = $uwfoverlay.SetMaximumSize($OverlaySize)

    if ($typeMethod.ReturnValue -eq 0 -and $sizeMethod.ReturnValue -eq 0) {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Successful"
    }
    else {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Failed"
    }
    return $returnObject
}

function Set-UWFOverlayThreshold {

    <# 
        .SYNOPSIS
        Set the threshold for the overlay.

        .DESCRIPTION
        Set the critical and warning threshold for the overlay so that users are made aware of possible overlay exhaustion.

        .PARAMETER ComputerName
        The name of the computer that the command is being ran on. If no computer name is given, then it runs locally.

        .PARAMETER Warning
        The amount of space for an early warning of possible overlay exhaustion. (Size must be in MB)

        .PARAMETER Critical
        The amount of space for a critical warning of possible overlay exhaustion. (Size must be in MB)
    #>

    param(
        [string]$ComputerName = "localhost",
        [int]$Warning,
        [int]$Critical
    )

    $namespace = "root\standardcimv2\embedded"
    
    try {
        $uwfoverlay = Get-WMIObject -Class "UWF_Overlay" -Namespace $namespace -ComputerName $ComputerName -ErrorAction Stop
    }
    catch {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Error"

        return $returnObject
    }

    if ($Warning) {
        $warnMethod = $uwfoverlay.SetWarningThreshold($Warning)
        if ($warnMethod.ReturnValue -eq 0) {
            Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Warning (Status)" -Value "Successful"
        }
        else {
            Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Warning (Status)" -Value "Failed"
        }
    }

    if ($Critical) {
        $critMethod = $uwfoverlay.SetCriticalThreshold($Critical)
        if ($critMethod.ReturnValue -eq 0) {
            Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Critical (Status)" -Value "Successful"
        }
        else {
            Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Critical (Status)" -Value "Failed"
        }
    }

    return $returnObject
}

function Get-UWFOverlayInfo {

    <# 
        .SYNOPSIS
        Get information about the overlay.

        .DESCRIPTION
        Get information about the overlay size, free space, and consumed space.

        .PARAMETER ComputerName
        The name of the computer that the command is being ran on. If no computer name is given, then it runs locally.

    #>

    param(
        [string]$ComputerName = "localhost"
    )

    $namespace = "root\standardcimv2\embedded"

    $returnObject = New-Object -TypeName psobject

    try {
        $uwfoverlay = Get-WMIObject -Class "UWF_Overlay" -Namespace $namespace -ComputerName $ComputerName -ErrorAction Stop
    }
    catch {
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName
        Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Status" -Value "Error"

        return $returnObject
    }

    $overlayConsumed = $uwfoverlay.OverlayConsumption
    $overlayAvail = $uwfoverlay.AvailableSpace
    $overlaySize = $overlayConsumed + $overlayAvail
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Overlay (Size)" -Value "$overlaySize MB"
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Overlay (Consumed)" -Value "$overlayConsumed MB"
    Add-Member -InputObject $returnObject -MemberType NoteProperty -Name "Overlay (Free Space)" -Value "$overlayAvail MB"

    return $returnObject

}