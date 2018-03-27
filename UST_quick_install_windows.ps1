param([String]$py="3",
      [Switch]$cleanpy=$false,
      [Switch]$offline=$false)

if ($py -eq "2"){
    $pythonVersion = "2"
} elseif ($py -eq "none"){
    $pythonVersion = "none"
}
else {$pythonVersion = "3"}

$UST_Version = "2.2.2"
$ErrorActionPreference = "Stop"

# Array for collecting warnings to display at end of install
$warnings = New-Object System.Collections.Generic.List[System.Object]

# URL's Combined for convenience here
$notepadURL = "https://notepad-plus-plus.org/repository/7.x/7.5.6/npp.7.5.6.bin.x64.zip"
$7ZipURL = "https://github.com/janssenda-adobe/UST-Install-Scripts/raw/master/Util/7-Zip64.zip"
$USTPython2URL = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-windows-py2714.tar.gz"
$USTPython3URL = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.2/user-sync-v2.2.2-windows-py363.tar.gz"
$USTExamplesURL = "https://github.com/adobe-apiplatform/user-sync.py/releases/download/v2.2.1/example-configurations.tar.gz"
$openSSLBinURL = "https://indy.fulgan.com/SSL/openssl-1.0.2l-x64_86-win64.zip"
$adobeIOCertScriptURL = "https://raw.githubusercontent.com/janssenda-adobe/UST-Install-Scripts/master/UST_io_certgen.ps1"
$Python2URL = "https://www.python.org/ftp/python/2.7.14/python-2.7.14.amd64.msi"
$Python3URL = "https://www.python.org/ftp/python/3.6.4/python-3.6.4-amd64.exe"

# Set global parameters
# TLS 1.2 protocol enable - required to download from GitHub, does NOT work on Powershell < 3
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Temporary download location
$DownloadFolder = "$env:TEMP\USTDownload"

# UST folder location
$USTInstallDir = (Get-Item -Path ".\" -Verbose).FullName.TrimEnd("\") + "\UST_Install"


function Print-Color ($msg, $color) {
    Write-Host $msg -ForegroundColor $color
}

function Banner {
    Param(
        [String]$message,
        [String]$type="Info",
        [String]$color="Green"
    )

    $message = If ($message) {$message} Else {$type}

    if ($color -eq "Green"){
        switch ($type) {
            "Warning" { $color = "Yellow"; break }
            "Error" { $color = "Red"; break }
        }
    }

    $msgChar = "="
    $charLen = 20

    $messageTop = ("`n" + $msgChar*$charLen + " ${message} " + $msgChar*$charLen)
    $messageBottom = $msgChar*($messageTop.length-1)

    Print-Color $messageTop $color
}


function Expand-Zip() {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateScript({Test-Path -path $_})]
        $Path,
        $Output
    )

    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($Path)

    foreach($item in $zip.items()) {
        $shell.Namespace($Output).copyhere($item, 0x14)
    }

}

function Expand-TarGZ() {
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateScript({Test-Path -path $_})]
        $Path,
        $Output
    )

    $filename = $Path.Split('\')[-1]
    $filename = $filename.Substring(0,$filename.Length-3)

    try    {
        Start-Process -FilePath $7zpath -ArgumentList "x `"$Path`" -aoa -y -o`"$DownloadFolder`"" -Wait
        Start-Process -FilePath $7zpath -ArgumentList "x `"$DownloadFolder\$filename`" -aoa -ttar -y -o`"$Output`"" -Wait
    } catch {
       Print-Color "Error while extracting $path..." red
       Print-Color ("- " + $PSItem.ToString()) red
       $warnings.Add("- " + $PSItem.ToString())
    }
}

