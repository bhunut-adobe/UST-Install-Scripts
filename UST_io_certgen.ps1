$ErrorActionPreference = "Stop"
Write-Host "Generate Adobe.IO Self-Signed Certifcation"
$defaulExpirationDate = (Get-Date).AddYears(5).ToString("d")

do{
    $inputDate = Read-Host -Prompt "Enter Certificate Expiring Date [$defaulExpirationDate]"
    $inputDate = ($defaulExpirationDate,$inputDate)[[bool]$inputDate]
    $expirationDate = Get-Date $inputDate  -Hour (Get-Date).Hour -Minute ((Get-Date).Minute + 1)
}while($expirationDate -le (Get-Date))

$expirationDay = ($expirationDate - (Get-Date)).Days

$USTFolder = "..\..\"
$OpenSSL = "openssl.exe"
$OpenSSLConfig = ".\openssl.cnf"

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
        try {
            # Will not work without GUI
            & explorer.exe "https://www.adobe.io/console"
        } catch {}
    }else{
        Write-Error "Error Generating Certificate"
    }

}else{

    Write-Error "Unable to Locate $OpenSSL"

}