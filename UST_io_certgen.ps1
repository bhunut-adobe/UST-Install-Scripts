
# Certificat generation script for the UMAPI - User-Sync transaction

# The certgen script generates a public/private key pair in the root install directory.  The certificate/key pair is
# needed for successful integration with the UMAPI.  The script will prompt the user for several values as part of
# the generation process.  The specific answers are not important in this case, as they are never used during
# verification of identity.  In fact, nearly any cert/key pair may be used for this transaction, including your
# own CA trusted pair (this script is not needed in that case).  All we need from this script is a means of
# proving the User-Sync tool's identity to the UMAPI.

# The primary user synce script creates a batch file that makes execution of this script
# as simple as double clicking and filling in the values!

$ErrorActionPreference = "Stop"
Write-Host "Generate Adobe.IO Self-Signed Certifcation"
$defaulExpirationDate = (Get-Date).AddYears(15).ToString("d")

# Prompt the user for the expiration date.  The default is 15 years for convenience, but may be extended indefinitely.
do{
    $inputDate = Read-Host -Prompt "Enter Certificate Expiring Date [$defaulExpirationDate]"
    $inputDate = ($defaulExpirationDate,$inputDate)[[bool]$inputDate]
    $expirationDate = Get-Date $inputDate  -Hour (Get-Date).Hour -Minute ((Get-Date).Minute + 1)
}while($expirationDate -le (Get-Date))

$expirationDay = ($expirationDate - (Get-Date)).Days

# Set the destination as two steps up from the relative path.  This will place the files in the root install directory
$USTFolder = "..\..\"
$OpenSSL = "openssl.exe"
$OpenSSLConfig = "openssl.cnf"

# The actual generation process - uses the downloaded portable version of OpenSSL to create a sha256 certificate
# with the requested expiration date.  The naming convention is arbitrary - cert/key pairs can be named anything
# - the authentication will not be impacted.
if(Test-Path $OpenSSL){
    $argslist = @("/c $OpenSSL",
                'req',
                "-config $OpenSSLConfig",
                '-x509',
                '-sha256',
                '-nodes',
                "-days $expirationDay",
                "-newkey rsa`:2048",
                "-keyout $USTFolder\private.key",
                "-out $USTFolder\certificate_pub.crt")

    $process = Start-Process -FilePath cmd.exe -ArgumentList $argslist -PassThru -Wait -NoNewWindow
    if($process.ExitCode -eq 0){
        Write-Host "Completed - Certificate located in $USTFolder."
        Pause
    }else{
        Write-Error "Error Generating Certificate"
    }

}else{

    Write-Error "Unable to Locate $OpenSSL"

}