function Expand-Archive(){
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateScript({Test-Path -path $_})]
        $Path,
        $Output
    )

    if ( $Path.Substring($Path.Length-3) -eq "zip" ) {
        Expand-Zip -Path $Path -Output $Output
    } elseif ( $Path.Substring($Path.Length-6) -eq "tar.gz" ) {
        Expand-TarGZ -Path $Path -Output $Output
    } else {
        Print-Color $Path.Split('\')[-1] red
        $fmt = $Path.Split('\')[-1]
        throw ("Unrecognized archive format.. $fmt")
    }

}

function Remove-Python(){
    Banner "Uninstalling Python" -type Info
    $errors = $false

    # Subkeys from registry for managing installed software state
    $UninstallKey = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
    $reg = [microsoft.win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$env:computername)
    $UninstallerSubkeys = $reg.OpenSubkey($UninstallKey).GetSubkeyNames()

    foreach ($k in $UninstallerSubkeys){
        $thisKey = $reg.OpenSubKey("${UninstallKey}\\${k}")
        if ($thisKey.GetValue("DisplayName") | Select-String -pattern "(Python)" -Quiet)    {
            $matches = $true
            $id = ([String] $thisKey).Split('\')[-1]
            $rmKey = "HKLM:\\" + $UninstallKey + "\\$id"
            $app = $thisKey.GetValue("DisplayName")

            Write-Host "- Removing" $app

            $instCode = (Start-Process msiexec.exe -ArgumentList("/x $id /q /norestart") -Wait -PassThru).ExitCode

            if ($instCode -eq 0 -or $instCode -eq 1603)  {
                if (Test-Path $rmKey) {
                    Remove-Item -Path $rmKey
                }
            } else {
                $errors = $true
                $errmsg =  "- There was a problem removing ($app)`n- Please remove it manually!"
                Print-Color $errmsg red
                Print-Color ("- " + $PSItem.ToString()) red
                $warnings.Add($PSItem.ToString())

            }

        }
    }

    $systemPaths = @("C:\Python27","C:\Program Files\Python36","C:\Program Files (x86)\Python36")

    foreach ($p in $systemPaths){
        if (Test-Path $p){
            Write-Host "- Removing $p"
            Remove-Item -path $p -Force -confirm:$false -recurse
        }
    }

    if (-not ($matches)){
        Write-Host "- Nothing to uninstall!"
    } elseif ($errors){
        Print-Color "`n- Uninstallation completed with some errors..." Yellow
    } else {
        Print-Color "`n- Uninstall completed succesfully!" Green
    }
}

function Set-Directories(){


    Write-Host "- Creating directory $USTInstallDir... "
    New-Item -ItemType Directory -Force -Path $USTInstallDir | Out-Null

    #Create Temp download folder
    New-Item -Path $DownloadFolder -ItemType "Directory" -Force | Out-Null

    return $USTInstallDir

}

function Get-Util($fileURL, $outputFolder){

    New-Item -Path $outputFolder -ItemType "Directory" -Force | Out-Null

    $filename = $fileURL.Split('/')[-1]
    $filepath = "$DownloadFolder\$filename"

    Write-Host "- Downloading $filename from $fileURL"
    (New-Object net.webclient).DownloadFile($fileURL, $filepath)

    if(Test-Path $filepath){
        Write-Host "- Extracting $filename to $outputFolder"
        Expand-Archive -Path $filepath -Output $outputFolder
        return $outputFolder
    }
}



function Get-USTFiles () {
    Banner -message "Download UST Files"
    if ($pythonVersion -eq 2){
        $URL = $USTPython2URL
    } else {
        $URL = $USTPython3URL
    }

    #Download UST 2.2.2 and Extract
    $USTdownloadList = @()
    $USTdownloadList += $URL
    $USTdownloadList += $USTExamplesURL

    foreach($download in $USTdownloadList){
        $filename = $download.Split('/')[-1]
        $downloadfile = "$DownloadFolder\$filename"

        #Download file
        Write-Host "- Downloading $filename from $download"

        $wc = New-Object net.webclient
        $wc.DownloadFile($download,$downloadfile)

        if(Test-Path $downloadfile){
            #Extract downloaded file to UST Folder
            Write-Host "- Extracting $downloadfile to $USTFolder"
            Expand-Archive -Path $downloadfile -Output $USTFolder
        }
    }


    #Make example config files readable in windows and Copy "config files - basic" to root
    $configExamplePath = "$USTFolder\examples"

    if(Test-Path -Path $configExamplePath){
        Get-ChildItem -Path $configExamplePath -Recurse -Filter '*.yml' | % { ( $_ |  Get-Content ) | Set-Content $_.pspath -Force }
        #Copy config files
        $configBasicPath = "$configExamplePath\config files - basic"
        Copy-Item -Path "$configBasicPath\3 connector-ldap.yml" -Destination $USTFolder\connector-ldap.yml -Force
        Copy-Item -Path "$configBasicPath\2 connector-umapi.yml" -Destination $USTFolder\connector-umapi.yml -Force
        Copy-Item -Path "$configBasicPath\1 user-sync-config.yml" -Destination $USTFolder\user-sync-config.yml -Force


    }
}


function Get-OpenSSL () {

    #Download OpenSSL 1.0.2l binary for Windows and extract to utils folder
    $openSSLBinFileName = $openSSLBinURL.Split('/')[-1]
    $openSSLOutputPath = "$DownloadFolder\$openSSLBinFileName"
    $openSSLUSTFolder = "$USTFolder\Utils\openSSL"
    Write-Host "- Downloading OpenSSL Win32 Binary from $openSSLBinURL"

    $wc = New-Object net.webclient
    $wc.DownloadFile($openSSLBinURL,$openSSLOutputPath)

    if(Test-Path $openSSLOutputPath){
        #- Extracting downloaded file to UST folder.
        Write-Host "- Extracting $openSSLBinFileName to $openSSLUSTFolder"
        try{
            New-Item -Path $openSSLUSTFolder -ItemType Directory -Force | Out-Null
            Expand-Archive -Path $openSSLOutputPath -Output $openSSLUSTFolder
            Write-Host "- Completed extracting $openSSLBinFileName to $openSSLUSTFolder"
        }catch{
            Write-Error "Unable to extract openSSL"
        }
    }

    #Download Default Openssl.cfg configuration file
    $openSSLConfigURL = 'http://web.mit.edu/crypto/openssl.cnf'
    $openSSLConfigFileName = $openSSLConfigURL.Split('/')[-1]
    $openSSLConfigOutputPath = "$USTFolder\Utils\openSSL\$openSSLConfigFileName"
    Write-Host "- Downloading default openssl.cnf config file from $openSSLConfigURL"
    #Invoke-WebRequest -Uri $openSSLConfigURL -OutFile $openSSLConfigOutputPath

    $wc = New-Object net.webclient
    $wc.DownloadFile($openSSLConfigURL,$openSSLConfigOutputPath)

    return $openSSLUSTFolder

}

function Finalize-Installation ($openSSLUSTFolder) {

    #Download Adobe.IO Cert generation Script and put it into utils\openSSL folder
    $adobeIOCertScript = $adobeIOCertScriptURL.Split('/')[-1]
    $adobeIOCertScriptOutputPath = "$USTFolder\Utils\openSSL\$adobeIOCertScript"
    Write-Host "- Downloading Adobe.IO Cert Generation Script from $adobeIOCertScriptURL"

    $wc = New-Object net.webclient
    $wc.DownloadFile($adobeIOCertScriptURL,$adobeIOCertScriptOutputPath)


    if(Test-Path $adobeIOCertScriptOutputPath){

        $batchfile = '@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -file ' + $adobeIOCertScript
        $batchfile | Out-File "$openSSLUSTFolder\Adobe_IO_Cert_Generation.bat" -Force -Encoding ascii

    }

    # Create Test-Mode and Live-Mode UST Batch file
    # Create batch file to easily open .yml files

    if(Test-Path $USTFolder){
        Write-Host "- Creating Open_Config_Files.bat... "
        $openCFG_batchfile = @"
start "" .\Utils\Notepad++\notepad++.exe *.yml *.crt
exit
"@
        $openCFG_batchfile | Out-File "$USTFolder\Open_Config_Files.bat" -Force -Encoding ascii

        Write-Host "- Creating Run_UST_Test_Mode.bat... "
        $test_mode_batchfile = @"
REM "Running UST in TEST-MODE"
python user-sync.pex --process-groups --users mapped -t
pause
"@
        $test_mode_batchfile | Out-File "$USTFolder\Run_UST_Test_Mode.bat" -Force -Encoding ascii

        Write-Host "- Creating Run_UST_Live.bat... "
        $live_mode_batchfile = @"
REM "Running UST"
python user-sync.pex --process-groups --users mapped
"@
        $live_mode_batchfile | Out-File "$USTFolder\Run_UST_Live.bat" -Force -Encoding ascii
    }

}

function Package(){

    Banner -message "Packaging"

    $filename = "UST_v$UST_Version.zip"

    try    {
        Write-Host "- Creating $filename with Python $pythonVersion"
        Start-Process -FilePath $7zpath -ArgumentList "a $filename `"$USTFolder\*`"" -Wait -NoNewWindow | Out-Null
    } catch {
        Print-Color "Error while packaging..." red
        Print-Color ("- " + $PSItem.ToString()) red
        $warnings.Add("- " + $PSItem.ToString())
    }
}

function Get-Python () {
    Banner -message "Install Python"
    $install = $FALSE
    $UST_version = 3
    $inst_version = $pythonVersion

    # Subkeys from registry for managing installed software state
    $UninstallKey = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
    $reg = [microsoft.win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$env:computername)
    $UninstallerSubkeys = $reg.OpenSubkey($UninstallKey).GetSubkeyNames()

    foreach ($k in $UninstallerSubkeys){
        $thisKey = $reg.OpenSubKey("${UninstallKey}\\${k}")
        if ($thisKey.GetValue("DisplayName") | Select-String -pattern "(Python).+(\(64-Bit\))" -Quiet)    {
            $thisKey.GetValue("DisplayVersion") | Select-String -pattern "((3.6)|(2.7))(.)" | foreach-object {
                switch ($_.Matches[0].Groups[1].Value) {
                    "2.7" {$p2_installed = $true; break}
                    "3.6" {$p3_installed = $true; break}
                }
            }
        }
    }

    if ($pythonVersion -eq "3" -and -not $p3_installed) { $install = $true }
    elseif ($pythonVersion -eq "2" -and -not $p2_installed) { $install = $true }
    elseif ($pythonVersion -eq "none"){ $install = $false }
    else {
        Write-Host "- Python version $pythonVersion is already installed..."
    }

    if ($install -or $offline){
        Write-Host "- Python $inst_version will be downloaded..."
        if ($inst_version -eq 2){
            $pythonURL = $Python2URL
            $UST_version = 2
        } else {
            $pythonURL = $Python3URL
            $UST_version = 3
        }

        $pythonInstaller = $pythonURL.Split('/')[-1]
        $pythonInstallerOutput = "$DownloadFolder\$pythonInstaller"

        Write-Host "- Downloading Python from $pythonURL"


        $wc = New-Object net.webclient

        if ($offline) {
            if (-not (Test-Path "$USTFolder\Utils\$pythonInstaller")){
                $wc.DownloadFile($pythonURL, "$USTFolder\Utils\$pythonInstaller")
            } else {
                Print-Color "- Python already discovered, skipping... " green
            }

        } else  {

            $wc.DownloadFile($pythonURL, $pythonInstallerOutput)

            if (Test-Path $pythonInstallerOutput)
            {

                #Passive Install of Python. This will show progressbar and error.
                Write-Host "- Begin Python Installation"
                $pythonProcess = Start-Process $pythonInstallerOutput -ArgumentList @('/passive', 'InstallAllUsers=1', 'PrependPath=1') -Wait -PassThru
                if ($pythonProcess.ExitCode -eq 0)
                {

                    if ($inst_version -eq 2)
                    {
                        Write-Host "- Add C:\Python27 to path..."
                        [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Python27\", [EnvironmentVariableTarget]::Machine)
                    }

                    Write-Host "- Python Installation - Completed"
                }
                else
                {
                    if ($inst_version -eq 3)
                    {
                        Print-Color "- Error: Python may have failed to install Windows updates for this version of Windows.`n- Update Windows manually or try installing Python 2 instead..." red
                    }

                    $errmsg = "- Python Installation - Error with ExitCode: $( $pythonProcess.ExitCode )"
                    Print-Color $errmsg red
                    $warnings.Add($errmsg)
                    $install = $false
                }
            }
        }
    }

    if (-not $offline) {

        #Set Environment Variable
        Write-Host "- Set PEX_ROOT System Environment Variable"
        [Environment]::SetEnvironmentVariable("PEX_ROOT", "$env:SystemDrive\PEX", "Machine")

    }



}

