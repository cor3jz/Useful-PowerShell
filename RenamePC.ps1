# RenamePC v1

$compNumber = ((Get-NetIPAddress -PrefixOrigin "Dhcp" -AddressFamily IPv4).IPAddress).Substring(12)
$compName = 'DESKTOP-FPS' + $compNumber
Rename-Computer -NewName $compName -Force -Restart