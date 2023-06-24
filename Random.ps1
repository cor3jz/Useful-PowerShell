# Restoring components
Repair-WindowsImage -Online -RestoreHealth
DISM /Online /Cleanup-Image /RestoreHealth

# WinSxS cleaning up
DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase

# Write-Progress
$ExcludedAppxPackages = @(
	"NVIDIACorp.NVIDIAControlPanel"
)
$OFS = "|"
$AppxPackages = (Get-AppxPackage -PackageTypeFilter Bundle -AllUsers).Name | Select-String $ExcludedAppxPackages -NotMatch
foreach ($AppxPackage in $AppxPackages)
{
	Write-Progress -Activity "Uninstalling UWP apps" -Status "Removing $AppxPackage" -PercentComplete ($AppxPackages.IndexOf($AppxPackage)/$AppxPackages.Count * 100)
	Get-AppxPackage -PackageTypeFilter Bundle -AllUsers | Where-Object -FilterScript {$_.Name -cmatch $AppxPackage} | Remove-AppxPackage -AllUsers
}
Write-Progress -Activity "Uninstalling UWP apps" -Completed

# Validate all .psd1 in all folders
$Folder = Get-ChildItem -Path "D:\Desktop\Sophia Script" -Recurse -Include *.psd1
foreach ($Item in $Folder.DirectoryName)
{
	Import-LocalizedData -FileName Sophia.psd1 -BaseDirectory $Item -BindingVariable Data
}

