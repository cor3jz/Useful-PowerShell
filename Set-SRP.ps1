# Политики ограниченного использования программ (SRP)

$RestrictedDirectory = @(
	"$env:userprofile\Downloads",
	"$env:userprofile\Documents",
	"D:\",
)
	
$AllowedDirectory = @(
	"$env:userprofile\Desktop",
	"D:\Games",
)

$ExecutableTypes = @("ADE", "ADP", "BAS", "BAT", "CHM", "CMD", "COM", "CPL", "CRT", "EXE", "HLP", "HTA", "INF", "INS", "ISP", "LNK", "MDB", "MDE", "MSC", "MSI", "MSP", "MST", "OCX", "PCD", "PIF", "REG", "SCR", "SHS", "URL", "VB", "WSC")
	
if ((Test-Path -LiteralPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer") -eq $true) { Remove-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer" -Recurse };
	New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer";
	New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer\codeidentifiers";
	New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer\codeidentifiers\0";
	New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer\codeidentifiers\262144";
	New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer\codeidentifiers\0\Paths";
	New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer\codeidentifiers\262144\Paths";
	New-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer\codeidentifiers' -Name 'DefaultLevel' -Value 262144 -PropertyType DWord;
	New-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer\codeidentifiers' -Name 'TransparentEnabled' -Value 1 -PropertyType DWord;
	New-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer\codeidentifiers' -Name 'PolicyScope' -Value 0 -PropertyType DWord;
	New-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer\codeidentifiers' -Name 'ExecutableTypes' -Value $ExecutableTypes -PropertyType MultiString;
	
foreach ($RestrictedDir in $RestrictedDirectory)
{
	$pathguid = [guid]::newguid()
	$newpathkey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer\codeidentifiers\0\Paths\{" + $pathguid + "}"
	if ((Test-Path -LiteralPath $newpathkey) -ne $true) { New-Item $newpathkey };
	New-ItemProperty -LiteralPath $newpathkey -Name 'SaferFlags' -Value 0 -PropertyType DWord;
	New-ItemProperty -LiteralPath $newpathkey -Name 'ItemData' -Value $RestrictedDir -PropertyType ExpandString;
}
	
foreach ($AllowedDir in $AllowedDirectory)
{
	$pathguid = [guid]::newguid()
	$newpathkey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer\codeidentifiers\262144\Paths\{" + $pathguid + "}"
	if ((Test-Path -LiteralPath $newpathkey) -ne $true) { New-Item $newpathkey };
	New-ItemProperty -LiteralPath $newpathkey -Name 'SaferFlags' -Value 0 -PropertyType DWord;
	New-ItemProperty -LiteralPath $newpathkey -Name 'ItemData' -Value $AllowedDir -PropertyType ExpandString;
}

# Удаление SRP
# Remove-Item -LiteralPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer" -Recurse