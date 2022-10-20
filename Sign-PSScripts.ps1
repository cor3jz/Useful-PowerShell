# Цифровая подпись для скриптов с помощью самозаверяющего сертификата

$CertName = "PowerSign Project"
$FolderPath = "C:\Scripts"

Get-ChildItem -Path Cert:\LocalMachine\My, Cert:\CurrentUser\My | Where-Object -FilterScript {$_.Subject -eq "CN=$CertName"} | Remove-Item

$Parameters = @{
	Subject           = $CertName
	NotAfter          = (Get-Date).AddMonths(24)
	CertStoreLocation = "Cert:\LocalMachine\My"
	Type              = "CodeSigningCert"
}
$authenticode = New-SelfSignedCertificate @Parameters

$rootStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("Root","LocalMachine")

$rootStore.Open("ReadWrite")

$rootStore.Add($authenticode)

$rootStore.Close()

$publisherStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("TrustedPublisher","LocalMachine")

$publisherStore.Open("ReadWrite")

$publisherStore.Add($authenticode)

$publisherStore.Close()

$codeCertificate = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object -FilterScript {$_.Subject -eq "CN=$CertName"}


Get-ChildItem -Path $FolderPath -Recurse -File | Where-Object -FilterScript {
    ($_.Directory -notmatch "bin") -and ($_.Directory -notmatch "Start_Layout") -and ($_.Directory -notmatch "Wrapper")
} | ForEach-Object -Process {
	$Parameters = @{
		FilePath        = $_.FullName
		Certificate     = $codeCertificate
		TimeStampServer = "http://timestamp.digicert.com"
	}
	Set-AuthenticodeSignature @Parameters
}