# Auto elevate script
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $IsAdmin)
{
	Start-Process -FilePath powershell.exe -ArgumentList "-ExecutionPolicy Bypass -NoProfile -NoLogo -File `"$PSCommandPath`"" -Verb Runas
	exit
}
& "$PSScriptRoot\File.ps1"

# Get NVidia videocard temperature
nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader

# Get disks temperature
Get-PhysicalDisk | Get-Disk | ForEach-Object -Process {
	[PSCustomObject]@{
		Disk        = $_.FriendlyName
		Temperature = (Get-PhysicalDisk -DeviceNumber $_.DiskNumber | Get-StorageReliabilityCounter).Temperature
	}
}

# Display all environment variables
Get-ChildItem -Path env:

# Add "Windows Photo Viewer" to Open with context menu
if (-not (Test-Path -Path Registry::HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\open\command))
{
	New-Item -Path Registry::HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\open\command -Force
}
if (-not (Test-Path -Path Registry::HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\open\DropTarget))
{
	New-Item -Path Registry::HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\open\DropTarget -Force
}
New-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\open -Name MuiVerb -Type String -Value "@photoviewer.dll,-3043" -Force
New-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\open\command -Name "(default)" -Type ExpandString -Value "%SystemRoot%\System32\rundll32.exe `"%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll`", ImageView_Fullscreen %1" -Force
New-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\Applications\photoviewer.dll\shell\open\DropTarget -Name Clsid -Type String -Value "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}" -Force

# Associate BMP, JPEG, PNG, TIF to "Windows Photo Viewer"
cmd.exe --% /c ftype Paint.Picture=%windir%\System32\rundll32.exe "%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll", ImageView_Fullscreen %1
cmd.exe --% /c ftype jpegfile=%windir%\System32\rundll32.exe "%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll", ImageView_Fullscreen %1
cmd.exe --% /c ftype pngfile=%windir%\System32\rundll32.exe "%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll", ImageView_Fullscreen %1
cmd.exe --% /c ftype TIFImage.Document=%windir%\System32\rundll32.exe "%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll", ImageView_Fullscreen %1
cmd.exe --% /c assoc .bmp=Paint.Picture
cmd.exe --% /c assoc .jpg=jpegfile
cmd.exe --% /c assoc .jpeg=jpegfile
cmd.exe --% /c assoc .png=pngfile
cmd.exe --% /c assoc .tif=TIFImage.Document
cmd.exe --% /c assoc .tiff=TIFImage.Document
cmd.exe --% /c assoc Paint.Picture\DefaultIcon=%SystemRoot%\System32\imageres.dll,-70
cmd.exe --% /c assoc jpegfile\DefaultIcon=%SystemRoot%\System32\imageres.dll,-72
cmd.exe --% /c assoc pngfile\DefaultIcon=%SystemRoot%\System32\imageres.dll,-71
cmd.exe --% /c assoc TIFImage.Document\DefaultIcon=%SystemRoot%\System32\imageres.dll,-122

# Signal if Internet connection is down (or vice-versa if needed)
while ($true)
{
	try
	{
		$Parameters = @{
			Uri              = "https://www.google.com"
			Method           = "Head"
			DisableKeepAlive = $true
			UseBasicParsing  = $true
		}
		if ((Invoke-WebRequest @Parameters).StatusDescription)
		{
			Write-Warning -Message "Internet connection is up" -Verbose
		}
	}
	catch [System.Net.WebException]
	{
		# Play beep
		[console]::beep(500,300)
	}
}

# Get Computer NetBIOS name
$ComputerList = Get-Content -Path ".\ComputerList.txt"

foreach ($Computer in $ComputerList) {
    $ComputerSystem = Get-WmiObject Win32_ComputerSystem -ComputerName $Computer
    Write-Host $ComputerSystem.Name -ForegroundColor Green
}

# Test Connection
$ComputerList = Get-Content -Path ".\ComputerList.txt"

foreach ($Computer in $ComputerList) {
    if (Test-Connection -ComputerName $Computer -Quiet -Count 1) {
        Write-Host $Computer -ForegroundColor Green
    }
    else {
        Write-Host $Computer -ForegroundColor Red
    }
}

## Getting information from WMI

## Find all properties and values in the Win32_ComputerSystem class
Get-WmiObject -Class Win32_ComputerSystem

## Find only the model
Get-WmiObject -Query 'SELECT Model FROM Win32_ComputerSystem'

## Find free disk space for all hard drive partitions
Get-WmiObject -Class win32_logicaldisk | % {"Drive $($_.DeviceID) has $($_.Freespace/1GB) GB free"}
Get-WmiObject -Class win32_logicaldisk | % {"Drive $($_.DeviceID) has " + “{0:N0}” -f ($_.Freespace/1GB) + ' GB free'}

# Install Google Chrome
$DownloadPath = Join-Path -Path "C:\buildArtifacts" -ChildPath "Chrome.msi"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile('https://dl.google.com/chrome/install/googlechromestandaloneenterprise64.msi', $DownloadPath) 
Start-Process -FilePath msiexec.exe -ArgumentList  "/i `"$DownloadPath`" /log `"C:\buildArtifacts\ChromeInstall.log`" /qn" -Wait

# Clear DNS Cache
Get-Item -Path “HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient\DnsPolicyConfig” | Remove-Item -Confirm:$false

# Check if file exists
$FileName = "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
if([System.IO.File]::Exists($FileName))
{
    Write-Host "Outlook is installed!"
}
else
{
    Write-Host "Outlook is NOT installed!"
}

# PopUp GUI
# Information 
# Example 1: Ok
[System.Windows.MessageBox]::Show("Please reboot your computer.")

## Yes or No
# Example 1: Concept
$result = [System.Windows.Forms.MessageBox]::Show("Do you want to proceed?`nNext Line`n`nTwo Lines Next", "Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo)

if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
    Write-Host "User clicked Yes."
} else {
    Write-Host "User clicked No."
}

# Example 2: Reboot
$result = [System.Windows.Forms.MessageBox]::Show("$AppName is ready to install.  Restart your computer now to complete installation?", "Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo)
if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
    Restart-Computer
} else {
    Write-Host "Shutdown postponed." -ForegroundColor Yellow
}

# Timer
# Start Timer
$Timer = [System.Diagnostics.Stopwatch]::StartNew()

# End Timer
$Timer.Stop()

# Display Timer
$Timer.Elapsed

# Display Timer (Hour, Minutes, Seconds)
$Timer.Elapsed | Select-Object Hours, Minutes, Seconds | Format-Table

<# Output
Hours Minutes Seconds
----- ------- -------
    0       1      44
#>

# Display Timer (HMS - Varible)
$TimerFinal = $Timer.Elapsed | Select-Object Hours, Minutes, Seconds | Format-Table
$TimerFinal

# Scheduled Task - Creation - At Logon
# Specify the command and argument
#$action = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument '/c C:\Temp\start.cmd'
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "Remove-Item 'C:\Users\$env:username\temp'"

### Use Powershell instead
# $action = New-ScheduledTaskAction -Execute 'Powershell.exe' `
#
#   -Argument '-NoProfile -WindowStyle Hidden -command "& {get-eventlog -logname Application -After ((get-date).AddDays(-1)) | Export-Csv -Path c:\fso\applog.csv -Force -NoTypeInformation}"'
###

# Set the trigger to be at any user logon
$trigger =  New-ScheduledTaskTrigger -AtLogOn

# Specifies that Task Scheduler uses the Local Service account to run tasks, and that the Local Service account uses the Service Account logon. The command assigns the **ScheduledTaskPrincipal** object to the $STPrin variable.
$STPrin = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount

# Create the scheduled task
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "StartCMD" -Description "Start the CMD as admin" -Principal $STPrin

## Delete the scheduled Task
# Unregister-ScheduledTask -TaskName StartCMD -Confirm:$False
##