function Cleanup() {
    try {
      if ($offline){
          #Delete UST Folder after archive is built for offline mode
          Remove-Item -Path $USTFolder -Recurse -Confirm:$false -Force
      }

    } catch {}
    try{
        #Delete Temp DownloadFolder for UST, Python and Config files
        Remove-Item -Path $DownloadFolder -Recurse -Confirm:$false -Force
    } catch {}
}

# Main
if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){

    $introBanner = "
                   _   _                 ___
                  | | | |___ ___ _ _    / __|_  _ _ _  __
                  | |_| (_-</ -_) '_|   \__ \ || | ' \/ _|
                   \___//__/\___|_|     |___/\_, |_||_\__|
                                             |__/
    "

    Print-Color "`n============================================================================" Cyan
    Print-Color "v $UST_Version" Cyan
    Print-Color $introBanner Cyan
    Banner -message "Adobe User Sync Tool Quick Install" -color Cyan
    Write-Host ""

    Print-Color "*** Parameter List ***`n" Green
    Write-Host "- Python Version: " $py
    Write-Host "- Clean Py Install: " $cleanpy
    Write-Host "- Offline Package: " $offline

    if ($cleanpy -and (-not $offline)) {
        try {
            Remove-Python
        } catch {
            $errmsg = "- Failed to completely remove python... "
            Print-Color $errmsg red
            $warnings.Add($errmsg)
        }
    }

    Banner -message "Creating UST Directory"
    $USTFolder = Set-Directories

    # Install Process
    Banner -message "Download Utilities"
    try    {
        Write-Host "- Downloading Notepad++..."
        Get-Util $notepadURL "$USTFolder\Utils\Notepad++\" | Out-Null
    } catch {
        Print-Color "- Failed to download Notepad++ resources with error:" red
        Print-Color ("- " + $PSItem.ToString()) red
        $warnings.Add("- " + $PSItem.ToString())
    }

    try    {
        Write-Host "- Downloading 7-Zip..."
        $7zpath = Get-Util $7ZipURL "$USTFolder\Utils\"
        $7zpath = "$7zpath\7-Zip\7z.exe"
    } catch {
        Print-Color ("- " + $PSItem.ToString()) red
        $warnings.Add("- " + $PSItem.ToString())

        if (Test-Path "$USTFolder\Utils\7-Zip\7z.exe") {
            $7zpath = "$USTFolder\Utils\7-Zip\7z.exe"
        } else {
            throw "Error getting 7zip, setup cannot continue... "
            exit
        }
    }

    try    {
        if ($pythonVersion -ne "none"){ Get-Python }
    } catch {
        Banner -type Error
        Print-Color "- Failed to install Python with error:" red
        Print-Color ("- " + $PSItem.ToString()) red
        $warnings.Add("- " + $PSItem.ToString())
    }


    try    {
        Get-USTFiles $pythonVersion
    } catch {
        Banner -type Error
        Print-Color "- Failed to download UST resources with error:" red
        Print-Color ("- " + $PSItem.ToString()) red
        $warnings.Add("- " + $PSItem.ToString())
    }

    # Try loop as connection occasionally fails the first time
    Banner -message "Download OpenSSL"
    $i = 0
    while ($true)  {
        $i++
        try {
            $openSSLUSTFolder = Get-OpenSSL
            $openSSLUSTFolder = ([String]$openSSLUSTFolder).trim()
            break
        }
        catch {
            Print-Color "- Connection failed... retrying... ctrl-c to abort..." Yellow
        }
        if ($i -eq 5) {
            Banner -type Warning
            $errmsg = "- Open SSL failed to download... retry or download manually..."
            Print-Color $errmsg red
            $warnings.Add($errmsg)
            break
        }
    }

    try  {
        Banner -message "Create Batch Scripts"
        Finalize-Installation $openSSLUSTFolder
    } catch {
        Banner -type Error
        Print-Color "- Failed to create batch files with error:" red
        Print-Color ("- " + $PSItem.ToString()) red
        $warnings.Add("- " + $PSItem.ToString())
    }

    if ($offline) {
        Package
    }

    Cleanup

    Banner -message "Install Finish" -color Blue

    if ($warnings.Count -gt 0){
        Print-Color "- Install completed with some warnings: " yellow

        foreach($w in $warnings){
            Print-Color "$w" red
        }

        Write-Host ""

    }

    Write-Host "- Completed - You can begin to edit configuration files in:`n"
    Print-Color "- $USTFolder" Green
    Write-Host ""

}else{
    Write-host "Not elevated. Re-run the script with elevated permission"
}


