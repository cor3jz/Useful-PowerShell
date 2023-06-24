function InvisibleRun
{
    param (
        [ValidateScript( { Test-Path $_ })]
        [string] $Script,
        [string] $Arguments,
        [switch] $Pwsh
    )
    
    if ($Pwsh)
    {
        $PSExec = "$Env:ProgramFiles\PowerShell\7\pwsh.exe"
    }
    else
    {
        $PSExec = "$Env:windir\System32\WindowsPowerShell\v1.0\powershell.exe"
    }

    $PSArguments = @()
    $PSArguments += '-NoLogo'
    $PSArguments += '-NoProfile'
    $PSArguments += "-File $Script $Arguments"

    return Start-Process -FilePath $PSExec -ArgumentList $PSArguments -WindowStyle Hidden -PassThru
}
